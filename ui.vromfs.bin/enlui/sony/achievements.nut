from "sony.trophies" import unlockPsnTrophy, isPsnTrophyUnlocked
from "%ui/userstats/unlocksState.nut" import unlockProgress, unlocksSorted, getUnlockProgress
from "%ui/ui_library.nut" import *
from "%sqstd/frp.nut" import subscribeList

function updateAchievements() {
  if (unlockProgress.get().len() == 0)
    return

  foreach (unlockDesc in unlocksSorted.get()) {
    local trophy_id = unlockDesc.ps4Id.tointeger()
    if (trophy_id > 0) {

      trophy_id -= 1 
      let progress = getUnlockProgress(unlockDesc, unlockProgress.get())
      let completed = progress.current >= progress.required
      let unlocked = isPsnTrophyUnlocked(trophy_id)
      if (completed && !unlocked)
        unlockPsnTrophy(trophy_id)
    }
  }
}

subscribeList(updateAchievements, unlockProgress, unlocksSorted)
