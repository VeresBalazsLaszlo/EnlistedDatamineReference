import "%ui/components/fontawesome.map.nut" as fa
import "%ui/control/gui_buttons.nut" as JB
import "%ui/meta/perks/perksList.nut" as perksList
import "%ui/components/faComp.nut" as faComp
import "%ui/components/spinner.nut" as spinnerCtor
import "%ui/components/colorize.nut" as colorize
import "%darg/helpers/mkTextRow.nut" as mkTextRow
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%ui/components/mkSoldierCard.nut" as mkSoldierCard
import "%ui/soldiers/model/getPayItemsData.nut" as getPayItemsData
import "%ui/currency/currenciesWidgetUi.nut" as currenciesWidgetUi
import "%ui/helpers/squad_vehicle_seats.nut" as mkVehicleSeats
import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
import "%ui/components/modalPopupWnd.nut" as modalPopupWnd

from "%ui/style/designConst.nut" import defTxtColor, attentionTxtColor, titleTxtColor, panelBgColor, darkPanelBgColor, darkTxtColor, smallPadding
  , midPadding, largePadding, bigPadding, sidePadding, unitSize, blockedTxtColor, isWide
from "%ui/meta/perks/treeDesign.nut" import getColors, getColorParams, NodeElements, darkColor,
  lightColor, treeBgColor
from "%ui/style/fontsStyle.nut" import fontSub, fontBody, fontHeading2, fontawesome
from "%ui/style/cursors.nut" import withTooltip
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/components/msgbox.nut" import showMsgbox, showMessageWithContent
from "%ui/components/textButton.nut" import Regular, Accented, soundActive
from "%ui/components/textButtonPurchase.nut" import priceGold, priceOrders, priceGoldOrOrders
from "%ui/shop/currencyComp.nut" import mkCurrencyUi
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/soldiers/components/perksPackage.nut" import perkPointIcon, getStatDescList
from "%ui/meta/perks/perksStats.nut" import perksStatsCfg
from "%ui/soldiers/model/soldierPerks.nut" import perksData
from "%ui/soldiers/model/collectSoldierData.nut" import collectSoldierDataImpl
from "%ui/preset/presetPerkUi.nut" import mkPerkPresetBlock, togglePerkPresetBlock,
  previewPerkPreset, presetWidgetOpened, getPerksAvailableToBuy, closePerkPresets
from "%ui/soldiers/model/config/outfitConfig.nut" import equippedOutfitsForArmy,
  isOutfitAllowedByCampaignImpl, outfitSchemes
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/meta/perks/perkTreePkg.nut" import PerkState, priceForPerk, statForPerk, hasEnoughPoints,
  iconForPerk, statIconForPerk, stateForPerk, tiersAvailable, treeForSoldier, getPerkPointsInfo,
  canDiscardPerk, MAX_LEVEL
from "%ui/soldiers/model/soldierActions.nut" import addPerk, removePerk, resetPerks,
  freeRerollPerks, buySoldierExp, useSoldierLevelupOrders
from "%ui/meta/perks/perksExp.nut" import getNextLevelData, perkLevelsGrid
from "%ui/components/defcomps.nut" import txt
from "%ui/helpers/gradients.nut" import mkColoredGradientX, mkTwoSidesGradientX
from "%ui/meta/configs.nut" import serverConfigs
from "%ui/meta/perks/perksSchemesConfig.nut" import perkSchemes, soldierSchemes, perkTrees, perkTreesSpecial
from "%ui/soldiers/model/state.nut" import armies, armySquadsById, armyItemCountByTpl, curVehicle,
  curSquadSoldiersInfo
from "%ui/meta/profile.nut" import campItemsByLink, curCampSquads, curCampItems, curCampSoldiers
from "%ui/meta/servProfile.nut" import squads, soldiersLook, soldierPerks
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfileLookCfg
from "dagor.debug" import logerr
from "%ui/currency/currenciesList.nut" import enlistedGold
from "%ui/currency/currenciesComp.nut" import mkCurrency
from "%ui/soldiers/model/config/soldierTrainingConfig.nut" import maxTrainByClass
from "%ui/soldiers/soldierPerksPkg.nut" import showTrainResearchMsg
from "%ui/components/soldierClasses.nut" import getClassCfg
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/currency/currencies.nut" import currenciesBalance
from "%ui/components/gamepadImgByKey.nut" import mkImageCompByDargKey
from "%ui/meta/tutorial/meta_tutorial_button.nut" import mkPageButton
from "%ui/meta/tutorial/meta_tutorial_config.nut" import Tutorial
from "%ui/state/appState.nut" import isInBattleState
from "%ui/ui_library.nut" import *
from "%ui/meta/perks/perksPoints.nut" import pPointsBaseParams, pPointsList
from "%ui/shop/armyCurrencyUi.nut" import currencySilverUi

const WND_UID = "perkTree"
const POPUP_UID = "perkList"

let logPerks = with_prefix("[PerksConfig] ")

function close() {
  removeModalWindow(WND_UID)
  closePerkPresets()
}

let defTxtStyle     = { color = defTxtColor       }.__update(fontSub)
let priceTxtStyle   = { color = attentionTxtColor }.__update(fontSub)
let titleTxtStyle   = { color = titleTxtColor     }.__update(fontHeading2)
let lineColor       = mul_color(lightColor, 0.4)

let textButtonColorStyle = @(sf)
  (sf & S_ACTIVE) ? defTxtColor
  : (sf & S_HOVER) ? darkTxtColor
  : defTxtColor

let msgBoxTextColorStyle = @(sf) sf & S_HOVER ? darkTxtColor : defTxtColor

const LEVEL_UP_ORDER = "soldier_levelup_order"

let PERK_ICON_SIZE = isWide ? unitSize * 2 : unitSize * 1.8
let COLUMN_GAP = largePadding
let VERTICAL_GAP = isWide ? largePadding : midPadding
let BIGGER_GAP = unitSize * 0.8
let MEDIUM_GAP = unitSize * (isWide ? 0.5 : 0.2)

let COLUMN_WIDTH = (unitSize * 8).tointeger()
let BTN_SIZE = isWide ? FLEX_H : [COLUMN_WIDTH, SIZE_TO_CONTENT]
let soldierCardSize = [(8 * unitSize).tointeger(), (1.8 * unitSize).tointeger()]

const separatorBgColor = Color(88, 39, 39)
const tooltipHeaderColor = Color(36, 40, 46)
const tooltipBodyColor = Color(43, 50, 56)

let selectedPerk = Watched(null)
let isExpBuyActionInProgress = Watched(false)

