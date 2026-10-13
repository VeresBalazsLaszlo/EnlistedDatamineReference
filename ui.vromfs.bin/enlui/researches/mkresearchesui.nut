import "%ui/components/colorize.nut" as colorize
import "%ui/components/mkSquadsList.nut" as mkCurSquadsList
import "%ui/components/faComp.nut" as faComp
import "%ui/components/spinner.nut" as spinner
import "%ui/researches/buyLevelsMsgbox.nut" as buyLevelsMsg
from "%ui/style/cursors.nut" import setTooltip
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/components/textButton.nut" import Regular, Purchase, Primary
from "%ui/components/soldierClasses.nut" import mkGlyphsStyle, getClassCfg, soldierClasses
from "%ui/components/scrollbar.nut" import makeHorizScroll
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/components/unseenSignal.nut" import noBlinkUnseenIcon
from "%ui/components/squadsUiComps.nut" import mkCardText
from "%ui/components/mkSpecialItemIcon.nut" import SIGN_NONE, SIGN_PREMIUM
from "%ui/components/itemsInfo.nut" import iconByGameTemplate, itemNameFromGametemplate, trimUpgradeSuffix
from "%ui/soldiers/model/state.nut" import curArmy, armySquadsById, curUnlockedSquads,
  soldiersBySquad, squadsByArmy
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierIdx
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/components/defComponents.nut" import gradientProgressBar
from "%ui/helpers/gradients.nut" import mkColoredGradientX
from "%ui/components/mkPromoWidget.nut" import promoWidget
from "%ui/researches/researchesFocus.nut" import researchToShow
from "%ui/currency/currenciesComp.nut" import mkCurrency
from "%ui/currency/currencies.nut" import currenciesById
from "%ui/soldiers/components/squadsFilter.nut" import squadsFilterUi, getFilterSquads, resetFilter, getCountSquadTypes
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/components/battleRatingPkg.nut" import mkBattleRatingShort
from "%ui/components/itemPkg.nut" import mkItemHintFromTemplate
from "%ui/vehicles/vehiclesListState.nut" import selectVehParams
from "%ui/soldiers/model/squadsFavoriteState.nut" import favoriteSquads
from "%ui/soldiers/model/selectItemState.nut" import openSelectItem, slotItems, curInventoryItem
from "%ui/researches/researchesState.nut" import mkViewStructure, tableStructure, selectedTable, squadProgress, allSquadsPoints, viewSquadId, armiesResearches
  , getAvailableResearches, viewArmy, researchStatuses, selectedResearch, curSquadProgress, squadsResearchAvailable, isBuyLevelInProgress
  , isResearchInProgress, closestTargets, buySquadLevel, RESEARCHED, CAN_RESEARCH
from "%ui/style/designConst.nut" import miniPadding, smallPadding, midPadding, bigPadding, largePadding, contentOffset, commonBtnHeight
  , panelBgColor, darkPanelBgColor, hoverPanelBgColor, accentColor, brightAccentColor, hoverSlotBgColor, selectedPanelBgColor
  , squadSlotBgIdleColor, unseenColor, defTxtColor, titleTxtColor, darkTxtColor, weakTxtColor, negativeTxtColor
  , attentionTxtColor, completedTxtColor, leftAppearanceAnim
from "%ui/ui_library.nut" import *

let hoverImage = require("%ui/components/hoverImage.nut")
let researchStatusesCfg = require("%ui/researches/researchStatuses.nut")



let filterResearchesSquad = Watched({})

let use = @(...) vargv

const FOUR_TO_NEXT_BRANCH = 4
const THREE_TO_NEXT_BRANCH = 3
const TWO_TO_NEXT_BRANCH = 2

const levelAndExpColor = 0xFFFFB200
const commonIconColor = 0xFFFFFFFF
let indicator = noBlinkUnseenIcon(0.6, unseenColor, "chevron-circle-up")
let pagesIcons = [ "upgrades_icon_squad", "upgrades_icon_personnel", "upgredes_icon_work_shop" ]
let waitingSpinner = spinner(hdpx(35))

const btnSound = {
  hover = "ui/enlist/button_highlight"
  click = "ui/enlist/button_click"
  active = "ui/enlist/button_action"
}

let iconSize = hdpxi(12)
const squadLineWidth = fsh(13)
const researchInfoWidth = fsh(32.5)
const lineDashSize = hdpx(3)
let priceIconSize = hdpxi(30)
const minWidthExp = hdpx(32)

const headerHeight = fsh(15.5)
let pageSize        = [hdpx(156), hdpx(74)]
let pageIconSize    = [hdpxi(50), hdpxi(50)]
let itemSlotArea    = [hdpx(280), hdpx(106)]
let childSlotSize   = [hdpx(124), hdpx(186)]
let slotSize        = [hdpx(124), hdpx(124)]
let slotGapSize     = [hdpx(156), hdpx(124)]
let slotMiniGapSize = [hdpx(62), hdpx(124)]
let vertLineSize    = [hdpx(124), hdpx(62)]
let itemSlotSize    = [hdpx(218), hdpx(74)]

let defTxtStyle = { color = defTxtColor }.__update(fontSub)
let priceTxtStyle = { color = titleTxtColor }.__update(fontSub)
let headerTxtStyle = { color = titleTxtColor }.__update(fontBody)
let hintTxtStyle = { color = weakTxtColor }.__update(fontSub)
let nameTxtStyle = { color = titleTxtColor }.__update(fontBody)
let attentionTxtStyle = { color = attentionTxtColor }.__update(fontBody)

let progressBarBgImage = mkColoredGradientX({colorLeft=0xFFFC7A40, colorRight=brightAccentColor})

let scrollHandler = ScrollHandler()


let iconSquadPoints = {
  rendObj = ROBJ_IMAGE
  size = array(2, iconSize)
  image = Picture("!ui/uiskin/research/squad_points_icon.svg:{0}:{0}:K".subst(iconSize))
}

let priceIcon = {
  rendObj = ROBJ_IMAGE
  size = [priceIconSize, priceIconSize]
  image = Picture("!ui/uiskin/research/squad_points_icon.svg:{0}:{0}:K".subst(priceIconSize))
}

let researchedSign = @(fontSize = hdpxi(62)) faComp("check-circle-o", {
  fontSize
  color = completedTxtColor
})

let researchedPageSign = faComp("check-circle-o", {
  vplace = ALIGN_BOTTOM
  margin = [midPadding, largePadding]
  fontSize = hdpxi(32)
  color = completedTxtColor
})

let classesTagsTable = mkGlyphsStyle(hdpxi(24))

let mkText = @(txt, override) {
  rendObj = ROBJ_TEXT
  text = txt
}.__update(override)

