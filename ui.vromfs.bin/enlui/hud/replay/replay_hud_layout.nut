import "%ui/style/cursors.nut" as cursors
import "%ui/control/gui_buttons.nut" as JB
import "%ui/hud/state/vehicle_seats.nut" as vehicleSeats
import "console" as console
import "camera" as camera
import "%ui/hud/replay/mkReplayTimeLine.nut" as mkReplayTimeLine
import "%ui/components/faComp.nut" as faComp
import "%ui/components/mkToggle.nut" as mkToggle
import "%ui/components/mkCheckbox.nut" as mkCheckbox
import "%ui/hud/replay/mkReplaySlider.nut" as mkReplaySlider
import "%ui/hud/replay/mkReplayPopup.nut" as mkPopupBlock
import "%dngscripts/ecs.nut" as ecs
from "%ui/style/fontsStyle.nut" import fontHeading2, fontSub, fontBody
from "%ui/style/designConst.nut" import panelBgColor, largePadding, defTxtColor,
  midPadding, smallPadding, bigPadding, maxContentWidth, titleTxtColor, accentColor, smallBtnHeight
from "%ui/components/textButton.nut" import Regular, FARegular, Pressed
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/replay/replayState.nut" import replayCurTime, replayPlayTime, replayTimeSpeed,
  replayAvailableSpeeds, canShowReplayHud, isTpsFreeCamera, canShowGameHudInReplay, curSoldierInfo,
  isFreeInput, isAttachedToWeapon, FPS_CAMERA, TPS_CAMERA, TPS_FREE_CAMERA, activeCameraId, OPERATOR_CAMERA
from "string" import format
from "dasevents" import ReplaySetFpsCamera, ReplaySetFreeTpsCamera, ReplaySetTpsCamera,
  ReplayToggleFreeCamera, NextReplayTarget, ReplaySetOperatorCamera, CmdReplayRewind,
  CmdReplayRewindSaveState, CmdReplayRewindLoadState, ReplayTrackAttachToWeapon,
  ReplayTrackDetachFromWeapon
from "%ui/hud/state/interactive_state.nut" import setInteractiveElement
from "%ui/hud/state/local_player.nut" import localPlayerName
from "%ui/helpers/time.nut" import secondsToString
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/hud/huds/scores.nut" import showScores
from "%ui/components/soldiersUiComps.nut" import kindIcon
from "%ui/hud/replay/replayConst.nut" import replayBgColor
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/hud/replay/replayCinematicState.nut" import levelTimeOfDay, changeDayTime,
  changeCameraFov, cameraFov, isRain, isSnow, isLightning, isCinematicModeActive, changeBloom,
  changeAbberation, changeFilmGrain, changeMotionBlur, changeVignette, motionBlur, bloomEffect,
  filmGrain, abberation, vigneteEffect, weatherPreset, weatherPresetList, dofFocusDist,
  dofFocalLength, dofStop, dofBokeCount, dofBokeSize, changeBoke, changeBokeSize, changeStop,
  changeFocalLength, changeFocusDist, isDofCameraEnabled, isDofFilmic, isDofFocalActive,
  setRandomWeather, hasSnow, hasRain, hasLightning, lenseFlareIntensity, changeLenseFlareIntensity,
  setCinemaRecording, isCinemaRecording, changeSuperPixel, makeScreenShot, superPixel,
  changeCameraLerpFactor, cameraLerpFactor, hasCameraLerpFactor, enablePostBloom,
  cameraStopLerpFactor, changeCameraStopLerpFactor, isHudSettingsEnable
from "%ui/hud/replay/saveReplaySettings.nut" import savePreset, replayPresets, lastChosenPreset,
  deletePreset, MAX_PRESETS, saveToCurrentPreset, saveDefaultSettings, restoreDefaultSettings
from "%ui/components/mkSelection.nut" import mkSmallSelection
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid
from "%ui/helpers/remap_nick.nut" import remap_others
from "%dngscripts/platform.nut" import is_pc, is_win32, is_linux
from "videomode" import is_dx12
from "dagor.system" import DBGLEVEL
from "%ui/hud/menus/settings_menu.nut" import showSettingsMenu
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/hud/menus/game_menu.nut" import showGameMenu
from "%ui/popup/popupsState.nut" import addPopup
from "%ui/hud/state/hudOptionsState.nut" import showSelfAwards, showTeammateName,
  showTeammateMarkers, showCrosshairHints, showTips, showGameModeHints, showPlayerUI
from "%ui/state/safeArea.nut" import safeAreaVerPadding, safeAreaHorPadding
from "%ui/ui_library.nut" import *
from "%sqstd/frp.nut" import subscribeList

