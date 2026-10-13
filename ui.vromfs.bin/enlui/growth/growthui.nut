import "%ui/control/gui_buttons.nut" as JB
import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
import "%ui/components/faComp.nut" as faComp
import "%ui/currency/currenciesWidgetUi.nut" as currenciesWidgetUi
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%ui/components/mkGlareAnim.nut" as mkGlare
import "%ui/soldiers/model/getPayItemsData.nut" as getPayItemsData
from "%ui/components/msgbox.nut" import msgboxStyling, showMsgbox
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontSub
from "%ui/components/slider.nut" import Horiz
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/style/designConst.nut" import sidePadding, largePadding, smallPadding, titleTxtColor, defTxtColor, midPadding, miniPadding
  , brightAccentColor, darkTxtColor, panelBgColor, defBdColor, squadSlotBgHoverColor, defItemBlur, inventoryItemDetailsWidth
  , commonBtnHeight, accentColor, hoverSlotBgColor, contentOffset, positiveTxtColor, navHeight
from "%ui/currency/currencies.nut" import currenciesBalance
from "%ui/currency/purchaseMsgBox.nut" import purchaseMsgBox
from "%ui/state/safeArea.nut" import safeAreaSize, safeAreaBorders, safeAreaAmount
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/meta/profile.nut" import curCampItems
from "%ui/growth/growthState.nut" import GrowthStatus, curGrowthId, curGrowthConfig, curGrowthState, curGrowthSelected, callGrowthSelect, callGrowthPurchase
  , curSquads, curTemplates, mkGrowthData, curGrowthTiers, curGrowthProgress, curGrowthFreeExp, callGrowthExp
  , callGrowthBuyExp, reqGrowthId, growthTierToScroll, isGrowthVisible, reqGrowthSelection, curAvailableToSelect
from "%ui/growth/growthAnimState.nut" import completedAnim, passCompleteAnim
from "%sqstd/frp.nut" import subscribeList
from "%ui/shop/shopItemClick.nut" import shopItemClick
from "%ui/helpers/gradients.nut" import mkColoredGradientX, mkColoredGradientY
from "%ui/components/scrollbar.nut" import makeHorizScroll
from "%ui/components/defComponents.nut" import gradientProgressBar
from "%sqstd/math.nut" import splitThousands, round_by_value, ceil
from "%ui/components/itemsInfo.nut" import itemNameFromTemplate
from "%ui/soldiers/components/itemTypesData.nut" import itemTypeIcon
from "%ui/components/textButton.nut" import Primary, Regular, textColor, primaryStyle
from "%ui/currency/currenciesComp.nut" import currencyBtn, mkCurrencyImg
from "%ui/growth/growthPkg.nut" import mkSquadDetails, mkItemDetails, mkGrowthRewardsText, mkGrowthSlotElems, mkTierObject
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/shop/currencyComp.nut" import mkCurrencyImage
from "%ui/shop/currencyPresentation.nut" import getCurrencyPresentation
from "%ui/currency/currenciesList.nut" import enlistedGold
from "%ui/debriefing/components/mkXpImage.nut" import mkPremiumSquadXpImage
from "%ui/shop/mkShopItemPrice.nut" import mkPrice
from "%ui/shop/armyCurrencyUi.nut" import freeExpUi, mkExpIcon
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/control/active_controls.nut" import isGamepad
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/shop/shopPackage.nut" import mkDiscountBar
from "%ui/mainMenu/mkMenuScene.nut" import mainMenuGap
from "%ui/shop/armyShopState.nut" import needGoodManage
from "%ui/tutorial/growthTutorialState.nut" import curGrowthGuidToPurchase
from "%ui/components/battleRatingPkg.nut" import mkBattleRatingShort
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/ui_library.nut" import *

const TRY_COMPLETE_WND_UID = "try_complete_wnd"
const RELATIONS_WND_UID = "growth_relations_list"
const BOOST_WND_UID = "growth_boost"


const GOLD_CURRENCY_ID = "EnlistedGold"
const SILVER_ID = "enlisted_silver"
const trigger = "completed_window_anim"

let tblScrollHandler = ScrollHandler()

const scrollBarsWidth = hdpxi(150)
let elemSize = [hdpxi(218), hdpxi(100)]
let elemNoNameSize = [hdpxi(218), hdpxi(80)]
let gapSize = [hdpxi(30), hdpxi(12)]
const headerSize = hdpxi(20)
const tierHeight = hdpxi(26)
const blocksGap = hdpxi(40)
let scrollAreaWidth = safeAreaSize.get()[0] - (inventoryItemDetailsWidth + blocksGap)

let progLeftStyle = freeze({ color = 0xFF0b0801 }.__update(fontSub))
let progRightStyle = freeze({ color = titleTxtColor }.__update(fontSub))
let progressValueStyle = freeze({ color = titleTxtColor }.__update(fontSub))
let alertStyle = freeze({ color = brightAccentColor }.__update(fontSub))

let expValueStyle = freeze({ color = brightAccentColor }.__update(fontBody))
let headerTxtStyle = freeze({ color = brightAccentColor }.__update(fontHeading2))

let infoTextStyle = freeze({ color = titleTxtColor }.__update(fontBody))

let textColorBtn = @(sf) sf & S_ACTIVE ? titleTxtColor
  : sf & S_HOVER ? darkTxtColor
  : titleTxtColor

const selectedWithBorder = hdpx(2)

const activeIdleProgColor = 0XFF3B4334
const activeHoverProgColor = 0xFF58603A
const progressColor = 0xFF667079
const unavailableIdleBgColor = 0xFF621D1D
const unavailableSelectedBgColor = 0xFF905D5D

const unavailableElemsColor = 0xFF764549
const activeElemsColor = 0xFF313841
const defElemsColor = 0xFFB3BDC1

const activeIdleBgColor = 0XFF414D5B
const premBgSelectedColor = 0xFF3C4050
const premBgIdleColor = 0xFF3C4050
const currentIdleBgColor = 0XFF1E272E
const currentHoverBgColor = 0xFFA0A2A3
const currentSelectedBgColor = 0XFF1E272E

let selectedGradient = mkColoredGradientY({
  colorTop = 0x5AFFFFFF, colorBottom = 0x00FFFFFF, height = 12, isAlphaPremultiplied = false
})

let selectedImg = freeze({
  rendObj = ROBJ_IMAGE
  size = FLEX
  image = selectedGradient
  animations = [{ prop = AnimProp.opacity, from = 0.1, to = 1.0,
    duration = 2, play = true, loop = true, easing = Blink }]
})


let isBoostWndOpen = Watched(false)
let curGrowthRelations = Watched(null)
let curInfoTabId = Watched(null)
local savedScrollXPos = null


const sliderWidth = hdpxi(540)

let btnHotkey = {
  hotkeys = [[$"^J:Y | Space"]]
}


function tabInteriorCb() {
  savedScrollXPos = tblScrollHandler.elem?.getScrollOffsX() ?? 0
  curGrowthRelations.set(null)
}

let infoTabs = {
  item = {
    locId = "weaponry"
    uiCtor = @(data) mkItemDetails(data, tabInteriorCb)
  }
  squad = {
    locId = "squad"
    uiCtor = @(data) @() {
      watch = [sClassesCfg, squadsCfgById]
      size = FLEX
      children = mkSquadDetails(data, sClassesCfg.get(), squadsCfgById.get(), tabInteriorCb)
    }
  }
}


let tabsToShow = Computed(function() {
  let { itemTemplate = null, squadId = null, armyId = null
    } = curGrowthConfig.get()?[curGrowthId.get()].reward
  let res = []
  let item = curTemplates.get()?[itemTemplate]
  if (item != null)
    res.append({
      tabId = "item"
      data = {
        item
        itemTemplate
        armyId
      }
    })

  let squad = curSquads.get()?[squadId]
  if (squad != null)
    res.append({
      tabId = "squad"
      data = {
        squad
        armyId
      }
    })
  return res
})

tabsToShow.subscribe(function(v) {
  if (v.len() == 0)
    return
  if (curInfoTabId.get() == null){
    curInfoTabId.set(v[0].tabId)
    return
  }
  let idxToSet = v.findindex(@(val) val.tabId == curInfoTabId.get())
  if (idxToSet == null)
    curInfoTabId.set(v[0].tabId)
  else
    curInfoTabId.set(v[idxToSet].tabId)
  })

