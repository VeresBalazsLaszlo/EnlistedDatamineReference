import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "dasevents" import CmdChangeTimeOfDay, CmdSetCameraFov, CmdSetBloomThreshold, CmdSetChromaticAberrationOffset, CmdSetCinematicModeEnabled, CmdSetFilmGrain, CmdSetMotionBlurScale
  , CmdSetVignetteStrength, CmdSetDofIsFilmic, CmdSetDofBokehCorners, CmdSetDofBokehSize, CmdSetDofFStop, CmdSetDofFocalLength, CmdSetDofFocusDistance
  , CmdSetCameraDofEnabled, CmdWeather, CmdSetRain, CmdSetSnow, CmdSetLightning, CmdSetLenseFlareIntensity, CmdSetCinemaRecording
  , CmdSetCinematicSetSuperPixels, CmdSetCinematicCustomSettings, CmdSetCameraLerpFactor, CmdSetCinematicPostFxBloom, CmdSetCameraStopLerpFactor
from "screencap" import take_screenshot_nogui
from "videomode" import is_upsampling
from "%ui/popup/popupsState.nut" import addPopup
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/ui_library.nut" import *

let { chooseRandom } = require("%sqstd/rand.nut")






let levelTimeOfDay = mkEcsComputed({
  comps = [["cinematic_mode__dayTime", ecs.TYPE_FLOAT]]
  defVal = 0
})
let cameraFov = Watched(0)
let cameraLerpFactor = Watched(0)
let cameraStopLerpFactor = Watched(0)
let hasCameraLerpFactor = Watched(false)
let motionBlur = Watched(0)
let bloomEffect = Watched(0)
let filmGrain = Watched(0)
let abberation = Watched(0)
let vigneteEffect = Watched(0)
let isDofCameraEnabled = WatchedImmediate(false)
let isDofFilmic = Watched(false)
let isDofFocalActive = Watched(false)
let dofFocusDist = Watched(0)
let dofFocalLength = Watched(0)
let dofStop = Watched(0)
let dofBokeCount = Watched(0)
let dofBokeSize = Watched(0)
let dofFocalValToSafe = Watched(-1)
let weatherPreset = Watched(null)
let isSnow = Watched(false)
let isRain = Watched(false)
let isLightning = Watched(false)
let hasSnow = Watched(false)
let hasRain = Watched(false)
let hasLightning = Watched(false)
let isCinematicModeActive = Watched(false)
let lenseFlareIntensity = Watched(0)
let enablePostBloom = Watched(false)
let isCinemaRecording = Watched(false)
let superPixel = Watched(1)
let isCustomSettings = Watched(false)
let isSettingsChecked = Watched(false)
let isHudSettingsEnable = Watched(false)

ecs.register_es("ui_get_is_rain_or_snow_es",
  {
    [["onInit","onChange"]] = function(_eid, comp) {
      isRain.set(comp.cinematic_mode__rain)
      isSnow.set(comp.cinematic_mode__snow)
      isLightning.set(comp.cinematic_mode__lightning)
      hasRain.set(comp.cinematic_mode__hasRain)
      hasSnow.set(comp.cinematic_mode__hasSnow)
      hasLightning.set(comp.cinematic_mode__hasLightning)
    }
  },
  {
    comps_track=[
      ["cinematic_mode__rain", ecs.TYPE_BOOL],
      ["cinematic_mode__snow", ecs.TYPE_BOOL],
      ["cinematic_mode__lightning", ecs.TYPE_BOOL],
      ["cinematic_mode__hasRain", ecs.TYPE_BOOL],
      ["cinematic_mode__hasSnow", ecs.TYPE_BOOL],
      ["cinematic_mode__hasLightning", ecs.TYPE_BOOL],
    ]
  }
)


ecs.register_es("ui_camera_fov_track_es",
  {
    [["onInit","onChange"]] = function(_eid, comp) {
      if (!comp.camera__active)
        return
      cameraFov.set(comp.fovSettings)
      cameraStopLerpFactor.set(comp.replay_camera__stopInertia ?? cameraStopLerpFactor.get())
      cameraLerpFactor.set(comp.replay_camera__tpsLerpFactor ?? cameraLerpFactor.get())
      hasCameraLerpFactor.set(comp.replay_camera__tpsLerpFactor != null)
    }
  },
  {
    comps_track=[
      ["fovSettings", ecs.TYPE_FLOAT],
      ["camera__active", ecs.TYPE_BOOL],
      ["replay_camera__stopInertia", ecs.TYPE_FLOAT, null],
      ["replay_camera__tpsLerpFactor", ecs.TYPE_FLOAT, null],
    ]
  }
)