let isAdvancedSettingsActive = Watched(false)
let isNavigationBlockHidden = Watched(false)
let isAnyAdvancedSettingsOn = Computed(@() isDofCameraEnabled.get() || isCinematicModeActive.get())
let isAdvancedBtnEnabled = Computed(@() !showSettingsMenu.get())
let showAdvancedSettings = Computed(@() !showGameMenu.get()
  && canShowReplayHud.get()
  && isAdvancedSettingsActive.get()
  && !showSettingsMenu.get())

local lastReplayTimeSpeed = 1
let bottomMargin = [0, 0, hdpx(32), 0]
let isAllSettingsEnabled = Computed(@() !isCinemaRecording.get())
let isSnowAvailable = Computed(@() hasSnow.get() && isAllSettingsEnabled.get() )
let isRainAvailable = Computed(@() hasRain.get() && isAllSettingsEnabled.get() )
let isLightningAvailable = Computed(@() hasLightning.get() && isAllSettingsEnabled.get() )

let needShowCursor = Computed(@() (canShowReplayHud.get() || showScores.get())
  && !(isGamepad.get() && isFreeInput.get()))




let gamepad_cursors_hide = Cursor(@() null)

let replayBlockPadding = [largePadding, largePadding]
const soldierIconSize = hdpxi(24)
let hideHudBtnSize = [hdpx(30), hdpxi(56)]
const commonBtnHeight = hdpx(40)


let squareButtonStyle = { btnWidth = commonBtnHeight, btnHeight = commonBtnHeight }
let smallSquareButtonStyle = { btnWidth = smallBtnHeight * 3, btnHeight = smallBtnHeight}
let defTxtStyle = { color = defTxtColor }.__update(fontHeading2)
let titleTxtStyle = { color = titleTxtColor }.__update(fontBody)
let brightTxtStyle = { color = titleTxtColor }.__update(fontHeading2)
let hintTxtStyle = { color = defTxtColor }.__update(fontSub)
let headerTxtStyle = { color = titleTxtColor }.__update(fontBody)
let smallStyle = { btnHeight = smallBtnHeight }

ecs.register_es("replay_rewind_save_hud_state_es", {
  [[CmdReplayRewindSaveState]] = function(evt, _eid, _comp) {
    evt.state["showSelfAwards"] = showSelfAwards.get()
    evt.state["showTeammateName"] = showTeammateName.get()
    evt.state["showTeammateMarkers"] = showTeammateMarkers.get()
    evt.state["showCrosshairHints"] = showCrosshairHints.get()
    evt.state["showTips"] = showTips.get()
    evt.state["showGameModeHints"] = showGameModeHints.get()
    evt.state["showPlayerUI"] = showPlayerUI.get()
    evt.state["isHudSettingsEnable"] = isHudSettingsEnable.get()
  }
}, {}, {tags="playingReplay"})

ecs.register_es("replay_rewind_load_hud_state_es", {
  [[CmdReplayRewindLoadState]] = function(evt, _eid, _comp) {
    isHudSettingsEnable.set(evt.state?.isHudSettingsEnable ?? isHudSettingsEnable.get())
    showSelfAwards.set(evt.state?.showSelfAwards ?? showSelfAwards.get())
    showTeammateName.set(evt.state?.showTeammateName ?? showTeammateName.get())
    showTeammateMarkers.set(evt.state?.showTeammateMarkers ?? showTeammateMarkers.get())
    showCrosshairHints.set(evt.state?.showCrosshairHints ?? showCrosshairHints.get())
    showTips.set(evt.state?.showTips ?? showTips.get())
    showGameModeHints.set(evt.state?.showGameModeHints ?? showGameModeHints.get())
    showPlayerUI.set(evt.state?.showPlayerUI ?? showPlayerUI.get())
  }
}, {}, {tags="playingReplay"})

function timeSpeedIncrease(curTimeSpeed) {
  foreach (timeSpeed in replayAvailableSpeeds.get())
    if (curTimeSpeed < timeSpeed) {
      console.command($"app.timeSpeed {timeSpeed}")
      return
    }
}


function timeSpeedDecrese(curTimeSpeed) {
  for (local i = replayAvailableSpeeds.get().len() - 1; i >= 0; --i)
    if (curTimeSpeed > replayAvailableSpeeds.get()[i]) {
      console.command($"app.timeSpeed {replayAvailableSpeeds.get()[i]}")
      return
    }
}

let hideReplayHudBtn = FARegular("chevron-down", @() canShowReplayHud.set(false), {
  btnHeight = hideHudBtnSize[0]
  btnWidth = hideHudBtnSize[1]
  style = { defBgColor = panelBgColor }
})

let hideReplayBlock = {
  hplace = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = smallPadding
  halign = ALIGN_CENTER
  pos = [0, -hideHudBtnSize[0] / 2]
  children = [
    hideReplayHudBtn
    tipCmp({ inputId = "Replay.DisableHUD", style = { rendObj = null } })
  ]
}

