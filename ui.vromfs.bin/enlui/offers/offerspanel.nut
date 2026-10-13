import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/helpers/isChineseVersion.nut" as isChineseVersion
import "%ui/offers/offersWindow.nut" as offersWindow
import "%ui/components/mkCountdownTimer.nut" as mkCountdownTimer
import "%ui/offers/offersPromoWindow.nut" as offersPromoWndOpen
import "%ui/currency/premiumWnd.nut" as premiumWnd
from "%ui/shop/shopItemClick.nut" import shopItemClick
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/offers/offersState.nut" import eventsData, eventsKeysSorted, allActiveOffers
from "%ui/components/tasksPkg.nut" import taskSlotPadding
from "%ui/style/designConst.nut" import defTxtColor, startBtnWidth, accentColor, bigPadding,
  miniPadding, midPadding, darkTxtColor, smallPadding, defItemBlur, transpPanelBgColor,
  transpBgColor, highlightLineTop, highlightLineHgt, hoverSlotBgColor, mkTimerIcon,
  brightAccentColor
from "%ui/gameModes/eventModesState.nut" import hasBaseEvent, openEventModes, promotedEvent,
  eventStartTime
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/shop/currencyComp.nut" import mkDiscountWidget
from "%ui/unlocks/eventsTaskState.nut" import eventForcedUrl
from "%ui/components/openUrl.nut" import openUrl
from "%ui/soldiers/model/state.nut" import curArmy, armySquadsById, armyItemCountByTpl
from "%ui/meta/servProfile.nut" import purchasesCount
from "%ui/shop/shopItems.nut" import shopItems, shopItemsIntervals
from "%ui/shop/shopState.nut" import isTemporaryVisible
from "%ui/shop/armyShopState.nut" import isShopItemAvailable, shownByTimestamp
from "%ui/ui_library.nut" import *

const MAX_WIDGETS = 4
const DUR = 0.15

let defSmallTxtStyle = { color = defTxtColor }.__update(fontSub)
let smallDiscountTxtStyle = { color = darkTxtColor }.__update(fontSub)
let headerTxtStyle = @(sf) { color = sf & S_HOVER ?  darkTxtColor : defTxtColor }
  .__update(fontBody)
let smallWidgetHeight = hdpx(72) + highlightLineHgt
const largeWidgetHeight = hdpx(248)
let widgetHeightDif = largeWidgetHeight - smallWidgetHeight
const largeWidgetInfoHeight = hdpxi(76)
const largeWidgetImgheight = largeWidgetHeight - largeWidgetInfoHeight
const smallImgWidth = hdpxi(148)

let curLargeWidgetIdx = Watched(0)
local oldLargeWidgetIdx = 0
let timerSize = defSmallTxtStyle.fontSize


enum WidgetType {
  OFFER
  EVENT_BASE
  EVENT_SPECIAL
  URL
  FEATURED
}

let customOfferActions = {
  ["PREMIUM"] = @(_specOffer) premiumWnd()
}

const SWITCH_SEC = 8.0
const defOfferImg = "ui/stalingrad_tractor_plant_offer.avif"
const defExtUrlImg = "ui/normandy_village_04.avif"

local offers = 1
let switchTime = Watched(SWITCH_SEC)
let displayedOffers = {}
function goToNextOffer() {
  oldLargeWidgetIdx = curLargeWidgetIdx.get()
  curLargeWidgetIdx.set((curLargeWidgetIdx.get() + 1) % offers)
}

function startSwitchTimer(_ = null) {
  anim_skip(curLargeWidgetIdx.get())
  if (offers > 1 && switchTime.get() > 0) {
    anim_start(curLargeWidgetIdx.get())
    gui_scene.resetTimeout(SWITCH_SEC, goToNextOffer)
  }
  else
    gui_scene.clearTimer(goToNextOffer)
}


let anims = freeze([
  { prop = AnimProp.scale, from = [0.301, 1], to = [1, 1], duration = DUR, play = true }
])

let mkOfferImage = @(image, imgVertAlign) freeze({
  size = FLEX
  key = image
  rendObj = ROBJ_IMAGE
  image = Picture(image)
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_CENTER
  imageValign = imgVertAlign
  transform = { pivot = [0, 0] }
  animations = anims
})

