import "%ui/control/gui_buttons.nut" as JB
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/gameModes/getMissionInfo.nut" as getMissionInfo
from "%ui/gameModes/createEventRoomState.nut" import isInRoom
from "%ui/components/textButton.nut" import Regular
from "%ui/style/fontsStyle.nut" import fontSub, fontBody, fontTitle
from "%ui/options/onlineSettings.nut" import settings, onlineSettingUpdated
from "%ui/style/cursors.nut" import setTooltip
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/style/designConst.nut" import tinyOffset, smallOffset, smallPadding, defInsideBgColor, sidePadding, activeBgColor, idleBgColor
  , defBgColor, defTxtColor, titleTxtColor
from "%ui/soldiers/components/armyPackage.nut" import mkArmySimpleIcon
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/gameModes/eventModesState.nut" import isEventModesOpened
from "%ui/ui_library.nut" import *

let { optIsPrivate, optMode, optDifficulty, optMaxPlayers, optBotCount, optVoteToKick, optCluster, optCrossplay, optArmiesA, optArmiesB, optMissions } = require("%ui/gameModes/createEventRoomState.nut")

const MAX_MISSIONS = 6

let baseOptions = [
  optIsPrivate
  optMode
  optDifficulty
  optMaxPlayers
  optBotCount
  optVoteToKick
  optCluster
  optCrossplay
  optArmiesA
  optArmiesB
  optMissions
]

const WND_UID = "saveChooseLobbySettingsWnd"
const SLOTS_COUNT = 5
const PRESETS_ID = "mpRoom/presets"

let slotSize = [hdpx(140), hdpx(140)]
let slotColor = @(sf) sf & S_HOVER ? activeBgColor : idleBgColor


let lobbyPresets = Computed(@() settings.get()?[PRESETS_ID] ?? {})

let curGameMode = optMode.curValue
let lobbySelectPresets = Computed(function() {
  let presets = lobbyPresets.get()
  if (!isInRoom.get())
    return presets

  let curMode = curGameMode.get()
  return presets.filter(@(v) v.mode == curMode)
})

function removePresets() {
  settings.mutate(@(s) s.$rawdelete(PRESETS_ID))
}


isEventModesOpened.subscribe(function(opened) {
  if (!opened || !onlineSettingUpdated.get())
    return
  let needToRenewPresets = (settings.get()?[PRESETS_ID] ?? [])
    .findvalue(@(preset) optArmiesA.id not in preset) != null
  if (needToRenewPresets) {
    removePresets()
    showMsgbox(loc("lobby/presetsRenew"))
  }
})

let separator = { size = [FLEX, tinyOffset] }

let mkParamName = @(text) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text
}.__update(fontSub)

let mkParamVal = @(text) {
  rendObj = ROBJ_TEXT
  hplace = ALIGN_RIGHT
  color = titleTxtColor
  text
}.__update(fontSub)

let mkParamList = @(list, bottomTxt = null) {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  halign = ALIGN_RIGHT
  color = titleTxtColor
  text = bottomTxt == null ? list : "{0}\n{1}".subst(list, bottomTxt)
}

function savePreset(idx) {
  let res = {}
  foreach (opt in baseOptions)
    res[opt.id] <- opt.curValue.get()
  settings.mutate(function(set) {
    let saved = clone (set?[PRESETS_ID] ?? {})
    saved[idx.tostring()] <- res
    set[PRESETS_ID] <- saved
  })
  removeModalWindow(WND_UID)
}

function choosePreset(idx) {
  let preset = lobbyPresets.get()?[idx.tostring()] ?? {}
  foreach (opt in baseOptions) {
    let { id } = opt
    if (id in preset)
      opt.setValue(preset[id])
  }
  removeModalWindow(WND_UID)
}

function mkBaseOptRow(opt, preset) {
  let { id, cfg, valToString } = opt
  let val = preset?[id]
  return val == null ? null
    : @() {
        watch = cfg
        size = FLEX_H
        children = [
          mkParamName(loc(cfg.get().locId))
          mkParamVal(valToString(val))
        ]
      }
}

function mkArmiesList(opt, preset) {
  let { id, cfg } = opt
  let val = clone preset?[id]
  let armiesToShow = val.sort(@(a, b) a <=> b)
  return @() {
    watch = cfg
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = { size = FLEX }
    valign = ALIGN_CENTER
    children = [
      mkParamName(loc(cfg.get().locId))
      armiesToShow.len() == 0
        ? mkParamVal(loc("option/all"))
        : {
            flow = FLOW_HORIZONTAL
            gap = smallPadding
            children = armiesToShow.map(@(c) mkArmySimpleIcon(c, fontSub.fontSize))
          }
    ]
  }
}

