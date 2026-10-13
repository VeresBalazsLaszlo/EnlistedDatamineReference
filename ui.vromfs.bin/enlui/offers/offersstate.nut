import "%ui/userstats/serverTime.nut" as serverTime
from "dagor.http" import httpFetch, HTTP_SUCCESS
from "json" import parse_json
from "app" import get_circuit
from "%ui/state/login_state.nut" import isLoggedIn
from "%ui/httpPkg.nut" import getPlatformId, getLanguageId
from "%ui/options/onlineSettings.nut" import settings
from "%ui/unlocks/eventsTaskState.nut" import specialEvents
from "statsd" import send_counter
from "%ui/meta/servProfile.nut" import offers
from "%ui/soldiers/model/state.nut" import curArmyData
from "%ui/shop/shopItems.nut" import priorityDiscounts, shopItems
from "%ui/meta/configs.nut" import mkComputedConfigView
from "%ui/featureFlags.nut" import isOffersVisible
from "%ui/meta/clientApi.nut" import update_offers, reset_offers, expire_offers
from "%ui/ui_library.nut" import *
from "%sqstd/frp.nut" import subscribeAndInit, subscribeList

const URL = "https://enlisted.net/{language}/events/event/{id}/?platform={platform}&circuit={circuit}&target=game" 
const SEEN_EVENTS_ID = "seen/eventPromo"
const SEEN_OFFERS_ID = "seen/offers"
const SEEN_OFFERS_TIME = 14400


let isSpecOffersOpened = mkWatched(persist, "isOpened", false)
let hasOfferStartBtn = Watched(false)

let eventDescs = mkWatched(persist, "eventDescs", {})
let descRequestedId = Watched(null)

let allActiveOffers = Watched([])
let curOfferIdx = Watched(0)
let curOffer = Watched(null)


let isEventUnseen = Computed(@() specialEvents.get()
  .findindex(@(event) (settings.get()?[SEEN_EVENTS_ID] ?? 0) < (event?.start ?? 0)) != null)

function markEventSeen() {
  settings.mutate(@(set)
    set[SEEN_EVENTS_ID] <- specialEvents.get()
      .reduce(@(res, event) max(res, event?.start ?? 0), 0)
  )
}


function markOfferSeen(specOffer) {
  settings.mutate(function(set) {
    let saved = clone set?[SEEN_OFFERS_ID] ?? {}
    saved[specOffer.guid] <- serverTime.get()
    set[SEEN_OFFERS_ID] <- saved
  })
}

let offersSchemes = mkComputedConfigView(function(cfg) {
  let res = {}
  foreach (offer in (cfg?.offersSchemes ?? []))
    res[offer.offerType] <- offer

  return res
})

let allOffers = Computed(function() {
  if (!isOffersVisible.get())
    return []

  let oSchemes = offersSchemes.get()
  let offersVal = offers.get()

  let offerslist = []
  foreach (offer in offersVal.values()) {
    if (offer.hasUsed)
      continue

    let scheme = oSchemes?[offer.offerType]
    if (scheme == null)
      continue

    offerslist.append(offer.__merge({ scheme }))
  }

  return offerslist
})

function recalcActiveOffers(_ = null) {
  let sItems = shopItems.get()
  let curTime = serverTime.get()
  let armyId = curArmyData.get()?.guid
  let offersList = []
  let newDiscounts = {}
  local nextTime = 0
  if (armyId != null)
    foreach (offer in allOffers.get()) {
      let { shopItemGuid, scheme = null, discountInPercent = 0 } = offer
      let shopItem = sItems?[shopItemGuid]
      if (shopItem == null || (shopItem?.curShopItemPrice.price ?? 0) <= 0)
        continue

      let endTime = offer.intervalTs[1]
      if (endTime <= curTime)
        continue

      nextTime = nextTime == 0 ? endTime : min(nextTime, endTime)
      offersList.append({
        endTime
        widgetTxt = loc(shopItem?.nameLocId ?? "")
        widgetImg = scheme?.baseWidgetImg
        windowImg = scheme?.basePromoImg
        descLocId = scheme?.baseDescLocId
        lifeTime  = scheme?.lifeTime ?? 0
        guid = offer.guid
        shopItemGuid
        discountInPercent
        offerType = offer.offerType
        testDrives = offer.testDrives
        br = offer?.br ?? 1
      })
      newDiscounts[shopItemGuid] <- discountInPercent
    }

  let wasDiscounts = priorityDiscounts.get()
  if (!isEqual(wasDiscounts, newDiscounts))
    priorityDiscounts.set(newDiscounts)

  if (allActiveOffers.get().len() > offersList.len())
    update_offers()

  allActiveOffers.set(offersList)

  let leftTime = nextTime - curTime
  if (leftTime > 0)
    gui_scene.resetTimeout(leftTime, recalcActiveOffers)
}

subscribeList(recalcActiveOffers, allOffers, curArmyData, shopItems)
recalcActiveOffers()

curOfferIdx.subscribe(@(idx) curOffer.set(allActiveOffers.get()?[idx]))

let visibleOffersInWindow = Computed(@()
  allActiveOffers.get().filter(@(o) o.offerType != "PREMIUM"))

visibleOffersInWindow.subscribe(function(offersList) {
  let offersCount = offersList.len()
  if (offersCount == 0)
    return curOfferIdx.set(-1)

  let idx = offersList.findindex(@(offer) offer.guid == curOffer.get()?.guid)
  if (idx != null)
    return curOfferIdx.set(idx)

  let curIdx = curOfferIdx.get()
  curOfferIdx.set(clamp(curIdx, 0, offersCount - 1))
})