let mkTextarea = @(txt, override) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  tagsTable = classesTagsTable
  text = txt
}.__update(override)


let mkResearchFrame = @(bgName, key, color, animations) {
  key
  rendObj = ROBJ_IMAGE
  size = FLEX
  image = Picture($"ui/uiskin/research/icons/{bgName}_frame.avif:0:P")
  color
  animations
}

function squadPoints(points, sf) {
  if (points <= 0)
    return null

  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = [
      mkCardText(points, sf)
      iconSquadPoints
    ]
  }
}

let allResearched = {
  minWidth = minWidthExp
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = researchedSign(hdpxi(20))
}

let mkSquadMkChild = @(needIndicator, hasAllResearch, points)
  @(sf) {
    hplace = ALIGN_RIGHT
    margin = [miniPadding, 0]
    flow = FLOW_HORIZONTAL
    halign = ALIGN_RIGHT
    valign = ALIGN_CENTER
    children = [
      needIndicator ? indicator : null
      hasAllResearch ? allResearched : squadPoints(points, sf)
    ]
  }

let filterSquads = Computed(@()
  getFilterSquads(curUnlockedSquads.get(),
    filterResearchesSquad.get(),
    squadsCfgById.get()?[curArmy.get()],
    favoriteSquads.get()))

let mkResearchesSquads = @(hasAllResearchedSquads)
  Computed(@() filterSquads.get().map(function(s) {
    let { squadId } = s
    let hasAllResearch = !!hasAllResearchedSquads.get()?[squadId]
    let points = allSquadsPoints.get()?[squadId] ?? 0
    let needIndicator = points > 0 && !hasAllResearch
    return s.__merge({
      mkChild = mkSquadMkChild(needIndicator, hasAllResearch, points)
      level = squadProgress.get()?[squadId].level ?? 0
    })
  }))


let mkPicName = memoize(@(pageIdx) $"!ui/uiskin/research/{pagesIcons[pageIdx]}.svg:{pageIconSize[0]}:{pageIconSize[1]}:K")

let mkResearchPageSlot = @(pageIdx, isSelected, isHover) {
  rendObj = ROBJ_BOX
  size = pageSize
  fillColor = isHover ? hoverSlotBgColor
    : isSelected ? selectedPanelBgColor
    : panelBgColor
  borderWidth = isSelected ? [0, 0, hdpx(4), 0] : 0
  borderColor = accentColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_IMAGE
    size = pageIconSize
    color = isHover ? darkTxtColor
      : isSelected ? titleTxtColor
      : defTxtColor
    image = Picture(mkPicName(pageIdx))
  }
}

function gotoNextPage() {
  let total = tableStructure.get()?.pages.len() ?? 0
  if (total > 0)
    selectedTable.set((selectedTable.get() + 1) % total)
}

let switchPageKey = @() {
  size = const [0, SIZE_TO_CONTENT]
  watch = isGamepad
  padding = largePadding
  vplace = ALIGN_CENTER
  children = isGamepad.get() ? mkHotkey("J:X", gotoNextPage) : null
}

let mkPagesListUi = @(pagesInfo) function() {
  let { pages = [] } = tableStructure.get()
  return {
    watch = tableStructure
    hplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    children = pages.map(function(_curPage, pageIdx) {
      let isSelected = Computed(@() selectedTable.get() == pageIdx)
      let isCompleted = Computed(function() {
        let { available = 0, completed = 0 } = pagesInfo.get()?[pageIdx]
        return available >= 0 && completed >= available
      })
      return {
        children = [
          watchElemState(@(sf) {
            watch = isSelected
            behavior = Behaviors.Button
            onClick = @() selectedTable.set(pageIdx)
            sound = btnSound
            children = mkResearchPageSlot(pageIdx, isSelected.get(), sf & S_HOVER)
          })
          @() {
            watch = isCompleted
            children = isCompleted.get() ? researchedPageSign : null
          }
        ]
      }
    })
    .append(switchPageKey)
  }
}

function mkPagesInfoUi(pagesInfo) {
  let mkResearchPageInfo = @(pageName, pageDesc, statusTxt) {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = midPadding
    children = [
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = { size = FLEX }
        children = [
          pageName!= null ? mkText(utf8ToUpper(loc(pageName)), headerTxtStyle) : null
          mkText(loc(statusTxt), headerTxtStyle)
        ]
      }
      {
        key = pageDesc
        size = FLEX_H
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc(pageDesc)
      }.__update(defTxtStyle)
    ]
  }

  let pInfo = Computed(@() pagesInfo.get()?[selectedTable.get()])
  return function() {
    let { name = "", description = "", completed = 0, available = 0 } = pInfo.get()
    return {
      watch = pInfo
      size = FLEX_H
      children = mkResearchPageInfo(name, description, $"{completed}/{available}")
    }
  }
}

function classHeader() {
  let pageIdx = selectedTable.get()
  let res = { watch = [selectedTable, viewSquadId, squadsCfgById] }
  if (pageIdx != 1)
    return res

  let armyId = curArmy.get()
  let { sign = SIGN_NONE, newClass = "" } = squadsCfgById.get()?[armyId][viewSquadId.get()]
  if (sign == SIGN_PREMIUM || newClass not in soldierClasses)
    return res

  let { locId } = getClassCfg(newClass)

  return res.__update({
    size = FLEX_H
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = largePadding
    children = {
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(loc(locId))
      }.__update(attentionTxtStyle)
  })
}

let mkHeaderUi = @(pagesInfo) {
  size = [pageSize[0] * 3, headerHeight]
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = largePadding
  children = [
    mkPagesListUi(pagesInfo)
    mkPagesInfoUi(pagesInfo)
    classHeader
  ]
}


let pageIcons = [
  "page_squad_upgrades_bg",
  "page_personnel_upgrades_bg",
  "page_workshop_upgrades_bg"
]

let iconColors = {
  disabled = 0x99999999
  veteran = 0xCCF6FF00
  disabled_veteran = 0x55F6FF00
}

const customIcons = {
  artillery_type_unlock_3_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_4_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_5_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_6_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_7_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_8_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_9_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_10_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_11_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_12_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_13_icon = "artillery_type_unlock_2_icon"
  artillery_type_unlock_15_icon = "artillery_type_unlock_14_icon"
  artillery_type_unlock_16_icon = "artillery_type_unlock_16_icon"
}

let blinkAnim = {
  prop = AnimProp.opacity, from = 0.6, to = 1, easing = CosineFull,
  duration = 2, play = true, loop = true
}

