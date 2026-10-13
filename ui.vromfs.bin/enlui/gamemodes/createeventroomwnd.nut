import "%ui/components/closeBtn.nut" as closeBtn
import "%ui/components/spinnerList.nut" as spinnerList
import "%ui/components/spinner.nut" as spinner
import "%ui/gameModes/components/mkOptionRow.nut" as mkOptionRow
import "%ui/components/mkWindowTab.nut" as mkWindowTab
import "%ui/components/faComp.nut" as faComp
import "%ui/gameModes/getMissionInfo.nut" as getMissionInfo
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/gameModes/sandbox/customMissionWnd.nut" as openCustomMissionWnd
import "%ui/currency/premiumWnd.nut" as premiumWnd
from "%enlSqGlob/missionType.nut" import MissionType
from "%ui/gameModes/createEventRoomState.nut" import isInRoom, isEditEventRoomOpened, OPT_LIST, OPT_CHECKBOX, OPT_EDITBOX, OPT_MULTISELECT, editEventRoom
  , isEditInProgress, currentPassword
from "%ui/style/fontsStyle.nut" import fontSub, fontBody, fontHeading2
from "dagor.debug" import logerr
from "%ui/style/designConst.nut" import bigPadding, defTxtColor, smallPadding, titleTxtColor, midPadding, maxContentWidth, selectedPanelBgColor
  , blurBgFillColor, smallOffset, isWide, defInsideBgColor, blurBgColor
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/gameModes/eventModesPkg.nut" import mkWindowHeader, txtColor, teamsColors, armyIconSize
from "%ui/components/textButton.nut" import Regular
from "%ui/gameModes/eventModeStyle.nut" import localGap, localPadding, rowHeight
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/components/missionsPresentation.nut" import getImagesFromMissions, typeToLocId, missionTypes
from "%ui/style/cursors.nut" import setTooltip
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/mpRoom/saveChooseLobbySettings.nut" import lobbyPresets, openSaveWindow, openChooseWindow
from "%ui/gameModes/sandbox/customMissionState.nut" import modPath, receivedModInfos, isModAvailable
from "%dngscripts/platform.nut" import isXboxOne, isPS4, is_console
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/currency/premiumComp.nut" import premiumImage
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon
from "%ui/ui_library.nut" import *

let { optArmiesA, optArmiesB, optIsPrivate, optMode, optDifficulty, optMaxPlayers, optBotCount, optCampaigns, optCluster, optCrossplay, optPassword, optMissions } = require("%ui/gameModes/createEventRoomState.nut")
let { chooseRandom } = require("%sqstd/rand.nut")
let textInput = require("%ui/components/textInput.nut")

enum TabsIds {
  EVENT_ID
  ARMY_ID
  MISSION_ID
}

let teams = [
  {
    teamLocId = "teamA"
    armyOpt = optArmiesA
    index = 0
  }
  {
    teamLocId = "teamB"
    armyOpt = optArmiesB
    index = 1
  }
]

const armyImages = {
  ussr = "ui/soldiers/ussr/squad_ussr_mgun_3_image.avif"
  ger = "ui/soldiers/germany/axis_stalingrad_assault_2_image.avif"
  usa = "ui/soldiers/usa/allies_pacific_assault_2_image.avif"
  jap = "ui/soldiers/japan/axis_pacific_assault_3_image.avif"
}

const WND_UID = "editEventGm"
let CARDS_PER_ROW = isWide ? 3 : 2
const ARMIES_PER_ROW = 4
const ARMIES_ITEMS_ROW = 2
let IMAGE_RATIO = isWide ? 16.0 / 9.0 : 4.0 / 3.0
const contentHeight = hdpxi(650)
const infoRowsToShow = 3
let wndWidth = min(maxContentWidth, sw(95))
const campaignsBlockWidth = hdpx(456)
let contentWidth = wndWidth - campaignsBlockWidth - localPadding * 3
let armyContentWidth = wndWidth - localPadding * 2
let missionsCardWidth = ((contentWidth - localPadding * (CARDS_PER_ROW - 1))
  / CARDS_PER_ROW).tointeger()
