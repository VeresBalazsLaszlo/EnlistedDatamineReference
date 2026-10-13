from "settings" import get_setting_by_blk_path
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/state/client_version.nut" import isMinimalClient
from "%ui/ui_library.nut" import *

let voiceoverState = nestWatched("voiceoverState",
  get_setting_by_blk_path("gameplay/voiceoverOriginalEnabled") ?? false)
let voiceoverStateUpdate = @(v) voiceoverState.set(v)

return {
  voiceoverState
  voiceoverStateUpdate
  isOptionAvailable = !isMinimalClient()
}
