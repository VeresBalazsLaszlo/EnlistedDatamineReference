import "%ui/control/gui_buttons.nut" as JB
import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
import "%ui/soldiers/model/getPayItemsData.nut" as getPayItemsData
import "%ui/components/colorize.nut" as colorize
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%ui/currency/currenciesWidgetUi.nut" as currenciesWidgetUi
from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontSub
from "%ui/components/msgbox.nut" import showMsgbox, showMessageWithContent, showMsgboxWithCloseButton
from "%ui/shop/mkShopItemPrice.nut" import mkSinglePrice
from "dagor.localize" import doesLocTextExist
from "%ui/components/defcomps.nut" import txt, noteTextArea
from "%ui/shop/currencyComp.nut" import mkItemCurrency, mkCurrencyImage
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/style/colors.nut" import HighlightFailure, MsgMarkedText, TextActive, TextHighlight
from "%ui/shop/shopPkg.nut" import getViewShopInfoBtnText, DISCOUNT_WARN_TIME, mkAlertObject
from "%ui/shop/armyShopState.nut" import barterShopItem, getBuyRequirementError, buyShopItem, realCurrencies, shopItemContentCtor, buyShopOffer, isContentSoldier
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/components/openUrl.nut" import openUrl, AuthenticationMode
from "%ui/currency/currencies.nut" import currenciesById, currenciesBalance
from "%ui/style/buttonsStyle.nut" import purchaseButtonStyle, primaryFlatButtonStyle
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/shop/currencyPresentation.nut" import getCurrencyPresentation
from "%ui/components/priceWidget.nut" import priceWidget
from "%ui/components/textButton.nut" import textColor, primaryStyle
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/offers/offersState.nut" import allActiveOffers
from "%ui/meta/profile.nut" import curCampItems
from "%ui/meta/servProfile.nut" import purchasesCount
from "%ui/style/designConst.nut" import midPadding, smallPadding, defTxtColor, commonBtnHeight
from "%ui/shop/shopState.nut" import setAutoGroup
from "%ui/mainMenu/sectionsState.nut" import setCurSection, Section
from "%ui/soldiers/components/perksPackage.nut" import mkStatList
from "%ui/shop/buyShopItemExternal.nut" import openPurchaseLink
from "%ui/currency/bonuses.nut" import bonusesList
from "%ui/shop/armySlotDiscount.nut" import hasSquadsEffects
from "%ui/shop/numberUtils.nut" import abbreviateAmount
from "%ui/unlocks/taskRewardsState.nut" import isSeasonEnds
from "%ui/ui_library.nut" import *

let { openShopByCurrencyId } = require("%ui/currency/purchaseMsgBox.nut")


let defTxtStyle = { color = defTxtColor }.__update(fontSub)
let smallActiveTxtStyle = { color = TextActive }.__update(fontSub)
let markedTxtStyle = { color = MsgMarkedText }.__update(fontSub)
let failureTxtStyle = { color = HighlightFailure }.__update(fontBody)
let highlightTxtStyle = { color = TextHighlight }.__update(fontBody)
let boldFailureTxtStyle = { color = HighlightFailure }.__update(fontBody)
let largeDefTxtStyle = { color = defTxtColor }.__update(fontHeading2)

let buyBtnStyle = {
  size = [SIZE_TO_CONTENT, commonBtnHeight]
  minWidth = hdpxi(200)
}

enum DISCOUNT_STATE {
  STARTED = 0
  ENDING = 1
  ENDED = 2
}

const ENLISTED_SILVER = "enlisted_silver"

let needAskOnSpendingTicket = @(ticketName) ticketName in {
  weapon_order_gold = true
  soldier_order_gold = true
  vehicle_with_skin_order_gold = true
}

const defGap = fsh(3)
const currencySize = hdpx(29)

const hotkeyY = { hotkeys = [[ "^J:Y | Enter | Space", { description = {skip = true}} ]] }
const hotkeyX = { hotkeys = [[ "^J:X", { description = {skip = true}} ]] }

