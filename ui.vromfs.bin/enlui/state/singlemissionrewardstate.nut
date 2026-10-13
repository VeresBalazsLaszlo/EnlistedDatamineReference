from "%dngscripts/globalState.nut" import nestWatched

let singleMissionRewardId = nestWatched("singleMissionRewardId", null)
let singleMissionRewardIdUpdate = @(v) singleMissionRewardId.set(v)
let singleMissionRewardSum = nestWatched("singleMissionRewardSum", 0)
let singleMissionRewardSumUpdate = @(v) singleMissionRewardSum.set(v)

return {
  singleMissionRewardId, singleMissionRewardIdUpdate,
  singleMissionRewardSum, singleMissionRewardSumUpdate
}