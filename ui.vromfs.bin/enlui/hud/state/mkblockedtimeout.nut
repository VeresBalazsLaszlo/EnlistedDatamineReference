from "%ui/ui_library.nut" import *
import "%ui/userstats/serverTime.nut" as serverTime

function findClosestTime(source, currentTs) {
  local nextTs = 0
  foreach (item in source) {
    let { showIntervalTs = null } = item
    if (showIntervalTs == null)
      continue

    foreach (time in showIntervalTs)
      if (nextTs == 0 || (time > currentTs && time < nextTs))
        nextTs = time
  }
  return nextTs
}

function isInsideInterval(intervals, currentTs) {
  let size = intervals?.len() ?? 0
  if (size == 0)
    return true

  local idx = 0
  while (idx < size) {
    let fromTs = intervals[idx]
    let toTs = intervals?[idx + 1] ?? 0
    idx += 2
    if (currentTs > fromTs && (toTs == 0 || currentTs < toTs))
      return true
  }

  return false
}

function getBlockedItems(source, currentTs) {
  let res = {}
  foreach (id, item in source) {
    let { showIntervalTs = null } = item
    if (!isInsideInterval(showIntervalTs, currentTs))
      res[id] <- id
  }
  return res
}

function mkBlockedTimeout(sourceWatched) {
  let blockedTimeouts = Watched({})

  function updateItems(_ = null) {
    let currentTs = serverTime.get()
    let sourceData = sourceWatched.get()
    blockedTimeouts.set(getBlockedItems(sourceData, currentTs))

    let nextTs = findClosestTime(sourceData, currentTs)
    if (nextTs > currentTs)
      gui_scene.resetTimeout(nextTs - currentTs, updateItems)
  }
  blockedTimeouts.whiteListMutatorClosure(updateItems)

  sourceWatched.subscribe(updateItems)
  updateItems()
  return blockedTimeouts
}

return mkBlockedTimeout
