import "%ui/shop/buyShopItem.nut" as buyShopItem
import "%ui/components/mkCountdownTimer.nut" as mkCountdownTimer
import "%ui/components/colorize.nut" as colorize
from "math" import abs, round
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/style/fontsStyle.nut" import fontGiant, fontTitle, fontHeading1, fontHeading2, fontBody, fontSub
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/shop/armyShopState.nut" import premiumProducts, purchaseInProgress
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/currency/currencies.nut" import currenciesList
from "%ui/currency/currenciesComp.nut" import mkCurrency
from "%ui/shop/currencyComp.nut" import mkDiscountWidget
from "%ui/components/defcomps.nut" import txt, noteTextArea
from "%ui/currency/premiumComp.nut" import premiumActiveInfo, premiumImage
from "%ui/components/textButton.nut" import Purchase
from "%ui/components/openUrl.nut" import openUrl
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, primeFlagStyle, mkCenterHeaderFlag
from "%ui/style/cursors.nut" import normal
from "%ui/offers/offersState.nut" import allActiveOffers
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/navigation/commonWndParams.nut" import wndHeader
from "%ui/style/designConst.nut" import transpBgColor, defItemBlur, midPadding, accentTitleTxtColor, commonBtnHeight, titleTxtColor, selectedTxtColor
  , activeTxtColor, smallPadding, bgPremiumColor, basePremiumColor
from "%ui/preset/presetEquipCfg.nut" import SLOT_COUNT, SLOT_COUNT_MAX
from "%ui/squadPresets/squadPresetsState.nut" import PREMIUM_SLOTS_COUNT
from "%ui/ui_library.nut" import *
from "app" import get_circuit_conf

let spinner = require("%ui/components/spinner.nut")(hdpxi(90))
let { premiumUrl = null } = get_circuit_conf()


const WND_UID = "premiumWindow"
const WND_WIDTH = fsh(120)
const ANIM_DELAY = 0.1
const ANIM_TIME = 0.3
const BLINK_DELAY = 0.2
const BONUSES_TEXT_DELAY = 2.0

const DEFAULT_PREMIUM_DAYS = 30
let curSelectedId = Watched(null)
let curAnimatedId = Watched(null)
let showAnimation = Watched(true)


let defaultSelectedItem = keepref(Computed(@() premiumProducts.get().reduce(@(res, item)
    abs(res.premiumDays - DEFAULT_PREMIUM_DAYS) <= abs(item.premiumDays - DEFAULT_PREMIUM_DAYS)
      ? res : item)?.id))
defaultSelectedItem.subscribe(@(defItem) defItem ? curSelectedId.set(defItem) : null)

let mkImage = @(path, customStyle = {}) {
  rendObj = ROBJ_IMAGE
  size = FLEX
  imageValign = ALIGN_TOP
  image = Picture(path)
}.__update(customStyle)

function close() {
  if (curAnimatedId.get() != null)
    curAnimatedId.set(null)
  else
    removeModalWindow(WND_UID)
}

let mkPremiumDescAnim = @(delay) !showAnimation.get() ? {} : {
  transform = true
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = delay + 0.05,
      play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = ANIM_TIME,
      delay, play = true, easing = OutQuad }
    { prop = AnimProp.translate, from = [0, -hdpx(150)], to = [0, 0],
      duration = ANIM_TIME, delay, play = true, easing = OutQuad, onFinish = @() showAnimation.set(false) }
  ]
}

let mkPremiumValAnim = @(delay, c1, c2) [
  { prop = AnimProp.color, from = c1, to = c2, duration = 0.75,
    play = true, delay }
  { prop = AnimProp.color, from = c2, to = c2, duration = 0.15,
    play = true, delay = delay + 0.7 }
  { prop = AnimProp.color, from = c2, to = c1, duration = 0.55,
    play = true, delay = delay + 0.8 }
  { prop = AnimProp.scale, from = [1,1], to = [1.1,1.1], duration = 0.25,
    play = true, delay }
  { prop = AnimProp.scale, from = [1.1,1.1], to = [1.1,1.1], duration = 0.35,
    play = true, delay = delay + 0.2 }
  { prop = AnimProp.scale, from = [1.1,1.1], to = [1,1], duration = 0.45,
    play = true, delay = delay + 0.5 }
]

