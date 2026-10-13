from "settings" import get_setting_by_blk_path
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *

let dirtyWordsFilterState = nestWatched("dirtyWordsFilterState",
  get_setting_by_blk_path("dirtyWordsFilterEnabled") ?? true)
let dirtyWordsFilterStateUpdate = @(v) dirtyWordsFilterState.set(v)

return {
  dirtyWordsFilterState
  dirtyWordsFilterStateUpdate
}