const NUM_TIERS = 3
let perkTreeTbl = @(perkTreesVal) perkTreesVal.map(function(perkIdList) {
  let res = []
  for (local tier = 1; tier <= NUM_TIERS; ++tier)
    res.append({
      tier
      perks = pPointsList.reduce(@(tbl, slotName) tbl.rawset(slotName, []), {})
    })

  foreach (perkId in perkIdList) {
    if (perkId not in perksList.get()) {
      logerr($"Perk /*{perkId}*/ not found in perk_list config")
      continue
    }
    if (perksList.get()[perkId].cost.len() == 0)
      continue 

    let perkDesc = clone perksList.get()[perkId]
    perkDesc.tier <- perkDesc.tier ?? 1
    perkDesc.perkId <- perkId
    let stat = statForPerk(perkDesc)
    let perksByTierList = res[perkDesc.tier - 1].perks[stat]

    if (perksByTierList.findindex(@(v) v.perkId == perkId) != null) {
      logerr($"Duplicated /*{perkId}*/ in the tree")
      continue
    }
    perksByTierList.append(perkDesc)
  }
  return res
})


let soundAddPerk = @(isMaximum)
  @(_) sound_play(isMaximum ? "ui/perk_max" : "ui/perk_add")

function onBuyLevelCb(_) {
  sound_play("ui/debriefing/squad_star")
  isExpBuyActionInProgress.set(false)
}

let buyLevelMsgBox = @(content) {
  size = const [sw(90), fsh(32)]
  children = [
    {
      flow = FLOW_HORIZONTAL
      hplace = ALIGN_RIGHT
      vplace = ALIGN_TOP
      valign = ALIGN_CENTER
      gap = midPadding
      children = [
        mkCurrencyUi(LEVEL_UP_ORDER)
        currenciesWidgetUi
      ]
    }
    {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = FLEX
      children = content
    }
  ]
}

let mkUseLevelUpOrderBtn = @(guid, payData) {
  text = priceOrders("perks/buyLevel", { count = 1, currencyTpl = LEVEL_UP_ORDER }, msgBoxTextColorStyle)
  action = @() useSoldierLevelupOrders(guid, payData)
  customStyle = {
    
    textMargin = [hdpx(10), hdpx(20)]
    hotkeys = [["^J:X"]]
  }
}

let mkBuyLevelGoldBtn = @(payData) {
  text = priceGold("perks/buyLevel", { count = payData.cost }, msgBoxTextColorStyle)
  action = payData.action
  customStyle = {
    
    textMargin = [hdpx(10), hdpx(20)]
    hotkeys = payData?.hotkeys ?? [["^J:Y"]]
  }
}

function buyLevelBtnParams(soldier, perksCfgVal, perkLevelsGridVal,
    currenciesBalanceVal, armyItemCountByTplVal, curCampItemsVal) {
  let { exp = 0, stepsLeft = 1 } = perksCfgVal
  let { guid, level } = soldier
  let maxLevel = perkLevelsGridVal.MAX_LEVEL
  if (level == maxLevel)
    return null

  let ordersReq = 1
  let ordersCount = armyItemCountByTplVal?[LEVEL_UP_ORDER] ?? 0
  let orderPayData = ordersReq > ordersCount
    ? null
    : getPayItemsData({ [LEVEL_UP_ORDER] = ordersReq }, curCampItemsVal)
  let nextLevelData = getNextLevelData({
    level
    maxLevel
    exp
    lvlsCfg = perkLevelsGridVal
  })

  if (nextLevelData == null && orderPayData == null)
    return null

  function action() {
    let notEnoughMoney = (nextLevelData?.cost ?? 0) - (currenciesBalanceVal?[enlistedGold.id] ?? 0)

    if (notEnoughMoney > 0 && orderPayData == null) {
      showMessageWithContent({
        content = buyLevelMsgBox({
          flow = FLOW_HORIZONTAL
          children = mkTextRow(loc("shop/notEnoughCurrency"),
            @(t) txt(t).__update(fontBody, { color = attentionTxtColor }), {
            ["{priceDiff}"] = mkCurrency({ 
              currency = enlistedGold
              price = notEnoughMoney
            })
          })
        })
      })
      return
    }

    let buttons = []
    if (guid != null && orderPayData != null)
      buttons.append(mkUseLevelUpOrderBtn(guid, orderPayData))

    if (notEnoughMoney <= 0)
      buttons.append(
        mkBuyLevelGoldBtn({
          action = function() {
            isExpBuyActionInProgress.set(true)
            buySoldierExp(perksCfgVal.guid,
              nextLevelData?.exp ?? 0, nextLevelData?.cost ?? 0, onBuyLevelCb)
          }
          cost = nextLevelData?.cost ?? 0
          hotkeys = [["^J:Y | Enter"]]
        }))

    buttons.append({
      text = loc("Cancel")
      isCancel = true
      customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
    })

    showMessageWithContent({
      uid = "buySoldierLevelMsgBox"
      content = buyLevelMsgBox({
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          {
            vplace = ALIGN_TOP
            margin = largePadding
            rendObj = ROBJ_TEXT
            text = loc("soldierLevel", { level })
            color = attentionTxtColor
          }.__update(fontHeading2)
          {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_BOTTOM
            children = mkTextRow(loc("buy/soldierLevelStats", { count = stepsLeft }),
              @(t) txt(t).__update(fontBody, { color = titleTxtColor }),
              { ["{countColorized}"] = 
                {
                  rendObj = ROBJ_TEXT
                  text = stepsLeft
                  color = attentionTxtColor
                }.__update(fontHeading2)
              })
          }
          {
            rendObj = ROBJ_TEXT
            text = loc("buy/soldierLevelConfirm")
            color = titleTxtColor
          }.__update(fontBody)
        ]
      })
      buttons
    })
  }

  let priceTextCtor = priceGoldOrOrders("perks/buyLevel",
    orderPayData == null ? null : {
      count = ordersReq,
      currencyTpl = LEVEL_UP_ORDER
    },
    orderPayData != null || nextLevelData == null ? null : {
      count = nextLevelData.cost
    })

  return { priceTextCtor, cost = nextLevelData?.cost ?? 0, action }
}

let spinner = spinnerCtor(hdpx(24))
let mkBuyLevelBtn = @(soldier, soldierPerksCfg) function() {
  let buyLevelData = buyLevelBtnParams(soldier, soldierPerksCfg,
    perkLevelsGrid.get(), currenciesBalance.get(), armyItemCountByTpl.get(), curCampItems.get())

  let isEnabled = !isExpBuyActionInProgress.get()
  return {
    watch = [isExpBuyActionInProgress, perkLevelsGrid,
      currenciesBalance, armyItemCountByTpl, curCampItems]
    flow = FLOW_HORIZONTAL
    gap = midPadding
    children = [
      buyLevelData == null ? null :
        Regular(buyLevelData.priceTextCtor, buyLevelData.action,
          { btnWidth = COLUMN_WIDTH, isEnabled })
      isEnabled ? null : spinner
    ]
  }
}

