from "settings" import get_setting_by_blk_path
from "%ui/ui_library.nut" import *

let narratorNativeLang = Watched(get_setting_by_blk_path("gameplay/narrator_nativeLanguage") ?? false)

let narratorNativeLangUpdate = @(enabled) narratorNativeLang.set(enabled)

return {
  narratorNativeLang
  narratorNativeLangUpdate
}