let progressBarStyle = freeze({
  size = const [FLEX, hdpx(22)]
  bgImage = mkColoredGradientX({ colorLeft = 0xFF993333, colorRight = brightAccentColor })
  emptyColor = panelBgColor
})

let elemInactive = @(_isPrem, isSelected, ...) {
  rendObj = ROBJ_BOX
  size = [elemSize[0], FLEX]
  borderWidth = isSelected ? selectedWithBorder : 0
  borderColor = defBdColor
}

let elemRewarded = elemInactive

let elemCompleted = @(_isPrem, isSelected, ...) {
  rendObj = ROBJ_BOX
  size = [elemSize[0], FLEX]
  borderWidth = isSelected ? selectedWithBorder : 0
  borderColor = accentColor
}

let elemActive = @(_isPrem, isSelected, progress, isCurrent, sf) {
  size = [elemSize[0], FLEX]
  children = [
    progress == 0 ? null : {
      size = [pw(progress), FLEX]
      rendObj = ROBJ_SOLID
      color = !isCurrent ? progressColor
        : (sf & S_HOVER) != 0 || isSelected ? activeHoverProgColor
        : activeIdleProgColor
    }
    {
      size = FLEX
      rendObj = ROBJ_BOX
      borderWidth = isSelected ? selectedWithBorder : 0
      borderColor = isSelected ? defBdColor : 0
    }
  ]
}

let lineStyle = freeze({
  [GrowthStatus.UNAVAILABLE] = @(pos, size, data) {
    rendObj = ROBJ_VECTOR_CANVAS
    pos
    size
    color = unavailableElemsColor
    lineWidth = hdpx(2)
    commands = [[VECTOR_LINE].extend(data)]
  },
  [GrowthStatus.ACTIVE] = @(pos, size, data) {
    rendObj = ROBJ_VECTOR_CANVAS
    pos
    size
    color = 0x55445533
    lineWidth = hdpx(2)
    commands = [[VECTOR_LINE].extend(data)]
  },
  [GrowthStatus.COMPLETED] = @(pos, size, data) {
    rendObj = ROBJ_VECTOR_CANVAS
    pos
    size
    color = 0xFFFFCC33
    lineWidth = hdpx(3)
    commands = [[VECTOR_LINE].extend(data)]
  },
  [GrowthStatus.PURCHASABLE] = @(pos, size, data) {
    rendObj = ROBJ_VECTOR_CANVAS
    pos
    size
    color = 0x66666666
    lineWidth = hdpx(3)
    commands = [[VECTOR_LINE].extend(data)]
  },
  [GrowthStatus.REWARDED] = @(pos, size, data) {
    rendObj = ROBJ_VECTOR_CANVAS
    pos
    size
    color = 0x66666666
    lineWidth = hdpx(3)
    commands = [[VECTOR_LINE].extend(data)]
  },
})

const lineHor = [0, 50, 100, 50]
const lineVer = [50, 0, 50, 100]


enum LineDir {
  NONE
  LESS
  MORE
}

let coordHor = @(index, dir = LineDir.NONE) (elemSize[0] + gapSize[0]) * index
  + (dir == LineDir.LESS ? 0 : dir == LineDir.MORE ? elemSize[0] : elemSize[0] * 0.5)

let coordVer = @(index, dir = LineDir.NONE) (elemSize[1] + gapSize[1]) * index
  + (dir == LineDir.LESS ? 0 : dir == LineDir.MORE ? elemSize[1] : elemSize[1] * 0.5)

function mkGrowthLines(colFrom, lineFrom, colTo, lineTo) {
  let res = []
  local horPos, verPos

  
  if (colFrom == colTo) {
    horPos = coordHor(colFrom, LineDir.LESS)
    if (lineFrom > lineTo) {
      verPos = coordVer(lineTo, LineDir.MORE)
      res.append({
        pos = [horPos, verPos]
        size = [elemSize[0], coordVer(lineFrom, LineDir.LESS) - verPos]
        draw = lineVer
      })
    }
    if (lineFrom < lineTo) {
      verPos = coordVer(lineFrom, LineDir.MORE)
      res.append({
        pos = [horPos, verPos]
        size = [elemSize[0], coordVer(lineTo, LineDir.LESS) - verPos]
        draw = lineVer
      })
    }
    return res
  }

  
  if (lineFrom == lineTo) {
    verPos = coordVer(lineFrom, LineDir.LESS) + headerSize * 0.5
    if (colFrom > colTo) {
      horPos = coordHor(colTo, LineDir.MORE)
      res.append({
        pos = [horPos, verPos]
        size = [coordHor(colFrom, LineDir.LESS) - horPos, elemSize[1]]
        draw = lineHor
      })
    }
    if (colFrom < colTo) {
      horPos = coordHor(colFrom, LineDir.MORE) + headerSize * 0.5
      res.append({
        pos = [horPos, verPos]
        size = [coordHor(colTo, LineDir.LESS) - horPos, elemSize[1]]
        draw = lineHor
      })
    }
    return res
  }

  
  horPos = coordHor(colTo, LineDir.LESS)
  if (lineFrom > lineTo) {
    verPos = coordVer(lineTo, LineDir.MORE)
    res.append({
      pos = [horPos, verPos],
      size = [elemSize[0], coordVer(lineFrom) - verPos + headerSize * 0.5]
      draw = lineVer
    })
  }
  if (lineFrom < lineTo) {
    verPos = coordVer(lineFrom)
    res.append({
      pos = [horPos, verPos + headerSize * 0.5],
      size = [elemSize[0], coordVer(lineTo, LineDir.LESS) - verPos]
      draw = lineVer
    })
  }

  
  verPos = coordVer(lineFrom, LineDir.LESS) + headerSize * 0.5
  if (colFrom > colTo) {
    horPos = coordHor(colTo)
    res.append({
      pos = [horPos, verPos]
      size = [coordHor(colFrom, LineDir.LESS) - horPos, elemSize[1]]
      draw = lineHor
    })
  }
  if (colFrom < colTo) {
    horPos = coordHor(colFrom, LineDir.MORE) + headerSize * 0.5
    res.append({
      pos = [horPos, verPos]
      size = [coordHor(colTo) - horPos, elemSize[1]]
      draw = lineHor
    })
  }
  return res
}

let mkText = @(text, style) {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  text
}.__update(style)

let emptyCell = @(size = elemSize) { size }

let premBgColor = @(sf, isSelected) sf & S_HOVER ? squadSlotBgHoverColor
  : isSelected || (sf & S_ACTIVE) != 0 ? premBgSelectedColor
  : premBgIdleColor

let baseCompletedBgColor = @(sf, isSelected) sf & S_HOVER ? brightAccentColor
  : isSelected || (sf & S_ACTIVE) != 0 ? activeHoverProgColor
  : activeIdleProgColor

let completedBgColor = @(sf, isSelected, isPrem) isPrem
  ? premBgColor(sf, isSelected)
  : baseCompletedBgColor(sf, isSelected)

let activeBgColor = @(sf, isSelected, _isPrem)
  sf & S_HOVER ? currentHoverBgColor
    : isSelected || (sf & S_ACTIVE) != 0 ? currentSelectedBgColor
    : currentIdleBgColor

let currentBgColor = @(sf, isSelected)
  sf & S_HOVER ? currentHoverBgColor
    : isSelected || (sf & S_ACTIVE) != 0 ? currentSelectedBgColor
    : currentIdleBgColor

let unavailableBgColor = @(sf, isSelected, _isPrem)
  sf & S_HOVER ? squadSlotBgHoverColor
    : isSelected || (sf & S_ACTIVE) != 0 ? unavailableSelectedBgColor
    : unavailableIdleBgColor

let rewardedBgColor = @(sf, _isSelected, _isPrem) sf & S_HOVER
  ? squadSlotBgHoverColor
  : activeIdleBgColor


let slotBgColorMap = freeze({
  [GrowthStatus.UNAVAILABLE] = unavailableBgColor,
  [GrowthStatus.ACTIVE] = activeBgColor,
  [GrowthStatus.COMPLETED] = completedBgColor,
  [GrowthStatus.PURCHASABLE] = completedBgColor,
  [GrowthStatus.REWARDED] = rewardedBgColor,
})

let defChColor = @(sf = 0) sf & S_HOVER ? activeElemsColor : defElemsColor

let elemColorMap = freeze({
  [GrowthStatus.UNAVAILABLE] = @(sf = 0) sf & S_HOVER ? defBdColor : unavailableElemsColor,
  [GrowthStatus.COMPLETED] = @(sf = 0) sf & S_HOVER ? activeElemsColor : brightAccentColor
})


