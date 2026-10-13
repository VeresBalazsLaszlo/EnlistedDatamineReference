from "%ui/soldiers/model/state.nut" import curArmy, curSquadId, curVehicle
from "%ui/meta/profile.nut" import curCampItems
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierIdx, defSoldierGuid
from "%ui/meta/servProfile.nut" import items, soldiers, squads
from "%ui/helpers/metalink.nut" import getLinkedSquadGuid, getFirstLinkedObjectGuid
from "%ui/ui_library.nut" import *

function deselectSoldier() {
  curSoldierIdx.set(null)
  defSoldierGuid.set(null)
}
curArmy.subscribe(@(_) deselectSoldier())
curSquadId.subscribe(@(_) deselectSoldier())


let isSquadRented = @(squad) (squad?.expireTime ?? 0) > 0

let vehicleCapacity = Computed(@() curCampItems.get()?[curVehicle.get()].crew ?? 0)

function isSoldierBelongToRentedSquad(soldier, allSquads) {
  let squadGuid = getLinkedSquadGuid(soldier)
  return squadGuid != null && isSquadRented(allSquads?[squadGuid])
}

function isObjGuidBelongToRentedSquad(guid) {
  let allSquads = squads.get()
  let allSoldiers = soldiers.get()
  let allItems = items.get()

  let item = allItems?[guid]
  let linkedSoldierGuid = item == null ? null
    : getFirstLinkedObjectGuid(item, allSoldiers)
  let soldier = allSoldiers?[linkedSoldierGuid ?? guid]

  return soldier == null ? false
    : isSoldierBelongToRentedSquad(soldier, allSquads)
}

let buyRentedSquad = mkWatched(persist, "buyRentedSquad", null)

return {
  vehicleCapacity
  isSquadRented
  isObjGuidBelongToRentedSquad
  buyRentedSquad
  deselectSoldier
}