let mkSmallImage = @(image, imgVertAlign) {
  size = [smallImgWidth, smallWidgetHeight - highlightLineHgt]
  rendObj = ROBJ_IMAGE
  image = Picture(image)
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_CENTER
  imageValign = imgVertAlign
}

let discountIconStyle = {
  size = const [hdpx(76), hdpx(38)]
  hplace = ALIGN_LEFT
  vplace = ALIGN_CENTER
}


let smallDiscountIconStyle = {
  size = const [hdpx(50), hdpx(24)]
  vplace = ALIGN_BOTTOM
  hplace = ALIGN_LEFT
  pos = const [-smallImgWidth, 0]
  textStyle = smallDiscountTxtStyle
}


let timerStyle = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = transpBgColor
  color = defItemBlur
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  padding = taskSlotPadding
}

let mkInfo = @(nameTxt, sf, override = {}) {
  size = const [FLEX, largeWidgetInfoHeight]
  vplace = ALIGN_BOTTOM
  valign = ALIGN_CENTER
  children = [
    highlightLineTop
    {
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      margin = bigPadding
      text = nameTxt
    }.__update(headerTxtStyle(sf))
  ]
}.__update(override)


let timer = mkTimerIcon(timerSize, {
  color = brightAccentColor
  margin = [miniPadding, smallPadding]
  hplace = ALIGN_RIGHT
})


let smallTimer = @(timestamp) timestamp <= 0 ? null : timer

let mkSmallInfo = @(nameTxt, override = {}) {
  rendObj = ROBJ_WORLD_BLUR
  size = FLEX
  fillColor = transpPanelBgColor
  color = defItemBlur
  children = {
    size = FLEX
    rendObj = ROBJ_TEXTAREA
    behavior = [Behaviors.TextArea, Behaviors.Marquee]
    vplace = ALIGN_CENTER
    margin = midPadding
    text = nameTxt
    orientation = O_VERTICAL
    delay = 1
  }.__update(defSmallTxtStyle)
}.__update(override)


function mkSmallOfferInfo(endTime, txt, discount, guid, anim) {
  if (guid not in displayedOffers) {
    displayedOffers[guid] <- true
    sendBigQueryUIEvent("display_offer", null, {
      shopItemGuid = guid
      discountInPercent = discount
    })
  }

  return {
    rendObj = ROBJ_WORLD_BLUR
    color = defItemBlur
    fillColor = transpPanelBgColor
    size = FLEX
    children = [
      mkSmallInfo(txt)
      mkDiscountWidget(discount, smallDiscountIconStyle)
      smallTimer(endTime)
    ]
  }.__update(anim)
}


function mkOfferInfo(endTime, txt, discount, guid, sf, anim) {
  let timerObject = endTime <= 0 ? null
    : {
      pos = [0, -widgetHeightDif]
      hplace = ALIGN_RIGHT
      children = mkCountdownTimer({
        timestamp = endTime
        override = timerStyle
        color = accentColor
      })
    }

  if (guid not in displayedOffers) {
    displayedOffers[guid] <- true
    sendBigQueryUIEvent("display_offer", null, {
      shopItemGuid = guid
      discountInPercent = discount
    })
  }

  return {
    size = FLEX
    children = [
      mkInfo(txt, sf)
      mkDiscountWidget(discount, { pos = const [0, -hdpx(76)] }.__update(discountIconStyle))
      timerObject
    ]
  }.__update(anim)
}

let timeBeforeEvent = @(timestamp) timestamp <= 0 ? null : mkCountdownTimer({
  timestamp = timestamp
  override = timerStyle
  prefixLocId = loc("events/comingIn")
  prefixColor = brightAccentColor
  expiredLocId = ""
})


let contentAnim = freeze({
  animations = [
    freeze({ prop = AnimProp.opacity, from = 0, to = 0, duration = DUR / 1.5, play = true })
    freeze({ prop = AnimProp.opacity, from = 0, to = 1, delay = DUR / 1.5, duration = DUR / 1.5, play = true })
  ]
})


