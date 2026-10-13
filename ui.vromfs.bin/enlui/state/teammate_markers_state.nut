from "settings" import get_setting_by_blk_path
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *

enum TeammateMarkers {
  DEFAULT = 0,
  INDEX = 1,
  COLOR = 2,
  INDEX_COLOR = 3,
}

let teammateMarkersState = nestWatched("teammateMarkersState",
  get_setting_by_blk_path("teammateMarkers") ?? TeammateMarkers.INDEX_COLOR)
let teammateMarkersStateUpdate = @(v) teammateMarkersState.set(v)

const MARKER_INDEX = 1
const MARKER_COLOR = 2

return {
  TeammateMarkers
  teammateMarkersState
  teammateMarkersStateUpdate
  MARKER_COLOR
  MARKER_INDEX
}
