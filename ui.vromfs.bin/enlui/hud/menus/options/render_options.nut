import "%dngscripts/platform.nut" as platform
from "%ui/hud/menus/options/renderOptionsState.nut" import addOptionVarInfo
from "%ui/hud/menus/options/antialiasing_state.nut" import AA_MODE_BLK_PATH, antiAliasingMode, antiAliasingModeDefaultValue, antiAliasingModeValue, antiAliasingModeAvailable, antiAliasingModeSetValue, antiAliasingModeValueToString
  , getFgHintFromAntiAliasingMode, AA_PRESET_BLK_PATH, upscalingPresetDefaultValue, upscalingPresetValue, upscalingPresetAvailable, upscalingPresetSetValue, upscalingPresetValueToString
  , AA_FGC_BLK_PATH, frameGenerationMode, fgcDefaultMode, fgcValue, fgcAvailable, fgcSetValue, fgcUnsupportedReason, fgcValueToString
  , AA_DLSS_RR_BLK_PATH, dlssRRDefaultValue, dlssRRAvailable, dlssRRValue, dlssRRSetValue
  , AA_DLSS_LEGACY_MODEL_BLK_PATH, dlssLegacyModeDefaultValue, dlssLegacyModeAvailable, dlssLegacyModeValue, dlssLegacyModeSetValue
from "math" import floor, round
from "settings" import get_setting_by_blk_path
from "%ui/state/safeArea.nut" import safeAreaAmount, safeAreaBlkPath, safeAreaSetAmount, safeAreaCanChangeInOptions
from "dagor.system" import DBGLEVEL
from "%ui/hud/menus/options/options_lib.nut" import loc_opt, defCmp, getOnlineSaveData, mkSliderWithText, optionPercentTextSliderCtor, optionCheckBox, optionCombo
  , mkDisableableCtor, optionSpinner, optionCtor, mkOptionWarning
from "%ui/hud/menus/options/resolution_state.nut" import resolutionList, resolutionValue, defVideoMode, originalValVideoMode, videoModeVar
from "%ui/hud/menus/options/low_latency_options.nut" import LOW_LATENCY_BLK_PATH__NVIDIA, LOW_LATENCY_BLK_PATH__AMD, LOW_LATENCY_BLK_PATH__INTEL, LOW_LATENCY_OFF, lowLatencySetValue_NV, lowLatencySetValue_AMD, lowLatencySetValue_Intel
  , lowLatencyValue_NV, lowLatencyValue_AMD, lowLatencyValue_Intel, lowLatencyAvailable, lowLatencySupported, isVsyncEnabledFromLowLatency
from "%ui/hud/menus/options/performance_metrics_options.nut" import PERF_METRICS_BLK_PATH, PERF_METRICS_FPS, perfMetricsAvailable, perfMetricsValue, perfMetricsSetValue
from "videomode" import is_dx12, is_vulkan, is_hdr_available, is_hdr_enabled, change_paper_white_nits, change_gamma, is_gui_driver_select_enabled
  , get_default_static_resolution_scale, is_only_low_gi_supported, is_rt_supported, rt_support_error_code, is_nvidia_gpu, is_amd_gpu, is_intel_gpu, get_vsync_refresh_rate
from "%ui/hud/menus/options/monitor_state.nut" import monitorValue, get_friendly_monitor_name
from "%ui/hud/menus/options/fps_list.nut" import fpsList, UNLIMITED_FPS_LIMIT
from "%ui/hud/menus/options/quality_preset_common.nut" import isBareMinimum
from "%ui/hud/menus/options/quality_preset_console_options.nut" import isConsoleBareMinimum
from "%ui/hud/state/hudOptionsState.nut" import fontKillLog, fontKillLogSetValue
from "%ui/ui_library.nut" import *
from "%sqstd/string.nut" import toFloatSafe
from "%ui/hud/menus/options/options_lib.nut" import optionSlider
from "%ui/state/safeArea.nut" import safeAreaList
from "%ui/hud/menus/options/low_latency_options.nut" import lowLatencyToString
from "%ui/hud/menus/options/performance_metrics_options.nut" import perfMetricsToString
from "%ui/hud/menus/options/monitor_state.nut" import availableMonitors

let resolutionToString = @(v) typeof v == "string" ? v : $"{v[0]} x {v[1]}"

const gammaBlkPath = "graphics/gamma_correction"
let gammaCorrectionSave = getOnlineSaveData(gammaBlkPath,
  @() get_setting_by_blk_path(gammaBlkPath) ?? 1.0,
  @(p) clamp(p, 0.5, 1.5)
)

let isBareMinimumPlatformSpecific = Computed(@() platform.is_pc ? isBareMinimum.get() : isConsoleBareMinimum.get())
let bareOffText = Computed(@() isBareMinimumPlatformSpecific.get() ? loc("option/off") : null)
let bareLowText = Computed(@() isBareMinimumPlatformSpecific.get() ? loc("option/low") : null)
let rtOptionsValid = Computed(@() is_rt_supported() && !isBareMinimumPlatformSpecific.get())
const BVH_NOT_SUPPORTED = 2
const BVH_NOT_ENOUGH_MEMORY = 3
const BVH_BLACKLISTED_GPU = 4
let rtErrorCode = rt_support_error_code();
let rtOffText = Computed(@() !rtOptionsValid.get() ? (rtErrorCode == BVH_NOT_SUPPORTED ? loc("option/rt_not_supported") :
                                                     (rtErrorCode == BVH_NOT_ENOUGH_MEMORY ? loc("option/rt_not_enough_memory") :
                                                     (rtErrorCode == BVH_BLACKLISTED_GPU ? loc("option/rt_too_slow_gpu") :
                                                                                           loc("option/off"))))
                                                   : null)

let consoleGfxSettingsBlk = get_setting_by_blk_path("graphics/consoleGfxSettings")
let consoleSettingsEnabled = (consoleGfxSettingsBlk != null) && (consoleGfxSettingsBlk == true)

let isOptAvailable = @() platform.is_pc || (DBGLEVEL > 0 && (platform.is_sony || platform.is_xbox) && consoleSettingsEnabled)
let isPcDx12 = @() platform.is_pc && is_dx12()
let isFGOptAvailable = @() platform.is_pc && (is_dx12() || is_vulkan())
let isDriverOptAvailable = @() platform.is_win64 && is_gui_driver_select_enabled()
let isDevBuild = @() platform.is_pc && DBGLEVEL != 0
let isRTOptAvailable = @() platform.is_pc && (is_dx12() || is_vulkan())

let enableAllRTFeaturesValue = get_setting_by_blk_path("graphics/enableAllRTFeatures") ?? false

const defDriver = "auto"
let originalDriverValue = get_setting_by_blk_path("video/driver") ?? defDriver
let driverValue = Watched(originalDriverValue)