let elemBgMap = freeze({
  [GrowthStatus.UNAVAILABLE] = elemInactive,
  [GrowthStatus.ACTIVE] = elemActive,
  [GrowthStatus.COMPLETED] = elemCompleted,
  [GrowthStatus.PURCHASABLE] = elemCompleted,
  [GrowthStatus.REWARDED] = elemRewarded,
})

let mkGrowthName = @(txt, group, color) {
  rendObj = ROBJ_TEXT
  size = FLEX_H
  text = txt
  group
  behavior = Behaviors.Marquee
  clipChildren = true
  scrollOnHover = true
  color
}.__update(fontSub)

let mkGrowthSlotBar = @(isPrem, status, isCurrent, isSelected, sf) {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = FLEX
  fillColor = isCurrent ? currentBgColor(sf, isSelected)
    : slotBgColorMap[status](sf, isSelected, isPrem)
  color = defItemBlur
  opacity = status == GrowthStatus.UNAVAILABLE ? 0.4 : 1
}


let priceIconSize = [hdpxi(22), hdpxi(22)]
let bigPriceIconSize = [hdpxi(30), hdpxi(30)]

let priceIconExp = mkExpIcon(priceIconSize)
let bigPriceIconExp = mkExpIcon(bigPriceIconSize)

let priceIconGold = mkCurrencyImg(enlistedGold, priceIconSize[0])
let priceIconSilver = mkCurrencyImage(getCurrencyPresentation(SILVER_ID)?.icon,
  priceIconSize)

let mkGrowthPrice = @(icon, price, color) {
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  margin = smallPadding
  valign = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  children = [
    icon
    {
      rendObj = ROBJ_TEXT
      color
      text = price
    }.__update(fontSub)
  ]
}

let mkEffects = @(stats, isCur) {
  size = FLEX
  children = [
    stats != GrowthStatus.PURCHASABLE ? null
      : mkGlare({
          nestWidth = elemSize[0]
          glareWidth = elemSize[0]
          glareDuration = 1
          glareDelay = 1
          glareOpacity = 0.7
          hasMask = true
        })
    isCur ? selectedImg : null
  ]
}


let curGrowthTitleText = Computed(function() {
  let { reward = null } = curGrowthConfig.get()?[curGrowthId.get()]
  let templates = curTemplates.get()
  let squads = curSquads.get()
  return "\n".join(mkGrowthRewardsText(reward, templates, squads))
})


function getGrowthSelectError(growthCfg, grState, grProgres, growthData) {
  if ((grState?[growthCfg.id].status ?? GrowthStatus.UNAVAILABLE) == GrowthStatus.ACTIVE)
    return null

  let growths = []
  local tier = null

  let { id, requirements = [] } = growthCfg
  foreach (reqId in requirements) {
    let status = grState?[reqId].status ?? GrowthStatus.UNAVAILABLE
    if (status != GrowthStatus.COMPLETED
        && status != GrowthStatus.PURCHASABLE
        && status != GrowthStatus.REWARDED)
      growths.append(reqId)
  }

  let { tierId, tierIdx } = growthData.growthLinks[id]
  let tierStatus = grProgres?[tierId].status ?? GrowthStatus.UNAVAILABLE
  if (tierStatus == GrowthStatus.UNAVAILABLE)
    tier = tierIdx

  return growths.len() == 0 && tier == null ? null : { growths, tier }
}


function selectAction(growthCfg, growthData) {
  let grState = curGrowthState.get()
  let grProgres = curGrowthProgress.get()
  let err = getGrowthSelectError(growthCfg, grState, grProgres, growthData)
  if (err == null) {
    callGrowthSelect(curArmy.get(), curGrowthId.get())
    return
  }

  let { growths, tier } = err
  showMsgbox("\n\n".join([
      (tier == null ? null : loc("growthTier/reqToSelectGrowth", { reqText = tier })),
      (growths.len() == 0 ? null : loc("growth/reqToCompletePrev"))
    ], true))
}


function findGrowthShopItem(shopItemsGuids, availShopItems) {
  if (shopItemsGuids.len() == 0)
    return null

  let guid = shopItemsGuids.findvalue(@(v) v in availShopItems)
  return availShopItems?[guid]
}


function growthAction(growthItem, growthData) {
  let { id, expRequired = 0, shopItemsGuids = [], rewardCost = 0 } = growthItem
  let { status = GrowthStatus.UNAVAILABLE } = curGrowthState.get()?[id]
  let isPrem = expRequired == 0
  let isCompleted = status == GrowthStatus.COMPLETED
  let isRewarded = status == GrowthStatus.REWARDED
  let isPurchasable = status == GrowthStatus.PURCHASABLE
  let isCurrent = curGrowthSelected.get() == id && !isCompleted && !isRewarded && !isPurchasable

  if (isPrem) {
    let shopItem = findGrowthShopItem(shopItemsGuids, shopItems.get())
    if (!isRewarded && shopItem != null)
      shopItemClick(shopItem)
  }
  else if (isCompleted)
    showMsgbox(loc("growth/notPurchasable"))
  else if (isPurchasable) {
    let buyInfo = getPayItemsData({ [SILVER_ID] = rewardCost }, curCampItems.get())
    if (buyInfo != null) {
      callGrowthPurchase(curArmy.get(), id, buyInfo)
      curGrowthRelations.set(null)
      needGoodManage.set(true)
    }
    else
      showMsgbox(loc("shop/noSilverToPayRequired", { required = rewardCost}))
  }
  else if (isRewarded) {
    let shopItem = findGrowthShopItem(shopItemsGuids, shopItems.get())
    if (shopItem != null)
      shopItemClick(shopItem)
  }
  else if (isCurrent)
    isBoostWndOpen.set(true)
  else
    selectAction(growthItem, growthData)
}


let reqGrowthObject = {
  size = const [FLEX, 0]
  halign = ALIGN_CENTER
  children = {
    size = [elemSize[0] + hdpxi(8), elemSize[1] + hdpxi(8)]
    pos = const [0, -hdpxi(4)]
    rendObj = ROBJ_BOX
    borderWidth = hdpxi(2)
    borderColor = accentColor
    fillColor = hoverSlotBgColor
    animations = [{ prop = AnimProp.opacity, from = 0.2, to = 0.5,
      duration = 1, play = true, loop = true, easing = Blink }]
  }
}


function mkDiscountPercBar(shopItem) {
  let { isPriceHidden = false, discountInPercent = 0 } = shopItem
  return isPriceHidden || discountInPercent <= 0 ? null
    : {
        vplace = ALIGN_CENTER
        children = mkDiscountBar({
          rendObj = ROBJ_TEXT
          text = $"-{discountInPercent}%"
          color = darkTxtColor
        }.__update(fontSub), false, brightAccentColor, hdpxi(2))
      }
}


let discountStyle = {
  color = positiveTxtColor
  fontFx = FFT_SHADOW
  fontFxColor = 0xFF000000
  fontFxFactor = hdpx(64)
}.__update(fontSub)

let mkGrowthSlotPrice = @(elemsColor, priceCount, priceIcon, shItem) {
  size = FLEX
  children = [
    priceCount > 0 ? mkGrowthPrice(priceIcon, priceCount, elemsColor) : null
    shItem.get() == null ? null : {
      flow = FLOW_HORIZONTAL
      gap = midPadding
      margin = smallPadding
      vplace = ALIGN_BOTTOM
      children = [
        mkPrice({
          shopItem = shItem.get()
          needPriceText = false
          discountStyle
          styleOverride = { color = elemsColor }.__update(fontSub)
          dimStyle = { color = elemsColor }.__update(fontSub)
          iconSize = priceIconSize
        })
        mkDiscountPercBar(shItem.get())
      ]
    }
  ]
}

let mkGrowthSlotBack = @(isPrem, status, progress, isCurrent, isSelected = true, sf = 0, addObj = null) {
  size = FLEX
  children = [
    mkGrowthSlotBar(isPrem, status, isCurrent, isSelected, sf)
    addObj
    elemBgMap[status](isPrem, isSelected, progress, isCurrent, sf)
    mkEffects(status, isCurrent)
    !isPrem ? null
      : @() {
          watch = curArmy
          children = mkPremiumSquadXpImage(hdpxi(32), curArmy.get())
        }
  ]
}

let calcProgress = @(exp, expRequired)
  expRequired == 0 ? 0 : ((exp).tofloat() / expRequired.tofloat()) * 100.0