ecs.register_es("ui_dof_track_es",
  {
    [["onInit","onChange"]] = function(_eid, comp) {
      isDofCameraEnabled.set(comp.dof__on)
      isDofFilmic.set(comp.dof__is_filmic)
      dofFocusDist.set(comp.dof__focusDistance)
      dofFocalLength.set(comp.dof__focalLength_mm)
      dofStop.set(comp.dof__fStop)
      dofBokeCount.set(comp.dof__bokehShape_bladesCount)
      dofBokeSize.set(17.0 - comp.dof__bokehShape_kernelSize)
    }
  },
  {
    comps_track=[
      ["dof__on", ecs.TYPE_BOOL],
      ["dof__is_filmic", ecs.TYPE_BOOL],
      ["dof__focusDistance", ecs.TYPE_FLOAT],
      ["dof__focalLength_mm", ecs.TYPE_FLOAT],
      ["dof__fStop", ecs.TYPE_FLOAT],
      ["dof__bokehShape_bladesCount", ecs.TYPE_FLOAT],
      ["dof__bokehShape_kernelSize", ecs.TYPE_FLOAT],
    ],
    comps_rq=["is_dof"]
  }
)

ecs.register_es("ui_cinematic_mode_es",
  {
    [["onInit","onChange"]] = function(_eid, comp) {
      motionBlur.set(comp.motion_blur__scale)
      bloomEffect.set(1.0 - comp.bloom__threshold)
      abberation.set(1.0 - comp.cinematic_mode__chromaticAberration.z)
      filmGrain.set(comp.cinematic_mode__filmGrainMul)
      vigneteEffect.set(comp.cinematic_mode__vignetteStrength)
      weatherPreset.set(comp.cinematic_mode__weatherPreset)
      lenseFlareIntensity.set(comp.cinematic_mode__lenseFlareIntensity)
      enablePostBloom.set(comp.cinematic_mode__enablePostBloom)
      isCinemaRecording.set(comp.cinematic_mode__recording)
      isCustomSettings.set(comp.settings_override__useCustomSettings)
      isCinematicModeActive.set(true)
    },
    onDestroy = function(_eid, _comp) {
      motionBlur.set(0)
      bloomEffect.set(0)
      abberation.set(0)
      filmGrain.set(0)
      vigneteEffect.set(0)
      lenseFlareIntensity.set(0)
      enablePostBloom.set(false)
      weatherPreset.set(null)
      isCustomSettings.set(isSettingsChecked.get())
      isCinematicModeActive.set(false)
      isCinemaRecording.set(false)
    }
  },
  {
    comps_track=[
      ["cinematic_mode__lenseFlareIntensity", ecs.TYPE_FLOAT],
      ["motion_blur__scale", ecs.TYPE_FLOAT],
      ["bloom__threshold", ecs.TYPE_FLOAT],
      ["cinematic_mode__chromaticAberration", ecs.TYPE_POINT3],
      ["cinematic_mode__filmGrainNoise", ecs.TYPE_POINT3],
      ["cinematic_mode__filmGrainLut", ecs.TYPE_POINT4],
      ["cinematic_mode__filmGrainMul", ecs.TYPE_FLOAT],
      ["cinematic_mode__vignetteStrength", ecs.TYPE_FLOAT],
      ["cinematic_mode__weatherPreset", ecs.TYPE_STRING],
      ["cinematic_mode__recording", ecs.TYPE_BOOL],
      ["settings_override__useCustomSettings", ecs.TYPE_BOOL],
      ["cinematic_mode__enablePostBloom", ecs.TYPE_BOOL],
    ],
    comps_rq = [
      "cinematic_mode_tag",
    ]
  }
)

function changeWeatherPreset(preset) {
  if (preset != null)
    ecs.g_entity_mgr.broadcastEvent( CmdWeather({ preset }))
}


let weatherPresets = mkEcsComputed({
  comps = [["cinematic_mode__weatherPresetList", ecs.TYPE_STRING_LIST]]
})

let weatherPresetList = Computed(@() (weatherPresets.get() ?? []).map(@(v) {
  loc = loc($"weatherPreset/{v}")
  preset = v
  setValue = @(_) changeWeatherPreset(v)
}))

function setRandomWeather() {
  let presets = weatherPresetList.get()
  if (presets.len() <= 1)
    return
  let currentPreset = weatherPreset.get()
  local newPreset = ""
  while (currentPreset != newPreset && newPreset == "")
    newPreset = chooseRandom(presets).preset
  changeWeatherPreset(newPreset)
}

let changeDayTime = @(time)
  ecs.g_entity_mgr.broadcastEvent(CmdChangeTimeOfDay({ timeOfDay = time }))
let changeCameraFov = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetCameraFov({ fov = newVal.tointeger() }))
let changeCameraLerpFactor = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetCameraLerpFactor({ lerpFactor = newVal.tointeger() }))
let changeCameraStopLerpFactor = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetCameraStopLerpFactor({ stopLerpFactor = newVal }))
let changeBloom = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetBloomThreshold({ threshold = 1.0 - newVal }))
let changeAbberation = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetChromaticAberrationOffset({ offset = 1.0 - newVal }))
let changeFilmGrain = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetFilmGrain({ strength = newVal }))
let changeMotionBlur = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetMotionBlurScale({ scale = newVal }))
let changeVignette = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetVignetteStrength({ strength = newVal }))