function getUnseenTestDriveOffer() {
  let offer = visibleOffersInWindow.get().findvalue(@(offer) (offer?.testDrives ?? 0) > 0)
  if (offer == null)
    return null

  let time = settings.get()?[SEEN_OFFERS_ID][offer.guid] ?? 0
  return serverTime.get() - time > SEEN_OFFERS_TIME ? offer : null
}


let offersByShopItem = Computed(function() {
  let res = {}
  foreach (offer in allActiveOffers.get())
    res[offer.shopItemGuid] <- offer
  return res
})

let eventsData = Computed(@() specialEvents.get().map(function(event, id) {
  let desc = eventDescs.get()?[id]
  local {
    title = null,
    titleshort = null,
    imagepromo = null,
    content = null,
    published = desc != null,
    tags = []
  } = desc

  tags = tags.reduce(function(tbl, tag) {
    let pairs = "".join(tag.split(" ")).split(":")
    if (pairs.len() < 1)
      return tbl
    let key = pairs[0]
    let value = pairs?[1]
    if (key not in tbl)
      tbl[key] <- value
    else if (typeof tbl[key] == "array")
      tbl[key].append(value)
    else
      tbl[key] = [tbl[key], value]
    return tbl
  }, {})

  let hasFirstImage = content?[0].t == "image"
  let heading = hasFirstImage ? content[0].v : null 
  let description = hasFirstImage ? content.slice(1) : content
  return event.__merge({
    id
    title = title ?? loc("offers/commonTitle")
    titleshort = titleshort ?? loc("offers/commonShortTitle")
    imagepromo = imagepromo ?? heading 
    heading
    description
    published
    tags
  })
}))

let availableEventTime = Watched({})

function recalcAvailableEvents(_ = null) {
  let curTime = serverTime.get()
  let res = {}
  local closestTime = -1
  foreach (id, event in eventsData.get()) {
    if (event.start <= curTime && curTime <= event.end)
      res[id] <- true
    if (curTime < event.start && (closestTime == -1 || closestTime > event.start))
      closestTime = event.start
    if (curTime < event.end && (closestTime == -1 || closestTime > event.end))
      closestTime = event.end
  }
  availableEventTime.set(res)
  if (closestTime > 0)
    gui_scene.resetTimeout(closestTime - curTime, recalcAvailableEvents)
}
subscribeAndInit(recalcAvailableEvents, eventsData)

let eventsKeysSorted = Computed(@() eventsData.get()
  .values()
  .filter(@(evt) evt.published && evt.id in availableEventTime.get())
  .sort(@(a, b) b.start <=> a.start || a.end <=> b.end || a.id <=> b.id)
  .map(@(evt) evt.id))

async function requestOffersData(eventId) {
  if (eventId in eventDescs.get() || descRequestedId.get() != null)
    return

  let url = URL.subst({
    id = eventId
    language = getLanguageId()
    platform = getPlatformId()
    circuit = get_circuit()
  })
  descRequestedId.set(eventId)

  function markFailed() {
    descRequestedId.set(null)
    eventDescs.mutate(@(data) data[eventId] <- { published = false })
  }

  let response = await httpFetch({ method = "GET", url })
  let { status = -1, http_code = 0, body = null } = response
  if (status != HTTP_SUCCESS || http_code < 200 || 300 <= http_code) {
    send_counter("offer_receive_error", 1, { http_code })
    log($"current offers request error: {http_code}")
    markFailed()
    return
  }

  local result
  try {
    result = parse_json(body?.as_string())?.result
  } catch(e) {
  }

  if (result == null) {
    log("current offers parse error")
    markFailed()
    return
  }

  log("current offers successful data request")
  descRequestedId.set(null)
  eventDescs.mutate(@(data) data[eventId] <- result)
}

let eventDescToUpdate = keepref(Computed(@()
  specialEvents.get().findindex(@(_, id) id not in eventDescs.get())))

eventDescToUpdate.subscribe(function(eventId) {
  if (eventId)
    requestOffersData(eventId)
})

isLoggedIn.subscribe(function(logged) {
  if (logged)
    update_offers()
})

console_register_command(expire_offers, "meta.expireOffers")
console_register_command(@() reset_offers(console_print), "meta.resetOffers")
console_register_command(@() update_offers(function(res) {
  let addedOffers = res?.offers ?? {}
  let removedOffers = res?.removed.offers ?? {}
  if (addedOffers.len() > 0) {
    log($"Add {addedOffers.len()} special offers")
    foreach (offer in addedOffers) {
      let { guid, offerType, shopItemGuid, discountInPercent } = offer
      log($" + {guid} {offerType} {shopItemGuid} {discountInPercent}%")
    }
  }
  if (removedOffers.len() > 0) {
    log($"Removed {removedOffers.len()} special offers")
    foreach (guid in removedOffers)
      log($" - {guid}")
  }
}), "meta.update_offers")

console_register_command(@()
  settings.mutate(@(set) set.$rawdelete(SEEN_EVENTS_ID)), "meta.resetSeenOffersPromo")
console_register_command(@()
  settings.mutate(@(set) set.$rawdelete(SEEN_OFFERS_ID)), "meta.resetSeenTestDrives")

return {
  isSpecOffersOpened
  hasOfferStartBtn
  isRequestInProgress = Computed(@() descRequestedId.get() != null)
  eventsData
  eventsKeysSorted

  isEventUnseen
  markEventSeen
  markOfferSeen

  allActiveOffers
  offersByShopItem
  visibleOffersInWindow
  curOfferIdx
  getUnseenTestDriveOffer
}
