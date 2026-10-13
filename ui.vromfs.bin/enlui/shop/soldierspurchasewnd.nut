import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
import "%ui/meta/perks/perksList.nut" as perksList
import "%ui/shop/buySquadWindow.nut" as buySquadWindow
import "%ui/shop/clickShopItem.nut" as clickShopItem
import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/soldiers/model/squadClassLimits.nut" as getClassLimitsComp
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/soldiers/model/state.nut" import curArmyData, curSquadParams
from "%ui/shop/armyShopState.nut" import shopItemContentCtor, curUnseenAvailShopGuids, realCurrencies
from "%ui/shop/soldiersPurchaseState.nut" import soldierShopItems, unseenSoldierShopItems, getSoldiersList, isSoldiersPurchasing
from "%ui/style/designConst.nut" import midPadding, smallPadding, titleTxtColor, defTxtColor, selectedTxtColor, smallOffset, tinyOffset
  , panelBgColor, hoverSlotBgColor
from "%ui/items/crateInfo.nut" import makeCrateToolTip
from "%ui/style/cursors.nut" import setTooltip
from "%ui/components/soldiersUiComps.nut" import kindIcon
from "%ui/shop/shopPkg.nut" import getCantBuyData, mkAlertObject
from "%ui/shop/unseenShopItems.nut" import markShopItemSeen
from "%ui/soldiers/model/cratesContent.nut" import getLoadedCrateContent, crateContentWatch
from "%ui/components/unseenComps.nut" import smallUnseenNoBlink
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/soldiers/model/chooseSoldiersState.nut" import soldiersSquad, soldiersSquadParams, squadSoldiers, soldiersStatuses, isPurchaseWndOpened
from "%ui/components/unseenComponents.nut" import unblinkUnseen
from "%ui/offers/offersState.nut" import offersByShopItem
from "%ui/meta/perks/perksStats.nut" import perksStatsCfg
from "%ui/soldiers/components/perksPackage.nut" import perkPointIcon, getStatDescList, flexTextArea, mkStatList
from "%ui/meta/perks/perksSchemesConfig.nut" import perkSchemes, soldierSchemes
from "%ui/soldiers/model/soldiersState.nut" import curSoldierKind, DEF_KIND
from "%ui/shop/shopPackage.nut" import mkSoldierShopItem
from "%ui/helpers/gradients.nut" import mkTwoSidesGradientX
from "%ui/growth/growthState.nut" import curGrowthState, curGrowthProgress, curGrowthConfig, curGrowthTiers
from "%ui/components/scrollbar.nut" import makeHorizScroll
from "%ui/shop/currencyComp.nut" import mkItemCurrency
from "%ui/shop/numberUtils.nut" import abbreviateAmount
from "%ui/ui_library.nut" import *

let { pPointsBaseParams } = require("%ui/meta/perks/perksPoints.nut")


const ENLISTED_SILVER = "enlisted_silver"

const bgColor = 0XEE1F242A
const rootColor = 0XFF1F242A
let selectedColor = mul_color(panelBgColor, 2)
const soldierCardHeight = hdpx(500)

let decorImg = mkTwoSidesGradientX({
  centerColor = 0x77FFFFFF
  sideColor = 0x11FFFFFF
  isAlphaPremultiplied = false
})

let decorObj = {
  size = [FLEX, smallPadding]
  rendObj = ROBJ_IMAGE
  image = decorImg
}


let curShopSoldierKind = Watched(DEF_KIND)

const WND_UID = "SOLDIERS_PURCHASE_WND"

const inactiveTxtColor = 0xFF777777

let headerTxtStyle = { color = defTxtColor }.__update(fontBody)

function switchKind(kindsToShow, delta){
  let amountKinds = kindsToShow.len()
  local idx = kindsToShow.findindex(@(val)
    val?.soldierKind == curShopSoldierKind.get())
  if (idx == null)
    return

  idx = (idx + delta + amountKinds) % amountKinds
  curSoldierKind.set(kindsToShow[idx].soldierKind)
}

let getCrateContent = @(shopItems) Computed(function() {
  let res = []
  foreach (shopItem in shopItems.get()) {
    let crateId = shopItem?.crates[0]
    res.append({
      shopItemId = shopItem.id
      content = getLoadedCrateContent(crateId, crateContentWatch.get())
    })
  }
  return res
})


let specializationIconColor = @(sf, isSelected, isAvailable)
  isSelected ? titleTxtColor
    : sf & S_HOVER ? selectedTxtColor
    : isAvailable ? titleTxtColor
    : inactiveTxtColor

let soldiersList = Computed(@() squadSoldiers.get().filter(@(s) s != null))
let currentLimits = getClassLimitsComp(soldiersSquad, soldiersSquadParams,
  soldiersList, soldiersStatuses)

let unseenSignCmp = smallUnseenNoBlink.__merge({ hplace = ALIGN_RIGHT, vplace = ALIGN_TOP })