function mkResearchIcon(
  pageIdx, iconId, hasResearched, canResearch, isSelected, researchId
) {
  let isActive = hasResearched || canResearch
  let bgName = pageIcons?[pageIdx]
  let disabledSuffix = hasResearched ?  "" : "_disabled"
  let bgImgPath = $"ui/uiskin/research/icons/{bgName}{disabledSuffix}.avif:0:P"
  let bgSaturate = isActive ? 1 : 0.3

  let isVeteran = iconId.endswith("_veteran")
  let iconName = isVeteran ? "common_veteran" : (customIcons?[iconId] ?? $"{iconId}")
  let iconPath = $"ui/uiskin/research/icons/{pageIdx}_{iconName}.avif:0:P"

  let iconColor = isVeteran
    ? (isActive ? iconColors["veteran"] : iconColors["disabled_veteran"])
    : (isActive ? commonIconColor : iconColors["disabled"])

  let key = $"frame_{researchId}_{isSelected}"
  let frameObj = isSelected ? mkResearchFrame(bgName, key, titleTxtColor, null)
    : canResearch ? mkResearchFrame(bgName, key, attentionTxtColor, [ blinkAnim ])
    : null

  return {
    size = FLEX
    padding = [0, midPadding]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = FLEX
        image = Picture(bgImgPath)
        picSaturate = bgSaturate
      }
      frameObj
      {
        rendObj = ROBJ_IMAGE
        size = FLEX
        image = Picture(iconPath)
        color = iconColor
      }
    ]
  }
}

let lockSign = faComp("ban", {
  margin = [0, largePadding]
  vplace = ALIGN_BOTTOM
  fontSize = hdpxi(42)
  color = negativeTxtColor
})

function mkResearchSlot(pageIdx, research, selectedId, statuses, onClick, onDoubleClick, multViewData = null) {
  let { hasMultUsed = false, hasSelectedInGroup = false, hasResearchedInGroup = false } = multViewData
  let { research_id = null, icon_id = null } = research
  let isSelected = research_id == selectedId
  let status = statuses?[research_id]
  let hasResearched = status == RESEARCHED
  let canResearch = status == CAN_RESEARCH
  let hasLockSign = hasMultUsed && status != RESEARCHED
    && (hasResearchedInGroup || (hasSelectedInGroup && !isSelected))
  let stateFlags = Watched(0)
  return @() {
    size = slotSize
    behavior = Behaviors.Button
    onClick
    watch = stateFlags
    onElemState = @(s) stateFlags.set(s)
    sound = btnSound
    onDoubleClick
    xmbNode = XmbNode({
      canFocus = true
      wrap = false
      isGridLine=true
      scrollToEdge = [true, false]
    })
    children = [
      hoverImage.create({
        sf = stateFlags.get()
        uid = research_id
        size = slotSize
        image = null
        pivot = [0.5, 0.5]
        children = mkResearchIcon(pageIdx, icon_id, hasResearched,
          canResearch, isSelected, research_id)
        hasSizeAnimation = canResearch
      })
      hasLockSign ? lockSign : null
    ]
  }
}


const ORIENTATIONS = {
  TOP = "TOP"
  BOTTOM = "BOTTOM"
  BOTTOM_LEFT = "BOTTOM_LEFT"
  BOTTOM_RIGHT = "BOTTOM_RIGHT"
  BOTTOM_BIG_LEFT = "BOTTOM_BIG_LEFT"
  BOTTOM_BIG_RIGHT = "BOTTOM_BIG_RIGHT"
}

let lineOffset = (largePadding / 2).tointeger()

let baseLineStyle = {
  color = 0xFF999999
  lineWidth = hdpx(1)
}
let gainLineStyle = {
  color = brightAccentColor
  lineWidth = hdpx(2)
}

let vectorStyle = {
  size = FLEX
  margin = [lineOffset, 0]
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(1)
}

let topVector = { commands = [[ VECTOR_LINE, 50, 0, 50, 100 ]] }
let btmLeftVector = { commands = [[ VECTOR_LINE, 80, 0, 65, 100 ]] }
let btmBigLeftVector = { commands = [[ VECTOR_LINE, 110, 0, 65, 100 ]] }
let btmRightVector = { commands = [[ VECTOR_LINE, 20, 0, 35, 100 ]] }
let btmBigRightVector = { commands = [[ VECTOR_LINE, -10, 0, 35, 100 ]] }

let multResearchSelectHint = mkText(loc("multResearchSelectHint"), {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}.__update(hintTxtStyle))

let mkTopMultVector = @(override = {}) {
  commands = [
    [ VECTOR_LINE_DASHED, 50, 0, 50, 30, lineDashSize, lineDashSize ],
    [ VECTOR_LINE_DASHED, 50, 80, 50, 100, lineDashSize, lineDashSize ],
    [ VECTOR_LINE_DASHED, 5, 100, 95, 100, lineDashSize, lineDashSize ]
  ]
  children = multResearchSelectHint
}.__update(override)

let mkBtmMultVector = @(override = {}) {
  commands = [
    [ VECTOR_LINE_DASHED, 50, 100, 50, 80, lineDashSize, lineDashSize ],
    [ VECTOR_LINE_DASHED, 50, 30, 50, 0, lineDashSize, lineDashSize ],
    [ VECTOR_LINE_DASHED, 5, 0, 95, 0, lineDashSize, lineDashSize ]
  ]
  children = multResearchSelectHint
}.__update(override)

let mkChainVertLine = @(override = {}) {
  size = FLEX
  children = vectorStyle.__merge(topVector, override)
}

let mkChainBtmLeftLine = @(override = {}) {
  size = FLEX
  children = vectorStyle.__merge(btmLeftVector, override)
}

let mkChainBtmBigLeftLine = @(override = {}) {
  size = FLEX
  children = vectorStyle.__merge(btmBigLeftVector, override)
}

let mkChainBtmRightLine = @(override = {}) {
  size = FLEX
  children = vectorStyle.__merge(btmRightVector, override)
}

let mkChainBtmBigRightLine = @(override = {}) {
  size = FLEX
  children = vectorStyle.__merge(btmBigRightVector, override)
}

let mkGapLongHorLine = @(override = {}) vectorStyle.__merge({
  size = slotGapSize
  margin = 0
  commands = [[ VECTOR_LINE, 0, 50, 100, 50 ]]
}, override)

let mkGapVertTopLine = @(override = {}) {
  size = slotMiniGapSize
  children = {
    size = vertLineSize
    pos = [slotMiniGapSize[0], -vertLineSize[1]]
    children = mkChainVertLine(override)
  }
}

let space = {
  rendObj = ROBJ_BOX
  size = slotGapSize
  margin = 0
}

let mkGapVertBtmLine = @(override = {}) {
  size = slotMiniGapSize
  children = {
    size = vertLineSize
    pos = [slotMiniGapSize[0], slotSize[1]]
    children = mkChainVertLine(override)
  }
}