let soldierInfo = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    @() {
      watch = localPlayerName
      rendObj = ROBJ_TEXT
      text = loc("replay/player", { player = remap_others(localPlayerName.get())})
    }.__update(brightTxtStyle)
    @() {
      watch = curSoldierInfo
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      valign = ALIGN_CENTER
      children = [
        kindIcon(curSoldierInfo.get()?.soldier__sClass, soldierIconSize ?? "")
        {
          rendObj = ROBJ_TEXT
          text = curSoldierInfo.get()?.name ?? ""
        }.__update(brightTxtStyle)
      ]
    }
  ]
}


let replayTiming = @() {
  watch = [replayCurTime, replayPlayTime]
  rendObj = ROBJ_TEXT
  text = $"{secondsToString(replayCurTime.get())} / {secondsToString(replayPlayTime.get())}"
}.__update(brightTxtStyle)


let replayTopBlock = @() {
  watch = replayPlayTime
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      children = [
        soldierInfo
        replayTiming
      ]
    }
    mkReplayTimeLine(replayCurTime, {
      min = 0
      max = replayPlayTime.get()
      canChangeVal = true
      setValue = @(time) ecs.g_entity_mgr.broadcastEvent(CmdReplayRewind({ time = time * 1000 }))
    })
  ]
}

let bottomHint = @(text) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(hintTxtStyle)

let mkSquareBtn = @(locId, action, btnHint) {
  flow = FLOW_VERTICAL
  gap = midPadding
  halign = ALIGN_CENTER
  children = [
    tipCmp({ inputId = btnHint, style = { rendObj = null } })
    FARegular(locId, action, squareButtonStyle)
  ]
}


let replayTimeControl = @() {
  watch = replayTimeSpeed
  flow = FLOW_HORIZONTAL
  gap = midPadding
  children = [
    replayTimeSpeed.get() <= 0
      ? mkSquareBtn("play", @() console.command($"app.timeSpeed {lastReplayTimeSpeed}"),
        "Replay.Pause")
      : mkSquareBtn("pause", function(){
          lastReplayTimeSpeed = replayTimeSpeed.get()
          console.command("app.timeSpeed 0")
        }, "Replay.Pause")
    mkSquareBtn("minus", @() timeSpeedDecrese(replayTimeSpeed.get()), "Replay.SpeedDown")
    {
      rendObj = ROBJ_TEXT
      text = format("x%.2f", replayTimeSpeed.get())
      size = [SIZE_TO_CONTENT, commonBtnHeight]
      valign = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
    }.__update(defTxtStyle)
    mkSquareBtn("plus", @() timeSpeedIncrease(replayTimeSpeed.get()), "Replay.SpeedUp")
  ]
}

let replayTimeBlock = {
  flow = FLOW_VERTICAL
  gap = midPadding
  halign = ALIGN_CENTER
  children = [
    replayTimeControl
    bottomHint(loc("replay/timeBlockHint"))
  ]
}

let canUseFPSCam = Computed(function(){
  let seat = vehicleSeats.get().data.findvalue(@(s) s?.owner.eid == watchedHeroEid.get())
  return seat?.order?.canPlaceManually ?? true
})

function toggleAttachToWeapon() {
  if (!isTpsFreeCamera.get())
    return
  let evt = isAttachedToWeapon.get() ? ReplayTrackDetachFromWeapon() : ReplayTrackAttachToWeapon()
  ecs.g_entity_mgr.sendEvent(camera.get_cur_cam_entity(), evt)
}

function setFirstCameraActive() {
  if (canUseFPSCam.get())
    ecs.g_entity_mgr.broadcastEvent(ReplaySetFpsCamera())
}

let camerasList = [
  {
    text = "1"
    id = FPS_CAMERA
    action = setFirstCameraActive
    handlers = { ["Replay.Camera1"] = @(_event) setFirstCameraActive()}
    hotkey = "1"
    isEnabled = canUseFPSCam
  }
  {
    text = "2"
    id = TPS_CAMERA
    action = @() ecs.g_entity_mgr.broadcastEvent(ReplaySetTpsCamera())
    handlers = { ["Replay.Camera2"] =
      @(_event) ecs.g_entity_mgr.broadcastEvent(ReplaySetTpsCamera()) }
    hotkey ="2"
  }
  {
    text = "3"
    id = TPS_FREE_CAMERA
    action = @() ecs.g_entity_mgr.broadcastEvent(ReplaySetFreeTpsCamera())
    handlers = { ["Replay.Camera3"] =
      @(_event) ecs.g_entity_mgr.broadcastEvent(ReplaySetFreeTpsCamera()) }
    hotkey ="3"
  }
  {
    text = "4"
    id = OPERATOR_CAMERA
    action = @() ecs.g_entity_mgr.broadcastEvent(ReplaySetOperatorCamera())
    handlers = { ["Replay.Camera4"] =
      @(_event) ecs.g_entity_mgr.broadcastEvent(ReplaySetOperatorCamera()) }
    hotkey ="4"
  }
]