let armyCardWidth = ((armyContentWidth - localPadding * (ARMIES_PER_ROW - 1))
  / ARMIES_PER_ROW).tointeger()
const missionsBlockHeight = hdpxi(500)
const missionsCardHeight = hdpxi(234)
let missionImageSize = [missionsCardWidth, missionsCardHeight / 2]
let armyImageSize = [armyCardWidth, (armyCardWidth / IMAGE_RATIO).tointeger()]
let waitingSpinner = spinner()

let prevGenPlatform = isXboxOne ? "xbox"
  : isPS4 ? "sony"
  : null

let curTabIdx = mkWatched(persist, "curTabIdx", 0)
let selectedMissionType = Watched(MissionType.INVASION)

function selectAll() {
  optArmiesA.setValue(optArmiesA.cfg.get().values)
  optArmiesB.setValue(optArmiesB.cfg.get().values)
}
function unselectAll() {
  optArmiesA.setValue([])
  optArmiesB.setValue([])
}

let activeTabIds = Computed(function() {
  let tabs = [TabsIds.EVENT_ID]
  if (modPath.get() == "" && !isInRoom.get()) {
    tabs.append(TabsIds.ARMY_ID)
    tabs.append(TabsIds.MISSION_ID)
  }
  return tabs
})

activeTabIds.subscribe(function(v) {
  if (curTabIdx.get() >= v.len())
    curTabIdx.set(0)
})

let baseOptions = [
  optIsPrivate
  optMode
  optDifficulty
  optMaxPlayers
  optBotCount
  optCampaigns
  optCluster
  optCrossplay
  optPassword
]

function curTabById(id) {
  let idx = activeTabIds.get().indexof(id)
  if (idx != null)
    curTabIdx.set(idx)
}

let armiesInfoBlocks = [
  {
    option = optArmiesA
    onClick = @() curTabById(TabsIds.ARMY_ID)
  }
  {
    option = optArmiesB
    onClick = @() curTabById(TabsIds.ARMY_ID)
  }
]


let close = @() isEditEventRoomOpened.set(false)

let locOn = loc($"option/on")
let locOff = loc($"option/off")
let defBoolToString = @(val) val ? locOn : locOff
let mkValueText = @(curValue, valToString, overrideText = null) @() {
  watch = curValue
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = overrideText ?? valToString?(curValue.get()) ?? curValue.get()
}.__update(fontBody)

let optionCtor = {
  [OPT_LIST] = @(opt, cfg, isInactive = false) (cfg.values.len() <= 1 || isInactive)
    ? mkValueText(opt.curValue, opt?.valToString)
    : spinnerList({
        curValue = opt.curValue, setValue = opt.setValue, allValues = cfg.values,
        valToString = opt?.valToString
      }),

  [OPT_CHECKBOX] = @(opt, cfg, isInactive = false) (cfg.values.len() <= 1 || isInactive)
    ? mkValueText(opt.curValue, opt?.valToString ?? defBoolToString)
    : spinnerList({
        curValue = opt.curValue, setValue = opt.setValue, allValues = cfg.values
        valToString = opt?.valToString ?? defBoolToString
      }),

  [OPT_EDITBOX] = @(opt, cfg, isInactive = false) isInactive
    ? mkValueText(opt.curValue, @(v) v, opt?.optDummy)
    : textInput(opt?.savedValue ?? opt.curValue,
      { maxChars = cfg?.maxChars, placeholder = opt?.placeholder, setValue = opt.setValue,
        textmargin = const [hdpx(6), hdpx(2)], password = opt?.password, charMaskTypes = opt?.charMaskTypes})
}

let optionRequirement = mkOptionRow(
  loc("password/req"),
  premiumImage(hdpx(40)), { valign = ALIGN_CENTER },
  premiumWnd)