let mkResearcheMiniGap = @(override = {}) vectorStyle.__merge({
  size = slotMiniGapSize
  margin = 0
  commands = [[ VECTOR_LINE, 0, 50, 100, 50 ]]
}, override)

let stepLengtGaps4 = {
  [1] = mkGapVertBtmLine,
  [2] = mkResearcheMiniGap,
  [3] = mkGapVertTopLine,
  [4] = mkResearcheMiniGap
}

let stepLengtGaps3 = {
  [1] = @(override = {}) {
    size = const [hdpx(62), hdpx(186)]
    pos = const [0, -hdpx(124)]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      size = slotSize
      padding = smallPadding
      children = vectorStyle.__merge({ commands = [[ VECTOR_LINE, 0, 0, 100, 100 ]] }, override)
    }
  },
  [2] = mkGapVertBtmLine,
  [3] = mkResearcheMiniGap
}

let stepLengtGaps2 = {
  [1] = mkGapVertTopLine,
  [2] = @(override = {}) {
    size = const [hdpx(62), hdpx(186)]
    pos = const [0, hdpx(62)]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = {
      size = slotSize
      padding = smallPadding
      children = vectorStyle.__merge({ commands = [[ VECTOR_LINE, 100, 0, 0, 100 ]] }, override)
    }
  }
}

let mkVertTopGapWithoutOffset = @(override = {}) {
  size = [0, slotMiniGapSize[1]]
  children = {
    size = vertLineSize
    pos = [0, -vertLineSize[1]]
    children = mkChainVertLine(override)
  }
}

let mkVertBtmGapWithoutOffset = @(override = {}) {
  size = [0, slotMiniGapSize[1]]
  children = {
    size = vertLineSize
    pos = [0, slotSize[1]]
    children = mkChainVertLine(override)
  }
}

function mkResearchMult(pageIdx, researches, selectedId, statuses, cbCtor, doubleCbCtor, orientation) {
  let multViewData = {
    hasMultUsed = true
    hasResearchedInGroup = researches.findvalue(@(r) statuses?[r.research_id] == RESEARCHED ) != null
    hasSelectedInGroup = researches.findvalue(@(r) r.research_id == selectedId ) != null
  }
  let isTop = orientation == ORIENTATIONS.TOP
  local yPos = isTop ? -childSlotSize[1] : slotSize[1]

  let hasGained = researches.findindex(function(r) {
    let status = statuses[r.research_id]
    return status == RESEARCHED || status == CAN_RESEARCH
  }) != null
  let lineStyle = hasGained ? gainLineStyle : baseLineStyle
  return {
    pos = [0, yPos]
    size = childSlotSize
    halign = ALIGN_CENTER
    children = {
      size = FLEX_V
      flow = FLOW_VERTICAL
      children = [
        isTop ? null : vectorStyle.__merge(mkTopMultVector(lineStyle))
        {
          flow = FLOW_HORIZONTAL
          children = researches.map(@(r)
            mkResearchSlot(pageIdx, r, selectedId, statuses, cbCtor(r), doubleCbCtor(r), multViewData))
        }
        isTop ? vectorStyle.__merge(mkBtmMultVector(lineStyle)) : null
      ]
    }
  }
}

function mkResearchChain(pageIdx, researches, selectedId, statuses, cbCtor, doubleCbCtor, orientation) {
  let xPos = orientation == ORIENTATIONS.BOTTOM_LEFT ? (-0.6 * slotSize[0]).tointeger()
    : orientation == ORIENTATIONS.BOTTOM_BIG_LEFT ? (-0.9 * slotSize[0]).tointeger()
    : orientation == ORIENTATIONS.BOTTOM_RIGHT ? (0.6 * slotSize[0]).tointeger()
    : orientation == ORIENTATIONS.BOTTOM_BIG_RIGHT ? (0.9 * slotSize[0]).tointeger()
    : 0
  let isBottom = orientation != ORIENTATIONS.TOP
  local yPos = isBottom ? slotSize[1] : -childSlotSize[1]
  return {
    children = researches.map(function(r, idx) {
      let status = statuses[r.research_id]
      let hasGained = status == RESEARCHED || status == CAN_RESEARCH
      let lineStyle = hasGained ? gainLineStyle : baseLineStyle
      yPos += childSlotSize[1] * idx * (isBottom ? 1 : -1)
      return {
        pos = [xPos, yPos]
        size = childSlotSize
        flow = FLOW_VERTICAL
        children = [
          orientation == ORIENTATIONS.TOP ? null
            : orientation == ORIENTATIONS.BOTTOM || idx > 0 ? mkChainVertLine(lineStyle)
            : orientation == ORIENTATIONS.BOTTOM_LEFT ? mkChainBtmLeftLine(lineStyle)
            : orientation == ORIENTATIONS.BOTTOM_RIGHT ? mkChainBtmRightLine(lineStyle)
            : orientation == ORIENTATIONS.BOTTOM_BIG_LEFT ? mkChainBtmBigLeftLine(lineStyle)
            : orientation == ORIENTATIONS.BOTTOM_BIG_RIGHT ? mkChainBtmBigRightLine(lineStyle)
            : null
          mkResearchSlot(pageIdx, r, selectedId, statuses, cbCtor(r), doubleCbCtor(r))
          orientation == ORIENTATIONS.TOP ? mkChainVertLine(lineStyle) : null
        ]
      }
    })
  }
}

function mkResearchChildren(
  pageIdx, children, selectedId, statuses, cbCtor, orientation, doubleCbCtor
) {
  let { researches = null, multiresearchGroup = 0 } = children
  if (researches == null)
    return null

  let ctor = multiresearchGroup > 0 ? mkResearchMult : mkResearchChain
  return ctor(pageIdx, researches, selectedId, statuses, cbCtor, doubleCbCtor, orientation)
}

