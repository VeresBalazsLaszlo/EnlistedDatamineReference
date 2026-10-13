from "videomode" import get_antialiasing_options, get_antialiasing_upscaling_options, get_supported_generated_frames, is_dynamic_mfg_supported,
get_frame_generation_unsupported_reason, is_dlss_rr_supported
from "settings" import get_setting_by_blk_path
from "%ui/ui_library.nut" import *

from "%ui/hud/menus/options/resolution_state.nut" import isExclusiveFullscreen

const AA_MODE_BLK_PATH = "video/antialiasing_mode"
const AA_PRESET_BLK_PATH = "video/antialiasing_upscaling"
const AA_FGC_BLK_PATH = "video/antialiasing_fgc"
const AA_DLSS_RR_BLK_PATH = "video/rayReconstruction"
const AA_DLSS_LEGACY_MODEL_BLK_PATH = "video/dlssLegacyMode"

enum antiAliasingMode {
  OFF = "off"
  FXAA = "high_fxaa",
  TSR = "tsr",
  DLSS = "dlss",
  XESS = "xess",
  FSR = "fsr",
  SSAA = "ssaa"
};

enum upscalingPreset {
  NATIVE = "native",
  ULTRA_QUALITY_PLUS = "ultra_quality_plus",
  ULTRA_QUALITY = "ultra_quality",
  QUALITY = "quality",
  BALANCED = "balanced",
  PERFORMANCE = "performance",
  ULTRA_PERFORMANCE = "ultra_performance"
};

enum frameGenerationMode {
  DYNAMIC = -1,
  OFF = 0,
  X2 = 1,
  X3 = 2,
  X4 = 3,
  X5 = 4,
  X6 = 5
}

let antiAliasingModeToString = {
  [antiAliasingMode.OFF]  = { optName = "option/off",  defLocString = "Off" },
  [antiAliasingMode.FXAA] = { optName = "option/fxaa", defLocString = "FXAA" },
  [antiAliasingMode.TSR]  = { optName = "option/tsr",  defLocString = "Temporal Super Resolution" },
  [antiAliasingMode.DLSS] = { optName = "option/dlss", defLocString = "NVIDIA DLSS" },
  [antiAliasingMode.XESS] = { optName = "option/xess", defLocString = "Intel XeSS" },
  [antiAliasingMode.FSR]  = { optName = "option/fsr",  defLocString = "AMD FSR" },
  [antiAliasingMode.SSAA] = { optName = "options/optSSAA", defLocString = "SSAA" },
}

let antiAliasingModeToFgString = {
  [antiAliasingMode.DLSS] = "guiHints/dlssFrameGeneration",
  [antiAliasingMode.XESS] = "guiHints/xessFrameGeneration",
  [antiAliasingMode.FSR] = "guiHints/fsrFrameGeneration",
}

let dlssToString = {
  [upscalingPreset.PERFORMANCE] = "option/performance",
  [upscalingPreset.ULTRA_QUALITY_PLUS] = "option/ultraqualityplus",
  [upscalingPreset.ULTRA_QUALITY] = "option/ultraquality",
  [upscalingPreset.BALANCED] = "option/balanced",
  [upscalingPreset.QUALITY]  = "option/quality",
  [upscalingPreset.ULTRA_PERFORMANCE]  = "option/ultraperformance",
  [upscalingPreset.NATIVE] = "option/dlaa",
}

let dlssgToString = {
  [frameGenerationMode.DYNAMIC] = "option/dynamic",
  [frameGenerationMode.OFF] = "option/off",
  [frameGenerationMode.X2] = "option/2x",
  [frameGenerationMode.X3] = "option/3x",
  [frameGenerationMode.X4] = "option/4x",
  [frameGenerationMode.X5] = "option/5x",
  [frameGenerationMode.X6] = "option/6x",
}

let xessAndFsrToString = {
  [upscalingPreset.PERFORMANCE] = "option/performance",
  [upscalingPreset.ULTRA_QUALITY_PLUS] = "option/ultraqualityplus",
  [upscalingPreset.ULTRA_QUALITY] = "option/ultraquality",
  [upscalingPreset.BALANCED] = "option/balanced",
  [upscalingPreset.QUALITY]  = "option/quality",
  [upscalingPreset.ULTRA_PERFORMANCE]  = "option/ultraperformance",
  [upscalingPreset.NATIVE] = "option/antialiasing",
}

let xessfgAndFsrfgToString = {
  [frameGenerationMode.DYNAMIC] = "option/off",
  [frameGenerationMode.OFF] = "option/off",
  [frameGenerationMode.X2] = "option/on",
  [frameGenerationMode.X3] = "option/on",
  [frameGenerationMode.X4] = "option/on",
  [frameGenerationMode.X5] = "option/on",
  [frameGenerationMode.X6] = "option/on",
}

const antiAliasingModeDefaultValue = antiAliasingMode.TSR
const antiAliasingAllModes = [antiAliasingMode.TSR, antiAliasingMode.DLSS, antiAliasingMode.XESS,
                              antiAliasingMode.FSR, antiAliasingMode.FXAA, antiAliasingMode.SSAA]
let antiAliasingModeAvailable = WatchedRo(antiAliasingAllModes.filter(@(q) get_antialiasing_options().split(";").map(@(mode) mode.split("|")[0]).contains(q)))
let antiAliasingModeValueChosen = Watched(get_setting_by_blk_path(AA_MODE_BLK_PATH) ?? antiAliasingModeDefaultValue)
let antiAliasingModeSetValue = @(v) antiAliasingModeValueChosen.set(v)
let antiAliasingModeValue = Computed(@() antiAliasingModeAvailable.get().contains(antiAliasingModeValueChosen.get()) ? antiAliasingModeValueChosen.get() : antiAliasingModeDefaultValue)
let antiAliasingModeValueToString = @(v) loc(antiAliasingModeToString[v].optName, antiAliasingModeToString[v].defLocString)
let getFgHintFromAntiAliasingMode = Computed(@() loc(antiAliasingModeToFgString?[antiAliasingModeValue.get()]))