let optSafeArea = optionCtor({
  name = loc("options/safeArea")
  widgetCtor = optionSpinner
  tab = "Graphics"
  isAvailable = safeAreaCanChangeInOptions
  blkPath = safeAreaBlkPath
  var = safeAreaAmount
  setValue = safeAreaSetAmount
  defVal = 1.0
  available = safeAreaList
  valToString = @(s) $"{s*100}%"
  isEqual = defCmp
  restart = false
  reload = true
  hint = loc("guiHints/safeArea")
})

let optDriver = optionCtor({
  name = loc("options/driver")
  widgetCtor = optionSpinner
  tab = "Graphics"
  blkPath = "video/driver"
  isAvailable = isDriverOptAvailable
  defVal = "auto"
  var = driverValue
  available = ["auto", "dx11", "dx12"]
  restart = true
  valToString = loc_opt
  hint = loc("guiHints/driver")
})

function get_available_window_modes() {
  if (platform.is_windows) {
    if (platform.is_gdk)
      return ["windowed", "fullscreenwindowed"]
    return ["windowed", "fullscreenwindowed", "fullscreen"]
  }
  return ["windowed", "fullscreen"]
}

let optVideoMode = optionCtor({
  name = loc("options/mode")
  widgetCtor = optionSpinner
  tab = "Graphics"
  blkPath = "video/mode"
  isAvailable = isOptAvailable
  defVal = defVideoMode
  available = get_available_window_modes()
  originalVal = originalValVideoMode
  var = videoModeVar
  restart = !platform.is_windows && !platform.is_linux
  valToString = @(s) loc($"options/mode_{s}")
  isEqual = defCmp
  hint = loc("guiHints/mode")
})

let optMonitorSelection = optionCtor({
  name = loc("options/monitor", "Monitor")
  widgetCtor = mkDisableableCtor(
    Computed(@() videoModeVar.get() == "windowed" ? loc("options/auto") : null),
    optionSpinner)
  tab = "Graphics"
  blkPath = "video/monitor"
  isAvailable = isOptAvailable
  defVal = availableMonitors.current
  available = availableMonitors.list
  originalVal = availableMonitors.current
  var = monitorValue
  valToString = @(v) (v == "auto") ? loc("options/auto") : get_friendly_monitor_name(v)
  isEqual = defCmp
  hint = loc("guiHints/monitor")
})

videoModeVar.subscribe(function(val){
  if (["fullscreenwindowed", "fullscreen"].contains(val))
    resolutionValue.set("auto")
  else
    monitorValue.set("auto")
})

let normalize_res_string = @(res) typeof res == "string" ? res.replace(" ", "") : res

let optResolution = optionCtor({
  name = loc("options/resolution")
  widgetCtor = optionCombo
  tab = "Graphics"
  originalVal = resolutionValue
  blkPath = "video/resolution"
  isAvailable = isOptAvailable
  var = resolutionValue
  defVal = resolutionValue
  available = resolutionList
  restart = !(platform.is_windows || platform.is_xboxone)
  valToString = @(v) (v == "auto") ? loc("options/auto") : "{0} x {1}".subst(v[0], v[1])
  isEqual = function(a, b) {
    if (typeof a == "string" || typeof b == "string")
      return normalize_res_string(a) == normalize_res_string(b)
    return a[0]==b[0] && a[1]==b[1]
  }
  convertForBlk = resolutionToString
  hint = loc("guiHints/resolution")
})

let optHdr = optionCtor({
  name = loc("options/hdr", "HDR")
  tab = "Graphics"
  blkPath = "video/enableHdr"
  isAvailable = @() isPcDx12() || platform.is_sony || is_vulkan()
  restart = platform.is_sony
  widgetCtor = mkDisableableCtor(
    Computed(@() is_hdr_available(monitorValue.get()) ? null : "{0} ({1})".subst(loc("option/off"), loc("option/monitor_does_not_support", "Monitor doesn't support"))),
    optionCheckBox)
  defVal = false
  hint = loc("guiHints/enableHdr")
})

let hdrWatched = optHdr.var

const MIN_PAPER_WHITE_NITS = 100
const MAX_PAPER_WHITE_NITS = 1000
const PAPER_WHITE_NITS_STEP = 10
const DEF_PAPER_WHITE_NITS = 200

const paperWhiteBlkPath = "video/paperWhiteNits"
let paperWhiteOptData = getOnlineSaveData(paperWhiteBlkPath,
  @() get_setting_by_blk_path(paperWhiteBlkPath) ?? DEF_PAPER_WHITE_NITS,
  @(p) clamp(p.tointeger(), MIN_PAPER_WHITE_NITS, MAX_PAPER_WHITE_NITS))

let optPaperWhiteNits = optionCtor({
  name = loc("options/paperWhiteNits", "Paper White Nits")
  tab = "Graphics"
  isAvailableWatched = Computed(@() platform.is_xbox ? is_hdr_enabled()
                                                     : is_hdr_available(monitorValue.get()) && hdrWatched.get())
  widgetCtor = mkSliderWithText
  var = paperWhiteOptData.watch
  setValue = function(val) {
    paperWhiteOptData.setValue(val)
    change_paper_white_nits(val)
  }
  blkPath = paperWhiteBlkPath
  defVal = DEF_PAPER_WHITE_NITS
  min = MIN_PAPER_WHITE_NITS
  max = MAX_PAPER_WHITE_NITS
  step = PAPER_WHITE_NITS_STEP
  pageScroll = PAPER_WHITE_NITS_STEP
  hint = loc("guiHints/paperWhiteNits")
})

let optVsync = optionCtor({
  name = loc("options/vsync")
  tab = "Graphics"
  isAvailable = isOptAvailable
  widgetCtor = mkDisableableCtor(
    Computed(@() isVsyncEnabledFromLowLatency(lowLatencyValue_NV.get())
                   ? null
                   : "{0} ({1})".subst(loc("option/off"), loc("option/off_by_reflex"))),
    optionCheckBox)
  restart = !platform.is_windows
  blkPath = "video/vsync"
  defVal = false
  hint = loc("guiHints/vsync")
})

let vsyncWatched = optVsync.var
let vsyncOffText = Computed(@() isVsyncEnabledFromLowLatency(lowLatencyValue_NV.get()) && vsyncWatched.get() ? loc("option/vsyncOff", { value = get_vsync_refresh_rate()} ) : null)

let optFpsLimit = optionCtor({
  name = loc("options/fpsLimit")
  tab = "Graphics"
  isAvailable = isOptAvailable
  widgetCtor = mkDisableableCtor(vsyncOffText, optionCombo)
  blkPath = "video/fpsLimit"
  defVal = UNLIMITED_FPS_LIMIT
  available = fpsList
  restart = false
  valToString = @(v) (v == UNLIMITED_FPS_LIMIT) ? loc("option/off") : loc("options/fpsLimit/hertz", { value = v })
  convertForBlk = @(v) (v == UNLIMITED_FPS_LIMIT) ? 0 : floor(v + 0.5).tointeger()
  convertFromBlk = @(v) (v == 0) ? UNLIMITED_FPS_LIMIT : v
  hint = loc("guiHints/fpsLimit")
})