let widgetData = freeze({
  [WidgetType.OFFER] = {
    ctor = @(specOffer, isSmall = false, hasAnim = true) function(sf) {
      let { endTime = 0, widgetTxt = "", discountInPercent = 0, shopItemGuid = "" } = specOffer
      let anim = hasAnim ? contentAnim : {}
      let infoContent = (sf & S_HOVER) != 0 || !isSmall
        ? mkOfferInfo(endTime, widgetTxt, discountInPercent, shopItemGuid, sf, anim)
        : mkSmallOfferInfo(endTime, widgetTxt, discountInPercent, shopItemGuid, anim)
      return infoContent
    }
    onClick = function(specOffer) {
      let action = customOfferActions?[specOffer.offerType] ?? offersWindow
      action(specOffer)
      let { discountInPercent = 0, shopItemGuid = "" } = specOffer
      sendBigQueryUIEvent("open_offer", null, { shopItemGuid, discountInPercent })
    }
  },

  [WidgetType.FEATURED] = {
    ctor = @(sItem, isSmall = false, hasAnim = true) function(sf) {
      let {
        isHidden = false, showIntervalTs = [], menuFeaturedIntervalTs = [],
        nameLocId = "", discountInPercent = 0, guid = ""
      } = sItem
      let endTime = !isHidden ? 0
        : max((showIntervalTs?[1] ?? 0), (menuFeaturedIntervalTs?[1] ?? 0))
      let txt = loc(nameLocId)
      let anim = hasAnim ? contentAnim : {}
      let infoContent = (sf & S_HOVER) != 0 || !isSmall
        ? mkOfferInfo(endTime, txt, discountInPercent, guid, sf, anim)
        : mkSmallOfferInfo(endTime, txt, discountInPercent, guid, anim)
      return infoContent
    }
    onClick = @(sItem) shopItemClick(sItem)
  },

  [WidgetType.EVENT_BASE] = {
    ctor = @(eventData, isSmall = false, hasAnim = true) function(sf) {
      let anim = hasAnim ? contentAnim : {}
      let isBig = !!(sf & S_HOVER) || !isSmall
      let infoContent = isBig
        ? mkInfo(eventData.text, sf, anim)
        : mkSmallInfo(eventData.text, anim)
      let timerCtor = isBig ? timeBeforeEvent : smallTimer
      return @() {
        size = FLEX
        watch = eventStartTime
        halign = ALIGN_CENTER
        children = [
          infoContent
          {
            size = FLEX
            pos = [0, isBig ? -widgetHeightDif : 0]
            children = timerCtor(eventStartTime.get()?[eventData.queueId] ?? 0)
          }.__update(anim)
        ]
      }}
    onClick = @(eventData) openEventModes(eventData.queueId)
  },

  [WidgetType.EVENT_SPECIAL] = {
    ctor = @(v, isSmall = false, hasAnim = true) function(sf) {
      let anim = hasAnim ? contentAnim : {}
      let infoContent = (sf & S_HOVER) || !isSmall
        ? mkInfo(utf8ToUpper(v.titleshort), sf, anim)
        : mkSmallInfo(utf8ToUpper(v.titleshort), anim)
      return infoContent
    }
    onClick = @(v) offersPromoWndOpen(v.id)
  },

  [WidgetType.URL] = {
    ctor = @(v, isSmall = false, hasAnim = true) function(sf) {
      let anim = hasAnim ? contentAnim : {}
      let infoContent = isSmall
        ? mkSmallInfo(v.title, anim)
        : mkInfo(v.title, sf, anim)
      return infoContent
    }
    onClick = @(v) openUrl(v.url)
  }
})

let featuredSwitchTime = Watched(0)

function updateSwitchTime(...) {
  let currentTs = serverTime.get()
  let { menuFeaturedIntervalItems = [] } = shopItemsIntervals.get()
  let nextTime = menuFeaturedIntervalItems.reduce(function(firstTs, item) {
    let [from, to = 0] = item.menuFeaturedIntervalTs
    return (currentTs < from && (from < firstTs || firstTs == 0)) ? from
      : (currentTs < to && (to < firstTs || firstTs == 0)) ? to
      : firstTs
  }, 0) - currentTs
  if (nextTime > 0)
    gui_scene.resetTimeout(nextTime, updateSwitchTime)
  featuredSwitchTime.set(currentTs)
}

