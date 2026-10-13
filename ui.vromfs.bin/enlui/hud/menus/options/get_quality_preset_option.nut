from "%dngscripts/platform.nut" import is_xbox, is_sony
from "%ui/hud/menus/options/quality_preset_console_options.nut" import optConsoleGraphicsPreset
from "%ui/hud/menus/options/quality_preset_option.nut" import optGraphicsQualityPreset
from "%ui/ui_library.nut" import *

let preset = is_xbox || is_sony ? optConsoleGraphicsPreset : optGraphicsQualityPreset

return preset