const upscalingPresetDefaultValue = upscalingPreset.NATIVE
const upscalingAllPresets = [upscalingPreset.ULTRA_PERFORMANCE, upscalingPreset.PERFORMANCE, upscalingPreset.BALANCED, upscalingPreset.QUALITY, upscalingPreset.ULTRA_QUALITY, upscalingPreset.ULTRA_QUALITY_PLUS, upscalingPreset.NATIVE]
let upscalingPresetAvailable = Computed(@() upscalingAllPresets.filter(@(q) get_antialiasing_upscaling_options(antiAliasingModeValueChosen.get()).split(";").contains(q)))
let upscalingPresetValueChosen = Watched(get_setting_by_blk_path(AA_PRESET_BLK_PATH) ?? upscalingPresetDefaultValue)
let upscalingPresetSetValue = @(v) upscalingPresetValueChosen.set(v)
let upscalingPresetValue = Computed(@() upscalingPresetAvailable.get().contains(upscalingPresetValueChosen.get()) ? upscalingPresetValueChosen.get() : upscalingPresetDefaultValue)
function upscalingPresetValueToString(value) {
  if (antiAliasingModeValueChosen.get() == antiAliasingMode.DLSS)
    return loc(dlssToString[value])
  else if ([antiAliasingMode.XESS, antiAliasingMode.FSR].contains(antiAliasingModeValueChosen.get()))
    return loc(xessAndFsrToString[value])
  else
    return ""
}

const fgcDefaultMode = frameGenerationMode.OFF
const fgcAllModes = [frameGenerationMode.OFF, frameGenerationMode.DYNAMIC, frameGenerationMode.X2, frameGenerationMode.X3, frameGenerationMode.X4, frameGenerationMode.X5, frameGenerationMode.X6]
let fgcAvailable = Computed(@() fgcAllModes.filter(@(q) (q >= 0 && q <= get_supported_generated_frames(antiAliasingModeValueChosen.get(), isExclusiveFullscreen.get()))
                                                 || (q < 0 && is_dynamic_mfg_supported(antiAliasingModeValueChosen.get(), isExclusiveFullscreen.get()))))
let fgcValueChosen = Watched(get_setting_by_blk_path(AA_FGC_BLK_PATH) ?? fgcDefaultMode)
let fgcSetValue = @(v) fgcValueChosen.set(v)
let fgcValue = Computed(@() fgcAvailable.get().contains(fgcValueChosen.get()) ? fgcValueChosen.get() : fgcDefaultMode)
let fgcUnsupportedReason = Computed(@() loc(get_frame_generation_unsupported_reason(antiAliasingModeValueChosen.get(), isExclusiveFullscreen.get())))
function fgcValueToString(value) {
  if (antiAliasingModeValueChosen.get() == antiAliasingMode.DLSS)
    return loc(dlssgToString[value])
  else if ([antiAliasingMode.XESS, antiAliasingMode.FSR].contains(antiAliasingModeValueChosen.get()))
    return loc(xessfgAndFsrfgToString[value])
  else
    return ""
}

const dlssRRDefaultValue = false
let dlssRRAvailable =  WatchedRo(is_dlss_rr_supported())
let dlssRRValueChosen = Watched(get_setting_by_blk_path(AA_DLSS_RR_BLK_PATH) ?? dlssRRDefaultValue)
let dlssRRSetValue = @(v) dlssRRValueChosen.set(v)
let dlssRRValue = Computed(@() dlssRRAvailable.get() && antiAliasingModeValue.get() == antiAliasingMode.DLSS ? dlssRRValueChosen.get() : false)

const dlssLegacyModeDefaultValue = "auto"
const dlssLegacyModeAvailable = ["auto", "on", "off"]
let dlssLegacyModeValueChosen = Watched(get_setting_by_blk_path(AA_DLSS_LEGACY_MODEL_BLK_PATH) ?? dlssLegacyModeDefaultValue)
let dlssLegacyModeSetValue = @(v) dlssLegacyModeValueChosen.set(v)
let dlssLegacyModeValue = Computed(@() dlssLegacyModeAvailable.contains(dlssLegacyModeValueChosen.get())
  ? dlssLegacyModeValueChosen.get()
  : dlssLegacyModeDefaultValue)

return {
  AA_MODE_BLK_PATH
  AA_PRESET_BLK_PATH
  AA_FGC_BLK_PATH
  AA_DLSS_RR_BLK_PATH
  AA_DLSS_LEGACY_MODEL_BLK_PATH

  antiAliasingMode
  frameGenerationMode

  antiAliasingModeDefaultValue
  antiAliasingModeAvailable
  antiAliasingModeSetValue
  antiAliasingModeValue
  antiAliasingModeValueToString
  getFgHintFromAntiAliasingMode

  upscalingPresetDefaultValue
  upscalingPresetAvailable
  upscalingPresetSetValue
  upscalingPresetValue
  upscalingPresetValueToString

  fgcDefaultMode
  fgcAvailable
  fgcSetValue
  fgcValue
  fgcUnsupportedReason
  fgcValueToString

  dlssRRDefaultValue
  dlssRRAvailable
  dlssRRSetValue
  dlssRRValue

  dlssLegacyModeDefaultValue
  dlssLegacyModeAvailable
  dlssLegacyModeSetValue
  dlssLegacyModeValue
}