function mkResearchColumn(pageIdx, idx, main, children, selectedId, statuses,
  hasLongBranches, cbCtor, doubleCbCtor, rGap
) {
  let [
    btmChildren = null, topChildren = null,
    addBtmChildren1 = null, addBtmChildren2 = null
  ] = children
  let { research_id } = main

  let hasMultiresearch = (topChildren?.multiresearchGroup ?? 0) > 0
    || (btmChildren?.multiresearchGroup ?? 0) > 0
  let reqOptimization = !hasMultiresearch && hasLongBranches

  let hasBtmChildren1 = addBtmChildren1 != null
  let hasBtmChildren2 = addBtmChildren2 != null
  let isTopMovedToBottom = reqOptimization && topChildren != null

  let btmOrientation = !hasBtmChildren1 && !isTopMovedToBottom ? ORIENTATIONS.BOTTOM
    : !hasBtmChildren2 ? ORIENTATIONS.BOTTOM_LEFT
    : ORIENTATIONS.BOTTOM_BIG_LEFT

  let topOrientation = !reqOptimization || btmChildren == null
    ? ORIENTATIONS.TOP
    : ORIENTATIONS.BOTTOM_RIGHT

  return {
    flow = FLOW_HORIZONTAL
    children = [
      idx == 0 ? null : rGap
      {
        key = research_id
        size = slotSize
        children = [
          mkResearchChildren(pageIdx, topChildren, selectedId, statuses, cbCtor,
            topOrientation, doubleCbCtor)
          mkResearchSlot(pageIdx, main, selectedId, statuses, cbCtor(main),
            doubleCbCtor(main))
          mkResearchChildren(pageIdx, btmChildren, selectedId, statuses, cbCtor,
            btmOrientation, doubleCbCtor)
          mkResearchChildren(pageIdx, addBtmChildren1, selectedId, statuses, cbCtor,
            hasBtmChildren2 ? ORIENTATIONS.BOTTOM_BIG_RIGHT : ORIENTATIONS.BOTTOM_RIGHT,
            doubleCbCtor)
          mkResearchChildren(pageIdx, addBtmChildren2, selectedId, statuses, cbCtor,
            ORIENTATIONS.BOTTOM, doubleCbCtor)
        ]
      }
    ]
  }
}


let fourStepLength = {
  [2] = { pos = [0, childSlotSize[1]], size = const [0, SIZE_TO_CONTENT] },
  [3] = { pos = [0, childSlotSize[1]] },
  [4] = { size = const [0, SIZE_TO_CONTENT] }
}
let threeStepLength = {
  [2] = { pos = [0, -childSlotSize[1]] },
  [3] = { size = const [0, SIZE_TO_CONTENT] }
}
let twoStepLength = {
  [2] = { pos = [0, -childSlotSize[1]], size = const [0, SIZE_TO_CONTENT] }
}