let mkOption = @(option) function () {
  let res = { watch = [option.cfg] }
  let cfg = option.cfg.get()
  if (cfg == null)
    return res

  let { isEditAllowed = true } = option
  let { optType, locId = null, isHidden = false } = cfg
  let hintText = loc($"{locId}/hint", "")

  return {
    watch = [option.cfg, isInRoom]
    size = FLEX_H
    children = isHidden ? optionRequirement
      : mkOptionRow(locId, {
          size = const [ pw(40), FLEX ]
          valign = ALIGN_CENTER
          children = optionCtor?[optType](option, cfg, (isInRoom.get() && !isEditAllowed))
        }, {
          onHover = hintText == "" ? null
            : @(on) setTooltip(on ? tooltipCtor({
                rendObj = ROBJ_TEXT
                color = defTxtColor
                text = hintText
              }.__update(fontSub)) : null)
        })
  }
}

function mkMultiSelect(opt, cfg, ctor) {
  if (cfg == null)
    return []

  let { optType, values = [] } = cfg
  if (optType != OPT_MULTISELECT) {
    logerr($"Option /*{opt.id}*/ support only multiselect mode in UI. (current option type: /*{optType}*/)")
    return []
  }

  let {
    curValue, valToString = @(v) v, typeToString = @(v) v, toggleValue
  } = opt
  return values.map(@(value) ctor(
    valToString(value),
    typeToString(value),
    @(isChecked) toggleValue(value, isChecked),
    Computed(@() (curValue.get() ?? []).contains(value)),
    value
  ))
}

let mkArmyImg = @(armyId) {
  rendObj = ROBJ_IMAGE
  size = armyImageSize
  keepAspect = KEEP_ASPECT_FILL
  imageHalign = ALIGN_CENTER
  imageValign = ALIGN_TOP
  image = Picture($"{armyImages[armyId]}:{armyImageSize[0]}:{armyImageSize[1]}")
  fallbackImage = Picture("ui/soldiers/army_default.avif")
  transitions = [ { prop = AnimProp.scale, duration = 0.4, easing = OutQuintic } ]
}

let cardTextBlock = @(label, typeTxt, sf, isSelected, params = {}) {
  rendObj = ROBJ_SOLID
  flow = FLOW_VERTICAL
  size = FLEX
  halign = ALIGN_RIGHT
  color = sf & S_HOVER ? defInsideBgColor : blurBgFillColor
  padding = bigPadding
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      size = FLEX
      behavior = Behaviors.TextArea
      color = txtColor(sf)
      text = label
    }.__update(fontHeading2, params?.label ?? {})
    {
      size = FLEX_H
      gap = smallPadding
      vplace = ALIGN_BOTTOM
      valign = ALIGN_CENTER
      children = [
        typeTxt == null ? null
          : {
              rendObj = ROBJ_TEXT
              color = txtColor(sf)
              text = typeTxt
            }.__update(fontBody)
        {
          size = [smallOffset, SIZE_TO_CONTENT]
          hplace = ALIGN_RIGHT
          children = isSelected.get() ? faComp("check") : null
        }
      ]
    }.__update(params?.sign ?? {})
  ]
}.__update(params)

let mkArmySelectBlock = @(label, _typeTxt, setValue, isSelected, value)
  watchElemState(@(sf) {
    watch = isSelected
    key = isSelected
    size = [armyCardWidth, armyCardWidth / IMAGE_RATIO]
    behavior = Behaviors.Button
    valign = ALIGN_CENTER
    onClick = function() {
      setValue(!isSelected.get())
      sound_play(isSelected.get() ? "ui/enlist/flag_set" : "ui/enlist/flag_unset")
    }
    children = [
      mkArmyImg(value)
      cardTextBlock(label, null, sf, isSelected, {
        flow = FLOW_HORIZONTAL
        vplace = ALIGN_BOTTOM
        size = FLEX_H
        minHeight = hdpx(48)
        label = { size = FLEX_H }
        sign = { size = FLEX_V }
      })
    ]
  })