function clickBuy(soldier, soldierPerksCfg, hasPoints, buyCb) {
  if (hasPoints) {
    buyCb()
    return
  }

  let { guid, sClass, tier } = soldier
  let maxTier = sClass in maxTrainByClass.get() ? maxTrainByClass.get()[sClass] + 1 : tier

  let buttons = []
  let ordersReq = 1
  let ordersCount = armyItemCountByTpl.get()?[LEVEL_UP_ORDER] ?? 0
  let payData = ordersReq > ordersCount
    ? null
    : getPayItemsData({ [LEVEL_UP_ORDER] = ordersReq }, curCampItems.get())
  if (tier < MAX_LEVEL && guid != null && payData != null)
    buttons.append(mkUseLevelUpOrderBtn(guid, payData))

  if (tier < maxTier) {
    let buyLevelData = buyLevelBtnParams(
      soldier, soldierPerksCfg, perkLevelsGrid.get(), currenciesBalance.get(),
      armyItemCountByTpl.get(), curCampItems.get())
    if (buyLevelData)
      buttons.append(mkBuyLevelGoldBtn(buyLevelData))
  }
  else if (tier < MAX_LEVEL)
    buttons.append({
      text = loc("perks/buyLevel", { price = "" })
      action = @() showTrainResearchMsg(soldier, close)
      customStyle = { hotkeys = [["^J:Y"]] }
    })

  buttons.append({
    text = buttons.len() == 0 ? loc("Close") : loc("Cancel")
    isCurrent = true
    customStyle = { hotkeys = [[ $"^{JB.B}" ]] }
  })

  showMsgbox({
    text = loc(tier < MAX_LEVEL ? "perks/notEnoughPoints" : "perks/notEnoughPointsMaxLevel")
    buttons
  })
}

let isUnlockMaximum = @(perkData, perks)
  max(1, perkData.available) == (perks?[perkData.perkId] ?? 0) + 1

function unlockPerkCb(guid, perkData) {
  if (guid == null)
    return

  let perksCfg = soldierPerks.get()?[guid] ?? {}
  let pointInfo = getPerkPointsInfo(perksList.get(), perksCfg)
  let hasPoints = hasEnoughPoints(pointInfo, perkData)
  let sound = soundAddPerk(isUnlockMaximum(perkData, perksCfg))
  let soldier = curCampSoldiers.get()?[guid]
  clickBuy(soldier, perksCfg, hasPoints, @() addPerk(guid, perkData.perkId, sound))
}

let mkTrainBtn = @(soldier) Regular(loc("perks/buyLevel", { price = "" }),
  @() showTrainResearchMsg(soldier, close), { btnWidth = COLUMN_WIDTH })


let unlockedPoints = @(taken, available, color, font, fillColor, borderColor = null) {
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_BOX
  borderWidth = hdpxi(1)
  borderRadius = hdpx(3)
  borderColor = borderColor ?? color
  fillColor
  padding = [0, midPadding]
  children = available == 0
    ? {
        rendObj = ROBJ_TEXT
        text = fa["check"]
        color
      }.__update(fontawesome)
    : {
        rendObj = ROBJ_TEXT
        text = $"{taken}/{available}"
        color
      }.__update(font)
}

let discardHigherTierMsg = @() showMsgbox({
  text = loc("perks/errorDiscardFirstTier")
  buttons = [{ text = loc("Ok"), isCurrent = true }]
})

let removeSoundCb = @(_) sound_play("ui/perk_remove")

function perkIconClick(guid, canUnlock, perkData, mouseEvent) {
  if (isGamepad.get()) {
    if (canUnlock)
      unlockPerkCb(guid, perkData)
    return
  }
  if (mouseEvent.ctrlKey) {
    selectedPerk.set(perkData)
    let perksCfg = soldierPerks.get()?[guid] ?? {}

    if (!perksCfg?.perks[perkData.perkId])
      return

    if (canDiscardPerk(perksList.get(), perksCfg, perkData))
      removePerk(guid, perkData.perkId, removeSoundCb)
    else
      discardHigherTierMsg()

    return
  }
  selectedPerk.set(perkData)
}

function perkIconBtn(soldierGuid, perkData, takenPoints, diffPoints, isTierAvailable, canUnlock) {
  let isSelected = Computed(@() selectedPerk.get()?.perkId == perkData.perkId)
  let { icon, color } = iconForPerk(perkData)

  return watchElemState(function(sf) {
    let isHover = sf & S_HOVER
    let isActive = isHover || isSelected.get()

    let btnColors = getColors(color, isActive,
      getColorParams(isTierAvailable, takenPoints,
        perkData.available , diffPoints))

    let pointsBorderColor = diffPoints == null && canUnlock && !isHover
      ? lightColor
      : btnColors[NodeElements.POINTS_BORDER]

    return {
      watch = isSelected
      size = [PERK_ICON_SIZE, PERK_ICON_SIZE]
      behavior = Behaviors.Button
      sound = soundActive
      skipDirPadNav = false
      onClick = @(mouseEvent) perkIconClick(soldierGuid, canUnlock, perkData, mouseEvent)
      onDoubleClick = function() {
        if (canUnlock)
          unlockPerkCb(soldierGuid, perkData)
      }
      onHover = function(_) {
        if (isGamepad.get())
          selectedPerk.set(perkData)
      }
      halign = ALIGN_CENTER
      children = {
        size = FLEX
        halign = ALIGN_CENTER
        children = [
          {
            rendObj = ROBJ_BOX
            borderRadius = hdpx(5)
            borderWidth = hdpxi(2)
            borderColor = darkColor
            fillColor = btnColors[NodeElements.OUTER]
            valign = ALIGN_CENTER
            halign = ALIGN_CENTER
            padding = smallPadding
            size = SIZE_TO_CONTENT
            children = {
              rendObj = ROBJ_BOX
              size = SIZE_TO_CONTENT
              borderRadius = hdpx(3)
              borderColor = darkColor
              borderWidth = (sf & S_HOVER) || isSelected.get() ? hdpxi(2) : 0
              halign = ALIGN_CENTER
              valign = ALIGN_TOP
              fillColor = btnColors[NodeElements.INNER]
              padding = [smallPadding, smallPadding, midPadding, smallPadding]
              children = perkPointIcon(icon, btnColors[NodeElements.ICON], hdpxi(isWide ? 62 : 56))
            }
          }
          unlockedPoints(takenPoints, perkData.available,
            btnColors[NodeElements.POINTS_TEXT],
            fontSub,
            btnColors[NodeElements.POINTS_BG],
            pointsBorderColor)
        ]
      }
    }
  })
}

let descriptionComp = @(text) {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  padding = midPadding
  text
}.__update(defTxtStyle)

function mkDescription(perksStatsCfgVal, perkCfg, taken, available) {
  let statConfig = perkCfg.stats.map(@(value) value * taken.tofloat() / max(1, available).tofloat())
  let text = "\n".join(getStatDescList(perksStatsCfgVal, { stats = statConfig }))
  return descriptionComp(text)
}


let tooltipStyle = {
  color = titleTxtColor
  margin = [midPadding, largePadding]
  halign = ALIGN_LEFT
}

