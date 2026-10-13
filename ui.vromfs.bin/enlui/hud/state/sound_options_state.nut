from "settings" import get_setting_by_blk_path
from "%ui/ui_library.nut" import *

let headshotSoundEnabled = Watched(get_setting_by_blk_path("sound/headshot_sound_enabled") ?? true)
let battleMusicEnabled = Watched(get_setting_by_blk_path("sound/battle_music_enabled") ?? true)
let humanCapzoneCapturingSoundEnabled = Watched(get_setting_by_blk_path("sound/human_capzone_capturing_sound_enabled") ?? true)

return {
  headshotSoundEnabled
  battleMusicEnabled
  humanCapzoneCapturingSoundEnabled
}