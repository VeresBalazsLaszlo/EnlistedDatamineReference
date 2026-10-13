from "settings" import get_setting_by_blk_path
from "%dngscripts/globalState.nut" import nestWatched

let forcedViolenceState = {
  isBloodEnabled = get_setting_by_blk_path("forcedViolenceSettings/bloodEnabled"),
  isGoreEnabled = get_setting_by_blk_path("forcedViolenceSettings/goreEnabled")
}

let violenceState = nestWatched("violenceState", {
  isBloodEnabled = forcedViolenceState.isBloodEnabled ?? get_setting_by_blk_path("gameplay/violence_blood") ?? true,
  isGoreEnabled = forcedViolenceState.isGoreEnabled ?? get_setting_by_blk_path("gameplay/violence_gore") ?? true
})
let violenceStateUpdate = @(v) violenceState.set(v)

return {
  violenceState
  violenceStateUpdate
  forcedViolenceState
}