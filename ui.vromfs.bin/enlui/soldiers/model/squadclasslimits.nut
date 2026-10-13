from "%ui/soldiers/readyStatus.nut" import READY
from "%ui/ui_library.nut" import *

let getClassLimitsComp = @(squad, squadParams, soldiersList, soldiersStatuses) Computed(function() {
  let res = []
  let { maxClasses = {} } = squadParams.get()
  if (maxClasses.len() == 0)
    return res

  let soldierStatus = soldiersStatuses.get()
  let usedClasses = {}
  foreach (soldier in soldiersList.get()) {
    if (soldierStatus?[soldier.guid] != READY)
      continue
    let { sKind = "" } = soldier
    usedClasses[sKind] <- (usedClasses?[sKind] ?? 0) + 1
  }

  let { fillerClass = null } = squad.get()
  foreach (sKind, total in maxClasses)
    res.append({
      sKind
      total
      used = usedClasses?[sKind] ?? 0
      isFiller = sKind == fillerClass
    })
  res.sort(@(a, b) a.isFiller <=> b.isFiller || b.total <=> a.total || a.sKind <=> b.sKind)
  return res
})

return getClassLimitsComp