function mkGrowthSlot(growthItem, tmplsCfg, squadsCfg) {
  let { id = null, expRequired = 0, reward = null } = growthItem
  let { itemTemplate = null, squadId = null } = reward
  let item = tmplsCfg?[itemTemplate]
  let squad = squadsCfg?[squadId]
  if (item == null && squad == null)
    return emptyCell(elemNoNameSize)

  let isPrem = expRequired == 0
  let elemStatus = Computed(@() curGrowthState.get()?[id].status ?? GrowthStatus.UNAVAILABLE)
  let isElemCurrent = Computed(@() curGrowthSelected.get() == id
    && elemStatus.get() != GrowthStatus.REWARDED)
  let elemProgress = Computed(@() calcProgress(curGrowthState.get()?[id].exp ?? 0,
    curGrowthConfig.get()?[id].expRequired ?? 0))

  return function() {
    let status = elemStatus.get()
    let isCurrent = isElemCurrent.get()
    let progress = elemProgress.get()
    let elemsColor = elemColorMap?[status]() ?? defChColor()
    return {
      watch = [elemStatus, isElemCurrent, elemProgress]
      size = elemNoNameSize
      children = [
        mkGrowthSlotBack(isPrem, status, progress, isCurrent)
        mkGrowthSlotElems(elemsColor, status, item, squad)
      ]
    }
  }
}


let mkShopSign = @(color) faComp("shopping-basket", {
  fontSize = hdpxi(16)
  padding = smallPadding
  vplace = ALIGN_BOTTOM
  color
})


function chooseGrowthMessageUi() {
  let watch = [ reqGrowthSelection, curGrowthId, curGrowthState, curGrowthConfig ]
  if (!reqGrowthSelection.get())
    return { watch }

  let { expRequired = 0 } = curGrowthConfig.get()?[curGrowthId.get()]
  let { status = GrowthStatus.UNAVAILABLE } = curGrowthState.get()?[curGrowthId.get()]

  let needAlert = curGrowthId.get() == "" || (expRequired > 0 && status == GrowthStatus.ACTIVE)
  return !needAlert ? { watch }
    : {
        watch
        size = FLEX_H
        children = {
          key = $"growth_{curGrowthId.get()}_{needAlert}"
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          gap = midPadding
          valign = ALIGN_CENTER
          children = [
            faComp("exclamation-triangle", {
              fontSize = hdpxi(32)
              color = brightAccentColor
            })
            mkText(loc("growth/reqChooseMessage"), expValueStyle)
          ]
          animations = [{ prop = AnimProp.opacity, from = 0.5, to = 1.0,
            duration = 1, play = true, loop = true, easing = Blink }]
        }
      }
}


let baseSlotAnim = [
  { prop = AnimProp.scale, from = [1.5, 2], to = [1, 1], duration = 0.5, play = true }
  { prop = AnimProp.translate, from = [hdpx(100), -hdpx(50)], to = [0, 0], duration = 0.5, play = true }
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true }
]

let choosableSign = {
  key = "choosable_sign"
  vplace = ALIGN_CENTER
  children = faComp("exclamation-triangle", {
    fontSize = hdpxi(16)
    color = brightAccentColor
  })
  animations = [{ prop = AnimProp.opacity, from = 0.1, to = 1.0,
    duration = 1, play = true, loop = true, easing = Blink }]
}

let completeSign = {
  key = "complete_sign"
  size = FLEX
  rendObj = ROBJ_BOX
  borderWidth = hdpx(3)
  borderColor = brightAccentColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = faComp("check-circle", { fontSize = hdpxi(50), color = brightAccentColor })
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = 2, play = true }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true, delay = 2 }
  ]
}

let mkExpAnimBar = @(expToAnim, expRequired) expToAnim <= 0 ? null
  : {
      size = [pw(100.0 * expToAnim / expRequired), FLEX]
      hplace = ALIGN_RIGHT
      rendObj = ROBJ_SOLID
      color = currentIdleBgColor
      transform = { pivot = [1, 1], scale = [0, 1] }
      animations = [
        { prop = AnimProp.scale, from = [1, 1], to = [1, 1], duration = 1, play = true }
        { prop = AnimProp.scale, from = [1, 1], to = [0, 1], duration = 0.7,
          delay = 1, play = true }
      ]
    }


function mkGrowthElement(growthItem, itemTemplates, tmplsCfg, squadsCfg, growthData = null,
    reqChoice = false) {
  let {
    id = null, expRequired = 0, reward = null, rewardCost = 0, shopItemsGuids = []
  } = growthItem
  let { itemTemplate = null, squadId = null } = reward
  let item = tmplsCfg?[itemTemplate]
  let squad = squadsCfg?[squadId]
  if (item == null && squad == null)
    return emptyCell()

  let isPrem = expRequired == 0
  let curRelations = growthData?.growthRelations[id]

  let elemStatus = Computed(@() curGrowthState.get()?[id].status ?? GrowthStatus.UNAVAILABLE)
  let isElemSelected = Computed(@() curGrowthId.get() == id)
  let isElemAnimated = Computed(@() reqGrowthId.get() == id)
  let isElemCurrent = Computed(@() curGrowthSelected.get() == id
    && elemStatus.get() != GrowthStatus.REWARDED)
  let elemOwnedExp = Computed(@() curGrowthState.get()?[id].exp ?? 0)
  let elemProgress = Computed(@() calcProgress(elemOwnedExp.get(),
    curGrowthConfig.get()?[id].expRequired ?? 0))

  let shItem = Computed(@() isPrem || elemStatus.get() == GrowthStatus.REWARDED
    ? findGrowthShopItem(shopItemsGuids, shopItems.get()) : null)

  let itemName = itemNameFromTemplate(item)
  let group = ElemGroup()

  return watchElemState(function(sf) {
    let status = elemStatus.get()
    let progress = elemProgress.get()
    let isSelected = isElemSelected.get()
    let isCurrent = isElemCurrent.get()
    let ownedExp = elemOwnedExp.get()
    let isCompleted = status == GrowthStatus.COMPLETED
    let isPurchasable = status == GrowthStatus.PURCHASABLE
    let isRewarded = status == GrowthStatus.REWARDED
    let isActive = status == GrowthStatus.ACTIVE

    let priceIcon = isRewarded ? null
      : isPrem ? priceIconGold
      : isCompleted || isPurchasable ? priceIconSilver
      : priceIconExp

    let priceCount = isRewarded ? 0
      : isPrem ? rewardCost
      : isCompleted || isPurchasable ? rewardCost
      : expRequired - ownedExp

    let elemsColor = elemColorMap?[status](sf) ?? defChColor(sf)
    let headerColor = status == GrowthStatus.UNAVAILABLE ? elemColorMap?[status](sf)
      : isCurrent || status == GrowthStatus.COMPLETED ? brightAccentColor
      : isSelected || (sf & S_ACTIVE) ? titleTxtColor
      : defTxtColor
    let brOpacity = status == GrowthStatus.UNAVAILABLE && !(sf & S_HOVER) ? 0.6 : 1

    let hasShopSign = !isPrem && status == GrowthStatus.REWARDED && shItem.get() != null
    let hasPrice = !isPrem || status == GrowthStatus.ACTIVE

    let expAnimVal = completedAnim.get()?.animExp ?? 0
    let hasExpAnim = (completedAnim.get()?.guid ?? "") == id && expAnimVal > 0
    let hasChoosableSign = !hasExpAnim && expAnimVal == 0 && !isPrem && reqChoice && isActive

    return {
      watch = [isElemSelected, isElemCurrent, elemStatus,
        elemProgress, shItem, elemOwnedExp, completedAnim]
      key = $"growth_{id}"
      size = elemSize
      flow = FLOW_VERTICAL
      group
      behavior = Behaviors.Button
      onClick = function() {
        curGrowthId.set(id)
        if (curRelations != null)
          curGrowthRelations.set(curRelations)
      }
      onDoubleClick = @() growthAction(growthItem, growthData)
      children = [
        @() {
          watch = [isGrowthVisible, isElemAnimated]
          key = $"growth_{id}_{isElemAnimated.get()}"
          size = const [FLEX, 0]
          children = isGrowthVisible.get() && isElemAnimated.get()
            ? reqGrowthObject
            : null
        }
        {
          size = const [FLEX, headerSize]
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          valign = ALIGN_BOTTOM
          children = [
            itemTypeIcon(item?.itemtype, item?.itemsubtype, {
              size = hdpxi(20)
              color = headerColor
            })
            {
              size = FLEX_H
              flow = FLOW_HORIZONTAL
              gap = miniPadding
              children = [
                mkGrowthName(itemName, group, headerColor)
                function() {
                  let { growthTier = 0 } = itemTemplates?[id]
                  return growthTier == 0 ? null
                    : mkBattleRatingShort(growthTier).__update({ opacity = brOpacity })
                }
              ]
            }
            hasChoosableSign ? choosableSign : null
          ]
        }
        {
          key = $"growth_slot_{id}_{hasExpAnim}"
          size = FLEX
          children = [
            mkGrowthSlotBack(isPrem, status, progress, isCurrent, isSelected, sf
              mkExpAnimBar(hasExpAnim ? expAnimVal : 0, expRequired))
            mkGrowthSlotElems(elemsColor, status, item, squad, curRelations)
            hasShopSign ? mkShopSign(elemsColor)
              : hasPrice ? mkGrowthSlotPrice(elemsColor, priceCount, priceIcon, shItem)
              : null
            hasExpAnim ? completeSign : null
          ]
          transform = { pivot = [0.5, 0.5] }
          animations = !hasExpAnim ? null : baseSlotAnim
        }
      ]
    }
  })
}

