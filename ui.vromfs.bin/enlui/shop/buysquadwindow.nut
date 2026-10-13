import "%ui/components/faComp.nut" as faComp
import "%ui/components/mkCountdownTimer.nut" as mkCountdownTimer
import "%ui/currency/currenciesWidgetUi.nut" as currenciesWidgetUi
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/shop/buyShopItem.nut" as buyShopItem
import "%ui/components/spinner.nut" as spinner
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import brightAccentColor, smallOffset, midPadding, smallPadding, activeTxtColor
from "%ui/navState.nut" import addScene, removeScene
from "%ui/mainMenu/mainmenu.style.nut" import navHeight
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/soldiers/model/state.nut" import armySquadsById, curUnlockedSquads
from "%ui/soldiers/mkSquadPromo.nut" import mkFullScreenBack, mkBackWithImage, mkSquadBodyBig, primeDescBlock, mkPromoSquadIcon, mkPromoBackBtn
from "%ui/soldiers/components/campaignPromoPkg.nut" import btnSizeBig
from "%ui/currency/purchaseMsgBox.nut" import purchaseMsgBox
from "%ui/battleData/testDrive.nut" import isTestDriveProfileInProgress, startSquadTestDrive
from "%ui/components/textButton.nut" import Regular, Purchase, Primary
from "%ui/shop/mkShopItemPrice.nut" import mkPrice
from "%ui/offers/offersState.nut" import offersByShopItem
from "%ui/shop/rentState.nut" import rentSquadsConfig, rentSquad
from "%ui/featureFlags.nut" import canRentSquad
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, primeFlagStyle
from "%ui/components/defcomps.nut" import txt
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/profile/wallpostersState.nut" import wallpostersCfg
from "%ui/profile/wallpostersPkg.nut" import mkWallposterImg
from "%ui/shop/shopPkg.nut" import mkProductView
from "%ui/soldiers/chooseSquadsSlots.nut" import mkRentComp
from "%ui/ui_library.nut" import *

let activatePremiumBtn = require("%ui/shop/activatePremiumBtn.nut")


let defTxtStyle = { color = activeTxtColor }.__update(fontSub)
let waitingSpinner = spinner(btnSizeBig[1]/2)
let buySquadParams = mkWatched(persist, "buySquadParams")

let open = @(params) buySquadParams.set(params)

let close = @() buySquadParams.set(null)

let viewData = Computed(function() {
  let params = buySquadParams.get()
  if (!params)
    return null

  let { armyId, squadId, shopItem } = params
  if (shopItem == null)
    return null

  let squad = armySquadsById.get()?[armyId][squadId]
  if (squad != null && (squad?.expireTime ?? 0) == 0)
    return null

  let squadCfg = squadsCfgById.get()?[armyId][squadId]
  let offer = offersByShopItem.get()?[shopItem.guid]
  let productView = mkProductView(shopItem)

  return squadCfg == null ? null
    : params.__merge({
        squad
        squadCfg
        offer
        productView
      })
})

let topRightBlock = {
  size = [SIZE_TO_CONTENT, navHeight]
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = fsh(1)
  children = [
    currenciesWidgetUi
    closeBtnBase({ onClick = close })
  ]
}

function purchaseSquadCb(shopItem, productView) {
  let offer = offersByShopItem.get()?[shopItem.guid]
  buyShopItem({
    shopItem
    pOfferGuid = offer?.guid
    activatePremiumBtn
    productView
  })
  close()
}

function rentSquadCb(productView, rentOptions, armyId, squadId) {
  if (rentOptions.len() == 0)
    return

  let bestOption = rentOptions
    .reduce(@(r, o) o.price > r.price ? o : r, rentOptions[0])
  let { price, rentTime } = bestOption
  purchaseMsgBox({
    productView
    price
    currencyId = "EnlistedGold"
    purchase = @() rentSquad(armyId, squadId, rentTime, price)
    alwaysShowCancel = true
    srcComponent = "rent_squad"
    purchaseText = loc("btn/rentFor", {
      timeText = secondsToHoursLoc(rentTime)
    })
    title = loc("rentSquadHeader")
    description = loc("rentSquadInfo")
  })
  close()
}