function mkResearchesTreeUi() {
  let researchCbCtor = @(research) @() selectedResearch.set(research)
  let researchDoubleCbCtor = @(research) function() {
    let statuses = researchStatuses.get()
    if (statuses == null || research == null)
      return

    let { research_id = null } = research
    let status = statuses?[research_id]
    let cfg = researchStatusesCfg?[status](research)

    let { onResearch = null } = cfg
    if (onResearch != null)
      onResearch()
  }

  let viewStructure = mkViewStructure()
  local cachedColumnsInfo = null
  let triggerComputed = Computed(function() {
    cachedColumnsInfo = null
    return use(tableStructure.get(), selectedResearch.get(),
      selectedTable.get(), researchStatuses.get(), viewStructure.get())
  })

  function getColumnsInfo() {
    if (cachedColumnsInfo!=null)
      return cachedColumnsInfo
    let columnPositions = [0]
    let { researches = {} } = tableStructure.get()
    let { research_id = null } = selectedResearch.get()
    let pageIdx = selectedTable.get()
    let rStatuses = researchStatuses.get()
    let { columns, maxChildHeight } = viewStructure.get()
    let hasResearchItem = columns.findindex(@(c)
      (c?.template ?? "") != "" && (c?.tplCount ?? 0) > 0) != null
    let needTopCurveSpace = columns.findindex(@(c)
        (c?.toChildren ?? 0) >= FOUR_TO_NEXT_BRANCH) == null
      && columns.findindex(@(c) (c?.toChildren ?? 0) >= TWO_TO_NEXT_BRANCH) != null

    let hasLongBranches = (maxChildHeight?[0] ?? 0) + (maxChildHeight?[1] ?? 0) > 2
    let offsetFactor = hasResearchItem ? 0
      : hasLongBranches ? 12
      : needTopCurveSpace ? 35
      : 100 * (maxChildHeight[1] + 1) / (maxChildHeight[0] + maxChildHeight[1] + 3)
    let hasItemLink = columns.findindex(@(c) c?.template != null) != null

    local req4CustomNests = false
    local req3CustomNests = false
    local req2CustomNests = false

    let researchColumns = columns.map(function(column, idx) {
      let { main, children, toChildren } = column

      let prevChildren = columns?[idx - 1].children ?? []
      let hasChildren = children.findvalue(@(ch) ch != null) != null
        && prevChildren.findvalue(@(ch) ch != null) != null
      let hasMult = children.findvalue(@(ch) (ch?.multiresearchGroup ?? 0) > 0) != null
        && req4CustomNests
      let hasLongBranch = children.reduce(@(r, ch) r + (ch?.children.len() ?? 0), 0) > 2

      if (toChildren >= FOUR_TO_NEXT_BRANCH)
        req4CustomNests = true
      else if (!req4CustomNests && !hasLongBranches
          && toChildren == THREE_TO_NEXT_BRANCH)
        req3CustomNests = true
      else if (!req3CustomNests && !hasLongBranches
          && !req4CustomNests && toChildren == TWO_TO_NEXT_BRANCH)
        req2CustomNests = true
      else if (toChildren == 0) {
        req4CustomNests = false
        req3CustomNests = false
        req2CustomNests = false
      }

      let chStyleId = hasItemLink || hasChildren || hasMult || hasLongBranch ? 0
        : req4CustomNests || req3CustomNests || req2CustomNests ? toChildren
        : FOUR_TO_NEXT_BRANCH

      let rMain = researches[main]
      let rMainId = rMain.research_id
      let rChildren = children.map(@(child) child == null ? null
        : {
            multiresearchGroup = child.multiresearchGroup
            researches = child.children.map(@(c) researches[c])
          })

      let nest = req4CustomNests ? (fourStepLength?[chStyleId] ?? {})
        : req3CustomNests ? (threeStepLength?[chStyleId] ?? {})
        : req2CustomNests ? (twoStepLength?[chStyleId] ?? {})
        : {}

      let hasGained = rStatuses[rMainId] == RESEARCHED || rStatuses[rMainId] == CAN_RESEARCH
      let lineStyle = hasGained ? gainLineStyle : baseLineStyle
      local researchGap = null
      if (req4CustomNests)
        researchGap = chStyleId == 3 && idx == 1
          ? mkVertTopGapWithoutOffset(lineStyle)
          : stepLengtGaps4?[min(chStyleId, stepLengtGaps4.len())](lineStyle)
              ?? mkGapLongHorLine(lineStyle)
      else if (req3CustomNests)
        researchGap = chStyleId == 2 && idx == 1
          ? mkVertBtmGapWithoutOffset(lineStyle)
          : stepLengtGaps3?[min(chStyleId, stepLengtGaps3.len())](lineStyle)
              ?? mkGapLongHorLine(lineStyle)
      else if (req2CustomNests)
        researchGap = chStyleId == 1 && idx == 1
          ? mkVertTopGapWithoutOffset(lineStyle)
          : stepLengtGaps2?[min(chStyleId, stepLengtGaps2.len())](lineStyle)
              ?? mkGapLongHorLine(lineStyle)
      else
        researchGap = stepLengtGaps4?[min(chStyleId, stepLengtGaps4.len())](lineStyle)
          ?? mkGapLongHorLine(lineStyle)

      let isNestSame = "size" in nest && nest.size[0] == 0
      let prevPos = columnPositions[columnPositions.len() - 1]
      columnPositions.append(isNestSame
        ? prevPos
        : prevPos + slotSize[0] + (researchGap?.size[0] ?? 0))

      let rGap = (rMain?.requirements.len() ?? 0) == 0 ? space : researchGap.__merge(lineStyle)
      let columnObject = mkResearchColumn(pageIdx, idx, rMain, rChildren, research_id, rStatuses,
        hasLongBranches, researchCbCtor, researchDoubleCbCtor, rGap)
      return { children = columnObject }.__update(nest)
    })
    let res = {offsetFactor, hasItemLink, hasLongBranches, researchColumns, columns, columnPositions}
    cachedColumnsInfo = res
    return res
  }

  function hasScroll() {
    let {columnPositions} = getColumnsInfo()
    let contentWidth = (columnPositions.len()> 0 ? columnPositions.top() : 0)+ slotSize[0]
    let saBorders = safeAreaBorders.get()
    let saSideOffset = saBorders[1] + saBorders[3]
    let freeWidth = sw(100) - (saSideOffset + hdpx(62) + researchInfoWidth + squadLineWidth)
    return contentWidth > freeWidth
  }


  let needScrollClosest = Watched(false)
  let closestResearch = Computed(@() closestTargets.get()?[selectedTable.get()])
  closestResearch.subscribe(@(_) needScrollClosest.set(true))

  function scrollToResearch(columns, curResearch) {
    if (columns == null)
      return

    let column = columns.findindex(@(col) col.main == curResearch
      || col.children.findvalue(@(branch) (branch?.children ?? []).contains(curResearch)) != null)
    if (column != null)
      scrollHandler.scrollToX(getColumnsInfo().columnPositions?[column] ?? 0)
  }

  let xmbContainer = XmbContainer({
    isGridLine = true
    canFocus = false
    wrap = false
    scrollSpeed = [2.0, 0]
  })

  let attractResearchWatchers = [researchToShow, needScrollClosest,
    closestResearch, viewStructure]

  function attractorFunc(_ = null) {
    let r = needScrollClosest.get() ? closestResearch.get() : researchToShow.get()
    if (r == null)
      return

    let { columns } = viewStructure.get()
    let { research_id } = r
    scrollToResearch(columns, research_id)
    defer(function() {
      if (researchToShow.get() != null) {
        hoverImage.attractToImage(researchToShow.get().research_id)
        researchToShow.set(null)
      }
      needScrollClosest.set(false)
    })
  }
  function onAttach() {
    foreach (w in attractResearchWatchers)
      w.subscribe(attractorFunc)
    attractorFunc()
  }
  function onDetach() {
    foreach (w in attractResearchWatchers)
      w.unsubscribe(attractorFunc)
  }

  function mkResearchItem(column, isLast) {
    let { template = null, tplCount = 0, main = null } = column
    if (template == null || tplCount == 0)
      return isLast ? null : { size = [itemSlotArea[0], 0] }

    let itemTemplate = allItemTemplates.get()?[curArmy.get()][main]
    let isVehicle = itemTemplate?.itemtype == "vehicle"
    let armyId = curArmy.get()
    let squadId = viewSquadId.get()

    function onClick(event) {
      if (event.button < 0 || event.button > 2)
        return

      if (isVehicle) {
        selectVehParams.mutate(@(params) params.__update({
          armyId
          squadId
          isCustomMode = false
          isHitcamMode = false
          selectOnOpen = trimUpgradeSuffix(main)
        }))
      }
      else {
        let armySquads = squadsByArmy.get()?[armyId] ?? []
        let squad = armySquads.findvalue(@(item) item?.squadId == squadId)
        let { squadType = null } = squad
        let soldiers = soldiersBySquad.get()?[squad?.guid] ?? []
        let idx = soldiers.findindex(@(item) soldierClasses?[item?.sClass].kind == squadType) ?? 0
        let soldier = soldiers?[idx]
        if (soldier) {
          curSoldierIdx.set(idx)
          if (template) {
            let itemByTemplate = slotItems.get().findvalue(@(item) item?.gametemplate == template)
            if (itemByTemplate != null)
              curInventoryItem.set(itemByTemplate)
          }
          openSelectItem(armyId, soldier.guid, "primary")
        }
      }
    }

    return {
      size = isLast ? [SIZE_TO_CONTENT, itemSlotArea[1]] : itemSlotArea
      children = [
        {
          pos = [-largePadding, 0]
          size = [tplCount * itemSlotArea[0] - hdpx(62), itemSlotArea[1] + hdpx(558)]
          rendObj = ROBJ_SOLID
          opacity = 0.05
          color = 0xFFFFFF
        }
        {
          flow = FLOW_VERTICAL
          children = [
            mkText(itemNameFromGametemplate(template), {
              margin = [largePadding, 0, smallPadding, 0]
            }.__update(defTxtStyle))
            watchElemState(@(sf) {
              rendObj = ROBJ_SOLID
              size = itemSlotSize
              behavior = Behaviors.Button
              color = isVehicle && (sf & S_HOVER) ? hoverPanelBgColor : panelBgColor
              onHover = @(on) setTooltip(on ? mkItemHintFromTemplate(itemTemplate) : null)
              onClick
              sound = {
                hover = "ui/enlist/button_highlight"
                click = "ui/enlist/button_click"
              }
              children = [
                iconByGameTemplate(template, {
                  width = itemSlotSize[0] - 4 * smallPadding
                  height = itemSlotSize[1] - 2 * smallPadding
                })
                {
                  vplace = ALIGN_BOTTOM
                  hplace = ALIGN_RIGHT
                  padding = smallPadding
                  children = mkBattleRatingShort(itemTemplate?.growthTier ?? 1)
                }
              ]
            })
          ]
        }
      ]
    }
  }

  return function researchesTreeUi() {
    let { columns, hasItemLink, offsetFactor, researchColumns } = getColumnsInfo()
    let researchTree = {
      flow = FLOW_HORIZONTAL
      children = researchColumns
    }

    let researchItemsRow = !hasItemLink ? null : {
      flow = FLOW_HORIZONTAL
      children = columns.map(@(column, idx) mkResearchItem(column, idx == columns.len() - 1))
    }

    let treeObject = {
      size = FLEX_V
      flow = FLOW_VERTICAL
      gap = largePadding
      padding = const [0, hdpx(62)]
      onAttach
      onDetach
      children = [
        researchItemsRow
        {
          size = FLEX_V
          flow = FLOW_VERTICAL
          children = [
            { size = [0, ph(offsetFactor)] }
            researchTree
          ]
        }
      ]
    }
    return {
      watch = triggerComputed
      size = FLEX
      children = hasScroll()
        ? makeHorizScroll({
            xmbNode = xmbContainer
            children = treeObject
            size = FLEX_V
          }, {
            size = FLEX
            scrollHandler
            rootBase = {
              behavior = Behaviors.Pannable
              wheelStep = 1
            }
          })
        : {
            size = FLEX
            halign = ALIGN_CENTER
            valign = ALIGN_BOTTOM
            vplace = ALIGN_BOTTOM
            children = treeObject
          }
    }
  }
}


