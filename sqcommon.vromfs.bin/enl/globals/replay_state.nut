from "%dngscripts/globalState.nut" import globalWatched

let { currentReplayInfo, currentReplayInfoUpdate } = globalWatched("currentReplayInfo", @() {})

return freeze({
  currentReplayInfo
  currentReplayInfoUpdate
})
