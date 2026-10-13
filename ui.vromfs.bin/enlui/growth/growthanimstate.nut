from "%dngscripts/globalState.nut" import nestWatched
from "%sqstd/frp.nut" import subscribeList
from "%ui/tutorial/growthTutorialState.nut" import isTutorialPassed
from "%ui/growth/growthState.nut" import GrowthStatus, isGrowthVisible, growthConfig, curGrowthConfig, curGrowthState
from "%ui/ui_library.nut" import *

let completedAnim = Watched(null)
let seenGrowthExp = nestWatched("seenGrowthExp", {})


function checkCompletedAnim() {
  let seen = seenGrowthExp.get()
  let armyCfg = curGrowthConfig.get()
  foreach (guid, st in curGrowthState.get()) {
    if (guid not in armyCfg || guid not in seen)
      continue

    let { status } = st
    if (status != GrowthStatus.COMPLETED && status != GrowthStatus.PURCHASABLE)
      continue

    let animExp = armyCfg[guid].expRequired - seen[guid]
    completedAnim.set({ guid, animExp })
    break
  }
}


function passCompleteAnim() {
  let { guid = null } = completedAnim.get()
  if (guid != null) {
    seenGrowthExp.mutate(function(v) {
      if (guid in v)
        v.$rawdelete(guid)
    })
    completedAnim.set(null)
  }
}


function updateAllSeenExp(_ = null) {
  let statuses = curGrowthState.get()
  let seen = {}
  foreach (armyCfg in growthConfig.get())
    foreach (guid, cfgs in armyCfg) {
      let { expRequired = 0 } = cfgs
      if (expRequired == 0)
        continue

      let { status = GrowthStatus.UNAVAILABLE, exp = 0 } = statuses?[guid]
      if (status == GrowthStatus.ACTIVE)
        seen[guid] <- exp
    }
  seenGrowthExp.mutate(@(v) v.__update(seen))

  if (isGrowthVisible.get() && isTutorialPassed.get())
    checkCompletedAnim()
  else
    completedAnim.set(null)
}


subscribeList(updateAllSeenExp, isTutorialPassed, isGrowthVisible, curGrowthState)
updateAllSeenExp()


return {
  completedAnim
  passCompleteAnim
}