let nextLevelHint = {
  rendObj = ROBJ_BOX
  size = FLEX_H
  fillColor = tooltipHeaderColor
  padding = [midPadding, largePadding]
  children = txt(utf8ToUpper(loc("perks/nextLevelEffect")))
    .__update(priceTxtStyle)
  borderWidth = const [hdpxi(1), hdpxi(1), 0, hdpxi(1)]
  borderColor = treeBgColor
}

let shortcutHintConsole = {
  flow = FLOW_HORIZONTAL
  gap = midPadding
  valign = ALIGN_CENTER
  children = [
    mkImageCompByDargKey(JB.A, { hplace = ALIGN_LEFT })
    txt(loc("perks/unlock")).__update(defTxtStyle)
  ]
}

let shortcutHint = {
  rendObj = ROBJ_TEXT
  text = loc("perks/doubleClick")
}.__update(defTxtStyle)

let discardShortcutHint = {
  rendObj = ROBJ_TEXT
  text = loc("perks/CtrlClick")
}.__update(defTxtStyle)

let mkPerkTooltip = @(perksStatsCfgVal, perkCfg, takenPoints,
    pointsPossible, isListView = false) function() {
  let showPoints = isListView ? takenPoints : 1 + takenPoints
  let hint = mkDescription(perksStatsCfgVal, perkCfg,
      min(showPoints, pointsPossible), pointsPossible).__update(tooltipStyle)
  return {
    rendObj = ROBJ_BOX
    flow = FLOW_VERTICAL
    minWidth = (unitSize * 7).tointeger()
    fillColor = tooltipBodyColor
    borderWidth = hdpxi(1)
    borderColor = treeBgColor
    children = isListView
      ? hint
      : [
          takenPoints < pointsPossible ? nextLevelHint : null
          hint
          @() {
            watch = isGamepad
            flow = FLOW_VERTICAL
            padding = [midPadding, largePadding]
            children = [
              takenPoints >= pointsPossible ? null
                : isGamepad.get() ? shortcutHintConsole
                : shortcutHint,
              (takenPoints > 0 && !isGamepad.get()) ? discardShortcutHint : null,
            ]
          }
        ]
  }
}

const PERKS_PER_ROW = 3

function mkTier(perksStatsCfgVal, perksListVal, presetDiffVal,
    perkListByStat, soldierPerkStruct, isTierAvailable, pointsInfo) {
  let bigRow = perkListByStat.findindex(@(perks) perks.len() > PERKS_PER_ROW) != null
  let rows = bigRow ? 2 : 1
  let vGap = unitSize * 0.4
  let hGap = unitSize * 0.5

  let { guid = "", perks = {} } = soldierPerkStruct
  let children = pPointsList.map(@(statId) {
    size = [FLEX, (PERK_ICON_SIZE * rows + vGap * (rows - 1)).tointeger() ]
    valign = ALIGN_TOP
    halign   = ALIGN_CENTER
    children = wrap(
      perkListByStat[statId].map(function(perkData) {
        let { perkId, available } = perkData
        let pointsTaken = perks?[perkId] ?? 0
        let canUnlock = isTierAvailable && pointsTaken < available
          && hasEnoughPoints(pointsInfo, perkData)
        let diffPoints = presetDiffVal?[perkData.perkId]

        return withTooltip(
          perkIconBtn(guid, perkData, pointsTaken, diffPoints, isTierAvailable, canUnlock),
          mkPerkTooltip(perksStatsCfgVal, perksListVal?[perkId],
            pointsTaken,
            max(available, 1)))
      }),
      {
        width  = COLUMN_WIDTH
        halign = ALIGN_CENTER
        hGap
        vGap
      })
  })

  return {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = COLUMN_GAP
    children
  }
}

const headerIconSize = hdpxi(45)
let pointsAnimationState = { guid = null, points = {} }
let addPointsAnimation = {
  opacity = 0
  transform = true
  animations = [
    { prop = AnimProp.opacity, from = 0.2, to = 1, duration = 0.3,
      play = true, easing = InOutCubic }
    { prop = AnimProp.opacity, from = 1, to = 1, duration = 0.4,
      play = true, easing = InOutCubic, delay = 0.3}
    { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.35,
      play = true, easing = InOutCubic, delay = 0.7 }
    { prop = AnimProp.translate, from = [hdpx(20), hdpx(50)], to = [hdpx(20), hdpx(20)],
      play = true, easing = OutCubic, duration = 1 }
  ]
}

let oldPointsAnimations = [
  { prop = AnimProp.opacity, from = 0.2, to = 1, duration = 0.2
    play = true, easing = InOutCubic }
  { prop = AnimProp.scale, from = [3.5,3.5], to = [1,1],
    play = true, easing = InOutCubic, duration = 1 }
]

let improvementRates = {
  weapon = 0.5
  vitality = 1
  speed = 0.5
}

let headerTooltip = @(statName, points, totalPoints) {
  rendObj = ROBJ_BOX
  fillColor = tooltipBodyColor
  borderWidth = hdpxi(1)
  borderColor = treeBgColor
  padding = largePadding
  gap = midPadding
  flow = FLOW_VERTICAL
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = titleTxtColor
      text = loc($"perks/{statName}_hint", {
        rate = colorize(attentionTxtColor, "{0}%".subst(
          improvementRates[statName] * max(0, totalPoints)))
      })
    }.__update(fontSub)
    {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      color = titleTxtColor
      text = loc("perks/tree/pointsTooltip", {
        points = colorize(attentionTxtColor, max(0, points))
        totalPoints = colorize(attentionTxtColor, totalPoints)
      })
    }.__update(fontSub)
  ]
}

let lineCmp = {
  rendObj = ROBJ_SOLID
  size = const [FLEX, hdpxi(1)]
  color = lineColor
}