let allertSign = {
  rendObj = ROBJ_IMAGE
  size = const [hdpx(30), hdpx(25)]
  image = Picture($"ui/uiskin/attention.avif")
  margin = bigPadding
  behavior = Behaviors.Button
  hplace = ALIGN_RIGHT
  onHover = @(on) setTooltip(on ? tooltipCtor({
    rendObj = ROBJ_TEXT
    color = defTxtColor
    text = loc("singleMissionAlert")
  }.__update(fontSub)) : null)
}

optMissions.curValue.subscribe(function(v) {
  if (prevGenPlatform) {
    let missionsWithAlert = []
    foreach (mission in v) {
      let { prevGenAlert = [] } = getMissionInfo(mission)
      if (prevGenAlert.contains(prevGenPlatform))
        missionsWithAlert.append(mission)
    }

    let count = missionsWithAlert.len()
    if (count > 0)
      showMsgbox(count > 1
        
        ? loc("manyMissionsAlert")
        : loc("singleMissionAlert"))
  }
})

function mkMissionCard(label, typeTxt, setValue, isSelected, value) {
  let { image, prevGenAlert = [] } = getMissionInfo(value)
  let resampledImage = $"{image}:{missionImageSize[0]}:{missionImageSize[1]}"
  let hasPrevgen = prevGenAlert.contains(prevGenPlatform)
  return watchElemState(@(sf) {
    watch = isSelected
    size = [missionsCardWidth, missionsCardHeight]
    behavior = Behaviors.Button
    flow = FLOW_VERTICAL
    onClick = function() {
      setValue(!isSelected.get())
      sound_play(isSelected.get() ? "ui/enlist/flag_set" : "ui/enlist/flag_unset")
    }
    children = [
      {
        rendObj = ROBJ_IMAGE
        size = missionImageSize
        image = Picture(resampledImage)
        keepAspect = KEEP_ASPECT_FILL
        children = hasPrevgen ? allertSign : null
      }
      cardTextBlock(label, typeTxt, sf, isSelected)
    ]
  })
}

function mkSelectArmyUi(items) {
  function renderRow() {
    let res = []
    local idx = 0
    while (idx < items.len()) {
      res.append({
        flow = FLOW_HORIZONTAL
        gap = localPadding
        children = items.slice(idx, idx + ARMIES_ITEMS_ROW)
      })
      idx += ARMIES_ITEMS_ROW
    }
    return res
  }
  return {
    size = [armyContentWidth / 2, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = localGap
    children = renderRow()
  }
}

let mkSelectUi = @(children, cfg) {
  size = FLEX_H
  watch = [cfg, selectedMissionType]
  children
}

let mkSelectArmy = @(options, content) function() {
  let cfg = {
    optType = OPT_MULTISELECT
    values = options.cfg.get().values
  }
  let children = mkSelectArmyUi(mkMultiSelect(options, cfg, content))

  return mkSelectUi(children, options.cfg)
}

let mkSelectMission = @(options, content, wrapP = null) function() {
  let cfg = {
    optType = OPT_MULTISELECT
    values = options.cfg.get().values.filter(function(blk) {
      let info = getMissionInfo(blk)
      return info.type == selectedMissionType.get()
    })
  }

  let children = makeVertScroll({ children = wrap(mkMultiSelect(options, cfg, content), wrapP) }, {
    size = const [SIZE_TO_CONTENT, missionsBlockHeight]
    styling = thinStyle
    rootBase = {
      key = "battlepassUnlocksRoot"
      behavior = Behaviors.Pannable
      wheelStep = 0.82
    }
  })

  return mkSelectUi(children, options.cfg)
}

let baseOptionsList = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  children = baseOptions.map(mkOption)
}