function onServerTime(t) {
  if (t <= 0)
    return
  serverTime.unsubscribe(callee())
  updateSwitchTime()
}

let switchTimerWatches = [curLargeWidgetIdx, switchTime]

function onOffersAttach() {
  serverTime.subscribe(onServerTime)
  shopItemsIntervals.subscribe(updateSwitchTime)
  foreach (v in switchTimerWatches)
    v.subscribe(startSwitchTimer)
}

function onOffersDetach() {
  serverTime.unsubscribe(onServerTime)
  shopItemsIntervals.unsubscribe(updateSwitchTime)
  foreach (v in switchTimerWatches)
    v.unsubscribe(startSwitchTimer)
}

function isFeaturedVisible(id, sItem, itemCount, itemsByTime, featuredByTime) {
  let { isHidden = false, isHiddenOnChinese = false } = sItem
  if (isChineseVersion && isHiddenOnChinese)
    return false

  return !isHidden
    || isTemporaryVisible(id, sItem, itemCount, itemsByTime)
    || isTemporaryVisible(id, sItem, itemCount, featuredByTime)
}

function mkWidgetList() {
  let shownFeaturedByTimestamp = Computed(function() {
    let res = {}
    let ts = featuredSwitchTime.get()
    let { menuFeaturedIntervalItems = [] } = shopItemsIntervals.get()
    foreach (item in menuFeaturedIntervalItems) {
      let [from, to = 0] = item.menuFeaturedIntervalTs
      if (from <= ts && (ts < to || to == 0))
        res[item.id] <- true
    }
    return res
  })

  let featuredItem = Computed(function() {
    let armyId = curArmy.get()
    let squadsById = armySquadsById.get()
    let purchases = purchasesCount.get()
    let itemsByTime = shownByTimestamp.get()
    let featuredByTime = shownFeaturedByTimestamp.get()
    let itemCount = armyItemCountByTpl.get()

    local found
    foreach (id, sItem in shopItems.get()) {
      let { armies = [], menuFeaturedWeight = 0 } = sItem
      if (menuFeaturedWeight <= 0
          || !(armies.contains(armyId) || armies.len() == 0)
          || !isFeaturedVisible(id, sItem, itemCount, itemsByTime, featuredByTime)
          || !isShopItemAvailable(sItem, squadsById, purchases))
        continue

      if (found == null) {
        found = sItem
        continue
      }

      let valIntervalLen = sItem?.menuFeaturedIntervalTs.len() ?? 0
      let resIntervalLen = found?.menuFeaturedIntervalTs.len() ?? 0
      let valIntervalWeight = valIntervalLen == 2 ? 20000 : valIntervalLen == 1 ? 10000 : 0
      let resIntervalWeight = resIntervalLen == 2 ? 20000 : resIntervalLen == 1 ? 10000 : 0
      let valWeight = sItem?.menuFeaturedWeight ?? 0
      let resWeight = found?.menuFeaturedWeight ?? 0
      if (valIntervalWeight + valWeight > resIntervalWeight + resWeight)
        found = sItem
    }
    return found
  })

  return Computed(function() {
    let list = []
    let eventCount = hasBaseEvent.get() ? 1 : 0
    let modesCount = eventsKeysSorted.get().len()
    let offersCount = allActiveOffers.get().len()
    let featuredCount = featuredItem.get() != null ? 1 : 0
    let linksCount = eventForcedUrl.get().len()
    let allShopItems = shopItems.get()
    local countLeft = MAX_WIDGETS - eventCount - modesCount

    if (countLeft > 0) {
      if (offersCount > 0) {
        list.extend(allActiveOffers.get()
          .slice(0, countLeft)
          .map(function(specOffer, idx) {
            let { shopItemGuid, widgetImg = null } = specOffer
            return {
              widgetType = WidgetType.OFFER
              data = specOffer
              id = idx
              backImage = widgetImg ?? allShopItems?[shopItemGuid].image ?? defOfferImg
              vertAlign = widgetImg != null ? ALIGN_CENTER : ALIGN_TOP
            }
          }))
        countLeft -= offersCount
      } else if (featuredCount > 0) {
        list.append({
          widgetType = WidgetType.FEATURED
          data = featuredItem.get()
          backImage = featuredItem.get()?.image ?? defOfferImg
        })
        countLeft -= featuredCount
      }
    }

    if (eventCount > 0) {
      local { locId = "events_and_custom_matches", title = "", queues = [] } = promotedEvent.get()
      let queue = queues?[0]
      if (title == "")
        title = loc(locId)
      let { queueId = "" } = queue
      let { image = defOfferImg } = queue?.extraParams
      list.append({
        widgetType = WidgetType.EVENT_BASE
        data = { text = utf8ToUpper(title), queueId }
        backImage = image
      })
    }

    if (linksCount > 0 && countLeft > 0) {
      list.extend(eventForcedUrl.get()
        .slice(0, countLeft)
        .map(@(v, idx) {
          widgetType = WidgetType.URL
          data = v
          id = idx
          backImage = v?.image ?? defExtUrlImg
        }))
    }

    foreach (eventId in eventsKeysSorted.get().slice(0, MAX_WIDGETS - eventCount)) {
      let event = eventsData.get()?[eventId]
      if (event != null) {
        let { id, imagepromo = defOfferImg } = event
        list.append({
          id
          widgetType = WidgetType.EVENT_SPECIAL
          data = event
          backImage = imagepromo
        })
      }
    }

    return list
  })
}


