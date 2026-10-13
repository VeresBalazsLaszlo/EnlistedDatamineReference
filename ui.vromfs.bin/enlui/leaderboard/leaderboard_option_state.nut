from "%dngscripts/globalState.nut" import nestWatched
from "%dngscripts/platform.nut" import is_sony, is_xbox, is_gdk
from "settings" import get_setting_by_blk_path
from "%ui/ui_library.nut" import *

const savedMyConsoleOnlyId = "gameplay/psn_only_leaderboards"
let consoleLeaderboardOnly = nestWatched("consoleLeaderboardOnly", get_setting_by_blk_path(savedMyConsoleOnlyId) ?? false)
let consoleLeaderboardOnlyUpdate = @(v) consoleLeaderboardOnly.set(v)

let separateLeaderboardPlatformName = Computed(@() !consoleLeaderboardOnly.get() ? ""
  : is_sony ? "psn"
  : is_gdk ? "live"
  : ""
)

return {
  savedMyConsoleOnlyId
  consoleLeaderboardOnlyUpdate
  separateLeaderboardPlatformName
  leaderboardOptionNeeded = is_sony || is_xbox
}