let mkDescription = @(descLocId) descLocId == null ? null
  : noteTextArea(loc(descLocId)).__update(defTxtStyle, {
      halign = ALIGN_CENTER
    })

function mkResourcesLackInfo(reqResources, viewCurrs, costLocId, counts) {
  let lackResources = []
  foreach (currencyTpl, required in reqResources) {
    let count = required * counts - (viewCurrs?[currencyTpl] ?? 0)
    if (count > 0)
      lackResources.append(mkItemCurrency({
        currencyTpl, count, textStyle = boldFailureTxtStyle
      }))
  }
  if (lackResources.len() == 0)
    return null
  return {
    size = const [fsh(50), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    margin = midPadding
    children = [
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        children = [
          txt(loc("shop/notEnoughCurrency", { priceDiff = "" })).__update(failureTxtStyle)
          {
            flow = FLOW_HORIZONTAL
            gap = midPadding
            children = lackResources
          }
        ]
      }
      noteTextArea(loc(costLocId)).__update({
        halign = ALIGN_CENTER
      }, smallActiveTxtStyle)
    ]
  }
}

let mkItemDescription = @(description) makeVertScroll({
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  text = description
}.__update(fontBody)
{
  size = FLEX_H
  maxHeight = hdpx(300)
  styling = thinStyle
})

let currencyImage = @(currency) currency
  ? {
      size = const [currencySize, currencySize]
      rendObj = ROBJ_IMAGE
      image = Picture(currency.image(currencySize))
    }
  : null

let mkAllPricesView = @(priceViews) {
  flow = FLOW_HORIZONTAL
  gap = midPadding
  valign = ALIGN_CENTER
  children = [
    txt(loc("shop/willCostYou")).__update(defTxtStyle)
    {
      flow = FLOW_HORIZONTAL
      gap = {
        padding = midPadding
        children = txt(loc("mainmenu/or")).__update(defTxtStyle)
      }
      valign = ALIGN_CENTER
      children = priceViews
    }
  ]
}

let mkBarterCurrency = @(barterTpl){
  size = FLEX_V
  minHeight = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = smallPadding
  children = [
    mkCurrencyImage(getCurrencyPresentation(barterTpl)?.icon)
    @(){
      watch = realCurrencies
      padding = const [0, hdpx(3)]
      rendObj = ROBJ_TEXT
      text = realCurrencies.get()?[barterTpl]
    }.__update(fontBody)
  ]
}

let btnWithCurrImageComp = @(text, currImgs, price, sf, count, shopItemPriceInc) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  margin = const [hdpx(10), hdpx(20), hdpx(10), hdpx(50)]
  gap = hdpx(10)
  children = [
    {
      rendObj = ROBJ_TEXT
      color = textColor(sf, primaryStyle)
      text
    }.__update(fontBody)
    currImgs
    {
      rendObj = ROBJ_TEXT
      color = textColor(sf, primaryStyle)
      text = count * price
        + shopItemPriceInc * count * (count - 1) / 2
    }.__update(fontBody)
  ]
}

let notEnoughMoneyInfo = @(price, currencyId) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    txt(loc("shop/notEnoughCurrency", {
      priceDiff = price - (currenciesBalance.get()?[currencyId] ?? 0)
    })).__update(failureTxtStyle)
    currencyImage(currenciesById.get()?[currencyId])
  ]
}

function buyCurrencyText(currency, sf) {
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    margin = const [hdpx(10), hdpx(20), hdpx(10), hdpx(50)]
    gap = currencyImage(currency)
    children = loc("btn/buyCurrency").split("{currency}").map(@(text) {
      rendObj = ROBJ_TEXT
      color = textColor(sf, primaryStyle)
      text
    }.__update(fontBody))
  }
}


let mkDiscountInfo = @(state) !state ? null
  : state == DISCOUNT_STATE.STARTED ? txt(loc("shop/discount_started")).__update(highlightTxtStyle)
  : state == DISCOUNT_STATE.ENDING ? txt(loc("shop/discount_ending")).__update(failureTxtStyle)
  : txt(loc("shop/discount_ended")).__update(failureTxtStyle)


