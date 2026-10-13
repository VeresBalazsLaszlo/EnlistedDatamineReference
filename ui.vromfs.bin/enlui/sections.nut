import "%ui/growth/growthUi.nut" as growthUi
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/shop/mkShopUi.nut" import buildShopUi
from "%ui/researches/mkResearchesUi.nut" import buildResearchesUi
from "%ui/mainScene/mainScene.nut" import mkMainSceneContent
from "%ui/mainMenu/sectionsState.nut" import setSectionsSorted, Section, curSection
from "%ui/researches/unseenResearches.nut" import markResearchesSeen, hasUnseenResearches
from "%ui/shop/armyShopState.nut" import curUnseenAvailShopGuids, curArmyShopItems, notOpenedShopItems
from "%ui/soldiers/model/state.nut" import curArmy, curArmyData
from "%ui/components/soldiersUiComps.nut" import mkAlertIcon, PERK_ALERT_SIGN, ITEM_ALERT_SIGN
from "%ui/soldiers/model/soldierPerks.nut" import notChosenPerkSquads
from "%ui/vehicles/unseenVehicles.nut" import unseenArmiesVehicle
from "%ui/components/openUrl.nut" import openUrl
from "%ui/networkedUrls.nut" import getStoreUrl, getEventUrl
from "%ui/gameModes/eventUnseenSignState.nut" import isEventUnseen, markEventSeen
from "%ui/shop/unseenShopItems.nut" import markShopItemOpened
from "%ui/shop/shopPackage.nut" import mkDiscountBar
from "%ui/shop/shopState.nut" import chapterIdx
from "%ui/style/designConst.nut" import titleTxtColor, darkTxtColor, brightAccentColor
from "%ui/growth/growthState.nut" import reqGrowthSelection, curGrowthState, curGrowthConfig, GrowthStatus
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/components/blinkingIcon.nut" import warningIcon
from "%ui/tutorial/growthTutorialState.nut" import curGrowthGuidToPurchase
from "%ui/ui_library.nut" import *

let alertSign = {
  pos = const [hdpx(10), hdpx(5)]
  children = warningIcon("circle")
}

let warningSign = {
  pos = const [hdpx(10), hdpx(5)]
  children = warningIcon("exclamation-triangle", null, brightAccentColor)
}

let styleAlertUi = {
  size = FLEX_H
  margin = hdpx(11)
  halign = ALIGN_RIGHT
}

let researchesSign = {
  pos = const [hdpx(10), hdpx(5)]
  children = warningIcon("chevron-circle-up")
}

function researchesAlertUi() {
  let watch = hasUnseenResearches
  return !hasUnseenResearches.get() ? { watch }
    : {
        watch
        children = researchesSign
      }.__update(styleAlertUi)
}

let hasUnseenShopItems = Computed(@() curUnseenAvailShopGuids.get().len() > 0)

let maxCurArmyDiscount = Computed(function() {
  local discount = 0
  foreach (item in curArmyShopItems.get())
    if (!item?.hideDiscount && "offerContainer" not in item)
      discount = max(discount, item?.discountInPercent ?? 0)
  return discount
})

let maxGrowthDiscount = Computed(function() {
  let sItems = shopItems.get()
  let growthStates = curGrowthState.get()
  local res = 0
  foreach (growthItem in curGrowthConfig.get()) {
    let { id, expRequired = 0 } = growthItem
    let { status = GrowthStatus.UNAVAILABLE } = growthStates?[id]

    if (status == GrowthStatus.REWARDED
        || (status != GrowthStatus.PURCHASABLE && expRequired > 0))
      continue

    let shopItemGuid = growthItem?.shopItemsGuids[0]
    if (shopItemGuid != null) {
      let discount = sItems?[shopItemGuid].discountInPercent ?? 0
      res = max(res, discount)
    }
  }
  return res
})

let hasPurchGrowth = Computed(function() {
  let configs = curGrowthConfig.get()
  return curGrowthState.get().findvalue(@(st)
    st.status == GrowthStatus.PURCHASABLE && st.guid in configs) != null
})