let roomInfoRow = @(block) function() {
  let { option, onClick } = block
  let res = { watch = [option.cfg, option.curValue] }
  let chosenValues = []
  let currentValue = option.curValue.get()
  if (option.cfg.get()?.optType != OPT_MULTISELECT)
    return res

  let {values, locId} = option.cfg.get()
  if (option.cfg.get().values.len() == 1)
    chosenValues.append(option.valToString(values[0]))
  else if (currentValue.len() == values.len() || currentValue.len() == 0)
    chosenValues.append(loc("options/any"))
  else {
    foreach (idx, val in currentValue) {
      if (idx >= infoRowsToShow)
        break
      chosenValues.append(option.valToString(val))
    }
    let count = currentValue.len() - infoRowsToShow
    if (count > 0)
      chosenValues.append(loc("options/andMore", { count }))
  }


  return res.__update({
    size = FLEX_H
    margin = [smallPadding, 0]
    gap = localGap
    minHeight = rowHeight
    children = watchElemState(@(sf) {
      rendObj = ROBJ_SOLID
      color = sf & S_HOVER ? defInsideBgColor : blurBgFillColor
      size = FLEX_H
      flow = FLOW_VERTICAL
      behavior = Behaviors.Button
      skipDirPadNav = true
      padding = [0, bigPadding]
      onClick
      children = [
        {
          rendObj = ROBJ_TEXT
          size = [SIZE_TO_CONTENT, rowHeight]
          text = loc(locId)
          hplace = ALIGN_CENTER
          valign = ALIGN_CENTER
          color = titleTxtColor
        }.__update(fontBody)
        {
          size = FLEX_H
          flow = FLOW_VERTICAL
          gap = localGap
          children = chosenValues.map(@(text) {
            rendObj = ROBJ_TEXT
            size = const [FLEX, hdpx(40)]
            clipChildren = true
            behavior = Behaviors.Marquee
            valign = ALIGN_CENTER
            color = defTxtColor
            text
          }.__update(fontBody))
        }
      ]
    })
  })
}

let modMissionTitle = is_console ? null : watchElemState(@(sf) {
  rendObj = ROBJ_SOLID
  watch = [modPath, receivedModInfos]
  color = sf & S_HOVER ? defInsideBgColor : blurBgFillColor
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  behavior = Behaviors.Button
  padding = [0, bigPadding]
  valign = ALIGN_CENTER
  margin = [smallPadding, 0]
  minHeight = rowHeight
  onClick = openCustomMissionWnd
  children = modPath.get() == ""
    ? {
        rendObj = ROBJ_TEXT
        text = loc("mods/noActive")
      }.__update(fontBody)
    : [
        {
          rendObj = ROBJ_TEXT
          size = FLEX_H
          color = titleTxtColor
          text = loc("Mods")
        }.__update(fontBody)
        {
          rendObj = ROBJ_TEXT
          size = const [flex(3), SIZE_TO_CONTENT]
          clipChildren = true
          behavior = Behaviors.Marquee
          color = defTxtColor
          halign = ALIGN_RIGHT
          text = receivedModInfos.get()?[modPath.get()].title
        }.__update(fontBody)
      ]
})

let armyInfoBlock = @(block, team) function() {
  let { option, onClick } = block
  let res = { watch = [option.cfg, option.curValue] }
  if (option.cfg.get()?.optType != OPT_MULTISELECT)
    return res

  let { locId, values } = option.cfg.get()
  let { defBgColor, hoverBgColor } = teamsColors[team]
  let armiesToShow = option.curValue.get().len() == 0 ? values : option.curValue.get()
  return res.__update({
    size = FLEX_H
    margin = [smallPadding, 0]
    gap = bigPadding
    children = watchElemState(@(sf) {
      rendObj = ROBJ_SOLID
      color = sf & S_HOVER ? hoverBgColor : defBgColor
      size = FLEX_H
      flow = FLOW_VERTICAL
      behavior = Behaviors.Button
      skipDirPadNav = true
      padding = [0, bigPadding]
      onClick
      children = [
        {
          rendObj = ROBJ_TEXT
          size = [SIZE_TO_CONTENT, rowHeight]
          text = loc(locId)
          hplace = team == 0 ? ALIGN_LEFT : ALIGN_RIGHT
          valign = ALIGN_CENTER
          color = titleTxtColor
        }.__update(fontBody)
        {
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          halign = team == 0 ? ALIGN_LEFT : ALIGN_RIGHT
          children = armiesToShow.map(@(v) mkArmyIcon(v, armyIconSize))
        }
      ]
    })
  })
}

