from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/hud/replay/replayCinematicState.nut" import levelTimeOfDay, changeDayTime, changeCameraFov, cameraFov, isRain, isSnow, isCinematicModeActive
  , changeBloom, changeAbberation, changeFilmGrain, changeMotionBlur, changeVignette, motionBlur, bloomEffect
  , filmGrain, abberation, vigneteEffect, weatherPreset, changeWeatherPreset, isDofCameraEnabled, isDofFilmic
  , isDofFocalActive, dofFocusDist, dofFocalLength, dofStop, dofBokeCount, dofBokeSize, changeBoke
  , changeBokeSize, changeStop, changeFocalLength, changeFocusDist, isLightning, lenseFlareIntensity, changeLenseFlareIntensity
  , changeRain, changeSnow, changeLightning, enablePostBloom, changePostBloom, isHudSettingsEnable
from "dagor.time" import get_local_unixtime
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/hud/state/hudOptionsState.nut" import showSelfAwards, showTeammateName, showTeammateMarkers, showCrosshairHints, showTips, showGameModeHints, showPlayerUI
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/ui_library.nut" import *

let savedReplayPresets = mkOnlineSaveData("savedReplayPresets", @() {})
let savedReplayPresetsStored = savedReplayPresets.watch

let savedReplaysCount = mkOnlineSaveData("savedReplaysCount", @() 0)
let savedReplaysCountStored = savedReplaysCount.watch

const MSG_UID = "preset_delete_confirm"
const MAX_PRESETS = 6
let lastChosenPreset = Watched(null)
local cachedSettings = {}

let replaySettings = {
  levelTimeOfDay = {
    watch = levelTimeOfDay
    action = changeDayTime
  }
  cameraFov = {
    watch = cameraFov
    action = changeCameraFov
  }
  weatherPreset = {
    watch = weatherPreset
    action = changeWeatherPreset
  }
  isRain = {
    watch = isRain
    action = changeRain
  }
  isLightning = {
    watch = isLightning
    action = changeLightning
  }
  isSnow = {
    watch = isSnow
    action = changeSnow
  }
  isCinematicModeActive = {
    watch = isCinematicModeActive
    action = @(v) isCinematicModeActive.set(v)
  }
  motionBlur = {
    watch = motionBlur
    action = changeMotionBlur
  }
  bloomEffect = {
    watch = bloomEffect
    action = changeBloom
  }
  filmGrain = {
    watch = filmGrain
    action = changeFilmGrain
  }
  abberation = {
    watch = abberation
    action = changeAbberation
  }
  vigneteEffect = {
    watch = vigneteEffect
    action = changeVignette
  }
  lenseFlareIntensity = {
    watch = lenseFlareIntensity
    action = changeLenseFlareIntensity
  }
  enablePostBloom = {
    watch = enablePostBloom
    action = changePostBloom
  }
  isDofCameraEnabled = {
    watch = isDofCameraEnabled
    action = @(v) isDofCameraEnabled.set(v)
  }
  isDofFilmic = {
    watch = isDofFilmic
    action = @(v) isDofFilmic.set(v)
  }
  isDofFocalActive = {
    watch = isDofFocalActive
    action = @(v) isDofFocalActive.set(v)
  }
  dofFocusDist = {
    watch = dofFocusDist
    action = changeFocusDist
  }
  dofFocalLength = {
    watch = dofFocalLength
    action = changeFocalLength
  }
  dofStop = {
    watch = dofStop
    action = changeStop
  }
  dofBokeCount = {
    watch = dofBokeCount
    action = changeBoke
  }
  dofBokeSize = {
    watch = dofBokeSize
    action = changeBokeSize
  }
  showSelfAwards = {
    watch = showSelfAwards
    action = @(v) showSelfAwards.set(v)
  }
  showTeammateName = {
    watch = showTeammateName
    action = @(v) showTeammateName.set(v)
  }
  showTeammateMarkers = {
    watch = showTeammateMarkers
    action = @(v) showTeammateMarkers.set(v)
  }
  showCrosshairHints = {
    watch = showCrosshairHints
    action = @(v) showCrosshairHints.set(v)
  }
  showTips = {
    watch = showTips
    action = @(v) showTips.set(v)
  }
  showGameModeHints = {
    watch = showGameModeHints
    action = @(v) showGameModeHints.set(v)
  }
  showPlayerUI = {
    watch = showPlayerUI
    action = @(v) showPlayerUI.set(v)
  }
  isHudSettingsEnable = {
    watch = isHudSettingsEnable
    action = @(v) isHudSettingsEnable.set(v)
  }
}