function changeCamera(delta) {
  let curCameraIdx = camerasList.findindex(@(v) v.id == activeCameraId.get())
  if (curCameraIdx == null)
    return
  let newIdx = curCameraIdx + delta
  if (camerasList?[newIdx] != null)
    camerasList[newIdx].action()
}

let wndEventHandlers = {
  ["Replay.PrevCamera"] = @(_event) changeCamera(-1),
  ["Replay.NextCamera"] = @(_event) changeCamera(1),
  ["Replay.RecordVideo"] = @(_event) setCinemaRecording(!isCinemaRecording.get()),
  ["Replay.AdvancedSettings"] =
    @(_event) isAdvancedSettingsActive.set(!isAdvancedSettingsActive.get()),
  ["Replay.Next"] = @(_event) ecs.g_entity_mgr.sendEvent(camera.get_cur_cam_entity(),
    NextReplayTarget({ delta = 1 })),
  ["Replay.Prev"] = @(_event) ecs.g_entity_mgr.sendEvent(camera.get_cur_cam_entity(),
    NextReplayTarget({ delta = -1 })),
}

if (DBGLEVEL > 0)
  wndEventHandlers["Replay.AttachToWeapon"] <- @(_event) toggleAttachToWeapon()

camerasList.each(function(v) {
  let bindedKey = v.handlers.keys()[0]
  let bindedAction = v.handlers.values()[0]
  wndEventHandlers[bindedKey] <- bindedAction
})

function replayCameraControl() {
  let cameraHint = activeCameraId.get() == null ? loc("replay/selectCamera")
    : loc("replay/camera", { camera = loc($"replay/cameraType/{activeCameraId.get()}") })
  return {
    watch = [activeCameraId, canUseFPSCam]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = midPadding
    children = [
      {
        flow = FLOW_HORIZONTAL
        size = FLEX_H
        children = [
          { size = flex(1) }
          tipCmp({ inputId = "Replay.PrevCamera", style = { rendObj = null } })
          { size = flex(2) }
          tipCmp({ inputId = "Replay.NextCamera", style = { rendObj = null } })
          { size = flex(1) }
        ]
      }
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        children = camerasList.map(function(cam) {
          let isPressed = activeCameraId.get() == cam.id
          let btnParams = squareButtonStyle.__merge({
            hotkeys = [[cam.hotkey, cam.action]]
            isEnabled = cam?.isEnabled.get() ?? true
            eventHandlers = { ["Replay.AdvancedSettings"] =
              @(_event) isAdvancedSettingsActive.set(!isAdvancedSettingsActive.get()) }
          })
          return isPressed
            ? Pressed(cam.text, cam.action, btnParams)
            : Regular(cam.text, cam.action, btnParams)
        })
      }
      bottomHint(cameraHint)
    ]
  }
}


function mkBtnWithHint(btnParams) {
  let { text, action, btnHint, actionDesc, isBtnSelected = Watched(false),
    isBtnEnabled = Watched(true), eventHandlers = null } = btnParams
  return @() {
    watch = [isBtnSelected, isBtnEnabled]
    flow = FLOW_VERTICAL
    gap = midPadding
    halign = ALIGN_CENTER
    eventHandlers
    children = [
      tipCmp({ inputId = btnHint, style = { rendObj = null } })
      !isBtnEnabled.get() ? Regular(text, action, { isEnabled = false, btnHeight = commonBtnHeight })
        : isBtnSelected.get() ? Pressed(text, action, { btnHeight = commonBtnHeight})
        : Regular(text, action, { btnHeight = commonBtnHeight })
      bottomHint(actionDesc)
    ]
  }
}