let optLatencyNVidia = optionCtor({
  name = loc("options/latency_nvidia", "NVIDIA Reflex Low Latency")
  tab = "Graphics"
  widgetCtor = mkDisableableCtor(
    Computed(@() lowLatencySupported.get()
                  ? null
                  : "{0} ({1})".subst(loc("option/off"), loc("option/unavailable"))),
    optionSpinner)
  isAvailable = @() is_nvidia_gpu() && isOptAvailable()
  blkPath = LOW_LATENCY_BLK_PATH__NVIDIA
  defVal = LOW_LATENCY_OFF
  var = lowLatencyValue_NV
  setValue = lowLatencySetValue_NV
  available = lowLatencyAvailable
  valToString = @(v) loc(lowLatencyToString[v])
  hint = loc("guiHints/latency_nvidia")
})

let optLatencyAMD = optionCtor({
  name = loc("options/latency_amd", "AMD Radeon Anti-Lag 2")
  tab = "Graphics"
  widgetCtor = mkDisableableCtor(
    Computed(@() lowLatencySupported.get()
                  ? null
                  : "{0} ({1})".subst(loc("option/off"), loc("option/unavailable"))),
    optionSpinner)
  isAvailable = @() is_amd_gpu() && isOptAvailable()
  blkPath = LOW_LATENCY_BLK_PATH__AMD
  defVal = LOW_LATENCY_OFF
  var = lowLatencyValue_AMD
  setValue = lowLatencySetValue_AMD
  available = lowLatencyAvailable
  valToString = @(v) loc(lowLatencyToString[v])
  hint = loc("guiHints/latency_amd")
})

let optLatencyIntel = optionCtor({
  name = loc("options/latency_intel", "Intel Xe Low Latency")
  tab = "Graphics"
  widgetCtor = mkDisableableCtor(
    Computed(@() lowLatencySupported.get() ?
                  (fgcValue.get() != frameGenerationMode.OFF ?
                    "{0} ({1})".subst(loc("option/on"), loc("option/forced_by_frame_generation")) :
                    null) :
                  "{0} ({1})".subst(loc("option/off"), loc("option/unavailable"))),
    optionSpinner)
  isAvailable = @() is_intel_gpu() && isOptAvailable()
  blkPath = LOW_LATENCY_BLK_PATH__INTEL
  defVal = LOW_LATENCY_OFF
  var = lowLatencyValue_Intel
  setValue = lowLatencySetValue_Intel
  available = lowLatencyAvailable
  valToString = @(v) loc(lowLatencyToString[v])
  hint = loc("guiHints/latency_intel")
})

let optPerformanceMetrics = optionCtor({
  name = loc("options/perfMetrics", "Performance Metrics")
  widgetCtor = optionSpinner
  tab = "Graphics"
  isAvailable = isOptAvailable
  blkPath = PERF_METRICS_BLK_PATH
  defVal = PERF_METRICS_FPS
  var = perfMetricsValue
  setValue = perfMetricsSetValue
  available = perfMetricsAvailable
  valToString = @(v) loc(perfMetricsToString[v])
  hint = loc("guiHints/perfMetrics")
})

let optRTSM = optionCtor(addOptionVarInfo({
  optId = "enableRTSM"
  name = loc("options/enableRTSM")
  blkPath = "graphics/enableRTSM"
  widgetCtor = mkDisableableCtor(rtOffText, optionSpinner)
  defVal = "off"
  tab = "Graphics"
  isAvailable = isRTOptAvailable
  available = ["off", "sun", "sun_and_dynamic"]
  restart = false
  valToString = loc_opt
  hint = loc("guiHints/enableRTSM")
}))

let rtsmWatched = optRTSM.var

let optRTR = optionCtor(addOptionVarInfo({
  optId = "enableRTR"
  name = loc("options/enableRTR")
  blkPath = "graphics/enableRTR"
  widgetCtor = mkDisableableCtor(Computed(@() rtOffText.get() ?? (dlssRRValue.get() ? "{0} ({1})".subst(loc("option/on"), loc("option/on_by_ray_reconstruction")) : null)), optionCheckBox)
  defVal = false
  tab = "Graphics"
  isAvailable = isRTOptAvailable
  restart = false
  hint = loc("guiHints/enableRTR")
}))

let rtrWatched = optRTR.var

let optRTTR = optionCtor(addOptionVarInfo({
  optId = "enableRTTR"
  name = loc("options/enableRTTR")
  blkPath = "graphics/enableRTTR"
  widgetCtor = mkDisableableCtor(rtOffText, optionCheckBox)
  defVal = false
  tab = "Graphics"
  isAvailable = isRTOptAvailable
  restart = false
  hint = loc("guiHints/enableRTTR")
}))

let ptgiOffText = Computed(@() rtOffText.get() ??
  (dlssRRValue.get() || enableAllRTFeaturesValue ? null : "{0} ({1})".subst(loc("option/off"), loc("option/requires_ray_reconstruction"))))

let optPTGI = optionCtor(addOptionVarInfo({
  optId = "enablePTGI"
  name = loc("options/enablePTGI")
  blkPath = "graphics/enablePTGI"
  widgetCtor = mkDisableableCtor(ptgiOffText, optionCheckBox)
  defVal = false
  tab = "Graphics"
  isAvailable = isRTOptAvailable
  restart = false
  hint = loc("guiHints/enablePTGI")
}))

let ptgiWatched = optPTGI.var

let optRTAO = optionCtor(addOptionVarInfo({
  optId = "enableRTAO"
  name = loc("options/enableRTAO")
  blkPath = "graphics/enableRTAO"
  widgetCtor = mkDisableableCtor(Computed(@() rtOffText.get() ??
    (ptgiWatched.get() && ptgiOffText.get() == null
      ? "{0} ({1})".subst(loc("option/off"), loc("option/off_by_ptgi"))
      : null)), optionCheckBox)
  defVal = false
  tab = "Graphics"
  isAvailable = isRTOptAvailable
  restart = false
  hint = loc("guiHints/enableRTAO")
}))

let rtaoWatched = optRTAO.var

let optRTWater = optionCtor(addOptionVarInfo({
  optId = "RTRWater"
  name = loc("options/RTRWater")
  blkPath = "graphics/RTRWater"
  widgetCtor = mkDisableableCtor(rtOffText, optionCheckBox)
  defVal = false
  tab = "Graphics"
  isAvailable = isRTOptAvailable
  restart = false
  hint = loc("guiHints/RTRWater")
}))

