from "%ui/meta/profile.nut" import soldiersByArmies, curArmiesList
from "%ui/soldiers/model/state.nut" import curArmy, curArmyLimits
from "%ui/helpers/metalink.nut" import getItemIndex, getLinkedSquadGuid
from "%ui/ui_library.nut" import *

let allReserveSoldiers = Computed(function() {
  let soldiersList = soldiersByArmies.get()
  let res = {}
  foreach (armyId in curArmiesList.get()) {
    res[armyId] <- (soldiersList?[armyId] ?? {})
      .filter(@(s) getLinkedSquadGuid(s) == null)
      .values()
      .sort(@(a, b) getItemIndex(a) <=> getItemIndex(b))
  }
  return res
})

let curArmyReserve = Computed(@() allReserveSoldiers.get()?[curArmy.get()] ?? [])

let curArmyReserveCapacity = Computed(@() curArmyLimits.get().soldiersReserve)

let hasCurArmyReserve = Computed(@() curArmyReserve.get().len() < curArmyReserveCapacity.get())

return {
  allReserveSoldiers
  curArmyReserve
  curArmyReserveCapacity
  hasCurArmyReserve
}
