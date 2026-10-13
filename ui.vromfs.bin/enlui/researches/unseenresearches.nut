from "%ui/meta/profile.nut" import squadsByArmies
from "%ui/researches/researchesState.nut" import squadProgress, viewArmy, armiesResearches
from "%ui/options/onlineSettings.nut" import settings
from "%ui/ui_library.nut" import *

const SEEN_ID = "seen/researches"
let seenSettings = Computed(@() settings.get()?[SEEN_ID] ?? {})


function getLevelsForSquads(armyId, squadsByArmiesVal, squadProgressVal, armiesResearchesVal) {
  let squads = squadsByArmiesVal?[armyId] ?? []
  let res = {}
  foreach (squad in squads) {
    let { squadId } = squad
    let { level = 0, points = 0 } = squadProgressVal?[squadId]
    if (points <= 0)
      continue

    let squadCfg = armiesResearchesVal?[armyId].squads[squadId]
    let { levels = [] } = squadCfg
    if (level + 1 < levels.len())
      res[squadId] <- level
  }
  return res
}

function markResearchesSeen(armyId) {
  let armyNewData = getLevelsForSquads(armyId,
    squadsByArmies.get(), squadProgress.get(), armiesResearches.get())

  let saved = seenSettings.get()
  settings.mutate(function(s) {
    let newSaved = clone saved
    newSaved[armyId] <- armyNewData
    s[SEEN_ID] <- newSaved
  })
}

function resetSeen() {
  let reseted = seenSettings.get().len()
  if (reseted > 0)
    settings.mutate(@(s) s.$rawdelete(SEEN_ID))
  return reseted
}

let hasUnseenResearches = Computed(function() {
  let armyId = viewArmy.get()
  if (armyId == null)
    return false

  let seenForArmy = seenSettings.get()?[armyId]
  let squadLevels = getLevelsForSquads(armyId,
    squadsByArmies.get(), squadProgress.get(), armiesResearches.get())

  return squadLevels.findvalue(@(level, squadId)
    (seenForArmy?[squadId] ?? 0) != level) != null
})

console_register_command(@()
    console_print("Reseted armies count = {0}".subst(resetSeen())),
  "meta.resetSeenResearches")

return {
  markResearchesSeen
  hasUnseenResearches
}