let premiumDesc = @(idx, unitVal, descText, unitDesc = null) {
  size = FLEX_H
  flow = FLOW_VERTICAL
  padding = const [fsh(4), fsh(1)]
  children = [
    {
      flow = FLOW_HORIZONTAL
      children = [
        txt({
          text = unitVal
          color = accentTitleTxtColor
          transform = true
          animations = mkPremiumValAnim(BLINK_DELAY * idx + BONUSES_TEXT_DELAY,
            accentTitleTxtColor, activeTxtColor)
        }).__update(fontGiant)
        unitDesc == null ? null
          : txt({
              text = unitDesc
              color = activeTxtColor
              padding = [0, midPadding]
            }).__update(fontHeading2)
      ]
    }
    {
      size = FLEX_H
      children = noteTextArea(descText).__update({ color = activeTxtColor }, fontBody)
    }
  ]
}.__update(mkPremiumDescAnim(ANIM_DELAY * idx))

function premiumDescBlock() {
  let { premiumBonuses = null } = gameProfile.get()
  let {
    premiumExpMul = 1, maxSquadsInBattle = 0, soldiersReserve = 0
  } = premiumBonuses
  let expBonus = 100 * (premiumExpMul - 1)
  let equipSlots = SLOT_COUNT_MAX - SLOT_COUNT
  let squadSlots = PREMIUM_SLOTS_COUNT
  return {
    watch = gameProfile
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = {
      rendObj = ROBJ_SOLID
      size = const [hdpx(1), FLEX]
      color = basePremiumColor
      margin = midPadding
    }
    children = [
      premiumDesc(0, $"+{expBonus}%", loc("premiumDescExp"), loc("exp"))
      premiumDesc(2, $"+{maxSquadsInBattle}", loc("premiumDescSquadUnits"))
      premiumDesc(3, $"+{soldiersReserve}", loc("premiumDescReserve"))
      premiumDesc(4, "+2", loc("premiumDecalSlots"))
      premiumDesc(5, $"+{max(equipSlots, squadSlots)}",
        loc("premiumPresetsSlots", { equipSlots, squadSlots }))
    ]
  }
}

function onPurchase(shopItem, premItemView, offer = null) {
  if (purchaseInProgress.get() || curAnimatedId.get() != null)
    return

  buyShopItem({
    shopItem
    pOfferGuid = offer?.guid
    productView = {
      margin = const [0,0,fsh(3),0]
      halign = ALIGN_CENTER
      children = premItemView
    }
    purchaseCb = @() curAnimatedId.set(shopItem.id)
  })
  sendBigQueryUIEvent("action_buy_premium", "premium_promo")
}

let saveValueBlock = @(selected, percents) {
  rendObj = selected ? ROBJ_SOLID : ROBJ_BOX
  size = const [hdpx(120), SIZE_TO_CONTENT]
  color = selected ? accentTitleTxtColor : null
  halign = ALIGN_CENTER
  borderWidth = const [0, 0, hdpx(2), 0]
  padding = const [hdpx(5), 0]
  children = {
    rendObj = ROBJ_TEXTAREA
    size = FLEX_H
    behavior = Behaviors.TextArea
    halign = ALIGN_CENTER
    text = loc("shop/youSave", {
      percents = colorize(selected ? selectedTxtColor :  accentTitleTxtColor, $"{percents}%")
    })
    color = selected ? selectedTxtColor : titleTxtColor
  }
}

let discountBannerHeight = hdpxi(16 + 2*smallPadding)