function mkButtonsBlock(viewOptions, rentOptions) {
  let {
    shopItem, productView, armyId, squadId, offer, isBuyDisabled = false
  } = viewOptions

  let squadRented = curUnlockedSquads.get()
    .findvalue(@(s) s.squadId == squadId && (s?.expireTime ?? 0) > 0 )
  let isRented = squadRented != null
  let rentInfo = !isRented ? null
    : mkRentComp(squadRented.expireTime, { size = FLEX_H })

  let offerInfo = offer == null ? null
    : mkHeaderFlag({
        flow = FLOW_VERTICAL
        padding = [smallPadding, smallOffset, midPadding, midPadding]
        children = [
          txt({ text = loc("specialOfferShort") }.__update(defTxtStyle))
          mkCountdownTimer({ timestamp = offer.endTime })
        ]
      }, primeFlagStyle.__merge({
        offset = 0
        flagColor = brightAccentColor
      }))

  let summary = mkPrice({
    shopItem,
    bgParams = { hplace = offer == null ? ALIGN_CENTER : ALIGN_RIGHT }
  })

  let purchaseInfo = isBuyDisabled ? null
    : {
        size = FLEX_H
        valign = ALIGN_CENTER
        children = [ offerInfo, summary ]
      }

  let isRentShopItem = (shopItem.squads ?? [])
    .findvalue(@(s) s.id == squadId && (s?.rentTime ?? 0) > 0) != null
  let purchaseTxt = !isRentShopItem ? loc("squads/purchase")
    : isRented ? loc("squads/extend")
    : loc("squads/rent")
  let purchaseBtn = isBuyDisabled ? null
    : Purchase(purchaseTxt, @() purchaseSquadCb(shopItem, productView), {
        size = btnSizeBig
        hotkeys = [[ "^J:Y", { description = { skip = true }} ]]
      })

  let rentBtn = isBuyDisabled || rentOptions.len() == 0 ? null
    : Primary(isRented ? loc("squads/extend") : loc("squads/rent"),
        @() rentSquadCb(productView, rentOptions, armyId, squadId),
        {
          size = btnSizeBig
          hotkeys = [[ "^J:Y", { description = { skip = true }} ]]
        }
      )
  return @() {
    watch = [isTestDriveProfileInProgress, canRentSquad]
    gap = midPadding
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      rentInfo
      purchaseInfo
      purchaseBtn
      canRentSquad.get() ? rentBtn : null
      isTestDriveProfileInProgress.get() ? waitingSpinner
        : Regular(loc("testDrive/squad"),
            @() startSquadTestDrive(squadId, shopItem?.guid ?? ""),
            {
              size = btnSizeBig
              hotkeys = [[ "^J:X", { description = { skip = true }} ]]
            })
      mkPromoBackBtn(close)
    ]
  }
}

const wpSize = hdpxi(100)
let plusObj = faComp("plus", {
  padding = midPadding
  fontSize = hdpx(36)
  color = activeTxtColor
})

function mkAdditionalObject(viewOptions) {
  let { shopItem } = viewOptions
  let { wallposters = [] } = shopItem
  if (wallposters.len() == 0)
    return null

  return function() {
    let res = {
      watch = wallpostersCfg
    }

    let wpCfg = wallpostersCfg.get()
    let wpChildren = wallposters.map(function(wp) {
      let wallposter = wpCfg.findvalue(@(cfg) cfg.armyId == wp.armyId && cfg.id == wp.id)
      return wallposter == null ? null : mkWallposterImg(wallposter.img, true, true, wpSize)
    }).filter(@(wp) wp != null)

    if (wpChildren.len() == 0)
      return res

    return res.__update({
      flow = FLOW_VERTICAL
      gap = smallPadding
      halign = ALIGN_RIGHT
      children = [
        txt({ text = loc("youWillAlsoGet") }.__update(defTxtStyle))
        {
          flow = FLOW_HORIZONTAL
          gap = smallOffset
          valign = ALIGN_CENTER
          children = [plusObj].extend(wpChildren)
        }
      ]
    })
  }
}

function buySquadWnd() {
  let watch = [viewData, rentSquadsConfig]
  let viewOptions = viewData.get()
  if (viewOptions == null)
    return { watch }

  let { armyId, squadCfg } = viewOptions
  let squadCfgExt = squadCfg.__merge({ armyId, isPrimeSquad = true, hasReceived = false })
  let rentOptions = rentSquadsConfig.get()?[armyId][squadCfgExt.id] ?? []
  return {
    watch
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    size = FLEX
    children = mkFullScreenBack(
      mkBackWithImage(squadCfgExt?.image),
      [
        mkSquadBodyBig(squadCfgExt,
          primeDescBlock(squadCfgExt, mkAdditionalObject(viewOptions)),
          mkButtonsBlock(viewOptions, rentOptions))
        mkPromoSquadIcon(squadCfgExt?.icon)
        topRightBlock
      ]
    )
  }
}

viewData.subscribe(@(val) val
  ? addScene(buySquadWnd)
  : removeScene(buySquadWnd))

if (viewData.get() != null)
  addScene(buySquadWnd)

return open