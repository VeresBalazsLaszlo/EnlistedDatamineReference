import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/userstats/unlocksState.nut" import unlockProgress, unlocksSorted, getUnlockProgress
from "%ui/ui_library.nut" import *
from "%sqstd/frp.nut" import subscribeList

let { steam_init_achievements = @() null, steam_set_achievement_stat = @(...) null,
  steam_unlock_achievement = @(...) null, steam_is_achievement_unlocked = @(...) true,
  steam_flush_user_stats = @() null } = require_optional("steam")
let logS = with_prefix("[STEAM ACHIEVEMENTS] ")

userInfo.subscribe(@(v) v ? steam_init_achievements() : null )

function updateSteamAchievements() {
  logS("Unlocks updated: try update steam achievements")

  if (unlockProgress.get().len() == 0) {
    logS("Empty unlock progress. Skipping")
    return
  }

  local unlocks = []
  local unlocksWithProgress = []
  foreach (unlockDesc in unlocksSorted.get().filter(@(task) task?.meta.achievement ?? false)) {
    let progress = getUnlockProgress(unlockDesc, unlockProgress.get())
    if (steam_is_achievement_unlocked(unlockDesc.name))
      continue

    if (progress.isCompleted)
      unlocks.append(unlockDesc.name)
    else if (progress.required > 1 && progress.current > 0)
      unlocksWithProgress.append({id = $"{unlockDesc.name}_stat", curVal = progress.current})
  }

  local needUpdateStats = false
  unlocks.each(function(v) {
    needUpdateStats = steam_unlock_achievement(v) || needUpdateStats
  })

  unlocksWithProgress.each(function(v) {
    needUpdateStats = steam_set_achievement_stat(v.id, v.curVal) || needUpdateStats
  })

  
  
  
  logS($"Call flush stats ? {needUpdateStats}")
  if (needUpdateStats)
    steam_flush_user_stats()
}

subscribeList(updateSteamAchievements, unlocksSorted, unlockProgress)