let treeScrollHandler = ScrollHandler()
let hasLeftScroll = Watched(false)
let hasRightScroll = Watched(true)

function updateArrowButtons(elem) {
  hasLeftScroll.set(elem.getScrollOffsX() > 0)
  hasRightScroll.set(elem.getContentWidth() - elem.getScrollOffsX() > safeAreaSize.get()[0])
}

treeScrollHandler.subscribe(function(_) {
  let { elem = null } = treeScrollHandler
  if (elem == null)
    return
  updateArrowButtons(elem)
})

let leftScroll = freeze({
  rendObj = ROBJ_IMAGE
  size = const [scrollBarsWidth, FLEX]
  image = mkColoredGradientX({colorLeft=0xFF060C12, colorRight=0x00000000})
})

let rightScroll = freeze({
  rendObj = ROBJ_IMAGE
  size = const [scrollBarsWidth, FLEX]
  image = mkColoredGradientX({colorLeft=0x00000000, colorRight=0xFF03090C})
})

let mkGrowthTree = @(growthData, itemTemplates) function() {
  local maxCol = 0
  let growthLines = curGrowthConfig.get()
    .reduce(function(res, growth, _, tbl) {
      let { id, col = 0, line = 0, requirements = [] } = growth
      foreach (reqId in requirements) {
        let reqGrowth = tbl[reqId]
        let capturedId = reqId 
        let status = Computed(@() curGrowthState.get()?[capturedId].status != GrowthStatus.REWARDED
          ? GrowthStatus.UNAVAILABLE
          : curGrowthState.get()?[id].status ?? GrowthStatus.UNAVAILABLE)
        let lines = mkGrowthLines(col, line, reqGrowth?.col ?? 0, reqGrowth?.line ?? 0)
        res.append(@() {
          watch = status
          children = lines.map(function(data) {
            let comp = lineStyle?[status.get()] ?? lineStyle[3]
            return comp(data.pos, data.size, data.draw)
          })
        })
      }
      return res
    }, [])

  let reqChoice = reqGrowthSelection.get()
  let { growthRelations = {} } = growthData
  let growthElements = curGrowthConfig.get()
    
    .reduce(function(res, growth, _, tbl) {
      let { id, col = 0, line = 0 } = growth
      maxCol = max(col, maxCol)
      while (res.len() <= line)
        res.append([])
      let arr = res[line]
      if (arr.len() <= col)
        arr.resize(col + 1, null)
      if (arr?[col] == null)
        arr[col] = growth
      else if (id in growthRelations) {
        let relations = growthRelations[id]
        let unrewardedId = relations.findvalue(@(relId)
          curGrowthState.get()?[relId].status != GrowthStatus.REWARDED) ?? id
        arr[col] = tbl[unrewardedId]
      }
      return res
    }, [])
    .map(@(growthLine) {
      flow = FLOW_HORIZONTAL
      gap = gapSize[0]
      children = growthLine.map(@(growthItem)
        mkGrowthElement(growthItem, itemTemplates, curTemplates.get(), curSquads.get(),
          growthData, reqChoice))
    })

  let maxLine = growthElements.len() - 1
  return {
    watch = [curGrowthConfig, curGrowthState, curTemplates, curSquads, reqGrowthSelection]
    size = FLEX_V
    children = [
      {
        size = [
          (elemSize[0] + gapSize[0]) * maxCol - gapSize[0],
          (elemSize[1] + gapSize[1]) * maxLine - gapSize[1]
        ]
        children = growthLines
      }
      {
        flow = FLOW_VERTICAL
        gap = gapSize[1]
        children = growthElements
      }
      @() {
        watch = hasLeftScroll
        size = FLEX_V
        children = hasLeftScroll.get() ? leftScroll : null
        hplace = ALIGN_LEFT
      }
      @() {
        watch = hasRightScroll
        size = FLEX_V
        children = hasRightScroll.get() ? rightScroll : null
        hplace = ALIGN_RIGHT
      }
    ]
  }
}

let mkContentHeaderUi = @(style) @() {
  watch = curGrowthTitleText
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = curGrowthTitleText.get()
}.__update(style)

function gotoNextPage(delta) {
  let total = tabsToShow.get().len()
  if (total > 1) {
    let curIndex = tabsToShow.get()
      .findindex(@(item) item.tabId == curInfoTabId.get()) ?? 0
    curInfoTabId.set(tabsToShow.get()[(curIndex + total + delta) % total].tabId)
  }
}

let switchPageKey = @() {
  size = const [0, SIZE_TO_CONTENT]
  padding = smallPadding
  vplace = ALIGN_CENTER
  children = mkHotkey("J:X", @() gotoNextPage(1))
}

function mkInfoTab(tab) {
  let { tabId } = tab
  let isSelected = Computed(@() tabId == curInfoTabId.get())
  return watchElemState(@(sf) {
    watch = isSelected
    rendObj = ROBJ_BOX
    size = [FLEX, commonBtnHeight]
    fillColor = isSelected.get() || (sf & S_HOVER) ? hoverSlotBgColor : panelBgColor
    borderWidth = isSelected.get() ? [0, 0, hdpx(4), 0] : 0
    borderColor = accentColor
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick = @() curInfoTabId.set(tabId)
    children = {
      rendObj = ROBJ_TEXT
      size = FLEX_H
      halign = ALIGN_CENTER
      color = isSelected.get() ? titleTxtColor
        : (sf & S_HOVER) ? darkTxtColor
        : defTxtColor
      text = loc(infoTabs[tabId].locId)
    }
  })
}

function infoTabsBlock() {
  let res = { watch = tabsToShow }
  if (tabsToShow.get().len() <= 0)
    return res

  let tabs = tabsToShow.get()
  return res.__update({
    watch = [tabsToShow, isGamepad]
    size = [inventoryItemDetailsWidth, FLEX]
    flow = FLOW_VERTICAL
    gap = midPadding
    margin = [0,0,sidePadding,0]
    children = [
      tabs.len() <= 1 ? null : {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        children = tabs.map(mkInfoTab).append(isGamepad.get() ? switchPageKey : null)
      }
      function() {
        let curId = curInfoTabId.get()
        let curIdx = tabs.findindex(@(v) v.tabId == curId)
        return {
          watch = [curInfoTabId, sClassesCfg]
          size = FLEX
          children = curIdx != null
            ? infoTabs[curId].uiCtor(tabs[curIdx].data)
            : null
        }
      }
    ]
  })
}