let buttons = [
  {
    text = loc("replay/tracking")
    action = @() ecs.g_entity_mgr.broadcastEvent(ReplayToggleFreeCamera())
    btnHint = "Replay.ToggleCamera"
    actionDesc = loc("replay/trackingHint")
    isBtnSelected = isFreeInput
    isBtnEnabled = isTpsFreeCamera
  }
  DBGLEVEL > 0 ? {
    text = loc("replay/attachToWeapon")
    action = toggleAttachToWeapon
    btnHint = "Replay.AttachToWeapon"
    actionDesc = loc("replay/attachToWeaponHint")
    isBtnSelected = isAttachedToWeapon
    isBtnEnabled = isTpsFreeCamera
  } : null
  {
    text = loc("replay/teams")
    action = @() showScores.set(!showScores.get())
    btnHint = "HUD.Scores"
    actionDesc = loc("replay/teamsHint")
    isBtnSelected = showScores
  }
  {
    text = loc("replay/showHud")
    action = @() canShowGameHudInReplay.set(!canShowGameHudInReplay.get())
    btnHint = "Replay.DisableGameHUD"
    actionDesc = loc("replay/showHudHint")
    isBtnSelected = canShowGameHudInReplay
  }
  {
    text = loc("replay/advancedSettings")
    action = @() isAdvancedSettingsActive.set(!isAdvancedSettingsActive.get())
    btnHint = "Replay.AdvancedSettings"
    eventHandlers = { ["Replay.AdvancedSettings"] =
      @(_event) isAdvancedSettingsActive.set(!isAdvancedSettingsActive.get()) }
    actionDesc = loc("replay/advancedSettingsHint")
    isBtnSelected = isAdvancedSettingsActive
    isBtnEnabled = isAdvancedBtnEnabled
  }
]


let buttonsBlock = {
  flow = FLOW_HORIZONTAL
  gap = midPadding
  hplace = ALIGN_RIGHT
  valign = ALIGN_TOP
  children = buttons.filter(@(v) v != null).map(mkBtnWithHint)
}

let cinematicToggleBlock = @() {
  watch = isAllSettingsEnabled
  size = FLEX_H
  margin = bottomMargin
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    {
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = loc("replay/cinematicMode")
    }.__update(headerTxtStyle)
    mkToggle(isCinematicModeActive, isAllSettingsEnabled.get())
  ]
}


let mkSettingsHeader = @(text) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = FLEX_H
  text = utf8ToUpper(text)
}.__update(titleTxtStyle)


let enviromentSettings = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    mkSettingsHeader(loc("replay/environment"))
      @() {
        watch = [levelTimeOfDay, isAllSettingsEnabled]
        size = FLEX_H
        children = mkReplaySlider(levelTimeOfDay, loc("replay/dayTime"), {
            max = 24
            setValue = @(newTime) changeDayTime(newTime)
            valueToShow = secondsToString(levelTimeOfDay.get() * 60)
            isEnabled = isAllSettingsEnabled.get()
          })
      }
    function() {
      let wPreset = weatherPreset.get()
      let wHeader = wPreset != null
        ? loc("replay/wPreset", { preset = loc($"weatherPreset/{wPreset}")})
        : loc("replay/chooseWeather")
      return {
        watch = [weatherPresetList, weatherPreset, isAllSettingsEnabled]
        size = FLEX_H
        children = mkSmallSelection(weatherPresetList.get(), weatherPreset, {
          header = wHeader
          isEnabled = isAllSettingsEnabled.get()
        })
      }
    }
    @() {
      watch = [isSnowAvailable, isRainAvailable, isLightningAvailable]
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap = { size = FLEX }
      children = [
        mkCheckbox(isSnow, loc("replay/weatherSnow"), {
          isActive = isSnowAvailable.get()
          textParams = hintTxtStyle
          size = FLEX_H
        })
        mkCheckbox(isRain, loc("replay/weatherRain"), {
          isActive = isRainAvailable.get()
          textParams = hintTxtStyle
          size = FLEX_H
        })
        mkCheckbox(isLightning, loc("replay/weatherLightning"), {
          isActive = isLightningAvailable.get()
          textParams = hintTxtStyle
          size = FLEX_H
        })
      ]
    }
    @() {
      watch = [weatherPresetList, isAllSettingsEnabled]
      children = Regular(loc("replay/randomWeather"), setRandomWeather, smallStyle.__merge({
        isEnabled = isAllSettingsEnabled.get() && weatherPresetList.get().len() > 1
      }))
    }
  ]
}


let cameraSettingsBlock = @() {
  watch = [cameraFov, isAllSettingsEnabled, cameraLerpFactor, hasCameraLerpFactor]
  size = FLEX_H
  margin = bottomMargin
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    mkSettingsHeader(loc("replay/cameraSettings"))
    mkReplaySlider(cameraFov, loc("replay/cameraFov"), {
      setValue = @(newVal) changeCameraFov(newVal)
      min = 10
      max = 130
      isEnabled = isAllSettingsEnabled.get()
    })
    mkReplaySlider(cameraLerpFactor, loc("replay/cameraLerpFactor"), {
      setValue = @(newVal) changeCameraLerpFactor(newVal)
      min = 1
      max = 10
      isEnabled = isAllSettingsEnabled.get() && hasCameraLerpFactor.get()
    })
    mkReplaySlider(cameraStopLerpFactor, loc("replay/cameraStopLerpFactor"), {
      setValue = @(newVal) changeCameraStopLerpFactor(newVal)
      min = 0.75
      max = 0.99
      step = 0.01
      isEnabled = isAllSettingsEnabled.get() && isTpsFreeCamera.get()
    })
  ]
}

