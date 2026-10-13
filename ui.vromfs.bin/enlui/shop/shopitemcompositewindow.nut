import "%ui/control/gui_buttons.nut" as JB
import "%ui/shop/buySquadWindow.nut" as buySquadWindow
import "%ui/shop/buyShopItem.nut" as buyShopItem
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/meta/profile.nut" import campaignsByArmy
from "%ui/shop/shopPkg.nut" import mkProductView
from "%ui/currency/premiumComp.nut" import premiumImage
from "%ui/profile/decoratorPkg.nut" import mkPortraitIcon, mkNickFrame
from "%ui/currency/currenciesComp.nut" import mkCurrency
from "%ui/currency/currenciesList.nut" import enlistedGold
from "%ui/shop/shopItems.nut" import shopSquadsCompensations, shopDecorsCompensations
from "%ui/components/textButton.nut" import Regular, Purchase
from "%ui/soldiers/model/state.nut" import squadsByArmy
from "%ui/profile/decoratorState.nut" import availPortraits, availNickFrames
from "%ui/soldiers/unlockSquadScene.nut" import openUnlockSquadScene
from "%ui/components/decoratorsPresentation.nut" import isPortrait, isFrameNick, getPortrait
from "%ui/style/designConst.nut" import smallPadding, midPadding, activeTxtColor, textBgBlurColor, accentTitleTxtColor
from "%ui/soldiers/mkSquadPromo.nut" import mkSquadBackground, mkFullScreenBack
from "%ui/soldiers/components/campaignPromoPkg.nut" import btnSizeBig
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, primeFlagStyle
from "%ui/ui_library.nut" import *

let { nickFrames } = require("%ui/components/decoratorsPresentation.nut")


let goodNameTxtStyle = { color = activeTxtColor }.__update(fontBody)
let goodValueTxtStyle = { color = accentTitleTxtColor }.__update(fontBody)


let compositeParams = mkWatched(persist, "compositeParams")

let open = @(params) compositeParams.set(params)
let close = @() compositeParams.set(null)


let mkText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  text
}.__update(fontSub, override)


let mkTextArea = @(text, override = {}) {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  text = text
}.__update(fontSub, override)


let crossOutLine = {
  size = FLEX
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(2)
  commands = [[ VECTOR_LINE, 1, 60, 99, 60 ]]
}


let mkGoldCompensation = @(count, override = {}) count == 0 ? null
  : {
      flow = FLOW_HORIZONTAL
      gap = midPadding
      valign = ALIGN_CENTER
      children = mkCurrency({
        currency = enlistedGold
        price = count
        txtStyle = { color = accentTitleTxtColor }.__update(fontSub)
      })
    }.__update(override)

function mkSquadsBlockUi(squads, shopItem) {
  return function() {
    let campaigns = campaignsByArmy.get()
    let squadsCfg = squadsCfgById.get()
    let compensations = shopSquadsCompensations.get()
    let armySquads = squadsByArmy.get()
    let squadsObjList = squads.map(function(squad) {
      let { armyId, id } = squad
      let squadCfg = squadsCfg?[armyId][id]
      if (squadCfg == null)
        return null

      let campaign = loc(campaigns?[armyId].title ?? "")
      let name = loc(squadCfg.nameLocId)
      let isOwned = (armySquads?[armyId] ?? []).findvalue(@(s) s.squadId == id) != null
      return watchElemState(@(sf) {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = midPadding
        padding = smallPadding
        valign = ALIGN_CENTER
        behavior = Behaviors.Button
        onClick = function() {
          if (isOwned)
            openUnlockSquadScene(armyId, squadCfg)
          else
            buySquadWindow({
              shopItem
              armyId
              squadId = id
              isBuyDisabled = true
            })
        }
        children = [
          {
            children = [
              mkText(loc("listWithDot", { text = $"{campaign} {name}" }), goodNameTxtStyle)
              isOwned ? crossOutLine : null
            ]
          }
          isOwned ? mkGoldCompensation(compensations?[id]) : null
          mkText(loc("btn/view"), sf & S_HOVER ? goodValueTxtStyle : goodNameTxtStyle)
        ]
      })
    })

    let headerText = utf8ToUpper(loc("shop/receiveSquadsHeader", { count = squads.len() }))
    return {
      watch = [campaignsByArmy, squadsByArmy, squadsCfgById, shopSquadsCompensations]
      size = FLEX_H
      flow = FLOW_VERTICAL
      padding = smallPadding
      children = [mkText(headerText, goodNameTxtStyle)]
        .extend(squadsObjList)
    }
  }
}


