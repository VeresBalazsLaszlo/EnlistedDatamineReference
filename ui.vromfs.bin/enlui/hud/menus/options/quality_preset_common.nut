from "%dngscripts/globalState.nut" import nestWatched
from "settings" import get_setting_by_blk_path
from "%ui/ui_library.nut" import *
from "videomode" import is_rt_supported

const BARE_MINIMUM = "bareMinimum"
const MINIMUM = "minimum"
const LOW = "low"
const MEDIUM = "medium"
const HIGH = "high"
const ULTRA = "ultra"
const RAY_TRACING = "RayTracing"
const CUSTOM = "custom"

const graphicsPresetBlkPath = "graphics/preset"

let savedPreset = get_setting_by_blk_path(graphicsPresetBlkPath) ?? MEDIUM
let graphicsPreset = nestWatched("graphicsPreset", savedPreset == RAY_TRACING && !is_rt_supported() ? ULTRA : savedPreset)
let graphicsPresetUpdate = @(v) graphicsPreset.set(v == RAY_TRACING && !is_rt_supported() ? ULTRA : v)
let isBareMinimum = Computed(@() graphicsPreset.get() == BARE_MINIMUM)

return {
  BARE_MINIMUM, MINIMUM, LOW, MEDIUM, HIGH, ULTRA, RAY_TRACING, CUSTOM,
  graphicsPresetBlkPath,
  graphicsPreset,
  graphicsPresetUpdate,
  isBareMinimum
}