let changeBoke = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetDofBokehCorners({ bokehCorners = newVal }))
let changeBokeSize = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetDofBokehSize({ bokehSize = 17.0 - newVal }))
let changeStop = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetDofFStop({ fStop = newVal }))
let changeFocalLength = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetDofFocalLength({ focalLength = newVal }))
let changeFocusDist = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetDofFocusDistance({ focusDistance = newVal }))
let changeLenseFlareIntensity = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetLenseFlareIntensity({ intensity = newVal }))
let setCinemaRecording = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetCinemaRecording({ enabled = newVal }))
let changePostBloom = @(newVal)
  ecs.g_entity_mgr.broadcastEvent(CmdSetCinematicPostFxBloom({ enabled = newVal }))
function changeSuperPixel(newVal) {
  superPixel.set(newVal.tointeger())
  ecs.g_entity_mgr.broadcastEvent(
    CmdSetCinematicSetSuperPixels({ super_pixels = newVal.tointeger() }))
}
let toggleCustomSettings = @() ecs.g_entity_mgr.broadcastEvent(
  CmdSetCinematicCustomSettings({ enabled = !isCustomSettings.get() }))

function takeScreenshot() {
  take_screenshot_nogui()
  addPopup({
    id = "cinema_screenshot_done_alert"
    text = loc("replay/screenshotDone")
    needPopup = true
    showTime = 2
  })
}

function makeScreenShot(){
  if (is_upsampling() && !isCustomSettings.get() && !isSettingsChecked.get())
    showMsgbox({
      text = loc("replay/screenshotWithDLSS"),
      buttons = [
        {
          text = loc("replay/setOptimalSettings")
          action = function() {
            toggleCustomSettings()
            takeScreenshot()
            isSettingsChecked.set(true)
          }
        },
        {
          text = loc("replay/screenshotAnyway")
          action = function() {
            takeScreenshot()
            isSettingsChecked.set(true)
          }
        }
      ]
    })
  else
    takeScreenshot()
}


let updateIsDofEnabled = @(v) ecs.g_entity_mgr.broadcastEvent(
  CmdSetCameraDofEnabled({ enabled = v }))

isDofFilmic.subscribe(function(v) {
  isDofCameraEnabled.set(v)
  ecs.g_entity_mgr.broadcastEvent(
    CmdSetDofIsFilmic({ isFilmic = v }))
})

isDofCameraEnabled.subscribe(@(v) updateIsDofEnabled(v))

isDofFocalActive.subscribe(function(v) {
  if (!v) {
    dofFocalValToSafe.set(dofFocalLength.get())
    changeFocalLength(-1)
  }
  else{
    changeFocalLength(dofFocalValToSafe.get())
    dofFocalLength.set(dofFocalValToSafe.get())
  }
})

enablePostBloom.subscribe(@(v) changePostBloom(v))


let updateCinematicMode = @() ecs.g_entity_mgr.broadcastEvent(
  CmdSetCinematicModeEnabled({ enabled = isCinematicModeActive.get()}))

isCinematicModeActive.subscribe(@(_v) updateCinematicMode())

let changeRain = @(v) ecs.g_entity_mgr.broadcastEvent(CmdSetRain({ enabled = v }))
let changeSnow = @(v) ecs.g_entity_mgr.broadcastEvent(CmdSetSnow({ enabled = v }))
let changeLightning = @(v) ecs.g_entity_mgr.broadcastEvent(CmdSetLightning({ enabled = v }))


isRain.subscribe(@(v) changeRain(v))
isSnow.subscribe(@(v) changeSnow(v))
isLightning.subscribe(@(v) changeLightning(v))

return {
  levelTimeOfDay
  cameraFov
  cameraLerpFactor
  cameraStopLerpFactor
  changeCameraStopLerpFactor
  hasCameraLerpFactor
  changeDayTime
  changeCameraFov
  changeCameraLerpFactor
  isRain
  isSnow
  isLightning
  isCinematicModeActive
  changeBloom
  changeAbberation
  changeFilmGrain
  changeMotionBlur
  changeVignette
  motionBlur
  bloomEffect
  filmGrain
  abberation
  vigneteEffect
  weatherPreset
  weatherPresetList
  isDofCameraEnabled
  isDofFilmic
  isDofFocalActive
  dofFocusDist
  dofFocalLength
  dofStop
  dofBokeCount
  dofBokeSize
  changeBoke
  changeBokeSize
  changeStop
  changeFocalLength
  changeFocusDist
  setRandomWeather
  setCinemaRecording
  isCinemaRecording
  hasSnow
  hasRain
  hasLightning
  changeWeatherPreset
  lenseFlareIntensity
  changeLenseFlareIntensity
  enablePostBloom
  changePostBloom
  changeRain
  changeSnow
  changeLightning
  changeSuperPixel
  makeScreenShot
  superPixel
  isHudSettingsEnable
}