let itemProgressUi = @(growthData) function () {
  let res = { watch = [curGrowthId, curGrowthConfig, curGrowthState, curGrowthSelected, curGrowthProgress] }
  let growthCfg = curGrowthConfig.get()?[curGrowthId.get()]
  let { expRequired = 0 } = growthCfg
  if (expRequired <= 0)
    return res

  let grState = curGrowthState.get()
  let { exp = 0, status = GrowthStatus.UNAVAILABLE } = grState?[curGrowthId.get()]
  let isResearching = curGrowthId.get() == curGrowthSelected.get()
  let statusLocId = isResearching ? "growth/statusGrowthing"
    : status == GrowthStatus.ACTIVE ? "growth/statusActive"
    : status == GrowthStatus.COMPLETED ? "growth/statusCompleted"
    : status == GrowthStatus.PURCHASABLE ? "growth/statusPurchasable"
    : status == GrowthStatus.REWARDED ? "growth/statusRewarded"
    : "growth/statusUnavailable"

  let grProgres = curGrowthProgress.get()
  local alertText = ""
  if (status == GrowthStatus.UNAVAILABLE) {
    let err = getGrowthSelectError(growthCfg, grState, grProgres, growthData)
    if (err != null) {
      let { growths, tier } = err
      alertText = "\n".join([
        (tier == null ? null : loc("growthTier/reqToSelectGrowth", { reqText = tier })),
        (growths.len() == 0 ? null : loc("growth/reqToCompletePrev"))
      ], true)
    }
  }

  let progressObject = status == GrowthStatus.UNAVAILABLE
      ? mkText(alertText, alertStyle)
    : status == GrowthStatus.ACTIVE
      ? {
          size = FLEX_H
          valign = ALIGN_CENTER
          children = [
            gradientProgressBar(exp.tofloat() / expRequired.tofloat(), progressBarStyle)
            {
              rendObj = ROBJ_TEXT
              padding = [0, smallPadding]
              text = $"{splitThousands(exp)} / {splitThousands(expRequired)}"
            }.__update(progressValueStyle)
          ]
        }
    : null
  return res.__update({
    size = FLEX_H
    gap = midPadding
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    children = [
      mkText(loc(statusLocId), infoTextStyle)
      progressObject
    ]
  })
}

let mkBtnReward = @(price, action, btnCtor) price == 0 ? null
  : btnCtor(function(_textComp, params, handler, group, sf) {
    let color = textColor(sf, primaryStyle)
    return textButtonTextCtor({
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = midPadding
      children = [
        {
          rendObj = ROBJ_TEXT
          color
          text = loc("growth/btnTakeReward")
        }.__update(fontBody)
        priceIconSilver
        {
          rendObj = ROBJ_TEXT
          color
          text = price
        }.__update(fontBody)
      ]
    }, params, handler, group, sf)}, action, {
      size = [FLEX, commonBtnHeight]
    }.__update(btnHotkey))

function mkBtnPurchase(shopItemsGuids, action) {
  let shItem = Computed(@() findGrowthShopItem(shopItemsGuids, shopItems.get()))
  return @() {
    watch = shItem
    size = FLEX_H
    children = shItem.get() == null ? null
      : Primary(function(_textComp, params, handler, group, sf) {
        let color = textColor(sf, primaryStyle)
        return textButtonTextCtor({
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = midPadding
          children = [
            {
              rendObj = ROBJ_TEXT
              color
              text = loc("shop/purchase")
            }.__update(fontBody)
            mkPrice({
              shopItem = shItem.get()
              needPriceText = false
              styleOverride = { color }.__update(fontBody)
              iconSize = priceIconSize
            })
          ]
        }, params, handler, group, sf)}, action, {
          size = [FLEX, commonBtnHeight]
        }.__update(btnHotkey))
  }
}

let mkBtnSelect = @(action) Regular(loc("growth/btnSelectCurrent"), action,
  { size = [FLEX, commonBtnHeight] }.__update(btnHotkey))

let mkBtnBoostExp = @(action) Primary(loc("growth/accelerated"), action,
  { size = [FLEX, commonBtnHeight] }.__update(btnHotkey))


function updateSliders(sliderGold, sliderExp) {
  let growthId = curGrowthId.get()
  let growthItem = curGrowthConfig.get()?[growthId]
  let freeExp = curGrowthFreeExp.get()
  let { exp = 0 } = curGrowthState.get()?[growthId]
  let { expRequired = 0, expCost = 0 } = growthItem

  let rate = expRequired.tofloat() / expCost.tofloat()
  let needExp = expRequired - exp
  let freeExpCount = min(freeExp, needExp)

  sliderGold.set(min(exp + rate, expRequired))
  sliderExp.set(exp + freeExpCount)
}


function buyCb(res) {
  if ("error" not in res)
    sound_play("ui/purchase_level_squad")
}

let mkBtnUseExp = @(growthId, boostSliderExp, exp, boostSliderGold) function() {
  let count = boostSliderExp.get() - exp
  return {
    watch = boostSliderExp
    size = const [FLEX, hdpxi(70)]
    halign = ALIGN_RIGHT
    children = count <= 0 ? null
      : Primary(@(_textComp, params, handler, group, sf) textButtonTextCtor({
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          gap = midPadding
          children = [
            bigPriceIconExp
            {
              rendObj = ROBJ_TEXT
              color = textColorBtn(sf)
              text = count
            }.__update(fontBody)
          ]
        }, params, handler, group, sf),
        @() callGrowthExp(curArmy.get(), growthId, count, function(res) {
          updateSliders(boostSliderGold, boostSliderExp)
          buyCb(res)
        }), { size = [pw(40), commonBtnHeight] })
  }
}


let mkGrowthControlsUi = @(growthDataVal) function () {
  let growthId = curGrowthId.get()
  let growth = curGrowthState.get()?[growthId]
  let growthItem = curGrowthConfig.get()?[growthId]
  let isInResearch = curGrowthSelected.get() == growthId
  let { status = GrowthStatus.UNAVAILABLE } = growth
  let { rewardCost = 0, expRequired = 0, shopItemsGuids = [] } = growthItem

  let isActive      = status == GrowthStatus.ACTIVE
  let isCompleted   = status == GrowthStatus.COMPLETED
  let isPurchasable = status == GrowthStatus.PURCHASABLE
  let isRewarded    = status == GrowthStatus.REWARDED

  let isPrem = expRequired == 0
  let hasShopItems = shopItemsGuids.len() > 0
  let reqBaseReward = (isCompleted || isPurchasable) && !isPrem
  let reqPurchase = hasShopItems && ((isPrem && !isRewarded) || (isRewarded && !isPrem))
  let reqBoost = !isPrem && isActive && isInResearch
  let reqSelect = !isPrem && isActive && !isInResearch

  function action() {
    growthAction(growthItem, growthDataVal)
    passCompleteAnim()
    curGrowthRelations.set(null)
  }
  return {
    watch = [curGrowthId, curGrowthState, curGrowthConfig, curGrowthSelected, curGrowthProgress]
    key = "growth_action_button"
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = reqSelect ? mkBtnSelect(action)
      : reqBoost ? mkBtnBoostExp(action)
      : reqBaseReward ? mkBtnReward(rewardCost, action, isPurchasable ? Primary : Regular)
      : reqPurchase ? mkBtnPurchase(shopItemsGuids, action)
      : null
  }
}

let mkInfoBlock = @(growthData, override = {}) @() {
  watch = growthData
  size = FLEX
  flow = FLOW_VERTICAL
  gap = midPadding
  padding = [smallPadding, 0]
  children = [
    infoTabsBlock
    chooseGrowthMessageUi
    itemProgressUi(growthData.get())
    mkGrowthControlsUi(growthData.get())
  ]
}.__update(override)


function mkTier(tierData) {
  let { id, from, to, required, index } = tierData
  let tierLength = to - from + 1
  let tierWidth = elemSize[0] * tierLength + gapSize[0] * (tierLength - 1)
  let tierState = Computed(@() curGrowthProgress.get()?[id] ?? {})

  return function() {
    let { current = 0 } = tierState.get()
    let progress = required == 0 ? 1 : current.tofloat() / required
    return {
      watch = tierState
      size = [tierWidth, FLEX]
      children = mkTierObject(progress,
        {
          rendObj = ROBJ_TEXT
          text = loc("growth/tier", { tier = index + 1 })
        }.__update(progLeftStyle),
        {
          rendObj = ROBJ_TEXT
          hplace = ALIGN_RIGHT
          text = $"{current}/{required}"
        }.__update(progRightStyle)
      )
    }
  }
}

let mkTiersHeader = @(tiersData) {
  size = const [FLEX, tierHeight]
  flow = FLOW_HORIZONTAL
  children = tiersData.map(mkTier)
  gap = gapSize[0]
}

let relationsLineSize = [gapSize[0], elemNoNameSize[1]]