function treeHeader(perksListVal, perksCfg) {
  let { total, used } = getPerkPointsInfo(perksListVal, perksCfg)

  if (pointsAnimationState.guid != perksCfg.guid) {
    pointsAnimationState.guid = perksCfg.guid
    pointsAnimationState.points = clone total
  }

  let headers = pPointsList.map(function(statName) {
    let usedPoints = used?[statName] ?? 0
    
    
    let totalPoints = total[statName]
    let points = totalPoints - usedPoints
    let justChanged = totalPoints - (pointsAnimationState.points?[statName] ?? totalPoints)
    let { icon, color } = pPointsBaseParams[statName]
    let pointsAnimation = {
      transform = true
      animations = justChanged > 0 ? oldPointsAnimations : null
    }

    return withTooltip({
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      size = FLEX_H
      gap = smallPadding
      skipDirPadNav = false
      children = [
        {
          rendObj = ROBJ_IMAGE
          size = const [headerIconSize, headerIconSize]
          image = Picture("{0}:{1}:{1}".subst(icon, headerIconSize))
          color
        }
        {
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = [
            txt(utf8ToUpper(loc($"perks/{statName}_title"))).__update(titleTxtStyle)
            txt(totalPoints).__update(titleTxtStyle, { color })
          ]
        }
        txt(loc("perks/tree/unallocated")).__update(priceTxtStyle)
        {
          flow = FLOW_HORIZONTAL
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          size = FLEX_H
          padding = [smallPadding, (unitSize * 1.2).tointeger()]
          gap = midPadding
          children = [
            lineCmp
            {
              key = $"{statName}_{points}"
              children = [
                {
                  rendObj = ROBJ_BOX
                  padding = [smallPadding, largePadding]
                  borderWidth = hdpxi(1)
                  borderRadius = hdpxi(3)
                  borderColor = attentionTxtColor
                  children = {
                    rendObj = ROBJ_TEXT
                    text = points
                    skipDirPadNav = false
                  }.__update(priceTxtStyle, fontBody, pointsAnimation)
                }
                justChanged == 0 ? null : {
                  rendObj = ROBJ_TEXT
                  text = $"+{justChanged}"
                  halign = ALIGN_RIGHT
                }.__update(priceTxtStyle, fontBody, addPointsAnimation)
              ]
            }
            lineCmp
          ]
        }
      ]
    },
    @() headerTooltip(statName, points, totalPoints))
  })

  pointsAnimationState.points = clone total
  return {
    flow = FLOW_HORIZONTAL
    size = FLEX_H
    gap = COLUMN_GAP
    children = headers
  }
}

let gradientLeft = mkColoredGradientX({
  colorLeft=0x00000000, colorRight=separatorBgColor, width=28
})
let gradientRight = mkColoredGradientX({
  colorLeft=separatorBgColor, colorRight=0x00000000, width=28
})
let twoSideGradient = mkTwoSidesGradientX({
  centerColor = 0x77FFFFFF, sideColor = 0x05FFFFFF, isAlphaPremultiplied = false
})

let gradientCmp = @(image, size) {
  rendObj = ROBJ_IMAGE
  size
  image
}

function separatorComp(tierInfo) {
  let res = {
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    size = [FLEX, midPadding * 2 + fontSub.fontSize]
    flow = FLOW_HORIZONTAL
    gap = midPadding
  }

  if (tierInfo.available)
    return res.__update({
      children = gradientCmp(twoSideGradient, [FLEX, smallPadding])
    })

  return res.__update({
    children = [
      gradientCmp(gradientLeft, FLEX)
      {
        rendObj = ROBJ_BOX
        borderRadius = hdpx(3)
        borderColor = lineColor
        borderWidth = hdpxi(1)
        fillColor = separatorBgColor
        padding = [smallPadding, midPadding]
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          faComp("lock", {
            size = hdpxi(18)
            fontSize = defTxtStyle.fontSize
            color = titleTxtColor
            halign = ALIGN_CENTER
          })
          tierInfo?.header
        ]
      }
      gradientCmp(gradientRight, FLEX)
    ]
  })
}

let columnBackground = {
  flow = FLOW_HORIZONTAL
  gap  = COLUMN_GAP
  size = FLEX
  children = array(3).map(@(_) {
    rendObj = ROBJ_BOX
    fillColor = treeBgColor
    size = FLEX
  })
}

function mkTree(perkTree, soldierInfo, presetPerks, presetDiff) {
  if (perkTree == null)
    return null

  return function() {
    let perksStruct = soldierPerks.get()?[soldierInfo?.guid] ?? {}
    let preset = presetPerks.get()
    let perksCfg = preset.len() == 0 ? perksStruct : perksStruct.__merge({ perks = preset })

    let pointsInfo = getPerkPointsInfo(perksList.get(), perksCfg)

    let tierInfo = soldierInfo == null
      ? tiersAvailable(0, {}, true)
      : tiersAvailable(soldierInfo?.level ?? 1, pointsInfo.used)

    let tiers = []
    foreach (tierConfig in perkTree) {
      tiers.append(mkTier(perksStatsCfg.get(), perksList.get(), presetDiff.get(),
        tierConfig.perks,
        perksCfg,
        tierInfo[tierConfig.tier].available,
        pointsInfo))
      if (tierConfig.tier < perkTree.len())
        tiers.append(separatorComp(tierInfo[tierConfig.tier + 1]))
    }

    let children = [treeHeader(perksList.get(), perksCfg)].extend(tiers)
    return {
      watch = [soldierPerks, perksList, perksStatsCfg, presetPerks, presetDiff]
      size = FLEX_H
      children = [
        columnBackground
        {
          flow = FLOW_VERTICAL
          size = FLEX_H
          gap = VERTICAL_GAP
          padding = [isWide ? BIGGER_GAP : midPadding, 0]
          children
        }
      ]
    }
  }
}

let lockedPerkCmp = @(text) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  text = utf8ToUpper(text)
  padding = MEDIUM_GAP
  margin = [MEDIUM_GAP, 0]
  color = attentionTxtColor
}.__update(fontBody)


const PRICE_ICON_SIZE = hdpxi(25)
let blockedPointsColor = { color = blockedTxtColor }

function priceCmp(selectedPerkVal, hasPoints, canGet = true) {
  let price = priceForPerk(selectedPerkVal)
  if (price == 0)
    return lockedPerkCmp(loc("perks/starter")).__update({
      halign = ALIGN_CENTER
    })

  let text = canGet ? loc("perks/obtain") : loc("perks/cost")
  let { icon, color } = statIconForPerk(selectedPerkVal)
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_BOTTOM
    padding = midPadding
    children = [
      txt(text).__update(defTxtStyle)
      { size = [midPadding, hdpx(1)] }
      txt(price).__update(priceTxtStyle, fontBody, hasPoints ? {} : blockedPointsColor)
      {
        rendObj = ROBJ_IMAGE
        size = [PRICE_ICON_SIZE, PRICE_ICON_SIZE]
        image = Picture("{0}:{1}:{1}".subst(icon, PRICE_ICON_SIZE))
        color
      }
    ]
  }
}

let availablePerk = @(soldier, perksCfg, hasPoints, buyCb) Accented(
  utf8ToUpper(loc("perks/unlock")),
  @() clickBuy(soldier, perksCfg, hasPoints, buyCb),
  {
    size = FLEX_H
    hotkeys = [[ "^J:X | Enter", { description = { skip = true }} ]]
  })

function unlockedPerk(perkListVal, perksCfg, selectedPerkVal) {

  let action = canDiscardPerk(perkListVal, perksCfg, selectedPerkVal)
    ? @() removePerk(perksCfg.guid, selectedPerkVal.perkId, removeSoundCb)
    : discardHigherTierMsg

  return Regular(loc("perks/discard"), action, {
    size = FLEX_H
    hotkeys = [[ "^J:Y", { description = { skip = true }} ]]
  })
}

let iconSize = [
  (unitSize * 0.8).tointeger(),
  (unitSize * 0.3).tointeger()
]

let nextLevelIcon = {
  rendObj = ROBJ_IMAGE
  size = iconSize
  image = Picture("ui/skin#arrow_next_lvl.svg:{0}:{1}".subst(iconSize[0], iconSize[1]))
  color = attentionTxtColor
}