let mkToggleBlock = @(toggleWatch, label) @() {
  watch = isAllSettingsEnabled
  size = FLEX_H
  valign = ALIGN_CENTER
  margin = bottomMargin
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    {
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = label
    }.__update(headerTxtStyle)
    mkToggle(toggleWatch, isAllSettingsEnabled.get())
  ]
}
let dofToggleBlock = mkToggleBlock(isDofFilmic, loc("replay/dofMode"))
let hudToggleBlock = mkToggleBlock(isHudSettingsEnable, loc("replay/extendedHUD"))


let dofSettings = @() {
  watch = [isDofFocalActive, isAllSettingsEnabled]
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = bigPadding
  children =  [
    mkSettingsHeader(loc("replay/dofSettings"))
    mkReplaySlider(dofFocusDist, loc("replay/focusDist"), {
      min = 0.1
      max = 20
      setValue = @(newVal) changeFocusDist(newVal)
      isEnabled = isAllSettingsEnabled.get()
    })
    mkReplaySlider(dofStop, loc("replay/focusStop"), {
      min = 1
      max = 22
      setValue = @(newVal) changeStop(newVal)
      isEnabled = isAllSettingsEnabled.get()
    })
    mkReplaySlider(dofBokeCount, loc("replay/bokeCount"), {
      min = 3
      max = 15
      setValue = @(newVal) changeBoke(newVal)
      isEnabled = isAllSettingsEnabled.get()
    })
    mkReplaySlider(dofBokeSize, loc("replay/bokeSize"), {
      min = 1
      max = 16
      setValue = @(newVal) changeBokeSize(newVal)
      isEnabled = isAllSettingsEnabled.get()
    })
    mkCheckbox(isDofFocalActive, loc("replay/isFocalActive"), {
      isActive = isAllSettingsEnabled.get()
    })
    mkReplaySlider(dofFocalLength, loc("replay/focalLength"), {
      min = 12
      max = 300
      setValue = @(newVal) changeFocalLength(newVal)
      isEnabled = isDofFocalActive.get() && isAllSettingsEnabled.get()
    })
  ]
}

let hudSettings = @() {
  watch = isAllSettingsEnabled
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = bigPadding
  children =  [
    mkSettingsHeader(loc("replay/hudSettings"))
    mkCheckbox(showSelfAwards, loc("gameplay/self_awards"), {
      isActive = isAllSettingsEnabled.get()
    })
    mkCheckbox(showTeammateName, loc("gameplay/show_teammate_name"), {
      isActive = isAllSettingsEnabled.get()
    })
    mkCheckbox(showTeammateMarkers, loc("gameplay/show_teammate_markers"), {
      isActive = isAllSettingsEnabled.get()
    })
    mkCheckbox(showCrosshairHints, loc("gameplay/show_crosshair_hints"), {
      isActive = isAllSettingsEnabled.get()
    })
    mkCheckbox(showTips, loc("gameplay/show_tips"), {
      isActive = isAllSettingsEnabled.get()
    })
    mkCheckbox(showGameModeHints, loc("gameplay/show_game_mode_hints"), {
      isActive = isAllSettingsEnabled.get()
    })
    mkCheckbox(showPlayerUI, loc("gameplay/show_player_ui"), {
      isActive = isAllSettingsEnabled.get()
    })
  ]
}

let postProcessinSettings = @() {
  watch = isAllSettingsEnabled
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = [
    mkSettingsHeader(loc("replay/postProcessing"))
    mkReplaySlider(motionBlur, loc("replay/motionBlur"), {
      setValue = @(newVal) changeMotionBlur(newVal)
      step = 0.1
      isEnabled = isAllSettingsEnabled.get()
    })
    mkReplaySlider(bloomEffect, loc("replay/bloomEffect"), {
      setValue = @(newVal) changeBloom(newVal)
      step = 0.1
      isEnabled = isAllSettingsEnabled.get()
    })
    mkReplaySlider(filmGrain, loc("replay/filmicNoise"), {
      setValue = @(newVal) changeFilmGrain(newVal)
      step = 0.1
      isEnabled = isAllSettingsEnabled.get()
    })
    mkReplaySlider(abberation, loc("replay/chromaticAbb"), {
      setValue = @(newVal) changeAbberation(newVal)
      step = 0.1
      isEnabled = isAllSettingsEnabled.get()
    })
    mkReplaySlider(vigneteEffect, loc("replay/vignette"), {
      setValue = @(newVal) changeVignette(newVal)
      step = 0.1
      isEnabled = isAllSettingsEnabled.get()
    })
    mkReplaySlider(lenseFlareIntensity, loc("replay/lensFlare"), {
      setValue = @(newVal) changeLenseFlareIntensity(newVal)
      step = 0.1
      isEnabled = isAllSettingsEnabled.get()
    })
  ]
}