let armiesSettingsInfo = {
  flow = FLOW_HORIZONTAL
  size = FLEX_H
  halign = ALIGN_CENTER
  borderWidth = 0
  gap = midPadding
  children = armiesInfoBlocks.map(@(v, team) armyInfoBlock(v, team))
}

let missionSettingsInfo = {
  size = FLEX_H
  halign = ALIGN_CENTER
  borderWidth = 0
  children = roomInfoRow({
    option = optMissions
    onClick = @() curTabById(TabsIds.MISSION_ID)
  })
}

let mainSettingsInfo = @() {
  watch = [isInRoom, isModAvailable, modPath]
  size = FLEX_H
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  borderWidth = 0
  children = [
    modPath.get() == "" ? armiesSettingsInfo : null
    missionSettingsInfo
  ].append(isInRoom.get() || !isModAvailable.get() ? null : modMissionTitle)
}

let applyButton = @(locId) Regular(loc(locId), editEventRoom, {
  hotkeys = [["^J:X", { description = { skip = true }}]]
})

function toggleMissionsFilter(missionType) {
  selectedMissionType.set(missionType)
}

function mkMissionsByType() {
  let missionsCfg = optMissions.cfg
  return Computed(function() {
    let { values = [] } = missionsCfg.get()
    let missions = {}
    values.each(function(blk) {
      let infoType = getMissionInfo(blk).type
      if (infoType not in missions)
        missions[infoType] <- []
      missions[infoType].append(blk)
    })

    return missions
  })
}

function mkMissionTypeSelectRow(missionType, missionsByType) {
  let isSelected = Computed(@() selectedMissionType.get() == missionType)
  let amountTotal = Computed(@() missionsByType.get()?[missionType].len() ?? 0)
  let curMissionsValue = optMissions.curValue
  let amountSelected = Computed(function() {
    local amount = 0
    let current = curMissionsValue.get()
    foreach (blk in missionsByType.get()?[missionType] ?? [])
      if (current.contains(blk))
        ++amount
    return amount
  })
  return watchElemState(@(sf) {
    rendObj = ROBJ_SOLID
    watch = [isSelected]
    size = [campaignsBlockWidth, rowHeight]
    flow = FLOW_HORIZONTAL
    behavior = Behaviors.Button
    color = isSelected.get() ? selectedPanelBgColor
      : sf & S_HOVER ? defInsideBgColor
      : blurBgFillColor
    valign = ALIGN_CENTER
    onClick = function() {
      toggleMissionsFilter(missionType)
      sound_play("ui/enlist/flag_set")
    }
    margin = [smallPadding, 0]
    padding = [0, bigPadding]
    children = [
      {
        rendObj = ROBJ_TEXTAREA
        size = FLEX_H
        behavior = Behaviors.TextArea
        color = isSelected.get() ? defTxtColor : txtColor(sf)
        text = loc(typeToLocId[missionType] ?? missionType)
      }.__update(fontBody)
      @() {
        watch = [amountTotal, amountSelected]
        rendObj = ROBJ_TEXT
        color = isSelected.get() ? defTxtColor : txtColor(sf)
        text = amountSelected.get() == 0 ? ""
          : loc("options/missionsAmount", { selected = amountSelected.get(),
              total = amountTotal.get() })
      }.__update(fontBody)
    ]
  })
}