let lineNextLevel = lineCmp.__merge({ margin = [COLUMN_GAP, MEDIUM_GAP] })

let nextLevelCmp = {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    lineNextLevel
    {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = midPadding
      children = [
        nextLevelIcon
        txt(utf8ToUpper(loc("perks/nextLevelEffect"))).__update(defTxtStyle)
        nextLevelIcon
      ]
    }
    lineNextLevel
  ]
}

function perkEffectDetails(perksListVal, perksStatsCfgVal, perksCfg, perkData) {
  
  
  
  
  
  let { perkId, available } = perkData
  let perkCfg = perksListVal?[perkId]
  if (perkCfg == null)
    return null

  let pointsPossible = max(available, 1)
  let taken = perksCfg?.perks[perkId] ?? 0
  let children = []

  if (taken > 0) {
    children.append(mkDescription(perksStatsCfgVal, perkCfg, taken, pointsPossible))
  }
  if (taken != pointsPossible) {
    children.append(nextLevelCmp)
    children.append(mkDescription(perksStatsCfgVal, perkCfg, taken + 1, pointsPossible))
  }

  return {
    flow = FLOW_VERTICAL
    size = FLEX_H
    halign = ALIGN_CENTER
    gap = BIGGER_GAP
    children
  }
}

let mkSelectedPerk = @(soldierInfo) function() {
  if (selectedPerk.get() == null || soldierInfo == null)
    return { watch = selectedPerk }

  let { icon, color } = iconForPerk(selectedPerk.get())
  let { guid = "", level = 1 } = soldierInfo
  let perksCfg = soldierPerks.get()?[guid] ?? {}
  if (perksCfg.len() == 0) {
    logPerks($"Perk structure empty for {guid}")
    return { watch = [selectedPerk, soldierPerks] }
  }

  let { perkId, available, tier } = selectedPerk.get()
  let taken = perksCfg?.perks[perkId] ?? 0

  let pointInfo = getPerkPointsInfo(perksList.get(), perksCfg)
  let tierInfo = tiersAvailable(level, pointInfo.used)

  let state = stateForPerk(!tierInfo[tier].available, available, taken)
  let hasPoints = hasEnoughPoints(pointInfo, selectedPerk.get())

  let isStarter = priceForPerk(selectedPerk.get()) == 0
  let isLocked = state == PerkState.LOCKED || isStarter
  let canBuy = !isStarter && (state == PerkState.AVAILABLE || state == PerkState.UNLOCKED_PART)
  let canRemove = !isStarter && state != PerkState.LOCKED && state != PerkState.AVAILABLE

  let sound = soundAddPerk(isUnlockMaximum(selectedPerk.get(), perksCfg.perks))
  return {
    watch = [selectedPerk, perksList, perksStatsCfg, soldierPerks]
    flow = FLOW_VERTICAL
    size = [COLUMN_WIDTH, isWide ? FLEX : SIZE_TO_CONTENT]
    children = [
      {
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = BIGGER_GAP
        halign = ALIGN_CENTER
        padding = isWide ? [unitSize * 0.5, 0] : null
        children = [
          {
            size = [(unitSize * 2.2).tointeger(), (unitSize * 2.5).tointeger()]
            halign = ALIGN_CENTER
            children = [
              {
                rendObj = ROBJ_BOX
                valign = ALIGN_TOP
                borderColor = color
                borderWidth = hdpxi(3)
                borderRadius = hdpx(4)
                fillColor = darkColor
                padding = midPadding
                children = perkPointIcon(icon, color, (unitSize * 1.8).tointeger())
              }
              unlockedPoints(taken, available, color, fontBody, darkColor)
            ]
          }
          perkEffectDetails(perksList.get(), perksStatsCfg.get(), perksCfg, selectedPerk.get())
          canRemove ? {
            size = FLEX_H
            children = unlockedPerk(perksList.get(), perksCfg, selectedPerk.get())
          } : null
        ]
      }
      isWide ? { size = FLEX_V } : null
      {
        flow = FLOW_VERTICAL
        size = FLEX_H
        gap = midPadding
        halign = ALIGN_CENTER
        children = [
          priceCmp(selectedPerk.get(), hasPoints, canBuy)
          isLocked ? lockedPerkCmp(tierInfo[tier]?.hint ?? "") : null
          canBuy ? availablePerk(soldierInfo, perksCfg,
            hasPoints, @() addPerk(guid, perkId, sound)) : null
        ]
      }
    ]
  }
}

let defaultPerkCfg = { available = 0, tier = 1 }

function getStartPerk(soldier, soldierPerksVal, perkSchemesVal, perksListVal) {
  let { perkSchemeId = "" } = soldierPerksVal?[soldier.guid] ?? {}
  let perkScheme = perkSchemesVal?[perkSchemeId]
  if (perkScheme == null)
    return null

  let defaultPerk = perkScheme.findvalue(@(s) s?.isDefault || (s?.numChosen == 1)) 
  if (defaultPerk == null || defaultPerk.perks.len() < 1)
    return null

  let perk = perksListVal?[defaultPerk.perks.top()]
  if (perk == null)
    return null

  return perk.__merge(defaultPerkCfg)
}

function resetPerksBtn(soldier) {
  let buttons = [
    {
      text = loc("perks/resetBtn")
      action = @() resetPerks(soldier.guid, true)
      customStyle = {
        
        textMargin = [hdpx(10), hdpx(20)]
        hotkeys = [["^J:Y | Enter"]]
      }
    }
  ]

  let { isPremium = false } = getClassCfg(soldier.sClass)
  if (isPremium)
    buttons.append({
      text = loc("perks/restorePremBtn")
      action = @() resetPerks(soldier.guid, false)
      customStyle = {
        hotkeys = [["^J:X"]]
      }
    })

  buttons.append({
    text = loc("Cancel")
    isCancel = true
    customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
  })

  let action = @() showMessageWithContent({
    uid = "resetPerksMsgBox"
    content = {
      size = const [sw(90), fsh(32)]
      flow = FLOW_VERTICAL
      children = [
        {
          hplace = ALIGN_RIGHT
          children = currencySilverUi
        }
        {
          size = FLEX
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = isPremium ? loc("perks/resetPremOptions") : loc("perks/resetConfirm")
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
        }.__update(fontBody)
      ]
    }
    buttons
  })

  return Regular(loc("perks/resetBtn"), action, { btnWidth = COLUMN_WIDTH })
}

let hasFreeRerolls = @(perksCfg) (perksCfg?.rerolls ?? 0) > 0