let mkSettingsBlock = @(watchedFlag, content) @(){
  watch = watchedFlag
  size = FLEX_H
  transform = { scale = watchedFlag.get() ? [1, 1] : [1, 0] }
  transitions = [ { prop = AnimProp.scale, duration = 0.4, easing = OutQuintic } ]
  margin = watchedFlag.get() ? bottomMargin : 0
  children = watchedFlag.get() ? content : null
}


function presetBlock() {
  let header = replayPresets.get().len() <= 0
    ? loc("replay/createPreset")
    : loc("replay/choosePreset")
  let preset = lastChosenPreset.get()
  return {
    watch = [replayPresets, lastChosenPreset, isAllSettingsEnabled]
    size = FLEX_H
    flow = FLOW_VERTICAL
    margin = bottomMargin
    gap = bigPadding
    children = [
      mkSmallSelection(replayPresets.get(), lastChosenPreset, {
        header = preset ?? header
        isEnabled = isAllSettingsEnabled.get()
      })
      @() {
        watch = [isAnyAdvancedSettingsOn, isAllSettingsEnabled]
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = smallPadding
        children = [
          Regular(loc("replay/savePreset"), savePreset, smallStyle.__merge({
            isEnabled = replayPresets.get().len() < MAX_PRESETS && isAnyAdvancedSettingsOn.get()
              && isAllSettingsEnabled.get()
            btnWidth = FLEX }))
          Regular(loc("replay/changePreset"),
            @() saveToCurrentPreset(lastChosenPreset.get()), smallStyle.__merge({
            isEnabled = lastChosenPreset.get() != null && isAllSettingsEnabled.get()
            btnWidth = FLEX}))
        ]
      }
      Regular(loc("replay/deletePreset"), @() deletePreset(lastChosenPreset.get()), smallStyle.__merge({
        isEnabled = lastChosenPreset.get() != null && isAllSettingsEnabled.get()
        btnWidth = FLEX
      }))
    ]
  }}


let makeScreenshotBlock = @() {
  watch = [isCinematicModeActive, isAllSettingsEnabled]
  size = FLEX_H
  halign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    @() {
      watch = superPixel
      size = FLEX_H
      children = mkReplaySlider(superPixel, loc("replay/suprePixel"), {
        min = 1
        max = 4
        setValue = changeSuperPixel
        isEnabled = isCinematicModeActive.get() && isAllSettingsEnabled.get()
        valueToShow = loc("common/amountShort", { count = superPixel.get() })
      })
    }
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      gap = { size = FLEX }
      valign = ALIGN_CENTER
      children = [
        tipCmp({ inputId = "Global.ScreenshotNoGUI", style = { rendObj = null }})
        FARegular("camera", makeScreenShot, {
          style = { defTxtColor =0xFF138808, hoverTxtColor = 0xFF138808 }
          isEnabled = isCinematicModeActive.get() && isAllSettingsEnabled.get()
        }.__update(smallSquareButtonStyle))
      ]
    }
  ]
}


const recordSignColor = 0xFFB00000
let recordBtnStyle = {
  defTxtColor = recordSignColor,
  hoverTxtColor = recordSignColor,
  activeTxtColor = recordSignColor
}

let recordVideoBlock = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = { size = FLEX }
  valign = ALIGN_CENTER
  children = [
    tipCmp({inputId = "Replay.RecordVideo", style = { rendObj = null }})
    @() {
      watch = [isCinemaRecording, isCinematicModeActive]
      children = FARegular("circle", @() setCinemaRecording(!isCinemaRecording.get()), {
        style = isCinemaRecording.get() ? { defTxtColor = recordSignColor } : recordBtnStyle
        isEnabled = isCinematicModeActive.get()
      }.__update(smallSquareButtonStyle))
    }
  ]
}

isCinemaRecording.subscribe(@(v) v ? null : addPopup({
  id = "cinema_recording_finish_alert"
  text = loc("replay/recordVideoFinished")
  needPopup = true
  showTime = 2
}))

let isVideoRecordingDisabled = is_linux || is_win32 || (is_pc && is_dx12())

let screenVideoBlock = @() {
  watch = isAllSettingsEnabled
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    mkCheckbox(enablePostBloom, loc("replay/enablePostBloom"), {
      isActive = isAllSettingsEnabled.get()
    })
    mkSettingsHeader(loc("replay/screenVideoHeader"))
    makeScreenshotBlock
    isVideoRecordingDisabled ? null : recordVideoBlock
  ]
}

let resetToDefaultBtn = @() {
  watch = isAllSettingsEnabled
  size = FLEX_H
  children = Regular(loc("replay/resetDefaultSettings"), restoreDefaultSettings, smallStyle.__merge({
    btnWidth = FLEX
    margin = bottomMargin
    isEnabled = isAllSettingsEnabled.get()
  }))
}