let mkDiscountBanner = @(locId, endTime) {
  size = const [FLEX, 0]
  pos = [0, discountBannerHeight]
  valign = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  gap = smallPadding
  flow = FLOW_VERTICAL
  children = [
    mkCenterHeaderFlag({
        size = [FLEX, discountBannerHeight]
        rendObj = ROBJ_TEXT
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        text = utf8ToUpper(loc(locId))
        color = selectedTxtColor
      }.__update(fontSub),
      primeFlagStyle.__merge({
        size = [pw(90), discountBannerHeight]
        centerColor = accentTitleTxtColor
        middle = 0.25
      })
    )
    endTime == 0 ? null : {
      rendObj = ROBJ_VECTOR_CANVAS
      size = [pw(80), discountBannerHeight]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      commands = [
        [VECTOR_WIDTH, hdpx(1)],
        [VECTOR_FILL_COLOR, accentTitleTxtColor],
        [VECTOR_COLOR, Color(0,0,0,0)],
        [VECTOR_POLY, 10,0, 90,0, 80,100, 20,100],
      ]
      children = mkCountdownTimer({ timestamp = endTime, color = selectedTxtColor })
    }
  ]
}

let mkPremItemView = @(selected, size, days, saveVal, sf = 0) {
  rendObj = ROBJ_BOX
  size
  borderWidth = hdpx(1)
  borderColor = selected || (sf & S_HOVER) ? accentTitleTxtColor : basePremiumColor
  children = {
    flow = FLOW_VERTICAL
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = [
      saveVal <= 0 ? null
        : saveValueBlock(selected, saveVal)
      txt({
        text = days
        color = selected || (sf & S_HOVER) ? accentTitleTxtColor : activeTxtColor
      }).__update(fontTitle)
      txt({
        text = loc("premiumDays", { days })
        color = activeTxtColor
      }).__update(fontHeading2)
    ]
  }
}


let purchaseButton = @(action, params = {}) Purchase(loc("btn/buy"), action, {
  size = [FLEX, commonBtnHeight]
  hotkeys = [ ["^J:Y", {description={ skip=true } sound="click"}] ]
}.__update(params))

let backgroundImageBlock = {
  rendObj = ROBJ_IMAGE
  size = FLEX
  image = Picture($"!ui/gameImage/prem_select_bg.svg")
}

let mkPremItem = kwarg(
  function(shopItem, idx, premSize, maxDayPrice, offer, currencies, curSelectedIdWatch) {
    let {
      id, premiumDays = 0, curShopItemPrice = {},
      discountInPercent = 0, discountIntervalTs = []
    } = shopItem
    local { currencyId = "", price = 0, fullPrice = 0 } = curShopItemPrice

    if (premiumDays == 0 || price == 0 || currencyId == "")
      return null

    let currency = currencies.findvalue(@(c) c.id == currencyId)
    if (currency == null)
      return null

    let isSelected = curSelectedIdWatch.get() == id
    let saveVal = premiumDays <= 0 || maxDayPrice <= 0 ? 0
      : 100 - round(price.tofloat() / premiumDays / maxDayPrice * 100)
    let cellSize = [premSize, premSize]

    let discountBanner = offer != null ? mkDiscountBanner("specialOfferShort", offer.endTime)
      : discountInPercent > 0 ? mkDiscountBanner("shop/discountNotify", discountIntervalTs?[1] ?? 0)
      : null

    return {
      flow = FLOW_VERTICAL
      children = [
        watchElemState(@(sf) {
          behavior = Behaviors.Button
          onHover = function(on) {
            if (on && isGamepad.get())
              curSelectedIdWatch.set(id)
          }
          onClick = @() isSelected
            ? onPurchase(shopItem, mkPremItemView(true, cellSize, premiumDays, saveVal), offer)
            : curSelectedIdWatch.set(id)
          children = [
            isSelected ? backgroundImageBlock : null
            {
              flow = FLOW_VERTICAL
              halign = ALIGN_CENTER
              size = [premSize + hdpx(20), SIZE_TO_CONTENT]
              padding = const [hdpx(8), 0,0,0]
              children = [
                {
                  size = FLEX_H
                  halign = ALIGN_CENTER
                  children = [
                    mkPremItemView(isSelected, cellSize, premiumDays, saveVal, sf)
                      .__update(mkPremiumDescAnim(ANIM_DELAY * idx + 0.5))
                    discountBanner
                  ]
                }
                {
                  size = [premSize, hdpx(68)]
                  valign = ALIGN_CENTER
                  halign = ALIGN_CENTER
                  gap = {
                    size = FLEX
                  }
                  flow = FLOW_HORIZONTAL
                  children = [
                    mkDiscountWidget(discountInPercent, mkPremiumDescAnim(ANIM_DELAY * idx + 0.5))
                    mkCurrency({
                      currency
                      price
                      fullPrice
                      txtStyle = { color = activeTxtColor }.__update(fontBody)
                      discountStyle = { color = activeTxtColor }.__update(fontBody)
                      dimStyle = { color = basePremiumColor}.__update(fontBody)
                    })
                  ]
                }
              ]
            }
          ]
        })
        !isSelected ? null :
          purchaseButton(@() onPurchase(shopItem,
            mkPremItemView(true, cellSize,  premiumDays, saveVal), offer))
      ]
    }.__update(mkPremiumDescAnim(ANIM_DELAY * idx + 0.5))
  })

