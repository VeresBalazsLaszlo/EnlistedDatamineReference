from "settings" import get_setting_by_blk_path
from "%dngscripts/globalState.nut" import nestWatched

let harmonizationNickState = nestWatched("harmonizationNickState", get_setting_by_blk_path("harmonizationNickEnabled") ?? false)
let harmonizationNickStateUpdate = @(v) harmonizationNickState.set(v)

return {
  harmonizationNickState
  harmonizationNickStateUpdate
}