let hasShopAlert = Computed(@() maxCurArmyDiscount.get() > 0
  || hasUnseenShopItems.get())

let hasGrowthSelectionAlert = Computed(@() reqGrowthSelection.get()
  && curGrowthGuidToPurchase.get() == null
  && curSection.get() != Section.GROWTH)

let mkGrowthAlertUi = @(sf) function() {
  let percents = maxGrowthDiscount.get()
  return {
    watch = [hasGrowthSelectionAlert, hasPurchGrowth, maxGrowthDiscount]
    children = hasGrowthSelectionAlert.get() ? warningSign
      : percents > 0
        ? mkDiscountBar({
            rendObj = ROBJ_TEXT
            text = $"-{percents}%"
            color = sf & S_HOVER ? titleTxtColor : darkTxtColor
          }.__update(fontSub), true, sf & S_HOVER ? darkTxtColor : brightAccentColor)
      : hasPurchGrowth.get() ? alertSign
      : null
  }.__update(styleAlertUi)
}

let mkShopAlertUi = @(sf) function() {
  let watch = [hasShopAlert, maxCurArmyDiscount]
  if (!hasShopAlert.get())
    return { watch }

  let percents = maxCurArmyDiscount.get()
  return {
    watch
    children = percents > 0
      ? mkDiscountBar({
          rendObj = ROBJ_TEXT
          text = $"-{percents}%"
          color = sf & S_HOVER ? titleTxtColor : darkTxtColor
        }.__update(fontSub), true, sf & S_HOVER ? darkTxtColor : brightAccentColor)
      : alertSign
  }.__update(styleAlertUi)
}

let mkEventAlertUi = @(_sf) function() {
  if (!isEventUnseen.get())
    return { watch = isEventUnseen }
  return {
    watch = isEventUnseen
    children = isEventUnseen.get() ? alertSign : null
  }.__update(styleAlertUi)
}

let mkUnseenAlert = mkAlertIcon(ITEM_ALERT_SIGN, Computed(@()
  (unseenArmiesVehicle.get()?[curArmy.get()].len() ?? 0) > 0))

let mkPerksAlert = mkAlertIcon(PERK_ALERT_SIGN, Computed(@()
  (notChosenPerkSquads.get()?[curArmy.get()].len() ?? 0) > 0))


let sections = [
  {
    locId = "menu/battles"
    getContent = mkMainSceneContent
    id = Section.MAIN
    camera = "soldiers"
    addChild = {
      pos = const [0, hdpx(16)]
      flow = FLOW_HORIZONTAL
      hplace = ALIGN_RIGHT
      valign = ALIGN_CENTER
      children = [
        mkUnseenAlert
        mkPerksAlert
      ]
    }
  }

  {
    locId = "menu/researches"
    descId = "menu/researchesDesc"
    getContent = buildResearchesUi
    id = Section.RESEARCHES
    camera = "researches"
    addChild = researchesAlertUi
    onExitCb = function() {
      markResearchesSeen(curArmyData.get()?.guid)
      return true
    }
  }

  {
    locId = "menu/shop"
    getContent = buildShopUi
    id = Section.SHOP
    camera = "researches"
    mkChild = mkShopAlertUi
    onBackCb = function() {
      if (chapterIdx.get() >= 0) {
        chapterIdx.set(-1)
        return false
      }
      return true
    }
    onExitCb = function() {
      markShopItemOpened(curArmyData.get()?.guid, notOpenedShopItems.get())
      return true
    }
    animations = null
  }

  {
    locId = "menu/growth"
    getContent = growthUi
    id = Section.GROWTH
    camera = "growth"
    mkChild = mkGrowthAlertUi
  }
]

if (getStoreUrl() != null)
  sections.append({
    locId = "menu/store"
    id = Section.STORE
    selectable = false
    onClickCb = @() openUrl(getStoreUrl())
  })

if (getEventUrl() != null)
  sections.append({
    locId = "menu/event"
    id = Section.EVENT
    selectable = false
    onClickCb = function(){
      openUrl(getEventUrl())
      markEventSeen()
    }
    mkChild = mkEventAlertUi
  })

setSectionsSorted(sections)