let offersByPremItem = Computed(function() {
  let offers = allActiveOffers.get()
  let res = {}
  foreach (shopItem in premiumProducts.get()) {
    let offer = offers.findvalue(@(o) o?.shopItemGuid == shopItem.guid)
    if (offer != null)
      res[shopItem.guid] <- offer
  }
  return res
})

function premiumBuyBlockUi() {
  let res = {
    watch = [curAnimatedId, premiumProducts, currenciesList, curSelectedId, offersByPremItem]
  }
  let premiumShopItems = premiumProducts.get()
  if (curAnimatedId.get() != null || premiumShopItems.len() == 0)
    return res

  let maxDayPrice = premiumShopItems.reduce(function(maxPrice, val) {
    let days = val.premiumDays
    let price = days > 0 ? val.curShopItemPrice.price / days : 0
    return max(price, maxPrice)
  }, 0)
  let premSize = min((WND_WIDTH / premiumShopItems.len()) - hdpx(20), hdpx(220))
  let offers = offersByPremItem.get()
  return res.__update({
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = { size = FLEX }
    children = premiumShopItems.map(function(shopItem, idx) {
      let offer = offers?[shopItem.guid]
      return mkPremItem({
        shopItem, idx, premSize, maxDayPrice, offer,
        currencies = currenciesList.get(),
        curSelectedIdWatch = curSelectedId
      })
    })
  })
}

let premiumBuyBlockBtn = {
  size = const [pw(30), FLEX]
  hplace = ALIGN_CENTER
  minWidth = SIZE_TO_CONTENT
  children = purchaseButton(@() openUrl(premiumUrl))
}

let premiumInfo = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  padding = fsh(2)
  margin = const [0,0,fsh(18),0]
  children = [
    premiumImage(hdpx(80))
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      padding = fsh(1)
      children = [
        noteTextArea(loc("premiumDescBase"))
          .__update({
            color = activeTxtColor
          }, fontBody)
        {
          size = FLEX
          halign = ALIGN_RIGHT
          children = premiumActiveInfo(fontHeading2, accentTitleTxtColor)
        }
      ]
    }
  ]
}

let premiumBlockContent = @() {
  size = FLEX
  flow = FLOW_VERTICAL
  gap = midPadding
  children = [
    premiumInfo
    mkHeaderFlag({
      padding = const [fsh(2), fsh(3)]
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc("premium/title"))
    }.__update(fontHeading1), primeFlagStyle)
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      vplace = ALIGN_BOTTOM
      gap = midPadding
      children = [
        premiumDescBlock
        premiumUrl != null ? premiumBuyBlockBtn : premiumBuyBlockUi
      ]
    }
  ]
}