function mkFreeRerollBtn(guid) {
  let buttons = [
    {
      text = loc("perks/resetBtn")
      action = @() freeRerollPerks(guid, true)
      customStyle = { hotkeys = [["^J:Y | Enter"]] }
    }
    {
      text = loc("perks/restorePremBtn")
      action = @() freeRerollPerks(guid, false)
      customStyle = { hotkeys = [["^J:X"]] }
    }
    {
      text = loc("Cancel")
      isCancel = true
      customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
    }
  ]

  let action = @() showMsgbox({
    text = loc("perks/resetPremOptions")
    buttons
  })
  return Regular(loc("perks/resetBtn"), action, { size = BTN_SIZE })
}

function freeRerollBtn(soldier, perksCfg, params = {}) {
  let rerolls = perksCfg?.rerolls ?? 0
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = MEDIUM_GAP
    children = [
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("perks/rerollHint", { count = rerolls })
      }.__update(defTxtStyle)
      mkFreeRerollBtn(soldier.guid)
    ]
  }.__update(params)
}

function presetBtnText(_textField, params, handler, group, sf) {
  let color = textButtonColorStyle(sf)
  return textButtonTextCtor({
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = bigPadding
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("perks/preset/open")
        color
      }.__update(fontBody)
      @() {
        watch = presetWidgetOpened
        rendObj = ROBJ_INSCRIPTION
        text = presetWidgetOpened.get() ? fa["caret-down"] : fa["caret-right"]
        color
      }.__update(fontawesome)
    ]}, params, handler, group, sf)
}

let perkPresetWidget = @(soldierInfoWatch) {
  flow = FLOW_VERTICAL
  gap = null
  size = [COLUMN_WIDTH, FLEX]
  children = [
    Regular(presetBtnText, togglePerkPresetBlock, {
      size = BTN_SIZE
      rendObj = ROBJ_WORLD_BLUR_PANEL
    })
    mkPerkPresetBlock(soldierInfoWatch)
  ]
}

function mkSoldierInfo(soldierInfoWatch, soldierPerksCfg) {
  let curVehicleInfo = Computed(@() curCampItems.get()?[curVehicle.get()])
  return function() {
    let watch = [soldierPerksCfg, soldierInfoWatch, maxTrainByClass, perkLevelsGrid, curVehicleInfo]

    let soldierInfo = soldierInfoWatch.get()
    if (soldierInfo == null)
      return { watch }

    function soldierSeatBlock() {
      let seatsOrder = mkVehicleSeats(curVehicleInfo.get())
      let curSoldierIdx = curSquadSoldiersInfo.get().findindex(@(v)
        v.guid == soldierInfo?.guid)
      let seat = seatsOrder?[curSoldierIdx]
      let result = { watch = curSquadSoldiersInfo }
      return seat == null ? result
        : result.__update({
            rendObj = ROBJ_TEXT
            text = loc(seat.locName)
            hplace = ALIGN_LEFT
            pos = [0, -MEDIUM_GAP]
          }, defTxtStyle)
    }

    let soldierCard = {
      flow = FLOW_VERTICAL
      children = [
        soldierSeatBlock
        mkSoldierCard({
          soldierInfo
          size = soldierCardSize
          expToLevel = perkLevelsGrid.get()?.expToLevel ?? []
        })
      ]
    }

    let { sClass, tier } = soldierInfo
    let maxTier = sClass in maxTrainByClass.get() ? maxTrainByClass.get()[sClass] + 1 : tier

    let levelupBtn = tier < maxTier ? mkBuyLevelBtn(soldierInfo, soldierPerksCfg.get())
      : tier < MAX_LEVEL ? mkTrainBtn(soldierInfo)
      : null

    let rerollsCmp = {
      size = BTN_SIZE
      flow = FLOW_VERTICAL
      gap = bigPadding
      halign = ALIGN_CENTER
      children = [
        hasFreeRerolls(soldierPerksCfg.get())
          ? freeRerollBtn(soldierInfo, soldierPerksCfg.get())
          : resetPerksBtn(soldierInfo)
      ]
    }

    return isWide
      ? {
          watch
          size = [COLUMN_WIDTH, FLEX]
          halign = ALIGN_CENTER
          children = [
            {
              size = [COLUMN_WIDTH, FLEX]
              flow = FLOW_VERTICAL
              gap = MEDIUM_GAP
              children = [
                soldierCard
                levelupBtn
                perkPresetWidget(soldierInfoWatch)
              ]
            }
            {
              vplace = ALIGN_BOTTOM
              children = rerollsCmp
            }
          ]
        }
      : {
          watch
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          gap = MEDIUM_GAP
          valign = ALIGN_BOTTOM
          children = [
            soldierCard
            levelupBtn
            rerollsCmp
          ]
        }
  }
}

function getTreeData(perkTreeCfg, perkTreesSpecialCfg, soldier,
  soldierPerksVal, perkSchemesVal, perksListVal) {
  let tree = treeForSoldier(perkTreeCfg, perkTreesSpecialCfg, soldier)
  if (soldier == null || tree == null)
    return null
  let startPerk = getStartPerk(soldier, soldierPerksVal, perkSchemesVal, perksListVal)
  if (startPerk == null)
    return tree

  let stat = statForPerk(startPerk)
  let newTree = clone tree
  newTree[0] = clone tree[0]
  newTree[0].perks <- clone tree[0].perks
  newTree[0].perks[stat] <- [startPerk].extend(clone tree[0].perks[stat])
  return newTree
}

let backBtn = Regular(loc("BACK"), close, {
  margin = unitSize * 0.3
  hotkeys = [[ $"^{JB.B} | Esc", { description = loc("BackBtn") } ]]
})

let currency = {
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = midPadding
  children = [
    mkCurrencyUi(LEVEL_UP_ORDER)
    currenciesWidgetUi
    currencySilverUi
  ]
}

let title = {
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("perks/tree")
      padding = midPadding
    }.__update(titleTxtStyle)
    mkPageButton(Tutorial.PERKS)
  ]
}