let mkPointsInfo = @(level, points) {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = smallPadding
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = [
    mkText(loc("levelInfo", { level = level + 1 }), nameTxtStyle)
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      halign = ALIGN_RIGHT
      valign = ALIGN_CENTER
      children = [
        mkText(loc("research/availPoints"), defTxtStyle)
        priceIcon
        mkText(points, nameTxtStyle)
      ]
    }
  ]
}

function getProgressTooltip(curLvl, maxLvl, curExp, expToNextLvl, accColor){
  let lvlBlock = colorize(accColor, $"{curLvl + 1}/{maxLvl + 1}")
  let expBlock = colorize(accColor, $"{curExp}/{expToNextLvl}")
  return $"{lvlBlock} {loc("research/squad_level")}\n{loc("research/squad_next_level")} {expBlock}"
}

let mkProgressUi = @(curSquadData) function() {
  let res = {
    watch = [curSquadData, curSquadProgress]
  }
  let { premIcon = null } = curSquadData.get()
  if (premIcon != null)
    return res

  let { level, maxLevel, exp, nextLevelExp, points } = curSquadProgress.get()
  let progressValue = nextLevelExp > 0 ? exp.tofloat() / nextLevelExp
    : level == maxLevel ? 1.0
    : 0.0
  return res.__update({
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = midPadding
    behavior = Behaviors.Button
    onHover = @(on) setTooltip(on
      ? getProgressTooltip(level, maxLevel, exp, nextLevelExp, levelAndExpColor)
      : null)
    children = [
      mkPointsInfo(level, points)
      gradientProgressBar(progressValue, {
        vplace = ALIGN_BOTTOM
        bgImage = progressBarBgImage
        emptyColor = panelBgColor
      })
    ]
  })
}

function mkResearchInfo(research) {
  if (research == null)
    return null

  let { research_id, name = null, description = null, params = null } = research
  return {
    size = FLEX
    flow = FLOW_VERTICAL
    gap = largePadding
    children = [
      mkTextarea(utf8ToUpper(loc(name, params)), {
        key = $"name_{research_id}"
      }.__update(attentionTxtStyle, leftAppearanceAnim(0)))
      mkTextarea(loc(description, params), {
        key = $"desc_{research_id}"
      }.__update(defTxtStyle, leftAppearanceAnim(0.1)))
    ]
  }
}


let mkResearchUnlockedView = @(research_id) {
  size = FLEX_H
  children = {
    key = research_id
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = largePadding
    children = [
      researchedSign
      mkText(utf8ToUpper(loc("research/unlocked")), headerTxtStyle)
    ]
  }.__update(leftAppearanceAnim(0.1))
}

function mkResearchPrice(researchDef) {
  let { price = 0 } = researchDef
  return price == 0 ? null : {
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = [
      mkText(loc("research/researchPrice", { price = "" }), priceTxtStyle)
      priceIcon
      mkText(price, headerTxtStyle)
    ]
  }
}

let mkResearchBtn = @(onResearch, researchText, canResearch) @() {
  hplace = ALIGN_RIGHT
  watch = isResearchInProgress
  children = isResearchInProgress.get()
    ? waitingSpinner
    : (canResearch ? Primary : Regular)(researchText, onResearch, {
        textParams = fontBody
        hotkeys = [[ "^J:Y", { description = { skip = true }} ]]
      })
}

let mkUnlockPrice = @(researchDef, specialPrice, onResearch) onResearch == null ? null
  : specialPrice ?? mkResearchPrice(researchDef)

let mkUnlockButton = @(researchText, onResearch, canResearch)
  onResearch == null ? null
    : mkResearchBtn(onResearch, researchText ?? loc("research/researchBtnText"), canResearch)

let mkBuyLevelPrice = @(levelCost) function() {
  let currency = currenciesById.get()?["EnlistedGold"]
  return {
    watch = currenciesById
    hplace = ALIGN_RIGHT
    children = mkCurrency({
      currency
      price = levelCost
      iconSize = priceIconSize
    })
  }
}

let buyLevelButton = @() {
  watch = isBuyLevelInProgress
  hplace = ALIGN_RIGHT
  children = isBuyLevelInProgress.get()
    ? waitingSpinner
    : Purchase(loc("btn/buy"), buyLevelsMsg)
}

let getLevelButton = @() {
  watch = isBuyLevelInProgress
  hplace = ALIGN_RIGHT
  children = isBuyLevelInProgress.get()
    ? waitingSpinner
    : Primary(loc("mainmenu/receive"), @() buySquadLevel(function(isSuccess) {
        if (isSuccess)
          sound_play("ui/purchase_level_squad")
      }))
}

let mkLevelBuyPanel = @(hasAllResearched) function() {
  let res = {
    watch = [hasAllResearched, selectedResearch, researchStatuses, curSquadProgress]
  }

  
  
  if (hasAllResearched.get())
    return res

  let researchDef = selectedResearch.get()
  let statuses = researchStatuses.get()
  if (researchDef == null || statuses == null)
    return res

  let { levelCost = 0, exp = 0, nextLevelExp = 0 } = curSquadProgress.get()
  let canGetLevel = exp > 0 && exp >= nextLevelExp
  if (levelCost <= 0 && !canGetLevel)
    return res

  return res.__update({
    size = FLEX_H
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap = { size = FLEX }
    children = levelCost == 0
      ? getLevelButton
      : [
          mkBuyLevelPrice(levelCost)
          buyLevelButton
        ]
  }.__update(leftAppearanceAnim(0.1)))
}