function advancedSettingsWnd() {
  let watch = showAdvancedSettings
  if (!showAdvancedSettings.get())
    return { watch }

  return {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    watch
    fillColor = replayBgColor
    size = const [fsh(42), SIZE_TO_CONTENT]
    margin = hdpx(62)
    hplace = ALIGN_RIGHT
    vplace = ALIGN_TOP
    onClick = @() null
    hotkeys = [[$"^{JB.B} | Esc", @() isAdvancedSettingsActive.set(false)]]
    onAttach = saveDefaultSettings
    children = makeVertScroll(
      {
        flow = FLOW_VERTICAL
        size = FLEX_H
        padding = const [hdpx(18), hdpx(32)]
        children = [
          cameraSettingsBlock
          cinematicToggleBlock
          mkSettingsBlock(Computed(@() is_pc && isCinematicModeActive.get()), screenVideoBlock)
          mkSettingsBlock(isCinematicModeActive, enviromentSettings)
          mkSettingsBlock(isCinematicModeActive, postProcessinSettings)
          dofToggleBlock
          mkSettingsBlock(isDofFilmic, dofSettings)
          hudToggleBlock
          mkSettingsBlock(isHudSettingsEnable, hudSettings)
          presetBlock
          resetToDefaultBtn
        ]
      }, {
        size = const [fsh(42), SIZE_TO_CONTENT],
        maxHeight = sh(70)
        rootBase = {
          behavior = Behaviors.Pannable
          wheelStep = 1
        }
        styling = thinStyle
    })
  }
}

let replayBottomBlock = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  valign = ALIGN_TOP
  gap = { size = FLEX, minWidth = midPadding }
  children = [
    replayTimeBlock
    replayCameraControl
    buttonsBlock
  ]
}


let replayNavigation = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  size = const [FLEX, fsh(21)]
  maxWidth = fsh(170)
  fillColor = replayBgColor
  children = [
    hideReplayBlock
    {
      size = FLEX
      flow = FLOW_VERTICAL
      gap = bigPadding
      padding = replayBlockPadding
      children = [
        replayTopBlock
        replayBottomBlock
      ]
    }
  ]
}


let hiddenNavigationBlock = watchElemState(function(sf) {
  let res = {
    watch = isNavigationBlockHidden
    onDetach = @() isNavigationBlockHidden.set(false)
  }
  if (isNavigationBlockHidden.get())
    return res

  return res.__update({
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillColor = sf & S_HOVER ? accentColor : replayBgColor
    padding = [midPadding, hdpx(12)]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = smallPadding
    vplace = ALIGN_BOTTOM
    transform = true
    animations = [
      { prop = AnimProp.opacity, from = 1, to = 0, duration = 1, delay = 4,
        play = true, onFinish = @() isNavigationBlockHidden.set(true) }
      { prop = AnimProp.opacity, from = 0, to = 0, delay = 4.9, duration = 1,
        play = true }
    ]
    children = [
      faComp("chevron-up", {
        fontSize = fontBody.fontSize
      })
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        children = [
          tipCmp({ inputId = "Replay.DisableHUD", style = { rendObj = null } })
          {
            rendObj = ROBJ_TEXT
            text = loc("replay/showReplayUi")
          }.__update(hintTxtStyle)
        ]
      }
    ]
  })
})

let replayNavigationBlock = @() {
  watch = canShowReplayHud
  size = FLEX_H
  halign = ALIGN_CENTER
  children = canShowReplayHud.get()
    ? replayNavigation
    : hiddenNavigationBlock
}


let setupInteractive = @(_ = null) setInteractiveElement("ReplayHud", isReplay.get() && canShowReplayHud.get())
subscribeList(setupInteractive, isReplay, canShowReplayHud)


return @() {
  watch = [needShowCursor, isFreeInput, showGameMenu, isGamepad, safeAreaHorPadding, safeAreaVerPadding]
  size = FLEX
  maxWidth = maxContentWidth
  padding = [safeAreaVerPadding.get(), safeAreaHorPadding.get()]
  key = "ReplayHud"
  eventHandlers = wndEventHandlers
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  cursor = needShowCursor.get() ? cursors.normal : (isGamepad.get() ? gamepad_cursors_hide : null)
  valign = ALIGN_BOTTOM
  behavior = isFreeInput.get() ? (showGameMenu.get() ? null : DngBhv.ReplayFreeCameraControl) : DngBhv.MenuCameraControl
  children = [
    mkPopupBlock({
      vplace = ALIGN_TOP
      hplace = ALIGN_LEFT
    })
    replayNavigationBlock
    advancedSettingsWnd
  ]
}