function campaignsFiltersBlock() {
  let missionsByType = mkMissionsByType()
  return {
    size = const [campaignsBlockWidth, SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    children = missionTypes.map(@(id) mkMissionTypeSelectRow(id, missionsByType))
  }
}

let mkAllCurrentValuesButton = @(option) function() {
  let res = { watch = [option.cfg, option.curValue, selectedMissionType] }
  let { values = [], optType = null } = option.cfg.get()

  let selectedType = selectedMissionType.get()
  let missionValues = values.filter(@(blk) getMissionInfo(blk).type == selectedType)

  if (optType != OPT_MULTISELECT)
    return res
  local hasSelected = false
  local hasUnselected = false
  let curList = option.curValue.get()
  if (curList != null) {
    foreach (m in missionValues) {
      if (curList.contains(m))
        hasSelected = true
      else
        hasUnselected = true
    }
  }
  if (!hasSelected && !hasUnselected)
    return res

  function removeMissionValues() {
    option.setValue((curList ?? []).filter(@(blk) !missionValues.contains(blk)))
  }

  function addMissionValues() {
    let toAdd = []
    missionValues.each(function(blk) {
      if (!(curList ?? []).contains(blk))
        toAdd.append(blk)
    })
    toAdd.extend(curList ?? [])
    option.setValue(toAdd)
  }

  return res.__update({
    gap = localGap
    flow = FLOW_HORIZONTAL
    pos = [campaignsBlockWidth + localPadding, 0]
    children = [
      !hasUnselected ? null
        : Regular(loc("SelectAll"), addMissionValues, { hotkeys = [["^J:LT"]] })
      !hasSelected ? null
        : Regular(loc("DeselectAll"), removeMissionValues, { hotkeys = [["^J:RT"]] })
    ]
  })
}

function allArmyValuesButtons() {
  let armiesToChoose = optArmiesA.cfg.get().values.len() + optArmiesB.cfg.get().values.len()
  let selectedArmiesCount = optArmiesA.curValue.get().len() + optArmiesB.curValue.get().len()
  let hasSelected = selectedArmiesCount > 0
  let hasUnselected = selectedArmiesCount < armiesToChoose
  return {
    watch = [optArmiesA.cfg, optArmiesB.cfg, optArmiesA.curValue, optArmiesB.curValue]
    gap = localGap
    flow = FLOW_HORIZONTAL
    children = [
      hasUnselected ? Regular(loc("SelectAll"), selectAll, { hotkeys = [["^J:LT"]] }) : null
      hasSelected ? Regular(loc("DeselectAll"), unselectAll, { hotkeys = [["^J:RT"]] }) : null
    ]
  }
}

let lobbyPresetsButtons = @() {
  watch = [lobbyPresets, modPath]
  flow = FLOW_HORIZONTAL
  gap = localGap
  children = modPath.get() != "" ? null : [
    Regular(loc("Save settings"), openSaveWindow, { hotkeys = [["^J:LT"]] }),
    (lobbyPresets.get()?.len() ?? 0) == 0 ? null
      : Regular(loc("Choose settings"), openChooseWindow, { hotkeys = [["^J:RT"]] })
  ]
}

let gameStartButtons = @() {
  watch = [isInRoom, isModAvailable, optMaxPlayers.curValue, modPath]
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = localGap
  children = [
    !isModAvailable.get() || isInRoom.get() || is_console
      ? null
      : Regular(loc("Mods"), openCustomMissionWnd)
    modPath.get() != "" && optMaxPlayers.curValue.get() <= 1
      ? applyButton("Start local")
      : applyButton(isInRoom.get() ? "changeAttributesRoom" : "createRoom")
  ]
}

function mkArmiesBlock(team, content) {
  let { index, teamLocId } = team
  return {
    size = FLEX
    flow = FLOW_VERTICAL
    gap = bigPadding
    halign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_SOLID
        size = [FLEX, rowHeight]
        color = teamsColors[index].defBgColor
        padding = [0, localGap]
        children = {
          rendObj = ROBJ_TEXT
          text = loc(teamLocId)
          color = titleTxtColor
          vplace = ALIGN_CENTER
          hplace = index == 0 ? ALIGN_LEFT : ALIGN_RIGHT
        }.__update(fontBody)
      }
      content
    ]
  }
}

let wrapParams = {
  width = contentWidth
  hGap = localPadding
  vGap = localGap
  halign = ALIGN_CENTER
}