let mkResearchPanel = @() function() {
  let res = { watch = [selectedResearch, researchStatuses] }
  let researchDef = selectedResearch.get()
  let statuses = researchStatuses.get()
  if (researchDef == null || statuses == null)
    return res

  let { research_id } = researchDef
  let status = statuses?[research_id]
  let cfg = researchStatusesCfg?[status](researchDef)
  if (cfg == null)
    return res.__update(mkResearchUnlockedView(research_id))

  let {
    info = null, warning = null, onResearch = null, researchPrice = null, researchText = null
  } = cfg
  return res.__update({
    key = $"research_footer_{research_id}"
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      info == null ? null : mkTextarea(utf8ToUpper(info), headerTxtStyle)
      warning == null ? null : mkTextarea(utf8ToUpper(warning), attentionTxtStyle)
      {
        size = FLEX_H
        valign = ALIGN_CENTER
        children = [
          mkUnlockPrice(researchDef, researchPrice, onResearch)
          mkUnlockButton(researchText, onResearch, status == CAN_RESEARCH)
        ]
      }
    ]
  }.__update(leftAppearanceAnim(0.1)))
}

function mkResearchInfoUi(hasAllResearched) {
  let curSquadData = Computed(@() armySquadsById.get()?[viewArmy.get()][viewSquadId.get()])
  let nameLocId = Computed(function() {
    let res = armiesResearches.get()?[curArmy.get()].squads[viewSquadId.get()].name ?? ""
    return res != "" ? res : (curSquadData.get()?.manageLocId ?? "")
  })
  let progressUi = mkProgressUi(curSquadData)
  let levelBuyBtn = mkLevelBuyPanel(hasAllResearched)
  let researchBtn = mkResearchPanel()

  return {
    size = FLEX_V
    flow = FLOW_VERTICAL
    gap = bigPadding
    children = [
      @() {
        watch = nameLocId
        rendObj = ROBJ_SOLID
        size = const [researchInfoWidth, SIZE_TO_CONTENT]
        hplace = ALIGN_RIGHT
        flow = FLOW_VERTICAL
        gap = bigPadding
        padding = largePadding
        color = darkPanelBgColor
        children = [
          {
            size = FLEX_H
            flow = FLOW_VERTICAL
            gap = bigPadding
            children = [
              nameLocId.get() == "" ? null : mkTextarea(loc(nameLocId.get()), nameTxtStyle)
              progressUi
            ]
          }
          levelBuyBtn
        ]
      }
      @() {
        watch = selectedResearch
        rendObj = ROBJ_SOLID
        size = const [researchInfoWidth, FLEX]
        flow = FLOW_VERTICAL
        gap = bigPadding
        padding = largePadding
        color = darkPanelBgColor
        children = [
          mkResearchInfo(selectedResearch.get())
          researchBtn
        ]
      }
    ]
  }
}


let emptyResearchesText = mkText(loc("researches/willBeAvailableSoon"), {
  vplace = ALIGN_CENTER
  hplace = ALIGN_CENTER
}.__update(nameTxtStyle))

let setCurSquadId = @(squadId) viewSquadId.set(squadId)

curArmy.subscribe(@(_v) resetFilter(filterResearchesSquad))
viewSquadId.subscribe(function(squadId) {
  if (squadId == null)
    resetFilter(filterResearchesSquad)
})

filterSquads.subscribe(function(v) {
  foreach(squad in v)
    if(squad.squadId == viewSquadId.get())
      return

  setCurSquadId(v?[0].squadId)
})

let mkOpenFilterButton = @(watchFilter, squadTypesCount) {
  rendObj = ROBJ_SOLID
  size = [FLEX, commonBtnHeight]
  color = squadSlotBgIdleColor
  children = squadsFilterUi({
    watchFilter,
    squadTypesCount,
    offset = [0, bigPadding],
    override = {
      size = FLEX
    }
  })
}

function mkResearchesUi() {
  let isBranchEmpty = Computed(@() (tableStructure.get()?.researches.len() ?? 0) == 0)
  let squadTypesCountWatch = Computed(@()
    getCountSquadTypes(curUnlockedSquads.get(), favoriteSquads.get()))
  let pagesInfo = Computed(function() {
    let statuses = researchStatuses.get()
    let { pages = [] } = tableStructure.get()
    let res = pages.map(function(page) {
      let { tables = {}, name = null, description = null } = page
      let available = getAvailableResearches(tables)
      let completed = tables.reduce(@(acc, val)
        statuses?[val.research_id] == RESEARCHED ? acc + 1 : acc, 0)
      return { name, description, available, completed }
    })
    return res
  })
  let hasAllResearched = Computed(@()
    pagesInfo.get().findvalue(@(page) page.completed < page.available) == null
  )
  let hasAllResearchedSquads = Computed(function() {
    let res = {}
    let curResearches = armiesResearches.get()?[curArmy.get()] ?? {}
    let { pages = {} } = curResearches
    if (pages.len() == 0)
      return res
    let statuses = researchStatuses.get()
    foreach (squad in curUnlockedSquads.get()) {
      let squadPages = pages?[squad.squadId] ?? {}
      local isCompleted = true
      foreach (index, page in squadPages) {
        let { tables = {} } = page
        local completed = 0
        let squadsAvailables = squadsResearchAvailable.get()?[squad.squadId]
        foreach (research in tables) {
          if (statuses?[research.research_id] == RESEARCHED)
            completed++
        }
        let available = squadsAvailables?[index] ?? 0
        if (completed < available) {
          isCompleted = false
          break
        }
      }
      res[squad.squadId] <- isCompleted
    }
    return res
  })
  let researchesSquads = mkResearchesSquads(hasAllResearchedSquads)
  return {
    size = FLEX
    children = [
      {
        size = FLEX
        flow = FLOW_HORIZONTAL
        children = [
          {
            size = FLEX_V
            children = mkCurSquadsList({
              curSquadsList = researchesSquads
              curSquadId = viewSquadId
              setCurSquadId = setCurSquadId
              topElement = mkOpenFilterButton(filterResearchesSquad, squadTypesCountWatch)
            })
          }
          @() {
            watch = [isBranchEmpty]
            padding = const [headerHeight, 0,0,0]
            size = FLEX
            children = isBranchEmpty.get() ? emptyResearchesText
              : mkResearchesTreeUi()
          }
          mkResearchInfoUi(hasAllResearched)
        ]
      }
      mkHeaderUi(pagesInfo)
    ]
  }
}

function buildResearchesUi() {
  return {
    size = FLEX
    flow = FLOW_VERTICAL
    margin = [contentOffset,0,0,0]
    gap = bigPadding
    children = [
      promoWidget("research_section", null)
      mkResearchesUi()
    ]
  }
}

return { buildResearchesUi }