function treeCmp(soldierInfoWatch) {
  let presetPerks = Computed(function() {
    let soldier = soldierInfoWatch.get()
    let { guid = null } = soldier
    if (guid == null)
      return {}

    let perksCfg = soldierPerks.get()?[guid] ?? {}
    let schemes = perkSchemes.get()
    let configs = serverConfigs.get()
    let list = perksList.get()
    let preset = previewPerkPreset.get()
    return preset?.fnApply(preset, soldier, perksCfg, schemes, configs, list) ?? {}
  })

  let presetDiff = Computed(function() {
    let preset = presetPerks.get()
    if (preset.len() == 0)
      return {}

    let soldier = soldierInfoWatch.get()
    let { guid = null } = soldier
    if (guid == null)
      return {}

    let perksCfg = soldierPerks.get()?[guid] ?? {}
    let list = perksList.get()

    return getPerksAvailableToBuy(soldier, true, preset, perksCfg, list)
  })

  let perkTree = Computed(function() {
    let perkTreeCfg = perkTreeTbl(perkTrees.get())
    if (perkTreeCfg.len() == 0)
      return null

    let soldier = soldierInfoWatch.get()
    if (soldier == null)
      return null

    return getTreeData(perkTreeCfg, perkTreesSpecial.get(), soldier,
      soldierPerks.get(), perkSchemes.get(), perksList.get())
  })

  let starterPerk = Computed(function() {
    let { guid = null } = soldierInfoWatch.get()
    if (guid == null)
      return null

    let { perksCfg = {} } = soldierPerks.get()?[guid] ?? {}
    let tree = perkTree.get() ?? []
    foreach (tierCfg in tree) {
      foreach (statId in pPointsList) {
        let list = tierCfg.perks?[statId] ?? []
        let firstPerk = list.findvalue(@(v) v.perkId not in perksCfg?.perks)
        if (firstPerk != null)
          return firstPerk
      }
    }
    return null
  })

  let soldierPerksCfg = Computed(@() soldierPerks.get()?[soldierInfoWatch.get()?.guid])

  return function() {
    if (perkTree.get() == null) {
      logPerks("Perk tree config is empty")
      return { watch = perkTree }
    }

    if (selectedPerk.get() == null)
      defer(@() selectedPerk.set(starterPerk.get()))

    let soldierInfo = soldierInfoWatch.get()
    let watch = [soldierInfoWatch, soldierPerks, perkTree]
    let tree = mkTree(perkTree.get(), soldierInfo, presetPerks, presetDiff)
    return isWide
      ? {
          watch
          size = FLEX
          flow = FLOW_VERTICAL
          gap = COLUMN_GAP
          children = [
            {
              size = FLEX_H
              children = [
                backBtn
                title
                currency
              ]
            }
            {
              size = FLEX_H
              flow = FLOW_HORIZONTAL
              gap = COLUMN_GAP
              children = [
                mkSoldierInfo(soldierInfoWatch, soldierPerksCfg)
                tree
                mkSelectedPerk(soldierInfo)
              ]
            }
          ]
        }
      : {
          size = FLEX
          flow = FLOW_VERTICAL
          watch
          margin = [0, sidePadding]
          gap = COLUMN_GAP
          children = [
            {
              size = FLEX_H
              children = [
                mkSoldierInfo(soldierInfoWatch, soldierPerksCfg)
                currency
              ]
            }
            title
            {
              flow = FLOW_HORIZONTAL
              size = FLEX
              gap = COLUMN_GAP
              children = [
                {
                  flow = FLOW_VERTICAL
                  size = FLEX
                  gap = MEDIUM_GAP
                  children = [
                    tree
                    backBtn
                  ]
                }
                {
                  flow = FLOW_VERTICAL
                  size = FLEX_V
                  gap = MEDIUM_GAP
                  children = [
                    mkSelectedPerk(soldierInfo)
                    perkPresetWidget(soldierInfoWatch)
                  ]
                }
              ]
            }
          ]
        }
  }
}

function openPerkTree(guid) {
  let soldier = Computed(@() isInBattleState.get() ? null
    : curCampSoldiers.get()?[guid])
  if (!soldier.get())
    return null
  let soldierInfoWatch = Computed(function() {
    let outfitSchemesVal = outfitSchemes.get()
    let squadsVal = squads.get()
    let armySquadsByIdVal = armySquadsById.get()
    let squadsCfgByIdVal = squadsCfgById.get()
    let soldierVal = soldier.get()
    let lookCfg = gameProfileLookCfg.get()
    return collectSoldierDataImpl(
      soldierVal, perksData.get(), curCampSquads.get(), armies.get(),
      sClassesCfg.get(), campItemsByLink.get(), soldiersLook.get(),
      equippedOutfitsForArmy.get().filter(
        @(outfit) isOutfitAllowedByCampaignImpl(outfit, soldierVal, outfitSchemesVal,
          squadsVal, armySquadsByIdVal, squadsCfgByIdVal, lookCfg)),
      soldierSchemes.get(), maxTrainByClass.get())
    })
  selectedPerk.set(null)

  function removeWindow(v) {
    if (v)
      close()
  }

  addModalWindow({
    key = WND_UID
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = darkPanelBgColor
    valign = ALIGN_TOP
    stopMouse = true
    stopHover = true
    onClick = @() null
    children = {
      flow = FLOW_VERTICAL
      padding = MEDIUM_GAP
      eventPassThrough = false
      size = FLEX
      valign = ALIGN_TOP
      children = treeCmp(soldierInfoWatch)
    }
    hotkeys = [[$"^{JB.B} | Esc", { action = close }]]
    onAttach = @() isInBattleState.subscribe(removeWindow)
    onDetach = @() isInBattleState.unsubscribe(removeWindow)
  })
}

let perkListPopup = @(soldierWatch) function() {
  let perksCfg = soldierPerks.get()?[soldierWatch.get()?.guid] ?? { perks = {} }
  let perksByStat = {}
  foreach(perkId, takenPoints in perksCfg.perks) {
    let perkData = perksList.get()?[perkId]
    let { icon, color } = iconForPerk(perkData)
    let stat = statForPerk(perkData)
    if (stat not in perksByStat)
      perksByStat[stat] <- []
    let pointsPossible = perkData?.available ?? 1
    let tooltip = mkPerkTooltip(perksStatsCfg.get(), perkData, takenPoints, pointsPossible, true)
    perksByStat[stat].append(withTooltip({
      rendObj = ROBJ_BOX
      valign = ALIGN_TOP
      borderColor = color
      borderWidth = hdpxi(2)
      borderRadius = hdpx(3)
      fillColor = darkColor
      padding = midPadding
      children = perkPointIcon(icon, color, (unitSize * 0.8).tointeger())
    }, tooltip))
  }

  let content = []

  foreach(statName, perkComponents in perksByStat) {
    let { color } = pPointsBaseParams[statName]
    content.append({
      rendObj = ROBJ_TEXT
      text = loc($"perks/{statName}_title")
      color
      padding = [midPadding, 0]
    }.__update(titleTxtStyle))
    content.append({
      flow = FLOW_HORIZONTAL
      gap = midPadding
      children = perkComponents
    })
  }

  return {
    watch = [soldierWatch, soldierPerks, perksStatsCfg, perksList]
    rendObj = ROBJ_BOX
    flow = FLOW_VERTICAL
    fillColor = panelBgColor
    gap = midPadding
    padding = MEDIUM_GAP
    children = content
  }
}

function openPerkList(event, soldierWatch) {
  let pos = [event.targetRect.r + COLUMN_GAP, event.targetRect.t]
  modalPopupWnd.add(pos, {
    uid = POPUP_UID
    popupHalign = ALIGN_LEFT
    popupValign = ALIGN_BOTTOM
    popupFlow = FLOW_VERTICAL
    rendObj = ROBJ_BOX
    fillColor = darkPanelBgColor
    padding = smallPadding
    valign = ALIGN_TOP
    stopMouse = true
    stopHover = true
    children = perkListPopup(soldierWatch)
    hotkeys = [[$"^{JB.B} | Esc", { action = @() modalPopupWnd.remove(POPUP_UID) }]]
  })
}

return {
  openPerkTree
  openPerkList
}