function mkAnnouncement(announcement) {
  if (announcement.announcementId == "EnlistedGold")
    return mkCurrency({
      currency = enlistedGold
      price = announcement.count
      txtStyle = { color = accentTitleTxtColor }
      iconSize = hdpxi(36)
      objectsGap = midPadding
    })
  return null
}


function mkAnnouncementsBlockUi(announcements) {
  if (announcements.len() == 0)
    return null

  return {
    flow = FLOW_VERTICAL
    gap = midPadding
    margin = midPadding
    children = announcements.map(mkAnnouncement)
  }
}


function mkPremiumBlockUi(premiumDays) {
  if (premiumDays == 0)
    return null

  return {
    flow = FLOW_HORIZONTAL
    gap = midPadding
    valign = ALIGN_CENTER
    children = [
      premiumImage(hdpxi(60), { color = textBgBlurColor })
      {
        flow = FLOW_VERTICAL
        children = [
          mkText(utf8ToUpper(loc("premium/title")), goodNameTxtStyle)
          mkText(loc("shop/addGoodWithCount", {
            count = premiumDays
            goodText = loc("premiumDays", { days = premiumDays })
          }), goodValueTxtStyle)
        ]
      }
    ]
  }
}


let receivedTextObj = {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = mkText(loc("squads/received"), { color = activeTxtColor })
}

function mkDecoratorsBlockUi(decorators) {
  if (decorators.len() == 0)
    return null

  return function() {
    let compensations = shopDecorsCompensations.get()
    let portraits = availPortraits.get()
    let availNF = availNickFrames.get()
    let children = decorators.map(function(decorator) {
      let { guid } = decorator
      if (isPortrait(guid)) {
        let isOwned = guid in portraits
        return {
          children = [
            {
              children = mkPortraitIcon(getPortrait(guid), hdpx(140))
              opacity = isOwned ? 0.3 : 1
            }
            isOwned
              ? {
                  size = FLEX
                  halign = ALIGN_CENTER
                  valign = ALIGN_BOTTOM
                  children = [
                    receivedTextObj
                    mkGoldCompensation(compensations?[guid] ?? 0, { margin = midPadding })
                  ]
                }
              : null
          ]
        }
      }
      else if (isFrameNick(guid)) {
        let isOwned = guid in availNF
        return {
          children = [
            {
              children = mkNickFrame(nickFrames[guid])
              opacity = isOwned ? 0.3 : 1
            }
            isOwned
              ? {
                  size = FLEX
                  halign = ALIGN_CENTER
                  valign = ALIGN_BOTTOM
                  children = [
                    receivedTextObj
                    mkGoldCompensation(compensations?[guid] ?? 0, { margin = midPadding })
                  ]
                }
              : null
          ]
        }
      }
      return null
    })
    return {
      watch = [shopDecorsCompensations, availPortraits, availNickFrames]
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = smallPadding
      children = [
        mkText(loc("shop/receiveDecoratorsHeader"), goodNameTxtStyle)
        {
          size = FLEX_H
          children = wrap(children, {
            width = sh(50)
            hGap = midPadding
            vGap = midPadding
          })
        }
      ]
    }
  }
}