function mkGrowthChain(growthElements, growthData, itemTemplates) {
  function mkGrowths() {
    let reqChoice = reqGrowthSelection.get()
    let growths = []
    growthElements.get().each(function(growthItem) {
      if (growths.len() > 0) {
        growths.append(function() {
          let elemStatus = Computed(@() curGrowthState.get()?[growthItem.id].status
            ?? GrowthStatus.UNAVAILABLE)
          return {
            watch = elemStatus
          }.__update(lineStyle[elemStatus.get()](null, relationsLineSize, lineHor))
        })
      }
      growths.append(mkGrowthElement(growthItem, itemTemplates, curTemplates.get(),
        curSquads.get(), growthData.get(), reqChoice))
    })
    return growths
  }

  return @() {
    watch = [growthElements, curTemplates, curSquads, growthData, reqGrowthSelection]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    children = mkGrowths()
  }
}

let mkCurRelationsUi = @(growthElements, growthData, itemTemplates) @() {
  watch = [safeAreaBorders, safeAreaAmount]
  size = FLEX
  flow = FLOW_HORIZONTAL
  gap = largePadding
  padding = safeAreaBorders.get()
  children = [
    {
      size = [inventoryItemDetailsWidth, FLEX]
      flow = FLOW_VERTICAL
      gap = mainMenuGap
      children = [
        { size = [FLEX, navHeight] }
        mkInfoBlock(growthData)
      ]
    }
    {
      size = FLEX
      flow = FLOW_VERTICAL
      gap = sidePadding
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = [
        mkGrowthChain(growthElements, growthData, itemTemplates)
        Regular(loc("mainmenu/btnBack"), function() {
            curGrowthRelations.set(null)
            removeModalWindow(RELATIONS_WND_UID)
          }, {
          hplace = ALIGN_CENTER
          hotkeys = [[$"^{JB.B} | Esc", { description = { skip = true }}]]
        })
      ]
    }
  ]
}

function curGrowthViewUi() {
  let growthItem = curGrowthConfig.get()?[curGrowthId.get()]
  return {
    watch = [curGrowthId, curGrowthConfig, curTemplates, curSquads]
    padding = largePadding
    hplace = ALIGN_CENTER
    children = mkGrowthSlot(growthItem, curTemplates.get(), curSquads.get())
  }
}

function changeSliderExp(delta, curExp, curPos, canBuy, expRequired) {
  let step = (delta * expRequired * 0.1).tointeger()
  return clamp(curPos + step, curExp, curExp + canBuy)
}

let mkSliderUi = kwarg(function(sliderWatch, exp, expRequired, canBuyCount, unit, info) {
  let gainObjectWidth = expRequired == 0 ? 0 : sliderWidth * exp / expRequired
  return {
    flow = FLOW_VERTICAL
    padding = largePadding
    rendObj = ROBJ_SOLID
    color = panelBgColor
    children = [
      function() {
        let addExp = round_by_value(sliderWatch.get() - exp, 1)
        let sliderTxt = $"{exp + addExp}/{expRequired}"
        return {
          watch = sliderWatch
          size = FLEX_H
          flow = FLOW_VERTICAL
          children = [
            {
              size = FLEX_H
              flow = FLOW_HORIZONTAL
              gap = smallPadding
              valign = ALIGN_CENTER
              children = [
                bigPriceIconExp
                {
                  rendObj = ROBJ_TEXT
                  text = sliderTxt
                }.__update(expValueStyle)
                { size = FLEX }
                info
              ]
            }
            {
              size = FLEX_H
              flow = FLOW_HORIZONTAL
              gap = smallPadding
              valign = ALIGN_CENTER
              halign = ALIGN_CENTER
              children = [
                priceIconExp
                {
                  rendObj = ROBJ_TEXT
                  text = $"+{addExp}"
                }.__update(progressValueStyle)
              ]
            }
          ]
        }
      }
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        valign = ALIGN_CENTER
        children = [
          Regular(loc("-"), @() sliderWatch.set(
            changeSliderExp(-1, exp, sliderWatch.get(), canBuyCount, expRequired)),
              fontSub.__merge({hotkeys = [["^J:LB"]]}))
          {
            size = [sliderWidth, hdpxi(30)]
            children = Horiz(sliderWatch, {
              min = 0
              max = expRequired
              unit
              step = expRequired * 0.1
              setValue = @(v) sliderWatch.set(clamp(v, exp, exp + canBuyCount))
              gainObject = gainObjectWidth == 0 ? null : {
                size = [gainObjectWidth, FLEX]
                rendObj = ROBJ_SOLID
                color = brightAccentColor
              }
            })
          }
          Regular(loc("+"), @() sliderWatch.set(
            changeSliderExp(1, exp, sliderWatch.get(), canBuyCount, expRequired)),
              fontSub.__merge({hotkeys = [["^J:RB"]]}))
          Regular(loc("growth/maxBoost"), @() sliderWatch.set(exp + canBuyCount),
            fontSub.__merge({hotkeys = [["^J:X | Space"]]}))
        ]
      }
    ]
  }
})


function scrollToSelected(growthId) {
  if (growthId != null) {
    let { col = 0 } = curGrowthConfig.get()?[growthId]
    let xPos = elemSize[0] * col + gapSize[0] * col + elemSize[0] / 2 - scrollAreaWidth / 2
    tblScrollHandler.scrollToX(xPos)
  }
}

function scrollToTier(tier) {
  if (tier != null) {
    let tierToScroll = curGrowthTiers.get()[tier]
    let {from, to} = tierToScroll
    let col = from + (to - from) / 2
    let xPos = elemSize[0] * col + gapSize[0] * col + elemSize[0] / 2 - scrollAreaWidth / 2
    tblScrollHandler.scrollToX(xPos)
  }
}

let mkBuyForGoldBthUi = @(growthId, boostSlider, exp, rate)
  function() {
    let expToBuy = boostSlider.get() - exp
    let spendGold = ceil(expToBuy.tofloat() / rate)
    return {
      watch = boostSlider
      size = const [FLEX, hdpxi(70)]
      halign = ALIGN_RIGHT
      children = spendGold <= 0 ? null
        : currencyBtn({
            currencyId = GOLD_CURRENCY_ID
            price = spendGold
            btnText = ""
            cb = @() purchaseMsgBox({
              currencyId = GOLD_CURRENCY_ID
              price = spendGold
              title = curGrowthTitleText.get()
              description = loc("growth/investGold")
              purchase = @() callGrowthBuyExp(curArmy.get(), growthId, expToBuy, spendGold, buyCb)
              srcComponent = "buy_army_growth"
              alwaysShowCancel = true
            })
            style = {
              size = const [pw(30), SIZE_TO_CONTENT]
              margin = 0
              padding = 0
              hotkeys = [["^J:Y | Enter"]]
            }
          })
    }
  }


function mkCurBoostUi() {
  let boostSliderGold = Watched(0)
  let boostSliderExp = Watched(0)
  return function() {
    let res = {
      watch = [safeAreaBorders, curGrowthConfig, curGrowthState,
        curGrowthId, currenciesBalance, curGrowthFreeExp]
    }
    let growthId = curGrowthId.get()
    let growthItem = curGrowthConfig.get()?[growthId]
    let { exp = 0 } = curGrowthState.get()?[growthId]
    let { expRequired = 0, expCost = 0 } = growthItem

    let needExp = expRequired - exp
    if (needExp <= 0 || expCost <= 0)
      return res

    let freeExp = curGrowthFreeExp.get()
    let rate = expRequired.tofloat() / expCost.tofloat()
    let balance = currenciesBalance.get()?[GOLD_CURRENCY_ID] ?? 0
    let canBuyCount = min(rate * balance, needExp)
    let freeExpCount = min(freeExp, needExp)
    return res.__update(
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = largePadding
      padding = safeAreaBorders.get()
      halign = ALIGN_CENTER
      vplace = ALIGN_CENTER
      onAttach = @() updateSliders(boostSliderGold, boostSliderExp)
      children = [
        msgboxStyling?.rootUpperDecor
        {
          size = FLEX_H
          valign = ALIGN_CENTER
          children = [
            Regular(loc("mainmenu/btnBack"), function() {
                isBoostWndOpen.set(false)
                removeModalWindow(BOOST_WND_UID)
              }, {
              hotkeys = [[$"^{JB.B} | Esc", { description = { skip = true }}]]
            })
            {
              rendObj = ROBJ_TEXT
              hplace = ALIGN_CENTER
              text = utf8ToUpper(loc("growth/accelerated"))
            }.__update(headerTxtStyle)
            {
              flow = FLOW_HORIZONTAL
              gap = largePadding
              hplace = ALIGN_RIGHT
              children = [
                freeExpUi,
                currenciesWidgetUi
              ]
            }
          ]
        }
        mkContentHeaderUi(infoTextStyle)
        curGrowthViewUi
        {
          flow = FLOW_VERTICAL
          gap = largePadding
          children = freeExpCount > 0
            ? [
                mkSliderUi({ exp, expRequired,
                  sliderWatch = boostSliderExp,
                  canBuyCount = freeExpCount,
                  unit = 1.0 / expRequired,
                  info = freeExpUi
                })
                mkBtnUseExp(growthId, boostSliderExp, exp, boostSliderGold)
              ]
            : [
                mkSliderUi({ exp, expRequired, canBuyCount,
                  sliderWatch = boostSliderGold,
                  unit = rate / expRequired,
                  info = currenciesWidgetUi
                })
                mkBuyForGoldBthUi(growthId, boostSliderGold, exp, rate)
              ]
        }
        msgboxStyling?.rootLowerDecor
      ]
    })
  }
}


