import "%ui/helpers/locByPlatform.nut" as locByPlatform
from "%ui/hud/menus/options/options_lib.nut" import optionCheckBox, optionCtor, getOnlineSaveData
from "settings" import get_setting_by_blk_path
from "%ui/leaderboard/leaderboard_option_state.nut" import consoleLeaderboardOnlyUpdate, leaderboardOptionNeeded, savedMyConsoleOnlyId
from "%ui/ui_library.nut" import *

let { settings = Watched({}) } = require_optional("onlineStorage") ? require_optional("%ui/options/onlineSettings.nut") : null

function saveLeaderboardState(val, setValue) {
  settings.mutate(@(set) set[savedMyConsoleOnlyId] <- val)
  consoleLeaderboardOnlyUpdate(val)
  setValue(val)
}

function mkOptionCrosschatOption() {
  let { watch, setValue } = getOnlineSaveData(savedMyConsoleOnlyId,
    @() get_setting_by_blk_path(savedMyConsoleOnlyId) ?? false)
  return optionCtor({
    name = locByPlatform("option/psn_only_leaderboards")
    tab = "Game"
    widgetCtor = optionCheckBox
    var = watch
    setValue = @(val) saveLeaderboardState(val, setValue)
    blkPath = savedMyConsoleOnlyId
  })
}

return {
  leaderboardOptions = leaderboardOptionNeeded
    ? [ mkOptionCrosschatOption() ]
    : []
}