let tabsData = {
  [TabsIds.EVENT_ID] = {
    locId = "events/setting"
    content = {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap = localPadding
      children = [
        baseOptionsList
        mainSettingsInfo
      ]
    }
    buttons = [
      lobbyPresetsButtons
      gameStartButtons
    ]
  },

  [TabsIds.ARMY_ID] = {
    locId = "options/armies"
    content = {
      size = FLEX
      flow = FLOW_HORIZONTAL
      gap = localPadding
      children = teams.map(@(team)
        mkArmiesBlock(team, mkSelectArmy(team.armyOpt, mkArmySelectBlock)))
    }
    buttons = [
      allArmyValuesButtons
      gameStartButtons
    ]
  },

  [TabsIds.MISSION_ID] = {
    locId = "options/missions"
    content = {
      flow = FLOW_HORIZONTAL
      gap = localPadding
      size = FLEX
      children = [
        campaignsFiltersBlock
        mkSelectMission(optMissions, mkMissionCard, wrapParams)
      ]
    }
    buttons = [
      mkAllCurrentValuesButton(optMissions)
      gameStartButtons
    ]
  }
}

function switchTab(delta) {
  local newIdx = curTabIdx.get() + delta
  let len = activeTabIds.get().len()
  if (newIdx > len-1)
    newIdx = 0
  else if (newIdx < 0)
    newIdx = len-1
  if (newIdx >= 0 && newIdx < len)
    curTabIdx.set(newIdx)
}

let headerTabs = @() {
  watch = [activeTabIds, curTabIdx, isGamepad, optMissions.cfg]
  flow = FLOW_HORIZONTAL
  size = FLEX_H
  gap = localPadding
  margin = [localGap, 0,0,0]
  valign = ALIGN_CENTER
  children = activeTabIds.get()
    .map(@(tabId, idx)
      mkWindowTab(loc(tabsData[tabId].locId), @() curTabIdx.set(idx), idx == curTabIdx.get()))
    .insert(0, isGamepad.get() && curTabIdx.get() != 0 && activeTabIds.get().len() > 1
      ? mkHotkey("^J:LB", @() switchTab(-1))
      : null)
    .append(isGamepad.get() && curTabIdx.get() + 1 < activeTabIds.get().len()
      ? mkHotkey("^J:RB", @() switchTab(1))
      : null)
}

let createRoomContent = @() {
  watch = [curTabIdx, activeTabIds]
  flow = FLOW_VERTICAL
  gap = localGap
  halign = ALIGN_CENTER
  size = const [FLEX, contentHeight]
  children = [
    headerTabs
    tabsData?[activeTabIds.get()?[curTabIdx.get()]].content
  ]
}

let wndButtons = @() {
  watch = [isEditInProgress, curTabIdx, activeTabIds]
  size = FLEX_H
  vplace = ALIGN_BOTTOM
  children = isEditInProgress.get()
    ? waitingSpinner
    : tabsData?[activeTabIds.get()?[curTabIdx.get()]].buttons
}

let createRoomWnd = @() {
  watch = isInRoom
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = [wndWidth, SIZE_TO_CONTENT]
  padding = localPadding
  maxWidth = maxContentWidth
  color = blurBgColor
  flow = FLOW_VERTICAL
  children = [
    mkWindowHeader(
      isInRoom.get() ? loc("changeAttributesRoom") : loc("createRoom"),
      chooseRandom(getImagesFromMissions()),
      closeBtn({ onClick = close })
        .__update({ margin = [bigPadding, 0] })
    )
    createRoomContent
    wndButtons
  ]
}

function open() {
  currentPassword.set("")
  return addModalWindow({
    key = WND_UID
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = defInsideBgColor
    size = FLEX
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = createRoomWnd
    onClick = @() null
  })
}

if (isEditEventRoomOpened.get())
  open()
isEditEventRoomOpened.subscribe(@(v) v ? open() : removeModalWindow(WND_UID))