function recalcOfferPrice(offers, offerGuid, price, fullPrice, discountState, ts) {
  let offer = offers.findvalue(@(o) o.guid == offerGuid)
  if (offer == null)
    return discountState.set(DISCOUNT_STATE.ENDED)

  let { endTime = 0, discountInPercent = 0 } = offer
  if (discountInPercent <= 0)
    return discountState.set(DISCOUNT_STATE.ENDED)

  price.set(fullPrice.get() - fullPrice.get() * discountInPercent / 100)
  let newState = endTime <= ts ? DISCOUNT_STATE.ENDED
    : endTime - ts < DISCOUNT_WARN_TIME ? DISCOUNT_STATE.ENDING
    : DISCOUNT_STATE.STARTED
  discountState.set(newState)
}

let checkAndBuy = @(needShowConfirmation, handler, text = loc("shop/purchaseBaseHeader"), customStyle = {}, currencyWidget = null)
  needShowConfirmation
    ? showMessageWithContent({
        uid = "confirmPurchaseMsgBox"
        content = {
          size = const [sw(90), fsh(32)]
          flow = FLOW_VERTICAL
          children = [
            {
              hplace = ALIGN_RIGHT
              children = currencyWidget
            }
            {
              size = FLEX
              rendObj = ROBJ_TEXT
              text
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
            }.__update(fontBody)
          ]
        }
        buttons = [
          {
            text = loc("btn/buy")
            action = handler
            customStyle = customStyle.__merge(buyBtnStyle, hotkeyX)
          }
          { text = loc("Cancel"), customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }, isCancel = true }
        ]
      })
    : handler()

function notEnoughMsg(itemTpl, missingOrders) {
  let descId = $"dontHaveEnoughOrders/{itemTpl}"
  showMsgbox({
    children = doesLocTextExist(descId)
      ? {
          rendObj = ROBJ_TEXTAREA
          size = const [sw(70), SIZE_TO_CONTENT]
          behavior = Behaviors.TextArea
          text = descId
        }.__update(largeDefTxtStyle)
      : {
        flow = FLOW_VERTICAL
        size = const [sw(70), SIZE_TO_CONTENT]
        gap = hdpx(15)
        children = [
          txt(loc("notEnoughOrders")).__update(largeDefTxtStyle)
          {
            flow = FLOW_HORIZONTAL
            children = [
              txt(loc("needMoreOrders" , { missingOrders })).__update(largeDefTxtStyle)
              mkCurrencyImage(getCurrencyPresentation(itemTpl)?.icon)
            ]
          }
          {
            rendObj = ROBJ_TEXTAREA
            size = FLEX_H
            behavior = Behaviors.TextArea
            text = loc("dontHaveEnoughOrders")
          }.__update(largeDefTxtStyle)
        ]
      }
  })
}

let titleLocalization = @(locId, shopItem) loc(locId, { purchase = loc(shopItem?.nameLocId) ?? "" })

function limitTextBlock(limit, guid) {
  if (limit <= 0)
    return null

  return function() {
    let count = purchasesCount.get()?[guid].amount ?? 0
    return {
      watch = purchasesCount
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = loc("shopItem/limit", { count, limit })
    }
  }}

let purchaseSilverBtn = {
  action = function(){
    setAutoGroup("silver")
    setCurSection(Section.SHOP)
  }
  text = function(textComp, params, handler, group, sf) {
    textComp = {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      margin = const [hdpx(10), hdpx(20), hdpx(10), hdpx(50)]
      gap = {
        size = const [currencySize, currencySize]
        rendObj = ROBJ_IMAGE
        image = Picture("!ui/uiskin/currency/enlisted_silver.svg")
      }
      children = loc("btn/buyCurrency").split("{currency}").map(@(text) {
        rendObj = ROBJ_TEXT
        color = textColor(sf, primaryStyle)
        text
      }.__update(fontBody))
      params = fontHeading2
    }
    return textButtonTextCtor(textComp, params, handler, group, sf)
  }
}

