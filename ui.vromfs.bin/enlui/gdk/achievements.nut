import "%gdkLib/impl/achievements.nut" as achievements
from "%ui/userstats/unlocksState.nut" import unlockProgress, unlocksSorted, getUnlockProgress
from "%ui/ui_library.nut" import *
from "%sqstd/frp.nut" import subscribeList

let logX = require("%enlSqGlob/library_logs.nut").with_prefix("[XBOX_ACHIEVEMENTS] ")


function update_xbox_achievements(_ = null) {
  logX("update_xbox_achievements")

  if (unlockProgress.get().len() == 0) {
    logX("Empty unlock progress. Skipping")
    return
  }

  local unlocks = []
  foreach (unlockDesc in unlocksSorted.get()) {
    let progress = getUnlockProgress(unlockDesc, unlockProgress.get())
    let id = unlockDesc.xboxId
    let percents = (100.0 * (progress.current * 1.0 / progress.required)).tointeger()
    unlocks.append({id = id, progress = percents})
  }

  achievements.set_achievements_progress(unlocks)
}


subscribeList(update_xbox_achievements, unlockProgress, unlocksSorted)