let mkPurchaseBtn = @(shopItem) Purchase(loc("shop/purchase"),
  @() buyShopItem({
    shopItem
    productView = mkProductView(shopItem)
  }),
  { margin = 0, hotkeys = [[ "^J:Y", { description = { skip = true }} ]] }
)


function mkCompensationText(shopItem) {
  let { squads = [], decorators = [] } = shopItem
  return function() {
    let squadCompensations = shopSquadsCompensations.get()
    let decorCompensations = shopDecorsCompensations.get()
    let armySquads = squadsByArmy.get()
    let portraits = availPortraits.get()
    let availNF = availNickFrames.get()

    local hasText = squads.findvalue(function(squad) {
      let { armyId, id } = squad
      return (armySquads?[armyId] ?? []).findvalue(@(s) s.squadId == id) != null
        && (squadCompensations?[id] ?? 0) > 0
    }) != null
    if (!hasText)
      hasText = hasText || decorators.findvalue(function(decorator) {
        let { guid } = decorator
        if (isPortrait(guid))
          return guid in portraits && (decorCompensations?[guid] ?? 0) > 0
        else if (isFrameNick(guid))
          return guid in availNF && (decorCompensations?[guid] ?? 0) > 0
        return false
      }) != null

    return {
      watch = [
        shopSquadsCompensations, shopDecorsCompensations, squadsByArmy,
        availPortraits, availNickFrames
      ]
      size = FLEX_H
      children = hasText
        ? mkTextArea(loc("shop/goodCompensationText"), {
            margin = [midPadding, smallPadding]
          }.__update(goodNameTxtStyle))
        : null
    }
  }
}


function mkRightBlockUi(shopItem) {
  let { squads = [], decorators = [], announcements = [], premiumDays = 0 } = shopItem
  let announcementsBlockUi = mkAnnouncementsBlockUi(announcements)
  let premiumBlockUi = mkPremiumBlockUi(premiumDays)
  let decoratorsBlockUi = mkDecoratorsBlockUi(decorators)
  let squadsBlockUi = mkSquadsBlockUi(squads, shopItem)
  return {
    size = [btnSizeBig[0], FLEX]
    padding = midPadding
    hplace = ALIGN_RIGHT
    children = [
      {
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = sh(2)
        vplace = ALIGN_CENTER
        children = [
          mkText(loc("shop/receiveHeader"), goodNameTxtStyle)
          announcementsBlockUi
          premiumBlockUi
          decoratorsBlockUi
          squadsBlockUi
          mkCompensationText(shopItem)
        ]
      }
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = midPadding
        padding = const [sh(3), sh(1)]
        vplace = ALIGN_BOTTOM
        children = [
          mkPurchaseBtn(shopItem)
          Regular(loc("mainmenu/btnBack"), close,
            { margin = 0, hotkeys = [[$"^{JB.B} | Esc", { description = { skip = true }}]] })
        ]
      }
    ]
  }
}

function mkShopItemName(shopItem) {
  let { nameLocId = "" } = shopItem
  return mkHeaderFlag({
    rendObj = ROBJ_TEXT
    text = utf8ToUpper(loc(nameLocId))
    padding = const [fsh(2), fsh(3)]
    color = activeTxtColor
  }.__update(fontBody), primeFlagStyle)
}

function buySquadWnd() {
  let watch = [compositeParams]
  let shopItem = compositeParams.get()
  if (shopItem == null)
    return { watch }

  return {
    watch
    size = FLEX
    children = mkFullScreenBack(
      mkSquadBackground(shopItem.image),
      [
        mkShopItemName(shopItem)
        mkRightBlockUi(shopItem)
      ]
    )
  }
}


compositeParams.subscribe(@(val) val != null
  ? sceneWithCameraAdd(buySquadWnd, "battle_pass")
  : sceneWithCameraRemove(buySquadWnd))

if (compositeParams.get() != null)
  sceneWithCameraAdd(buySquadWnd, "battle_pass")


return open