let btnSize = [hdpxi(48), hdpx(52)]

function mkSpecializationBtn(soldier, isSelected, unseenKinds) {
  let { soldierKind } = soldier
  return watchElemState(function(sf) {
    let isSelectedVal = isSelected.get()
    let classInfo = currentLimits.get().findvalue(@(x) x.total > 0 && x.sKind == soldierKind)
    let isAvailable = classInfo != null

    return {
      size = [btnSize[0], SIZE_TO_CONTENT]
      behavior = Behaviors.Button
      watch = [isSelected, currentLimits]
      onClick = @() curShopSoldierKind.set(soldierKind)
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = smallPadding
      children = [
        {
          size = [FLEX, btnSize[1]]
          valign = ALIGN_CENTER
          halign = ALIGN_CENTER
          rendObj = ROBJ_SOLID
          color = sf & S_HOVER ? hoverSlotBgColor
            : isSelectedVal ? selectedColor
            : panelBgColor
          children = [
            kindIcon(soldierKind, hdpxi(30), specializationIconColor(sf, isSelectedVal, isAvailable))
            soldierKind in unseenKinds ? unseenSignCmp : null
          ]
        }
        classInfo == null ? null : {
          rendObj = ROBJ_TEXT
          text = $"{classInfo.used}/{classInfo.total}"
          color = isSelectedVal || isAvailable || (sf & S_HOVER) ? defTxtColor : inactiveTxtColor
        }
      ]
    }
  })
}

let specializationsBlock = @(kindsToShow, unseenKinds) @() {
  watch = isGamepad
  flow = FLOW_VERTICAL
  size = FLEX_H
  halign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      margin = [0, 0, smallOffset, 0]
      text = loc("soldiers/specializationChoice")
    }.__update(headerTxtStyle)
    {
      flow = FLOW_HORIZONTAL
      gap = tinyOffset
      valign = ALIGN_CENTER
      children = [
        isGamepad.get() ? mkHotkey("^J:LB", @() switchKind(kindsToShow, -1)) : null
        {
          flow = FLOW_HORIZONTAL
          children = kindsToShow.map(function(v) {
            let isSelected = Computed(@() curShopSoldierKind.get() == v.soldierKind)
            return mkSpecializationBtn(v, isSelected, unseenKinds)
          })
        }
        isGamepad.get() ? mkHotkey("^J:RB", @() switchKind(kindsToShow, 1)) : null
      ]
    }
    @() {
      watch = [curSoldierKind, curSquadParams]
      hplace = ALIGN_CENTER
      size = const [SIZE_TO_CONTENT, hdpx(30)]
      children = curSoldierKind.get() in (curSquadParams.get()?.maxClasses ?? {}) ? null
        : mkAlertObject(loc("shop/unsuitableForSquad"))
    }
  ]
}


function mkStartPerk(perksListVal, perksStatsCfgVal, perkScheme, isLocked) {
  if (perkScheme == null)
    return null

  let defaultPerk = perkScheme.findvalue(@(s) s?.isDefault || (s?.numChosen == 1)) 
  if (defaultPerk == null || defaultPerk.perks.len() < 1)
    return null

  let perk = perksListVal?[defaultPerk.perks.top()]
  if (perk == null)
    return null

  let perkStat = perk.cost.keys().top()

  let textarea = flexTextArea({
    text = "\n".join(getStatDescList(perksStatsCfgVal, perk, true))
    size = const [hdpx(225), SIZE_TO_CONTENT]
    halign = ALIGN_LEFT
  }.__update(fontSub))

  let { icon, color } = pPointsBaseParams[perkStat]
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_TOP
    halign = ALIGN_LEFT
    gap = smallPadding
    children = [
      perkPointIcon(icon, isLocked ? defTxtColor : color)
      textarea
    ]
  }
}