let optRTGI = optionCtor(addOptionVarInfo({
  optId = "enableRTGI"
  name = loc("options/enableRTGI")
  blkPath = "graphics/enableRTGI"
  widgetCtor = mkDisableableCtor(Computed(@() rtOffText.get() ??
    (ptgiWatched.get() && ptgiOffText.get() == null
      ? "{0} ({1})".subst(loc("option/off"), loc("option/off_by_ptgi"))
      : null)), optionCheckBox)
  defVal = false
  tab = "Graphics"
  isAvailable = @() isRTOptAvailable() && enableAllRTFeaturesValue
  restart = false
  hint = loc("guiHints/enableRTGI")
}))

let rtgiWatched = optRTGI.var

let optBVHDagdp = optionCtor(addOptionVarInfo({
  optId = "bvhDagdp"
  name = loc("options/bvhDagdp")
  blkPath = "graphics/bvhDagdp"
  widgetCtor = mkDisableableCtor(rtOffText, optionCheckBox)
  defVal = false
  tab = "Graphics"
  isAvailable = isRTOptAvailable
  restart = false
  hint = loc("guiHints/bvhDagdp")
}))

let optShadowsQualityVarInfo = addOptionVarInfo({
  optId = "shadowsQuality"
  name = loc("options/shadowsQuality", "Shadow Quality")
  blkPath = "graphics/shadowsQuality"
  widgetCtor = mkDisableableCtor(Computed(@() rtOptionsValid.get() && rtsmWatched.get() != "off" ? loc("option/rayTracedQuality") : bareLowText.get()), optionSpinner)
  defVal = "low"
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = [ "low", "medium", "high", "ultra" ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
  getMoreBlkSettings = function(val){
    return [
      {blkPath = "graphics/dynamicShadowsQuality", val = val.replace("low","medium")}
    ]
  }
  hint = loc("guiHints/shadowsQuality")
})
let optShadowsQualityObservable = optShadowsQualityVarInfo?.var
if (optShadowsQualityObservable)
  optShadowsQualityVarInfo.nameChild <- mkOptionWarning(
    Computed(@() optShadowsQualityObservable.get() == "ultra"),
    loc("settings/performance_warning"),
    loc("settings/shadow_warning"))
let optShadowsQuality = optionCtor(optShadowsQualityVarInfo)


let optLensFlares = optionCtor(addOptionVarInfo({
  optId = "lensFlares"
  name = loc("options/lensFlares", "Lens Flares")
  blkPath = "graphics/lensFlares"
  widgetCtor = mkDisableableCtor(bareOffText, optionCheckBox)
  defVal = false
  tab = "Graphics"
  isAvailable = @() true
  restart = false
  hint = loc("guiHints/lensFlares")
}))

let optChromaticAberration = optionCtor(addOptionVarInfo({
  optId = "chromaticAberration"
  name = loc("options/chromaticAberration")
  blkPath = "graphics/chromaticAberration"
  widgetCtor = mkDisableableCtor(bareOffText, optionCheckBox)
  defVal = false
  tab = "Graphics"
  isAvailable = @() true
  restart = false
  hint = loc("guiHints/chromaticAberration")
}))

let optFilmGrain = optionCtor(addOptionVarInfo({
  optId = "filmGrain"
  name = loc("options/filmGrain")
  blkPath = "graphics/filmGrain"
  widgetCtor = mkDisableableCtor(bareOffText, optionCheckBox)
  defVal = false
  tab = "Graphics"
  isAvailable = @() !platform.is_xboxone && !platform.is_ps4
  restart = false
  hint = loc("guiHints/filmGrain")
}))

let optMotionBlur = optionCtor(addOptionVarInfo({
  optId = "motionBlur"
  name = loc("options/motionBlur")
  blkPath = "graphics/motionBlurStrength"
  widgetCtor = mkDisableableCtor(bareOffText, optionPercentTextSliderCtor)
  defVal = 0.0
  min = 0.0
  max = 100.0
  unit = 5.0/100.0
  pageScroll = 5.0
  tab = "Graphics"
  isAvailable = @() !platform.is_xboxone && !platform.is_ps4
  restart = false
  hint = loc("guiHints/motionBlur")
  valToString = loc_opt
  isEqual = defCmp
}))

let optEffectsShadows = optionCtor(addOptionVarInfo({
  optId = "effectsShadows"
  name = loc("options/effectsShadows", "Shadows from Effects")
  blkPath = "graphics/effectsShadows"
  widgetCtor = mkDisableableCtor(bareOffText, optionCheckBox)
  defVal = true
  tab = "Graphics"
  isAvailable = isOptAvailable
  restart = false
  hint = loc("guiHints/effectsShadows")
}))

let optPhysicalShellCasings = optionCtor(addOptionVarInfo({
  optId = "physicalShellCasings"
  name = loc("options/physicalShellCasings", "Physical shell casings")
  blkPath = "graphics/physicalShellCasings"
  widgetCtor = mkDisableableCtor(bareOffText, optionCheckBox)
  defVal = false
  tab = "Graphics"
  isAvailable = isOptAvailable
  restart = false
  hint = loc("guiHints/physicalShellCasings")
}))


let giLowText = Computed(@() (isBareMinimum.get() || is_only_low_gi_supported()) ? loc("option/low") : null)

let optGiAlgorithm = optionCtor(addOptionVarInfo({
  optId = "giAlgorithm"
  name = loc("options/giAlgorithm")
  blkPath = "graphics/giAlgorithm"
  widgetCtor = mkDisableableCtor(Computed(@() rtOptionsValid.get() && ((ptgiWatched.get() && ptgiOffText.get() == null) || rtgiWatched.get()) ? loc("option/rayTracedQuality") : giLowText.get()), optionSpinner)
  defVal = "medium"
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = ["low", "medium", "high"]
  restart = false
  valToString = loc_opt
  hint = loc("guiHints/giAlgorithm")
}))

let optGiAlgorithmQuality = optionCtor(addOptionVarInfo({
  optId = "giAlgorithmQuality"
  name = loc("options/giAlgorithmQuality")
  blkPath = "graphics/giAlgorithmQuality"
  widgetCtor = optionSlider
  isEnabled = Computed(@() !isBareMinimum.get() && !is_only_low_gi_supported())
  defVal = 1.0
  tab = "Graphics"
  isAvailable = isOptAvailable
  min = 0.0 max = 1.0 unit = 0.01 pageScroll = 0.01
  restart = false
  hint = loc("guiHints/giAlgorithmQuality")
}))



let optSkiesQuality = optionCtor(addOptionVarInfo({
  optId = "skiesQuality"
  name = loc("options/skiesQuality", "Atmospheric Scattering Quality")
  blkPath = "graphics/skiesQuality"
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  defVal = "low"
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = [ "low", "medium", "high" ]
  restart = false
  valToString = loc_opt
  hint = loc("guiHints/skiesQuality")
}))


let optSsaoQualityVarInfo = addOptionVarInfo({
  optId = "aoQuality"
  name = loc("options/ssaoQuality", "Ambient Occlusion Quality")
  blkPath = "graphics/aoQuality"
  widgetCtor = mkDisableableCtor(Computed(@() rtOptionsValid.get() && ((ptgiWatched.get() && ptgiOffText.get() == null) || rtaoWatched.get()) ? loc("option/rayTracedQuality") : bareOffText.get()), optionSpinner)
  defVal = "medium"
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = [ "low", "medium", "high" ]
  valToString = loc_opt
  restart = false
  isEqual = defCmp
  hint = loc("guiHints/aoQuality")
})
let optSsaoQualityObservable = optSsaoQualityVarInfo?.var
if (optSsaoQualityObservable)
  optSsaoQualityVarInfo.nameChild <- mkOptionWarning(
    Computed(@() optSsaoQualityObservable.get() == "ultra"),
    loc("settings/performance_warning"),
    loc("settings/ssao_warning"))
let optSsaoQuality = optionCtor(optSsaoQualityVarInfo)


let optObjectsDistanceMul = optionCtor(addOptionVarInfo({
  optId = "objectsDistanceMul"
  name = loc("options/objectsDistanceMul")
  blkPath = "graphics/objectsDistanceMul"
  widgetCtor = optionSlider
  defVal = 1.0
  tab = "Graphics"
  isAvailable = isDevBuild
  min = 0.0 max = 1.5 unit = 0.05 pageScroll = 0.05
  restart = false
  getMoreBlkSettings = function(val){
    return [
      {blkPath = "graphics/rendinstDistMul", val = val},
      {blkPath = "graphics/riExtraMulScale", val = val}
    ]
  }
}))

let optCloudsQualityVarInfo = addOptionVarInfo({
  optId = "cloudsQuality"
  name = loc("options/cloudsQuality", "Clouds Quality")
  blkPath = "graphics/cloudsQuality"
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  defVal = "default"
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = [ "default", "highres", "volumetric", "movie"]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
  hint = loc("guiHints/cloudsQuality")
  getMoreBlkSettings = function(val){
    return [
      {blkPath = "graphics/HQVolumetricClouds", val = (val == "movie")},
    ]
  }
})
let optCloudsQualityObservable = optCloudsQualityVarInfo?.var
if (optCloudsQualityObservable)
  optCloudsQualityVarInfo.nameChild <- mkOptionWarning(
    Computed(@() optCloudsQualityObservable.get() == "movie"),
    loc("settings/performance_warning"),
    loc("settings/clouds_warning"))
let optCloudsQuality = optionCtor(optCloudsQualityVarInfo)

let optVolumeFogQualityVarInfo = addOptionVarInfo({
  optId = "volumeFogQuality"
  name = loc("options/volumeFogQuality")
  blkPath = "graphics/volumeFogQuality"
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  defVal = "close"
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = [ "close", "medium", "far", "movie"]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
  hint = loc("guiHints/volumeFogQuality")
  getMoreBlkSettings = function(val){
    return [
      {blkPath = "graphics/HQVolfog", val = (val == "movie")},
    ]
  }
})
let optVolumeFogQualityObservable = optVolumeFogQualityVarInfo?.var
if (optVolumeFogQualityObservable)
  optVolumeFogQualityVarInfo.nameChild <- mkOptionWarning(
    Computed(@() optVolumeFogQualityObservable.get() == "movie"),
    loc("settings/performance_warning"),
    loc("settings/fog_warning"))
let optVolumeFogQuality = optionCtor(optVolumeFogQualityVarInfo)

let optWaterQuality = optionCtor(addOptionVarInfo({
  optId = "waterQuality"
  name = loc("options/waterQuality", "Water Quality")
  blkPath = "graphics/waterQuality"
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  defVal = "low"
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = [ "low", "medium", "high" ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
  hint = loc("guiHints/waterQuality")
}))


let optGroundDisplacementQuality = optionCtor(addOptionVarInfo({
  optId = "groundDisplacementQuality"
  name = loc("options/groundDisplacementQuality", "Terrain Tessellation Quality")
  blkPath = "graphics/groundDisplacementQuality"
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  defVal = 1
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = [ 0, 1, 2 ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
  hint = loc("guiHints/groundDisplacementQuality")
}))


let optGroundDeformations = optionCtor(addOptionVarInfo({
  optId = "groundDeformations"
  name = loc("options/groundDeformations", "Dynamic Terrain Deformations")
  blkPath = "graphics/groundDeformations"
  widgetCtor = mkDisableableCtor(bareOffText, optionSpinner)
  defVal = "low"
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = [ "off", "low", "medium", "high" ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
  hint = loc("guiHints/groundDeformations")
}))


let optImpostor = optionCtor(addOptionVarInfo({
  optId = "impostor"
  name = loc("options/impostor", "Impostor quality")
  blkPath = "graphics/impostor"
  widgetCtor = optionSpinner
  defVal = 0
  isAvailable = isDevBuild
  tab = "Graphics"
  available = [ 0, 1, 2 ]
  restart = false
  valToString = loc_opt
  isEqual = defCmp
}))

let antiAliasingModeValueFiltered = Computed(@() isBareMinimum.get() ? antiAliasingMode.FXAA : antiAliasingModeValue.get())

let antiAliasingModeNameWarning = mkOptionWarning(
  Computed(@() antiAliasingModeValueFiltered.get() == antiAliasingMode.SSAA),
  loc("settings/performance_warning"),
  loc("settings/ssaa_warning"))

let optAntiAliasingMode = optionCtor({
  name = loc("options/antiAliasingMode", "Anti-aliasing Mode")
  nameChild = antiAliasingModeNameWarning
  blkPath = AA_MODE_BLK_PATH
  widgetCtor = mkDisableableCtor(Computed(@() isBareMinimum.get() ? loc("option/fxaa", "FXAA") : null), optionSpinner)
  defVal = antiAliasingModeDefaultValue
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  var = antiAliasingModeValueFiltered
  setValue = antiAliasingModeSetValue
  available = antiAliasingModeAvailable
  valToString = antiAliasingModeValueToString
  hint = loc("guiHints/antiAliasingMode")
})

let optSuperResolution = optionCtor({
  name = loc("options/superResolution", "Super Resolution")
  blkPath = AA_PRESET_BLK_PATH
  widgetCtor = optionSpinner
  defVal = upscalingPresetDefaultValue
  tab = "Graphics"
  isAvailable = isOptAvailable
  isAvailableWatched = Computed(@() isOptAvailable() && [antiAliasingMode.DLSS, antiAliasingMode.XESS, antiAliasingMode.FSR].contains(antiAliasingModeValueFiltered.get()))
  var = upscalingPresetValue
  setValue = upscalingPresetSetValue
  available = upscalingPresetAvailable
  valToString = upscalingPresetValueToString
  hint = loc("guiHints/upscalingPreset")
})

let optFrameGeneration = optionCtor({
  name = loc("options/frameGeneration", "Frame Generation")
  blkPath = AA_FGC_BLK_PATH
  widgetCtor = mkDisableableCtor(fgcUnsupportedReason, optionSpinner)
  defVal = fgcDefaultMode
  tab = "Graphics"
  isAvailable = @() isOptAvailable() && isFGOptAvailable()
  isAvailableWatched = Computed(@() isOptAvailable() && isFGOptAvailable() && [antiAliasingMode.DLSS, antiAliasingMode.FSR].contains(antiAliasingModeValueFiltered.get()))
  var = fgcValue
  setValue = fgcSetValue
  available = fgcAvailable
  valToString = fgcValueToString
  hint = getFgHintFromAntiAliasingMode
})

let optDlssRayReconstruction = optionCtor(addOptionVarInfo({
  name = loc("options/dlssRayReconstruction", "Ray Reconstruction")
  blkPath = AA_DLSS_RR_BLK_PATH
  widgetCtor = mkDisableableCtor(rtOffText, optionCheckBox)
  defVal = dlssRRDefaultValue
  tab = "Graphics"
  isAvailable = @() isOptAvailable() && (isPcDx12() || is_vulkan())
  isAvailableWatched = Computed(@() isOptAvailable() && (isPcDx12() || is_vulkan()) && antiAliasingModeValueFiltered.get() == antiAliasingMode.DLSS && dlssRRAvailable.get())
  setValue = dlssRRSetValue
  var = dlssRRValue
  hint = loc("guiHints/dlssRayReconstruction")
}))

let optDlssLegacyMode = optionCtor(addOptionVarInfo({
  name = loc("options/dlssLegacyMode", "DLSS Legacy Mode")
  blkPath = AA_DLSS_LEGACY_MODEL_BLK_PATH
  widgetCtor = optionSpinner
  defVal = dlssLegacyModeDefaultValue
  tab = "Graphics"
  isAvailable = isOptAvailable
  isAvailableWatched = Computed(@() isOptAvailable() && antiAliasingModeValue.get() == antiAliasingMode.DLSS && !dlssRRValue.get())
  setValue = dlssLegacyModeSetValue
  var = dlssLegacyModeValue
  available = dlssLegacyModeAvailable
  valToString = loc_opt
  hint = loc("guiHints/dlssLegacyMode")
}))

let optSharpening = optionCtor(addOptionVarInfo({
  optId = "sharpening"
  name = loc("options/sharpening", "Sharpening")
  blkPath = "graphics/sharpening"
  widgetCtor = mkDisableableCtor(bareOffText, optionPercentTextSliderCtor)
  defVal = 0.0
  isAvailable = isOptAvailable
  min = 0.0
  max = 100.0
  unit = 5.0/100.0
  pageScroll = 5.0
  restart = false
  tab = "Graphics"
  valToString = loc_opt
  isEqual = defCmp
  hint = loc("guiHints/sharpening")
}))


const DYNAMIC_RESOLUTION_BLK_PATH = "video/dynamicResolution/targetFPS"
const DYNAMIC_RESOLUTION_OFF = 0
let dynamicResolutionFPS = Watched(isPcDx12() ? get_setting_by_blk_path(DYNAMIC_RESOLUTION_BLK_PATH) ?? DYNAMIC_RESOLUTION_OFF : DYNAMIC_RESOLUTION_OFF)

let optDynamicResolution = optionCtor({
  name = loc("options/dynamic_resolution", "Dynamic Resolution")
  blkPath = DYNAMIC_RESOLUTION_BLK_PATH
  widgetCtor = mkDisableableCtor(bareOffText, optionCombo)
  defVal = DYNAMIC_RESOLUTION_OFF
  tab = "Graphics"
  isAvailable = @() isOptAvailable() && isPcDx12()
  isAvailableWatched = Computed(@() isOptAvailable() && isPcDx12() && antiAliasingModeValueFiltered.get() == antiAliasingMode.TSR)
  var = dynamicResolutionFPS
  setValue = @(v) dynamicResolutionFPS.set(v)
  available = [DYNAMIC_RESOLUTION_OFF].extend(fpsList.get().filter(@(v) v != UNLIMITED_FPS_LIMIT))
  valToString = @(v) v == DYNAMIC_RESOLUTION_OFF ? loc("option/off") : "{0} {1}".subst(v, loc("options/fps", "FPS"))
  isEqual = defCmp
  restart = false
  getMoreBlkSettings = function(v){
    return [
      {blkPath = "video/dynamicResolution/enabled", val = v != DYNAMIC_RESOLUTION_OFF}
    ]
  }
  hint = loc("guiHints/dynamic_resolution")
})

let optMinDynamicResolutionScale = optionCtor({
  name = loc("options/minimum_resolution_scale", "Minimum Resolution Scale")
  blkPath = "video/dynamicResolution/minResolutionScale"
  widgetCtor = mkDisableableCtor(bareOffText, optionPercentTextSliderCtor)
  defVal = 0.5
  tab = "Graphics"
  isAvailableWatched = Computed(@() isOptAvailable() && dynamicResolutionFPS.get() != DYNAMIC_RESOLUTION_OFF && antiAliasingModeValueFiltered.get() == antiAliasingMode.TSR)
  min = 50.0
  max = 75.0
  unit = 5.0/25.0
  pageScroll = 5.0
  convertForBlk = @(v) v * 0.01
  convertFromBlk = @(v) v * 100.0
  restart = false
  hint = loc("guiHints/minimum_resolution_scale")
})


let roundUpsamplingRatio = @(v, step) step * round(v / step)
let optTemporalUpsamplingRatio = optionCtor(addOptionVarInfo({
  optId = "temporalUpsamplingRatio"
  name = loc("options/temporal_upsampling_ratio", "Temporal Resolution Scale")
  blkPath = "video/antialiasing_upscaling"
  widgetCtor = mkDisableableCtor(
    Computed(@() dynamicResolutionFPS.get() != DYNAMIC_RESOLUTION_OFF ? loc("options/adaptive", "Adaptive") : null),
    optionPercentTextSliderCtor)
  defVal = 100.0
  tab = "Graphics"
  isAvailable = isOptAvailable
  isAvailableWatched = Computed(@() isOptAvailable() && antiAliasingModeValueFiltered.get() == antiAliasingMode.TSR)
  min = 50.0
  max = 100.0
  unit = 5.0/50.0
  pageScroll = 5.0
  restart = false
  convertFromBlk = @(v) roundUpsamplingRatio(10000.0/toFloatSafe(v, 100.0, false), 5.0)
  convertForBlk = @(v) $"{10000.0/v}"
  hint = loc("guiHints/temporal_upsampling_ratio")
}))


let optStaticResolutionScale = optionCtor(addOptionVarInfo({
  optId = "staticResolutionScale"
  name = loc("options/static_resolution_scale", "Static Resolution Scale")
  blkPath = "video/staticResolutionScale"
  widgetCtor = optionPercentTextSliderCtor
  defVal = get_default_static_resolution_scale()
  tab = "Graphics"
  isAvailable = isOptAvailable
  isAvailableWatched = Computed(@() isOptAvailable() && isBareMinimum.get())
  min = 50.0
  max = 100.0
  unit = 5.0/50.0
  pageScroll = 5.0
  restart = false
  hint = loc("guiHints/static_resolution_scale")
}))



let staticResolutionScaleWatched = optStaticResolutionScale.var

let optStaticUplsamplingQuality = optionCtor(addOptionVarInfo({
  optId = "staticUpsampleQuality"
  name = loc("options/static_upsampling_quality", "Static Upsampling Quality")
  blkPath = "graphics/staticUpsampleQuality"
  widgetCtor = optionSpinner
  defVal = "catmullrom"
  tab = "Graphics"
  isAvailable = isOptAvailable
  isAvailableWatched = Computed(@() isOptAvailable() && isBareMinimum.get() && staticResolutionScaleWatched.get() < 100.0)
  available = ["bilinear", "catmullrom", "sharpen"]
  restart = false
  valToString = loc_opt
  hint = loc("guiHints/static_upsampling_quality")
}))



let optGammaCorrection = optionCtor({
  name = loc("options/gamma_correction", "Gamma correction")
  blkPath = "graphics/gamma_correction"
  widgetCtor = mkSliderWithText
  defVal = 1.0
  tab = "Graphics"
  isAvailableWatched = Computed(@() platform.is_xbox ? !is_hdr_enabled()
                                                     : !is_hdr_available(monitorValue.get()) || !hdrWatched.get())
  var = gammaCorrectionSave.watch
  setValue = function(v) {
      gammaCorrectionSave.setValue(v)
      change_gamma(v)
    }
  min = 0.5 max = 1.5 unit = 0.05 pageScroll = 0.05
  restart = false
  hint = loc("guiHints/gamma_correction")
})


let optTexQuality = optionCtor(addOptionVarInfo({
  optId = "texQuality"
  name = loc("options/texQuality")
  blkPath = "graphics/texquality"
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  defVal = "high"
  isAvailable = isOptAvailable
  tab = "Graphics"
  available = ["low", "medium", "high"]
  restart = true
  valToString = loc_opt
  isEqual = defCmp
  hint = loc("guiHints/texQuality")
}))


let optAnisotropy = optionCtor(addOptionVarInfo({
  optId = "anisotropy"
  name = loc("options/anisotropy")
  blkPath = "graphics/anisotropy"
  widgetCtor = mkDisableableCtor(bareOffText, optionSpinner)
  defVal = 4
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = [1, 2, 4, 8, 16]
  restart = false
  valToString = @(v) (v==1) ? loc("option/off") : $"{v}X"
  isEqual = defCmp
  hint = loc("guiHints/anisotropy")
}))


let optOnlyonlyHighResFx = optionCtor(addOptionVarInfo({
  optId = "onlyHighResFx"
  name = loc("options/onlyHighResFx")
  blkPath = "graphics/fxTarget"
  widgetCtor = mkDisableableCtor(bareOffText, optionSpinner)
  defVal = "lowres"
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = ["lowres", "medres", "highres"]
  restart = true
  valToString = loc_opt
  hint = loc("guiHints/onlyHighResFx")
}))


let optScreenSpaceWeatherEffects = optionCtor(addOptionVarInfo({
  optId = "screenSpaceWeatherEffects"
  name = loc("options/screenSpaceWeatherEffects")
  blkPath = "graphics/screenSpaceWeatherEffects"
  widgetCtor = mkDisableableCtor(bareOffText, optionCheckBox)
  defVal = true
  tab = "Graphics"
  isAvailable = @() true
  restart = false
  hint = loc("guiHints/screenSpaceWeatherEffects")
}))


let optFXAAQuality = optionCtor(addOptionVarInfo({
  optId = "fxaaQuality"
  name = loc("options/FXAAQuality")
  blkPath = "graphics/fxaaQuality"
  widgetCtor = optionSpinner
  defVal = "medium"
  tab = "Graphics"
  isAvailableWatched = Computed(@() (platform.is_pc || !isConsoleBareMinimum.get())
    && antiAliasingModeValueFiltered.get() == antiAliasingMode.FXAA)
  available = ["low", "medium", "high"]
  restart = false
  valToString = loc_opt
  hint = loc("guiHints/FXAAQuality")
}))


let optSSRQuality = optionCtor(addOptionVarInfo({
  optId = "ssrQuality"
  name = loc("options/SSRQuality")
  blkPath = "graphics/ssrQuality"
  widgetCtor = mkDisableableCtor(Computed(@() rtOptionsValid.get() && rtrWatched.get() ? loc("option/rayTracedQuality") : bareLowText.get()), optionSpinner)
  defVal = "low"
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = ["low", "medium", "high"]
  restart = false
  valToString = loc_opt
  hint = loc("guiHints/SSRQuality")
  getMoreBlkSettings = function(val){
    return [
      {blkPath = "graphics/HQSSR", val = (val == "high")},
    ]
  }
}))


let optScopeImageQuality = optionCtor(addOptionVarInfo({
  optId = "scopeImageQuality"
  name = loc("options/scopeImageQuality", "Scope Image Quality")
  blkPath = "graphics/scopeImageQuality"
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  defVal = 0
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = [0, 1, 2, 3]
  valToString = loc_opt
  restart = false
  isEqual = defCmp
  hint = loc("guiHints/scopeImageQuality")
}))


const SCREENSHOT_FORMAT_BLK_PATH = "screenshots/format"
const SCREENSHOT_FORMAT_JPEG = "jpeg"
const SCREENSHOT_FORMAT_TGA = "tga"
const SCREENSHOT_FORMAT_PNG = "png"
const SCREENSHOT_FORMAT_EXR = "exr"

let screenshotFormatAvailable = Computed(@() is_hdr_available(monitorValue.get()) && hdrWatched.get() ?
                                [SCREENSHOT_FORMAT_JPEG, SCREENSHOT_FORMAT_PNG, SCREENSHOT_FORMAT_TGA, SCREENSHOT_FORMAT_EXR] :
                                [SCREENSHOT_FORMAT_JPEG, SCREENSHOT_FORMAT_PNG, SCREENSHOT_FORMAT_TGA])

let screenshotFormatValueChosen = Watched(get_setting_by_blk_path(SCREENSHOT_FORMAT_BLK_PATH) ?? SCREENSHOT_FORMAT_JPEG)

let screenshotFormatSetValue = @(v) screenshotFormatValueChosen.set(v)

let screenshotFormatValue = Computed(@() screenshotFormatAvailable.get().contains(screenshotFormatValueChosen.get())
  ? screenshotFormatValueChosen.get() : SCREENSHOT_FORMAT_JPEG)

let optScreenshotFormat = optionCtor(addOptionVarInfo({
  optId = "screenshotFormat"
  name = loc("options/screenshotFormat")
  blkPath = SCREENSHOT_FORMAT_BLK_PATH
  widgetCtor = optionSpinner
  defVal = SCREENSHOT_FORMAT_JPEG
  tab = "Graphics"
  isAvailable = isOptAvailable
  restart = false
  var = screenshotFormatValue
  setValue = screenshotFormatSetValue
  available = screenshotFormatAvailable
  valToString = loc_opt
  hint = loc("guiHints/screenshotFormat")
}))


let optFFTWaterQuality = optionCtor(addOptionVarInfo({
  optId = "fftWaterQuality"
  name = loc("options/fft_water_quality", "Water Ripples Quality")
  blkPath = "graphics/fftWaterQuality"
  widgetCtor = mkDisableableCtor(bareLowText, optionSpinner)
  defVal = "high"
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = ["low", "medium", "high", "ultra"]
  restart = false
  valToString = loc_opt
  hint = loc("guiHints/fft_water_quality")
}))

let optHQProbeReflections = optionCtor(addOptionVarInfo({
  optId = "hqProbeReflections"
  name = loc("options/HQProbeReflections")
  blkPath = "graphics/HQProbeReflections"
  widgetCtor = mkDisableableCtor(bareOffText, optionCheckBox)
  defVal = true
  tab = "Graphics"
  isAvailable = @() platform.is_pc
  restart = false
  hint = loc("guiHints/HQProbeReflections")
}))

let optSSSS = optionCtor(addOptionVarInfo({
  optId = "ssss"
  name = loc("options/ssss")
  blkPath = "graphics/ssssQuality"
  widgetCtor = mkDisableableCtor(bareOffText, optionSpinner)
  defVal = "low"
  tab = "Graphics"
  isAvailable = isOptAvailable
  available = ["off", "low", "high"]
  restart = false
  valToString = loc_opt
  hint = loc("guiHints/ssss")
}))


let optFontKillLog = optionCtor({
  optId = "fontKillLog"
  name = loc("options/fontKillLog", "fontKillLog")
  widgetCtor = optionSpinner
  tab = "Game"
  blkPath = "gameplay/fontKillLog"
  defVal = get_setting_by_blk_path("gameplay/font_kill_log")
    ?? (platform.is_console ? "big" : "small")
  var = fontKillLog
  setValue = fontKillLogSetValue
  available = ["small", "big", "off"]
  valToString = loc_opt
})

return {
  optFontKillLog
  resolutionToString
  optDriver
  optResolution
  optSafeArea
  optVideoMode
  optMonitorSelection
  optHdr
  optPaperWhiteNits
  optPerformanceMetrics
  optLatencyNVidia
  optLatencyAMD
  optLatencyIntel
  optVsync
  optFpsLimit
  optShadowsQuality
  optLensFlares
  optChromaticAberration
  optFilmGrain
  optMotionBlur
  optEffectsShadows
  optGiAlgorithm
  optGiAlgorithmQuality
  optSkiesQuality
  optSsaoQuality
  optObjectsDistanceMul
  optCloudsQuality
  optVolumeFogQuality
  optWaterQuality
  optGroundDisplacementQuality
  optGroundDeformations
  optImpostor
  optGammaCorrection
  optTexQuality
  optAnisotropy
  optOnlyonlyHighResFx
  optPhysicalShellCasings
  optScreenSpaceWeatherEffects
  optSSRQuality
  optScopeImageQuality
  optScreenshotFormat
  optSharpening
  optTemporalUpsamplingRatio
  optStaticResolutionScale
  optStaticUplsamplingQuality
  optFFTWaterQuality
  optHQProbeReflections
  optSSSS
  optAntiAliasingMode
  optRTSM
  optRTR
  optRTTR
  optPTGI
  optRTAO
  optRTWater
  optRTGI
  optBVHDagdp

  renderOptions = [
    optSafeArea,
    optFontKillLog,

    
    {name = loc("group/display", "Display") isSeparator=true tab="Graphics"},
    optDriver,
    optResolution,
    optVideoMode,
    optMonitorSelection,
    optHdr,
    optPaperWhiteNits,
    optGammaCorrection,
    optPerformanceMetrics,
    optLatencyNVidia,
    optLatencyAMD,
    optLatencyIntel,
    optVsync,
    optFpsLimit,

    
    {name = loc("group/antialiasing", "Antialiasing") isSeparator=true tab="Graphics"},
    optAntiAliasingMode,
    optSuperResolution,
    optFrameGeneration,
    optDlssRayReconstruction,
    optDlssLegacyMode,
    optDynamicResolution,
    optMinDynamicResolutionScale,
    optTemporalUpsamplingRatio,
    optStaticResolutionScale,
    optStaticUplsamplingQuality,
    optFXAAQuality,
    optSharpening,

    
    {name = loc("group/shadows_n_lighting", "Shadows & Lighting") isSeparator=true tab="Graphics"},
    optShadowsQuality,
    optEffectsShadows,

    
    optGiAlgorithm,
    optGiAlgorithmQuality,
    optSkiesQuality,
    optSsaoQuality,
    optSSRQuality,
    optHQProbeReflections,
    optSSSS,

    {name = loc("group/details_n_textures", "Details & Textures") isSeparator=true tab="Graphics"},
    
    optTexQuality,
    optAnisotropy,
    
    optCloudsQuality,
    optVolumeFogQuality,
    optWaterQuality,
    optFFTWaterQuality,
    optGroundDisplacementQuality,
    optGroundDeformations,
    optOnlyonlyHighResFx,
    optScopeImageQuality,
    optPhysicalShellCasings,

    {name = loc("group/ray_tracing", "Ray Tracing") isSeparator=true tab="Graphics"},
    optRTSM,
    optRTR,
    optRTTR,
    optPTGI,
    optRTAO,
    optRTWater,
    optRTGI,
    optBVHDagdp,

    {name = loc("group/postfx_effects", "Postfx effects") isSeparator=true tab="Graphics"},
    optScreenSpaceWeatherEffects,
    optLensFlares,
    optChromaticAberration,
    optFilmGrain,
    optMotionBlur,

    
    {name = loc("group/other", "Other")
     isSeparator=true
     tab="Graphics"
     isAvailable = optScreenshotFormat.isAvailable },  
     optScreenshotFormat,

    
    {name = "Dev options" isSeparator=true tab="Graphics" isAvailable = isDevBuild },
    optImpostor,
    optObjectsDistanceMul,
  ]
}