let premiumInfoBlock = {
  size = FLEX
  children = [
    mkImage("ui/gameImage/premium_bg.avif", { keepAspect = KEEP_ASPECT_FIT })
    premiumBlockContent()
  ]
  transform = true
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5,
      play = true, easing = OutCubic }
    { prop = AnimProp.translate, from = [0, -hdpx(250)], to = [0, 0],
      duration = 0.2, play = true, easing = OutQuad }
  ]
}

function open() {
  curSelectedId.set(defaultSelectedItem.get())
  showAnimation.set(true)
  addModalWindow({
    key = WND_UID
    rendObj = ROBJ_SOLID
    size = FLEX
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    color = bgPremiumColor
    stopMouse = true
    stopHover = true
    cursor = normal
    children = [
      @() {
        watch = safeAreaBorders
        size = FLEX
        maxHeight = fsh(100)
        padding = safeAreaBorders.get()
        children = [
          {
            size = FLEX
            flow = FLOW_HORIZONTAL
            halign = ALIGN_CENTER
            children = [
              {
                size = const [FLEX, ph(75)]
                maxWidth = hdpx(180)
                hplace = ALIGN_RIGHT
                children = mkImage("ui/gameImage/premium_decor_left.avif")
              }
              {
                size = const [WND_WIDTH, FLEX]
                children = premiumInfoBlock
              }
              {
                size = const [FLEX, ph(75)]
                maxWidth = hdpx(180)
                children = mkImage("ui/gameImage/premium_decor_right.avif")
              }
            ]
          }
          wndHeader(close)
        ]
      }
      @() {
        watch = purchaseInProgress
        pos = const [0, -hdpx(180)]
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        children = purchaseInProgress.get() ? spinner : null
      }
      function() {
        let res = { watch = [curAnimatedId, premiumProducts] }
        let shopItemId = curAnimatedId.get()
        if (shopItemId == null)
          return res

        let shopItem = premiumProducts.get().findvalue(@(s) s.id == shopItemId)
        if (shopItem == null)
          return res

        let days = shopItem?.premiumDays ?? 0
        return res.__update({
          size = FLEX
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          rendObj = ROBJ_WORLD_BLUR_PANEL
          fillColor = transpBgColor
          color = defItemBlur
          children = {
            flow = FLOW_VERTICAL
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            padding = const [0,0,hdpxi(100),0]
            children = [
              txt({ text = loc("youHaveReceived") }).__update(fontHeading2)
              txt({ text = days, color = accentTitleTxtColor }).__update(fontTitle)
              txt({ text = loc("premiumDays", { days }), color = activeTxtColor
                }).__update(fontHeading2)
              {
                size = hdpxi(140)
                margin = midPadding
                halign = ALIGN_CENTER
                valign = ALIGN_CENTER
                children = [
                  mkImage("ui/gameImage/searchlight_earth_flare.avif", {
                    size = const [hdpxi(512), hdpxi(256)]
                  })
                  premiumImage(hdpxi(140))
                ]
              }
            ]
            transform = true
            animations = [
              { prop = AnimProp.scale, from = [0.1, 0.1], to = [1, 1], duration = 0.7,
                play = true, easing = OutCubic }
              { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.7,
                play = true, easing = OutCubic }
              { prop = AnimProp.scale, from = [1, 1], to = [2, 2], delay = 2.5, duration = 0.5,
                play = true, easing = OutCubic }
              { prop = AnimProp.opacity, from = 1, to = 0, delay = 2.5, duration = 0.5,
                play = true, onFinish = @() curAnimatedId.set(null) }
            ]
          }
        })
      }
    ]
    onClick = @() null
    onDetach = @() curAnimatedId.set(null)
  })
}

return open
