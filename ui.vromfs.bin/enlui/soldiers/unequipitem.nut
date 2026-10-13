from "%ui/helpers/metalink.nut" import getFirstLinkByType, getFirstLinkedObjectGuid, getLinkedSquadGuid
from "%ui/soldiers/model/state.nut" import getDemandingSlots, getDemandingSlotsInfo, getSoldierItemSlots
from "%ui/soldiers/model/itemActions.nut" import equipItem
from "%ui/meta/profile.nut" import campItemsByLink, curCampSoldiers, curCampItems
from "%ui/meta/servProfile.nut" import squads, soldiers
from "%ui/soldiers/model/squadInfoState.nut" import isSquadRented
from "%ui/soldiers/components/squadsComps.nut" import showRentedSquadLimitsBox
from "%ui/ui_library.nut" import *

let popupsState = require("%ui/popup/popupsState.nut")


let showUnequipImpossible = @(text) popupsState.addPopup({
  id = "unequip_item_error"
  text
  styleName = "error"
})


function unequip(slotType, slotId, ownerGuid, cb = null) {
  let owner = curCampSoldiers.get()?[ownerGuid] ?? curCampItems.get()?[ownerGuid]
  let sList = soldiers.get()
  let soldier = sList?[ownerGuid] ?? sList?[getFirstLinkedObjectGuid(owner, sList)]
  if (soldier != null) {
    let squadGuid = getLinkedSquadGuid(soldier)
    if (squadGuid != null && isSquadRented(squads.get()?[squadGuid])) {
      showRentedSquadLimitsBox()
      return
    }
  }

  let equippedItems = getSoldierItemSlots(ownerGuid, campItemsByLink.get())
  let { item = null } = equippedItems.findvalue(@(d) d.slotType == slotType && d.slotId == slotId)
  if (item?.isFixed ?? false) {
    showUnequipImpossible(loc($"equipDemand/deniedUnequipPremium"))
    return
  }

  let demandingSlots = getDemandingSlots(slotType, owner, campItemsByLink.get())
  if (demandingSlots.len() > 0) {
    let equippedCount = demandingSlots.reduce(@(res, v) v != null ? res + 1 : res, 0)
    if (equippedCount <= 1) {
      let demandingInfo = getDemandingSlotsInfo(owner, slotType)
      if (demandingInfo != "") {
        showUnequipImpossible(demandingInfo)
        return
      }
    }
  }
  equipItem(null, slotType, slotId, ownerGuid, cb)
}

function unequipBySlot(slotData, cb = null) {
  let { slotType, slotId, ownerGuid } = slotData
  unequip(slotType, slotId, ownerGuid, cb)
}

function unequipItem(data, cb = null) {
  let { item = null, slotType = null, slotId = null, soldierGuid = null } = data
  if (item == null || slotType == null || item?.guid == null)
    return
  let ownerGuid = soldierGuid ?? getFirstLinkByType(item, slotType)
  if (!ownerGuid)
    return
  unequip(slotType, slotId, ownerGuid, cb)
}

return {
  unequipBySlot
  unequipItem
}