function mkTryCompleteUi(growthData, isVisible) {
  curGrowthId.set(completedAnim.get().guid)
  return function() {
    let watch = growthData
    return {
      watch
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = largePadding
      halign = ALIGN_CENTER
      vplace = ALIGN_CENTER
      children = [
        msgboxStyling?.rootUpperDecor
        {
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          gap = midPadding
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = [
            faComp("check-circle", { fontSize = hdpxi(40), color = brightAccentColor })
            {
              rendObj = ROBJ_TEXT
              text = utf8ToUpper(loc("mainmenu/research_completed"))
            }.__update(headerTxtStyle)
          ]
        }
        curGrowthViewUi
        mkText(loc("growth/canGetReward"), {
          size = const [pw(50), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
        }.__update(infoTextStyle))
        mkContentHeaderUi({ halign = ALIGN_CENTER }.__update(infoTextStyle))
        @() {
          watch = isVisible
          size = [inventoryItemDetailsWidth, SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = midPadding
          margin = sidePadding
          halign = ALIGN_CENTER
          children = [
            !isVisible.get() ? null : mkGrowthControlsUi(growthData.get())
            Regular(loc("mainmenu/btnBack"), function() {
              if (!isVisible.get()) {
                anim_skip(trigger)
                isVisible.set(true)
                return
              }
              passCompleteAnim()
              curGrowthRelations.set(null)
              removeModalWindow(TRY_COMPLETE_WND_UID)
            }, { hotkeys = [[$"^{JB.B} | Esc", { description = { skip = true }}]] })
          ]
        }
        msgboxStyling?.rootLowerDecor
      ]
    }
  }
}


let additionalWndStyle = {
  size = FLEX
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = defItemBlur
}
let boostWndStyle = {
  size = FLEX
  rendObj = msgboxStyling.Root.rendObj
  fillColor = msgboxStyling.Root.fillColor
}


function applyAutoScroll(_ = null) {
  let tutorGuid = curGrowthGuidToPurchase.get()
  if (tutorGuid != null) {
    curGrowthId.set(tutorGuid)
    scrollToSelected(tutorGuid)
    return
  }

  if (savedScrollXPos != null) {
    tblScrollHandler.scrollToX(savedScrollXPos)
    savedScrollXPos = null
    return
  }

  let { guid = "" } = completedAnim.get()
  if (guid != "") {
    curGrowthId.set(guid)
    scrollToSelected(guid)
    savedScrollXPos = tblScrollHandler.elem?.getScrollOffsX() ?? 0
    return
  }

  let tierScroll = growthTierToScroll.get()
  if (tierScroll != null) {
    scrollToTier(tierScroll)
    growthTierToScroll.set(null)
    return
  }

  let growthId = reqGrowthId.get()
    ?? curGrowthSelected.get()
    ?? curAvailableToSelect.get()
    ?? ""
  curGrowthId.set(growthId)
  scrollToSelected(growthId)
}


function markGrowthVisible() {
  isGrowthVisible.set(true)
}

let closeModalWindows = @()
  [TRY_COMPLETE_WND_UID, BOOST_WND_UID, RELATIONS_WND_UID].each(removeModalWindow)

function mkGrowthUi() {
  let growthData = mkGrowthData()
  let curArmyItemTemplates = Computed(@() allItemTemplates.get()[curArmy.get()])

  function checkAdditionalWnd(_v = null) {
    let isBoostOpen = isBoostWndOpen.get()
    let relations = curGrowthRelations.get()

    if (completedAnim.get() != null) {
      removeModalWindow(RELATIONS_WND_UID)
      removeModalWindow(BOOST_WND_UID)
      let isVisible = Watched(false)
      addModalWindow({
        key = TRY_COMPLETE_WND_UID
        size = FLEX
        onClick = function() {
          anim_skip(trigger)
          isVisible.set(true)
        }
        children = {
          size = FLEX
          children = mkTryCompleteUi(growthData, isVisible)
        }.__update(boostWndStyle)
        animations = [
          { prop = AnimProp.opacity, from = 0, to = 0, duration = 3, play = true,
            trigger, onFinish = @() isVisible.set(true) }
          { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.4, play = true,
            delay = 3, trigger }
        ]
      })
    }
    else if (isBoostOpen) {
      removeModalWindow(RELATIONS_WND_UID)
      removeModalWindow(TRY_COMPLETE_WND_UID)
      addModalWindow({
        key = BOOST_WND_UID
        onClick = @() null
        children = mkCurBoostUi()
      }.__update(boostWndStyle))
    }
    else if (relations != null) {
      removeModalWindow(BOOST_WND_UID)
      removeModalWindow(TRY_COMPLETE_WND_UID)
      let growthElements = Computed(function() {
        let configs = curGrowthConfig.get()
        return relations.map(@(id) configs[id])
      })
      addModalWindow({
        key = RELATIONS_WND_UID
        onClick = @() null
        children = mkCurRelationsUi(growthElements, growthData, curArmyItemTemplates.get())
      }.__update(additionalWndStyle))
    }
    else
      closeModalWindows()
  }

  return {
    key = growthData
    size = FLEX
    padding = [contentOffset,0,0,0]
    onAttach = function() {
      applyAutoScroll()
      if (reqGrowthId.get() != null)
        gui_scene.resetTimeout(5, @() reqGrowthId.set(null))
      gui_scene.resetTimeout(0.5, markGrowthVisible)
      foreach (v in [completedAnim, curGrowthRelations, isBoostWndOpen])
        v.subscribe(checkAdditionalWnd)
    }
    onDetach = function() {
      gui_scene.clearTimer(markGrowthVisible)
      reqGrowthId.set(null)
      isGrowthVisible.set(false)
      closeModalWindows()
      foreach (v in [completedAnim, curGrowthRelations, isBoostWndOpen])
        v.unsubscribe(checkAdditionalWnd)
    }
    children = {
      size = FLEX
      flow = FLOW_HORIZONTAL
      gap = blocksGap
      children = [
        {
          size = [inventoryItemDetailsWidth, FLEX]
          children = mkInfoBlock(growthData)
        }
        makeHorizScroll(@() {
          watch = [growthData, curGrowthTiers, curArmyItemTemplates]
          flow = FLOW_VERTICAL
          gap = midPadding
          children = [
            mkTiersHeader(curGrowthTiers.get())
            mkGrowthTree(growthData.get(), curArmyItemTemplates.get())
          ]
        }, {
          size = FLEX
          scrollHandler = tblScrollHandler
          rootBase = {
            behavior = Behaviors.Pannable
            wheelStep = 1
          }
        })
      ]
    }
  }
}

function checkBoostStatus(_v = null) {
  let status = curGrowthState.get()?[curGrowthId.get()].status ?? GrowthStatus.UNAVAILABLE
  if (status != GrowthStatus.ACTIVE)
    isBoostWndOpen.set(false)
}

subscribeList(applyAutoScroll, completedAnim, curArmy)
subscribeList(checkBoostStatus, curGrowthState, curGrowthId)

function resetCurGrowthId(_ = null) {
  if (curGrowthId.get() in curGrowthConfig.get())
    return

  let curSelected = curGrowthSelected.get()
  if ((curSelected ?? "") == "") {
    curGrowthId.set(curSelected)
    return
  }

  if (curSelected not in curGrowthConfig.get())
    curGrowthId.set(curGrowthConfig.get().findindex(@(_) true) ?? "")
}

subscribeList(resetCurGrowthId, curGrowthSelected, curGrowthConfig)
resetCurGrowthId()

return mkGrowthUi