function mkMissionText(m) {
  let mCfg = getMissionInfo(m)
  let mName = loc(mCfg.locId)
  let mTypeLocId = mCfg.typeLocId
  return mTypeLocId == null ? mName
    : loc("missionNameWithType", { mName, mType = loc(mTypeLocId) })
}

function mkMissionList(list) {
  let { cfg } = optMissions
  let visList = list.len() <= MAX_MISSIONS ? list
    : list.slice(0, MAX_MISSIONS)
  let bottomTxt = list.len() <= MAX_MISSIONS ? null
    : loc("options/andMore", { count = list.len() - MAX_MISSIONS })
  return @() {
    watch = cfg
    size = FLEX_H
    children = [
      mkParamName(loc(cfg.get().locId))
      list.len() == 0
        ? mkParamVal(loc("option/all"))
        : mkParamList("\n".join(visList.map(@(m) mkMissionText(m))), bottomTxt)
    ]
  }
}

let mkPresetInfo = @(preset, bottomTxt) {
  size = const [hdpx(550), SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  children = (preset == null ? [] 
    : [
        mkParamName(loc("lobbyPresetHeader")).__update(fontBody)
        separator
        mkBaseOptRow(optMode, preset)
        mkBaseOptRow(optDifficulty, preset)
        mkBaseOptRow(optMaxPlayers, preset)
        mkBaseOptRow(optBotCount, preset)
        mkBaseOptRow(optCluster, preset)
        separator
        mkArmiesList(optArmiesA, preset)
        mkArmiesList(optArmiesB, preset)
        mkMissionList(preset?[optMissions.id] ?? [])
        separator
        separator
      ]).append({
          rendObj = ROBJ_TEXTAREA
          size = FLEX_H
          behavior = Behaviors.TextArea
          color = titleTxtColor
          text = bottomTxt
        }.__update(fontBody))
}

function mkPresetSlot(curPresets, idx, onClick, bottomTxt) {
  let slotId = idx.tostring()
  let preset = curPresets?[slotId]
  return watchElemState(@(sf) {
    rendObj = ROBJ_BOX
    size = slotSize
    borderWidth = hdpx(1)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    fillColor = defBgColor
    borderColor = slotColor(sf)
    behavior = Behaviors.Button
    onHover = @(on) setTooltip(on ? tooltipCtor(mkPresetInfo(preset, bottomTxt)) : null)
    onClick
    children = {
      rendObj = ROBJ_TEXT
      text = preset == null ? loc("presetEmpty") : (idx + 1).tostring()
      color = slotColor(sf)
    }.__update(preset == null ? fontSub : fontTitle)
  })
}

let windowParams = {
  key = WND_UID
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = defInsideBgColor
  size = FLEX
  flow = FLOW_VERTICAL
  gap = smallOffset
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  onClick = @() null
}

let closeButton = Regular(loc("Cancel"), @() removeModalWindow(WND_UID), {
  hplace = ALIGN_CENTER
  hotkeys = [[$"^{JB.B} | Esc"]]
})

let openSaveWindow = @() addModalWindow({
  children = [
    mkParamVal(loc("header/saveLobbyPreset"))
      .__update(fontBody, { hplace = ALIGN_CENTER })
    function() {
      let curPresets = lobbyPresets.get()
      let presetsKeys = curPresets.keys().sort(@(a, b) a <=> b)
      let maxSlot = curPresets.len()
      if (maxSlot < SLOTS_COUNT)
        presetsKeys.append(maxSlot.tostring())
      return {
        watch = lobbyPresets
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = presetsKeys.map(function(idxKey) {
            let idx = idxKey.tointeger()
            let bottomTxt = loc("clickToSavePreset", {
              presetName = (idx + 1).tostring()
            })
            return mkPresetSlot(curPresets, idx, @() savePreset(idx), bottomTxt)
          })
      }
    }
    closeButton
  ]
}.__update(windowParams))

let openChooseWindow = @() addModalWindow({
  children = [
    mkParamVal(loc("header/chooseLobbyPreset"))
      .__update(fontBody, { hplace = ALIGN_CENTER })
    function() {
      let watch = lobbySelectPresets
      let curPresets = lobbySelectPresets.get()
      if (curPresets.len() == 0)
        return mkParamName(loc("header/noExactPresets"))
          .__update(fontBody, { watch, hplace = ALIGN_CENTER, margin = sidePadding })

      let presetsKeys = curPresets.keys().sort(@(a, b) a <=> b)
      return {
        watch
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = presetsKeys.map(function(idxKey) {
          let idx = idxKey.tointeger()
          let bottomTxt = loc("clickToChoosePreset", {
            presetName = (idx + 1).tostring()
          })
          return mkPresetSlot(curPresets, idx, @() choosePreset(idx), bottomTxt)
        })
      }
    }
    closeButton
  ]
}.__update(windowParams))

console_register_command(removePresets, "meta.resetLobbyPresets")

return {
  openSaveWindow
  openChooseWindow
  lobbyPresets
}