let animTable = {
  shrinksBelowAnim = {
    transform = { pivot = [1, 0] }
    animations = [
      { prop = AnimProp.opacity, from = 1, to = 0.7, duration = DUR, play = true}
      { prop = AnimProp.scale, from = [1, 3.325], to = [1, 1], duration = DUR, play = true }
    ]
  }
  shrinksAboveAnim = {
    transform = { pivot = [1, 1] }
    animations = [
      { prop = AnimProp.opacity, from = 1, to = 0.7, duration = DUR, play = true}
      { prop = AnimProp.scale, from = [1, 3.325], to = [1, 1], duration = DUR, play = true }
    ]
  }
  moveUpAnim = {
    transform = { pivot = [0, 0] }
    animations = [
      { prop = AnimProp.translate, from = [0, widgetHeightDif], to = [0, 0], duration = DUR, play = true}
    ]
  }
  moveDownAnim = {
    transform = { pivot = [0, 0] }
    animations = [
      { prop = AnimProp.translate, from = [0, -widgetHeightDif], to = [0, 0], duration = DUR, play = true}
    ]
  }
}

let contentImgAnim = {
  transform = { pivot = [0, 0] }
  animations = [
    { prop = AnimProp.scale, from = [3.325, 1], to = [1, 1], duration = DUR, play = true }
  ]
}


function mkSmallWidget(content, idx, oldIdx, curIdx) {
  if (content == null)
    return null

  let animKey = idx > oldIdx && idx < curIdx ? "moveUpAnim"
    : idx < oldIdx && idx > curIdx ? "moveDownAnim"
    : oldIdx == idx && curIdx > idx ? "shrinksBelowAnim"
    : oldIdx == idx && curIdx < idx ? "shrinksAboveAnim"
    : null

  let hasContAnim = animKey == "shrinksBelowAnim" || animKey == "shrinksAboveAnim"
  let contImgAnim = hasContAnim ? contentImgAnim : {}

  let { widgetType, id = "", data = null, backImage = null, vertAlign = null } = content
  let offerData = widgetData[widgetType]
  let { ctor = null, onClick = null } = offerData
  let imgVertAlign = vertAlign ?? (widgetType != WidgetType.FEATURED ? ALIGN_CENTER : ALIGN_TOP)
  let smallImg = freeze({
    size = const [smallImgWidth, FLEX]
    clipChildren = true
    valign = ALIGN_BOTTOM
    children = mkSmallImage(backImage, imgVertAlign).__update(contImgAnim)
  })

  let wContent = ctor?(data, true, hasContAnim)
  return watchElemState(@(sf) {
    size = [startBtnWidth, smallWidgetHeight]
    key = id
    behavior = Behaviors.Button
    onClick = @() onClick?(data)
    onHover = function(_on) {
      oldLargeWidgetIdx = curLargeWidgetIdx.get()
      curLargeWidgetIdx.set(idx)
    }
    flow = FLOW_VERTICAL
    clipChildren = true
    rendObj = ROBJ_WORLD_BLUR
    fillColor = transpPanelBgColor
    color = defItemBlur
    children = [
      highlightLineTop
      {
        flow = FLOW_HORIZONTAL
        size = FLEX
        children = [
          smallImg
          wContent?(sf)
        ]
      }
    ]
  }.__update(animKey == null ? {} : animTable[animKey]))
}