let replayPresets = Computed(function() {
  let res = []
  savedReplayPresetsStored.get().each(@(val) res.append({
    val = val
    loc = loc("replay/preset", { preset = val.name })
    setValue = @(idx) lastChosenPreset.set(idx)
  }))
  return res.sort(@(a, b) a.val.creationTime <=> b.val.creationTime)
})


function savePreset() {
  let saved = clone savedReplayPresetsStored.get()
  let data = {}
  let presetNumber = savedReplaysCountStored.get() + 1
  let creationTime = get_local_unixtime()
  let curPreset = $"preset{presetNumber}"
  savedReplaysCount.setValue(presetNumber)
  foreach (key, val in replaySettings)
    data[key] <- val.watch.get()
  data.__update({
    pNumber = presetNumber
    name = presetNumber.tostring()
    creationTime
  })
  saved[curPreset] <- data
  savedReplayPresets.setValue(saved)
}


function loadPreset(presetIdx) {
  cachedSettings = {}
  let presetValues = replayPresets.get()?[presetIdx].val ?? {}
  presetValues.each(function(v, key){
    replaySettings?[key].action(v)
    cachedSettings[key] <- v
  })
}


function saveToCurrentPreset(presetIdx) {
  if (lastChosenPreset.get() == null)
    return
  let { pNumber = -1 } = replayPresets.get()?[presetIdx].val
  let presetKey = $"preset{pNumber}"
  let settingsToUpdate = replaySettings.map(@(val) val.watch.get())
  let creationTime = get_local_unixtime()
  settingsToUpdate.__update({
    pNumber
    name = pNumber.tostring()
    creationTime
  })
  let saved = clone savedReplayPresetsStored.get()
  saved[presetKey] <- settingsToUpdate
  savedReplayPresets.setValue(saved)
}

function deletePreset(presetIdx) {
  showMsgbox({
    uid = MSG_UID
    text = loc("replay/deletePresetConfirm", { preset = replayPresets.get()[presetIdx].loc })
    buttons = [
      { text = loc("Yes"),
        action = function() {
          let saved = clone savedReplayPresetsStored.get()
          let presetToDelete = $"preset{replayPresets.get()[presetIdx].val.pNumber}"
          saved.$rawdelete(presetToDelete)
          savedReplayPresets.setValue(saved)
          lastChosenPreset.set(null)
        }
        isCurrent = true
      }
      { text = loc("No")
        isCancel = true
      }
    ]
  })
}

lastChosenPreset.subscribe(@(v) loadPreset(v))

function resetHudSettings() {
  showSelfAwards.set(true)
  showTeammateName.set(true)
  showTeammateMarkers.set(true)
  showCrosshairHints.set(true)
  showTips.set(true)
  showGameModeHints.set(true)
  showPlayerUI.set(true)
}

let needResetHudSettings = keepref(Computed(@() isHudSettingsEnable.get() && isReplay.get()))
needResetHudSettings.subscribe(@(v) v ? resetHudSettings() : null)
if (isReplay.get() && !isHudSettingsEnable.get())
  resetHudSettings()

local defaultSettings = {}
function saveDefaultSettings() {
  if (defaultSettings.len() <= 0)
    defaultSettings = replaySettings.map(@(v) v.watch.get())
}

function restoreDefaultSettings() {
  isCinematicModeActive.set(false)
  replaySettings.each(function(setup, key) {
    if (key in defaultSettings)
      setup.action(defaultSettings[key])
  })
}


return {
  savePreset
  deletePreset
  lastChosenPreset
  replayPresets
  MAX_PRESETS
  saveToCurrentPreset
  saveDefaultSettings
  restoreDefaultSettings
}
