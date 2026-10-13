from "%dngscripts/platform.nut" import is_xboxone, is_xboxone_X, isXboxScarlett, is_xbox_anaconda, is_ps5, is_ps5_pro, is_ps4, is_ps4_pro
from "%ui/hud/menus/options/options_lib.nut" import loc_opt, optionSpinner, optionCtor
from "settings" import get_setting_by_blk_path
from "%dngscripts/globalState.nut" import nestWatched
from "videomode" import is_hfr_supported
from "%ui/ui_library.nut" import *

const ConsolePresetBlkPath = "graphics/consolePreset"

local defaultPreset = "HighFPS"
local availableGraphicPresets = ["HighFPS"]
local locKey = "guiHints/unknownConsole"

if (is_xboxone) {
  if (is_xboxone_X) {
    availableGraphicPresets = [ "HighFPS", "HighQuality" ]
    locKey = "guiHints/xboxOneXPreset"
  }
  else {
    availableGraphicPresets = ["HighFPS", "bareMinimum"]
    locKey = "guiHints/xboxOnePreset"
  }
}
else if (isXboxScarlett) {
  availableGraphicPresets = [ is_hfr_supported() ? "HighFPS" : null, "HighQuality", is_xbox_anaconda ? "RayTracing" : null].filter(@(q) q != null)
  defaultPreset = "HighQuality"
  locKey = is_xbox_anaconda ? "guiHints/xboxSeriesXPreset" : "guiHints/xboxSeriesSPreset"
}
else if (is_ps4) {
  availableGraphicPresets = ["HighFPS", "bareMinimum"]
  locKey = is_ps4_pro ? "guiHints/ps4ProPreset" : "guiHints/ps4Preset"
}
else if (is_ps5) {
  availableGraphicPresets = [ is_hfr_supported() ? "HighFPS" : null, "HighQuality", "RayTracing" ].filter(@(q) q != null)
  defaultPreset = "HighQuality"
  locKey = is_ps5_pro ? "guiHints/ps5ProPreset" : "guiHints/ps5Preset"
}

let isPresetsContainsBareMinimum = availableGraphicPresets.contains("bareMinimum")

let consoleGraphicsPreset = nestWatched("consoleGraphicsPreset",
  get_setting_by_blk_path(ConsolePresetBlkPath) ?? defaultPreset)
let consoleGraphicsPresetUpdate =  @(v) consoleGraphicsPreset.set(v)
wlog(consoleGraphicsPreset, "consoleGraphicsPreset")

let consoleGfxSettingsBlk = get_setting_by_blk_path("graphics/consoleGfxSettings")
let presetAvailable = ((consoleGfxSettingsBlk == null) || (consoleGfxSettingsBlk == false)) && availableGraphicPresets.len() > 1
function preset_val_loc(v) {
  if ((isXboxScarlett || is_ps5) && v == "HighFPS")
    return loc("option/HighFPSwithHint")
  else if (isPresetsContainsBareMinimum)
    return v == "bareMinimum" ? loc_opt("HighFPS") : loc_opt("HighQuality")
  else
    return loc_opt(v)
}

let optConsoleGraphicsPreset = optionCtor({
  name = loc("options/graphicsPreset")
  widgetCtor = optionSpinner
  tab = "Graphics"
  var = consoleGraphicsPreset
  setValue = consoleGraphicsPresetUpdate
  defVal = defaultPreset
  isAvailable = @() presetAvailable
  available = availableGraphicPresets
  valToString = preset_val_loc
  blkPath = ConsolePresetBlkPath
  restart = true
  hint = loc(locKey)
})

let isConsoleBareMinimum = Computed(@() consoleGraphicsPreset.get() == "bareMinimum")

return {
  optConsoleGraphicsPreset
  isConsoleBareMinimum
}