function mkNoFreeSpace(requiredInfo, activatePremiumBtn){
  let buttons = [{ text = loc("Ok"), isCancel = true }]
  if (requiredInfo.solvableByPremium && activatePremiumBtn!=null)
    buttons.append(activatePremiumBtn)
  if (requiredInfo?.resolveCb != null)
    buttons.append({ text = requiredInfo.resolveText,
      action = requiredInfo.resolveCb,
      isCurrent = true })
  return showMsgbox({ text = requiredInfo.text, buttons })
}


let canBuyWithGold = {
  size = const [fsh(50), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  margin = midPadding
  children = [
    noteTextArea(loc("buy/forEnlistedGold")).__update({
      halign = ALIGN_CENTER
    }, markedTxtStyle)
  ]
}

function getIsSeasonEndsVal() {
  return isSeasonEnds.get()
}

function buyItem(shopItem, productView = null, viewBtnCb = null, activatePremiumBtn = null,
  description = null, pOfferGuid = null, countWatched = Watched(1), isNotSuitable = false,
  purchaseCb = null, needCheckAndBuy = false
) {
  
  let requiredInfo = getBuyRequirementError(shopItem)
  if (requiredInfo != null)
    return mkNoFreeSpace(requiredInfo, activatePremiumBtn)

  let {
    guid, curItemCost = {}, referralLink = "", discountIntervalTs = [], shopItemPriceInc = 0,
    limit = -1
  } = shopItem

  
  local { price = 0, fullPrice = 0, currencyId = ""} = shopItem?.curShopItemPrice
  let currency = currenciesById.get()?[currencyId]
  if (!(isObservable(price)))
    price = Watched(price)
  if (!(isObservable(fullPrice)))
    fullPrice = Watched(fullPrice)

  let ts = serverTime.get()
  let discountState = Watched(null)
  let setDiscountEnding = @() discountState.set(DISCOUNT_STATE.ENDING)

  if (pOfferGuid != null) {
    allActiveOffers.subscribe(function(offers) {
      recalcOfferPrice(offers, pOfferGuid, price, fullPrice, discountState, serverTime.get())
    })
    recalcOfferPrice(allActiveOffers.get(), pOfferGuid, price, fullPrice, discountState, ts)
  }
  else if (discountIntervalTs.len() > 0){
    local [from, to = 0] = discountIntervalTs
    if (ts < from || ts < to){
      shopItems.subscribe(function(items){
        let curShopItem = items?[shopItem.guid]
        let curPrice = curShopItem?.curShopItemPrice.price ?? 0
        if (curPrice != price.get()){
          discountState.set(curPrice > price.get() ? DISCOUNT_STATE.ENDED : DISCOUNT_STATE.STARTED)
          price.set(curPrice)
        }
      })
      if (to > 0) {
        let delayTime = to - ts - DISCOUNT_WARN_TIME
        if (delayTime > 0) {
          gui_scene.resetTimeout(delayTime, setDiscountEnding, guid)
        } else {
          setDiscountEnding()
        }
      }
    }
  }
  let hasGold = Computed(@() price.get() > 0)

  
  let barterPrice = clone curItemCost
  let hasSilver = ENLISTED_SILVER in curItemCost
  local silverPrice = {}
  if (hasSilver){
    silverPrice = { [ENLISTED_SILVER] = curItemCost[ENLISTED_SILVER]}
    barterPrice.$rawdelete(ENLISTED_SILVER)
  }
  let silverInfo = Computed(@()
    getPayItemsData(silverPrice, curCampItems.get(), countWatched.get()))
  let hasBarter = barterPrice.len() > 0
  let barterInfo = Computed(@()
    getPayItemsData(barterPrice, curCampItems.get(), countWatched.get()))

  let hasOfferExpired = Computed(@() pOfferGuid != null
    && discountState.get() == DISCOUNT_STATE.ENDED)

  let hasSquads = (shopItem?.squads.len() ?? 0) > 0
  let hasPremDays = (shopItem?.premiumDays ?? 0) > 0
  let hasSlotSquad = hasSquadsEffects(bonusesList.get()?[shopItem?.bonusId].armyEffects)
  let contentCtor = shopItemContentCtor(shopItem)
  let shopItemContent = contentCtor?.get().content
  let isSoldier = isContentSoldier(shopItemContent)

  
  local title = isSoldier ? titleLocalization("shop/wantPurchaseSoldier", shopItem)
    : !hasSquads ? titleLocalization("shop/wantPurchaseMsg", shopItem)
    : shopItem?.nameLocId ? loc(shopItem.nameLocId)
    : ", ".join(shopItem.squads.map(@(sq) loc(getSquadPresentation(sq.id, sq.armyId)?.titleLocId)))

  local costLocId = "shop/noItemsToPay"

  if (hasBarter)
    foreach (cur, _ in curItemCost) {
      let curLocId = $"items/{cur}/acquire"
      let locId = $"shop/noItemsToPay/{cur}"

      if (doesLocTextExist(curLocId))
        title = $"{title}\n{loc(curLocId)}"

      if (doesLocTextExist(locId))
        costLocId = locId
    }

  let srcComponent = hasSquads ? "buy_squad_window" : "buy_shop_item"

  function buyCb(isSuccess) {
    if (!isSuccess)
      return
    if (hasSquads || hasPremDays || hasSlotSquad)
      sound_play("ui/purchase_additional_squad")
    purchaseCb?()
  }

  function msgBoxContent() {
    local silverPriceView = null
    local barterPriceView = null
    local goldPriceView = null
    let statsList = !isSoldier ? null : mkStatList(shopItemContent, sClassesCfg.get())
    let msgBody = [
      limitTextBlock(limit, guid)
      isNotSuitable ? mkAlertObject(loc("shop/unsuitableForSoldier")) : null
      productView ?? mkDescription(shopItem?.descLocId)
      statsList
      typeof description == "string" ? mkItemDescription(description) : description
    ]

    let allPricesData = []

    if (hasSilver){
      silverPriceView = mkSinglePrice({
        currTpl = ENLISTED_SILVER
        value = curItemCost[ENLISTED_SILVER]
      }, countWatched.get(), shopItem.guid)
      allPricesData.append(silverPriceView)
    }

    if (hasBarter) {
      let barterTpl = barterPrice.keys()[0]
      barterPriceView = mkSinglePrice({
        currTpl = barterTpl
        value = barterPrice[barterTpl]
      }, countWatched.get(), shopItem.guid)
      allPricesData.append(barterPriceView)
    }

    if (hasGold.get()){
      goldPriceView = mkSinglePrice({
        currTpl = "EnlistedGold"
        price = price.get()
        fullPrice = fullPrice.get()
      }, countWatched.get(), shopItem.guid)
      allPricesData.append(goldPriceView)
    }

    let allPrices = mkAllPricesView(allPricesData)

    msgBody.append(allPrices)

    
    local canBuyWithGoldInfo = null
    if (hasSilver && !silverInfo.get()) {
      msgBody.append(mkResourcesLackInfo(
        silverPrice, realCurrencies.get(), "shop/noSilverToPay", countWatched.get()))
      if (price.get() > 0) {
        canBuyWithGoldInfo = canBuyWithGold
      }
    }

    
    if (hasBarter && !barterInfo.get()){
      msgBody.append(mkResourcesLackInfo(
        barterPrice, realCurrencies.get(), "shop/noItemsToPay", countWatched.get()))
      if (price.get() > 0) {
        canBuyWithGoldInfo = canBuyWithGold
      }
    }

    if (canBuyWithGoldInfo
      && (currenciesBalance.get()?[currencyId] ?? 0) >= price.get() * countWatched.get())
      msgBody.append(canBuyWithGoldInfo)

    
    if ((currenciesBalance.get()?[currencyId] ?? 0) < price.get() * countWatched.get())
      msgBody.append(notEnoughMoneyInfo(price.get() * countWatched.get(), currencyId))

    msgBody.append(mkDiscountInfo(discountState.get()))

    let watch = [price, fullPrice, currenciesBalance, silverInfo, barterInfo, hasGold, countWatched,
      discountState, contentCtor, countWatched]
    return {
      watch
      size = const [fsh(80), SIZE_TO_CONTENT]
      margin = const [defGap, 0, 0, 0]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = midPadding
      children = msgBody
      onDetach = @() gui_scene.clearTimer(guid)
    }
  }

  
  function topPanel(){
    let allResources = []

    if (hasBarter){
      let allBarterCurrencies = curItemCost.keys().map(@(tpl) mkBarterCurrency(tpl))
      allResources.extend(allBarterCurrencies)
    }

    if (hasGold.get() && currencyId in currenciesById.get()){
      let amount = currenciesBalance.get()?[currencyId]
      let buyResource =
        priceWidget(amount ?? loc("currency/notAvailable"), currencyId)
          .__update({
            size = FLEX_V
            gap = hdpx(10)
          })
      allResources.append(buyResource)
    }

    if (hasSilver && ENLISTED_SILVER in realCurrencies.get()){
      allResources.append(mkItemCurrency({
        currencyTpl = ENLISTED_SILVER
        count = abbreviateAmount(realCurrencies.get()[ENLISTED_SILVER])
      }))
    }

    return {
      watch = [hasGold, currenciesById, currenciesBalance]
      flow = FLOW_HORIZONTAL
      size = FLEX_V
      gap = hdpx(20)
      children = allResources
    }
  }

  let buttons = Computed(function(){
    local isUsedX = false
    local isUsedY = false
    let countVal = countWatched.get()
    let priceVal = price.get()
    let realCurrenciesVal = realCurrencies.get()
    let purchaseCurrency = openShopByCurrencyId?[currencyId]
    let btns = []

    if (hasSilver)
      if (silverInfo.get()){
        let [silverTpl = null, silverPrc = 0] = silverPrice.topairs()?[0]
        let buyInfoSilver = getPayItemsData(silverPrice, curCampItems.get(), countVal)
        let silverCurrImg = mkCurrencyImage(getCurrencyPresentation(silverTpl)?.icon)
        btns.append({
          action = function() {
            let deltaSilver = silverPrc * countVal - (realCurrenciesVal?[silverTpl] ?? 0)
            if (deltaSilver > 0)
              notEnoughMsg(silverTpl, deltaSilver)
            else
              barterShopItem(shopItem, buyInfoSilver, buyCb, countVal)
          }
          text = function(textComp, params, handler, group, sf) {
            textComp = btnWithCurrImageComp(
              isSoldier ? loc("btn/enlist") : loc("btn/buy"),
              silverCurrImg,
              silverPrc,
              sf,
              countVal,
              shopItemPriceInc)
            params = params.__merge(fontHeading2)
            return textButtonTextCtor(textComp, params, handler, group, sf)
          }
          customStyle = {}.__update(primaryFlatButtonStyle, hotkeyY)
        })
        isUsedY = true
      } else if (referralLink == "")
        btns.append(purchaseSilverBtn)

    if (hasBarter)
      if (barterInfo.get()) {
        let [barterTpl = null, barterPrc = 0] = barterPrice.topairs()?[0]
        let buyInfoBarter = getPayItemsData(barterPrice, curCampItems.get(), countVal)
        let barterCurrImgs = mkCurrencyImage(getCurrencyPresentation(barterTpl)?.icon)
        let customStyle = {}.__update(primaryFlatButtonStyle, !isUsedY ? hotkeyY : {})

        btns.append({
          action = function() {
            let deltaBarter = barterPrc * countVal - (realCurrenciesVal?[barterTpl] ?? 0)
            if (deltaBarter > 0)
              notEnoughMsg(barterTpl, deltaBarter)
            else
              checkAndBuy(
                needAskOnSpendingTicket(barterTpl),
                @() barterShopItem(shopItem, buyInfoBarter, buyCb, countVal),
                titleLocalization("shop/wantPurchaseMsg", shopItem),
                customStyle,
                mkBarterCurrency(barterTpl)
              )
          }
          text = function(textComp, params, handler, group, sf) {
            textComp = btnWithCurrImageComp(
              isSoldier ? loc("btn/enlist") : loc("btn/buy"),
              barterCurrImgs,
              barterPrc,
              sf,
              countVal,
              shopItemPriceInc)
            params = params.__merge(fontHeading2)
            return textButtonTextCtor(textComp, params, handler, group, sf)
          }
          customStyle
        })
        isUsedY = true
      }

    if (referralLink != "" && ((hasSilver && !silverInfo.get())
      || (hasBarter && !barterInfo.get()))){
      btns.append({
        text = loc("btn/gotoReferralLink")
        action = @() openUrl(referralLink, AuthenticationMode.NOT_AUTHENTICATED, true)
        customStyle = !isUsedY ? hotkeyY : {}
      })
      isUsedY = true
    }

    if (hasGold.get() && !hasOfferExpired.get()) {
      let currencyBalance = currenciesBalance.get()?[currencyId] ?? 0
      if (currencyBalance >= priceVal * countVal) {
        let customStyle = {}.__update(purchaseButtonStyle, buyBtnStyle, hotkeyX)

        btns.append({
          action = function() {
            if (("prempass_active_stat_season" in shopItem) && getIsSeasonEndsVal())
              return showMsgbox(loc("bp/seasonEndsText"))

            if (pOfferGuid != null) {
              buyShopOffer(shopItem, currencyId, priceVal, buyCb, pOfferGuid)
              sendBigQueryUIEvent("action_buy_currency", null, srcComponent)
              return
            }

            checkAndBuy(
              priceVal > 100 && needCheckAndBuy,
              function() {
                buyShopItem(shopItem, currencyId, priceVal, buyCb, countVal)
                sendBigQueryUIEvent("action_buy_currency", null, srcComponent)
              },
              titleLocalization("shop/wantPurchaseMsg", shopItem),
              customStyle,
              currenciesWidgetUi
            )
          }
          text = function(_textComp, params, handler, group, sf) {
            let textComp = btnWithCurrImageComp(
              isSoldier ? loc("btn/enlist") : loc("btn/buy"),
              currencyImage(currency),
              priceVal,
              sf,
              countVal,
              shopItemPriceInc)
            params = params.__merge(fontHeading2)
            return textButtonTextCtor(textComp, params, handler, group, sf)
          }
          customStyle
        })
        isUsedX = true
      }
      else {
        btns.append({
          text = function(textComp, params, handler, group, sf) {
            textComp = buyCurrencyText(currency, sf)
            params = params.__merge(fontHeading2)
            return textButtonTextCtor(textComp, params, handler, group, sf)
          }
          customStyle = hotkeyX,
          action = function() {
            purchaseCurrency?()
            sendBigQueryUIEvent("event_low_currency", null, srcComponent)
          }
        })
        isUsedX = true
      }
    }

    btns.append({
      text = loc("Cancel")
      customStyle = { hotkeys = [[$"^{JB.B}" ]] }
    })

    if (viewBtnCb)
      btns.append({
        text = getViewShopInfoBtnText(loc("btn/view"))
        action = viewBtnCb
        customStyle = !isUsedY ? hotkeyY
          : !isUsedX ? hotkeyX
          : {}
      })

    return btns
  })

  if (hasBarter || hasSilver || hasGold.get()){
    let params = {
      text = colorize(MsgMarkedText, title)
      fontStyle = fontBody
      children = msgBoxContent
      topPanel
      buttons
    }
    showMsgboxWithCloseButton(params)
    if (hasGold.get())
      sendBigQueryUIEvent("open_buy_currency_window", null, srcComponent)
    return
  }

  if (openPurchaseLink(shopItem))
    return

  
  showMsgbox(loc(costLocId))
}

return kwarg(buyItem)