let animations1 = freeze([{ prop = AnimProp.fillColor, from = transpPanelBgColor, to = hoverSlotBgColor,
        duration = DUR, play = true, trigger = "hovered+asasd"}])
let animations0 = freeze([
  { prop = AnimProp.color, from = transpPanelBgColor, to = hoverSlotBgColor, duration = 1, play = true,
    trigger = "hovered",}
  { prop = AnimProp.opacity, from = 0.7, to = 1, duration = DUR, play = true}
  { prop = AnimProp.scale, from = [1, 0.301], to = [1, 1], duration = DUR, play = true }
])


function mkLargeWidget(content, idx, oldIdx) {
  if (content == null)
    return null

  let { widgetType, id = "", data = null, backImage = null, vertAlign = null } = content
  let offerData = widgetData[widgetType]
  let { ctor = null, onClick = null } = offerData
  let wContent = ctor?(data)
  let imgVertAlign = vertAlign ?? (widgetType != WidgetType.FEATURED ? ALIGN_CENTER : ALIGN_TOP)

  let bgImage = freeze({
    rendObj = ROBJ_WORLD_BLUR
    size = const [FLEX, largeWidgetImgheight]
    color = defItemBlur
    fillColor = transpPanelBgColor
    clipChildren = true
    children = mkOfferImage(backImage, imgVertAlign)
  })

  return watchElemState(@(sf) {
    key = id
    size = [startBtnWidth, largeWidgetHeight]
    behavior = Behaviors.Button
    onClick = @() onClick?(data)
    onHover = function(on) {
      curLargeWidgetIdx.set(idx)
      if (on) {
        anim_skip(id)
        anim_start("hovered+asasd")
        gui_scene.clearTimer(goToNextOffer)
      }
      else
        startSwitchTimer()
    }
    clipChildren = true
    children = [
      bgImage
      {
        rendObj = ROBJ_WORLD_BLUR
        size = [FLEX, largeWidgetInfoHeight]
        vplace = ALIGN_BOTTOM
        fillColor = sf & S_HOVER ? hoverSlotBgColor : transpPanelBgColor
        color = defItemBlur
        animations = animations1
        transform = true
        children = wContent?(sf)
      }
    ]
    transform = { pivot = [1, idx < oldIdx ? 0 : 1] }
    animations = animations0
  })
}


function mkOffersPromoWidget(isExpandLocked) {
  let widgetList = mkWidgetList()
  let watch = [widgetList, curLargeWidgetIdx, isExpandLocked]

  function syncSwitchTimer(_ = null) {
    offers = widgetList.get().len()
    startSwitchTimer()
  }
  function onAttach() {
    onOffersAttach()
    widgetList.subscribe(syncSwitchTimer)
    syncSwitchTimer()
  }
  function onDetach() {
    onOffersDetach()
    widgetList.unsubscribe(syncSwitchTimer)
    gui_scene.clearTimer(goToNextOffer)
  }

  return function() {
    let widgets = widgetList.get()
    if (widgets.len() == 0)
      return { watch }
    let curIdx = isExpandLocked.get() ? -1 : curLargeWidgetIdx.get()
    return {
      watch
      size = [startBtnWidth, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = smallPadding
      halign = ALIGN_RIGHT
      onAttach
      onDetach
      children = widgets.map(@(w, idx) curIdx == idx
        ? mkLargeWidget(w, idx, oldLargeWidgetIdx)
        : mkSmallWidget(w, idx, oldLargeWidgetIdx, curLargeWidgetIdx.get())
      )
    }
  }
}

return mkOffersPromoWidget