function mkShopItemCard(idx, shopItem, armyData, offers) {
  let { guid = null, requirements = null } = shopItem
  let squad = shopItem?.squads[0]
  let armyId = armyData?.guid ?? ""
  let crateContent = shopItemContentCtor(shopItem)
  let offer = offers?[guid]
  let lockData = Computed(@() getCantBuyData(armyData, requirements, curGrowthState.get(),
    curGrowthConfig.get(), curGrowthProgress.get(), curGrowthTiers.get(), allItemTemplates.get()))

  return function() {
    let isLocked = lockData.get() != null
    let { perkSchemeId = "" } = soldierSchemes.get()?[armyId][shopItem.soldierSpec]
    let perkScheme = perkSchemes.get()?[perkSchemeId]
    let perkElement = mkStartPerk(perksList.get(), perksStatsCfg.get(), perkScheme, isLocked)
    let content = crateContent.get()?.content
    let statsList = mkStatList(content, sClassesCfg.get(), isLocked)
    let hasUnseenSignal = curUnseenAvailShopGuids.get()?[guid] ?? false
    let templates = allItemTemplates.get()
    let unseenSignalObj = hasUnseenSignal ? unblinkUnseen : null
    let lockTxt = lockData.get()?.lockTxt ?? ""

    function onClick() {
      clickShopItem(shopItem)
      if (hasUnseenSignal)
        markShopItemSeen(armyId, guid)
    }
    function onHover(on) {
      setTooltip(on ? makeCrateToolTip(crateContent) : null)
      if (hasUnseenSignal)
        hoverHoldAction("markSeenShopItem", { armyId, guid },
          @(v) markShopItemSeen(v.armyId, v.guid))(on)
    }
    let onInfoCb = squad == null ? null
      : @() buySquadWindow({
          shopItem
          armyId = squad.armyId
          squadId = squad.id
        })

    return {
      watch = [curUnseenAvailShopGuids, crateContent, sClassesCfg,
        perkSchemes, soldierSchemes, perksList, perksStatsCfg, allItemTemplates, lockData]
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      behavior = Behaviors.Button
      gap = smallPadding
      xmbNode = XmbNode()
      children = [
        mkSoldierShopItem(idx, armyId, shopItem, offer, content, templates,
          lockTxt, onClick, onHover, null, onInfoCb, unseenSignalObj)
        {
          flow = FLOW_VERTICAL
          valign = ALIGN_TOP
          halign = ALIGN_LEFT
          gap = midPadding
          padding = midPadding
          children = [ statsList, perkElement ]
        }
      ]
    }
  }
}

function mkSoldiersList(soldiersToShow) {
  let soldiers = Computed(@()
    soldiersToShow.filter(@(s) s?.soldierKind == curShopSoldierKind.get()))
  return function() {
    let offers = offersByShopItem.get()
    let armyData = curArmyData.get()
    return {
      watch = [curArmyData, soldiers, offersByShopItem]
      size = FLEX_H
      minHeight = soldierCardHeight + sh(7)
      halign = ALIGN_CENTER
      xmbNode = XmbContainer({
        canFocus = false
        scrollSpeed = 10.0
        isViewport = true
      })
      children = makeHorizScroll({
        flow = FLOW_HORIZONTAL
        gap = midPadding
        children = soldiers.get().map(@(shopItem, idx)
          mkShopItemCard(idx, shopItem, armyData, offers))
      }, {
        size = SIZE_TO_CONTENT
        maxWidth = pw(100)
        rootBase = {
          behavior = Behaviors.Pannable
          wheelStep = 1
        }
      })
    }
  }
}

function currencies() {
  let allResources = []

  allResources.append(mkItemCurrency({
    currencyTpl = ENLISTED_SILVER
    count = abbreviateAmount(realCurrencies.get()[ENLISTED_SILVER])
  }))

  return {
    watch = [realCurrencies]
    flow = FLOW_HORIZONTAL
    size = FLEX_V
    gap = hdpx(20)
    children = allResources
  }
}


function wndContent() {
  let crateContent = getCrateContent(soldierShopItems)
  return function() {
    let contentToShow = getSoldiersList(crateContent.get(), soldierShopItems.get())
    let { kindsToShow, soldiersToShow } = contentToShow
    let unseenKinds = {}
    crateContent.get().each(function(val) {
      let soldierSpec = val?.content.soldierClasses[0]
      if (val.shopItemId in unseenSoldierShopItems.get() && soldierSpec != null) {
        let soldier = soldiersToShow.findvalue(@(v) v?.soldierSpec == soldierSpec)
        if (soldier != null)
          unseenKinds[soldier.soldierKind] <- true
      }
    })
    return {
      watch = [crateContent, unseenSoldierShopItems, soldierShopItems]
      size = FLEX_H
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      rendObj = ROBJ_SOLID
      color = rootColor
      children = [
        decorObj
        {
          size = FLEX_H
          padding = hdpx(40)
          children = [
            {
              flow = FLOW_HORIZONTAL
              hplace = ALIGN_RIGHT
              gap = smallOffset
              children = [
                currencies
                closeBtnBase({ onClick = @() isPurchaseWndOpened.set(false) })
              ]
            }
            {
              size = FLEX_H
              flow = FLOW_VERTICAL
              gap = tinyOffset
              hplace = ALIGN_CENTER
              children = [
                specializationsBlock(kindsToShow, unseenKinds)
                mkSoldiersList(soldiersToShow)
              ]
            }
          ]
        }
        decorObj
      ]
    }
  }
}

let soldiersPurchaseWnd = @() {
  key = WND_UID
  size = FLEX
  valign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  color = bgColor
  stopMouse = true
  stopHover = true
  onDetach = function() {
    isSoldiersPurchasing.set(false)
  }
  onAttach = function() {
    isSoldiersPurchasing.set(true)
  }
  onClick = @() null
  children = wndContent()
}


return soldiersPurchaseWnd
