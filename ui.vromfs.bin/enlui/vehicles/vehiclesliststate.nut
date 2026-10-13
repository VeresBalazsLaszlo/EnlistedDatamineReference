import "%ui/control/gui_buttons.nut" as JB
import "%ui/vehicles/allowedVehicles.nut" as allowedVehicles
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/helpers/metalink.nut" import getFirstLinkByType, getObjectsByLink, getLinkedArmyName
from "%ui/meta/profile.nut" import itemsByArmies
from "%ui/soldiers/model/state.nut" import curArmy, squadsByArmy, vehicleBySquad
from "%ui/soldiers/model/items_list_lib.nut" import addShopItems, findItemByGuid
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix
from "%ui/mainMenu/sectionsState.nut" import curSection, jumpToArmyGrowth
from "%ui/meta/clientApi.nut" import set_vehicle_to_squad
from "%ui/growth/growthState.nut" import curGrowthByItem
from "%ui/shop/armyShopState.nut" import curArmyItemsPrefiltered, itemToShopItem
from "%ui/quickMatchQueue.nut" import isChangesBlocked, showBlockedChangesMessage
from "%ui/soldiers/armySquadTier.nut" import updateBROnVehicleChange
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *

const CAN_USE                    = 0
const AVAILABLE_IN_GROWTH        = 0x01
const CAN_PURCHASE               = 0x02
const IS_BUSY_BY_SQUAD           = 0x04
const LOCKED                     = 0x10
const CANT_USE                   = 0x20 

let viewVehicle = mkWatched(persist, "viewVehicle")
let selectVehParams = mkWatched(persist, "selectVehParams", {})
let isCustomizeWndOpen = Computed(@() selectVehParams.get()?.isCustomMode ?? false)
let closeCustomizeWnd = @() selectVehParams.mutate(@(v) v.isCustomMode <- false)

let vehicleClear = @() selectVehParams.mutate(@(v) v.clear())

curSection.subscribe(@(_) vehicleClear())

let curSquad = Computed(function() {
  let { armyId = null, squadId = null } = selectVehParams.get()
  if (armyId == null || squadId == null)
    return null

  return (squadsByArmy.get()?[armyId] ?? []).findvalue(@(s) s.squadId == squadId)
})

let curSquadArmy = Computed(@() getLinkedArmyName(curSquad.get()))

let curVehicleType = Computed(function() {
  let { armyId = null, squadId = null } = selectVehParams.get()
  if (armyId == null || squadId == null)
    return null

  return squadsCfgById.get()?[armyId][squadId].vehicleType
})

let getVehicleSquad = @(vehicle) getFirstLinkByType(vehicle, "curVehicle")
let findSelVehicle = @(vehicleList, squadGuid) getObjectsByLink(vehicleList, squadGuid, "curVehicle")?[0].guid

function calcVehicleStatus(vehicle, vehicles, growthByItem, itemLinks, shopItems, vehByOwner) {
  let { basetpl } = vehicle
  let trimmed = trimUpgradeSuffix(basetpl)
  let isAllowed = trimmed in vehicles
  let growthId = growthByItem?[trimmed]
  let shopItemId = (itemLinks?[basetpl] ?? [])
    .findvalue(@(id) id in shopItems)

  local flags = CAN_USE
  if (!isAllowed)
    flags = flags | CANT_USE
  else if (vehicle?.isShopItem) {
    flags = flags | LOCKED
    if (basetpl in vehByOwner)
      flags = flags | IS_BUSY_BY_SQUAD
    else if (growthId != null)
      flags = flags | AVAILABLE_IN_GROWTH
    else if (shopItemId != null)
      flags = flags | CAN_PURCHASE
  }

  let res = { flags }
  if (flags == CAN_USE)
    res.__update({
      canUse = true
      statusText = loc("squad/vehicles")
    })
  if (flags & CANT_USE)
    res.__update({
      isHiddenInGroup = true
      statusText = loc("hint/notAllowedForCurSquad")
    })
  else if (flags & AVAILABLE_IN_GROWTH)
    res.__update({
      growthId
      statusText = loc("itemDemandsHeader/canObtainInGrowth")
    })
  else if (flags & CAN_PURCHASE)
    res.__update({
      shopItemId 
      statusText = loc("itemDemandsHeader/canObtainInShop_yes")
    })
  else if (flags & IS_BUSY_BY_SQUAD)
    res.__update({
      owners = vehByOwner[basetpl]
      statusText = loc("itemDemandsHeader/busyBySquad")
    })
  else if (flags & LOCKED)
    res.statusText <- loc("hint/unknowVehicleReceive")

  return res
}

let vehicleSort = @(vehicles, curVeh)
  vehicles.sort(@(a, b) (b == curVeh) <=> (a == curVeh)
    || (a?.status.flags ?? 0) <=> (b?.status.flags ?? 0)
    || (a?.growthTier ?? 0) <=> (b?.growthTier ?? 0)
    || a.basetpl <=> b.basetpl
    || (a?.guid ?? "") <=> (b?.guid ?? ""))


let curArmyVehicles = Computed(function() {
  let armyId = curArmy.get()
  return (itemsByArmies.get()?[armyId] ?? {}).filter(@(i) i?.itemtype == "vehicle")
})


let vehicles = Computed(function() {
  local res = []
  let squadGuid = curSquad.get()?.guid
  let vehicleType = curVehicleType.get()
  if (squadGuid == null || vehicleType == null)
    return res

  let armyId = getLinkedArmyName(curSquad.get())
  let curVehicles = curArmyVehicles.get()
  let vehByOwner = {}
  foreach (item in curVehicles) {
    if (item?.itemsubtype != vehicleType)
      continue

    let tpl = trimUpgradeSuffix(item.basetpl)
    let ownerGuid = getVehicleSquad(item)
    if (ownerGuid == null || ownerGuid == squadGuid)
      res.append(item)
    if (ownerGuid != null)
      vehByOwner[tpl] <- (vehByOwner?[tpl] ?? []).append(ownerGuid)
  }

  let selectedGuid = findSelVehicle(res, squadGuid)
  let haveTmpls = res.reduce(@(r, v) r.rawset(trimUpgradeSuffix(v.basetpl), true), {})
  let filterFunc = @(tplId, tpl) tpl?.itemtype == "vehicle"
    && (tpl?.itemsubtype ?? "") == vehicleType
    && (tpl?.upgradeIdx ?? 0) == 0
    && trimUpgradeSuffix(tplId) not in haveTmpls

  addShopItems(res, armyId, filterFunc, vehByOwner)

  let allowed = allowedVehicles.get()?[armyId][curSquad.get()?.squadId] ?? {}
  let growthByItem = curGrowthByItem.get()
  let itemLinks = itemToShopItem.get()?[armyId] ?? {}
  let shopItems = curArmyItemsPrefiltered.get()
  res = res.map(@(vehicle) vehicle.__merge({
    status = calcVehicleStatus(vehicle, allowed, growthByItem, itemLinks, shopItems, vehByOwner)
  }))
  vehicleSort(res, res.findvalue(@(v) v.guid == selectedGuid))
  return res
})

let selectedVehicle = Computed(function() {
  let vList = vehicles.get()
  let squadGuid = curSquad.get()?.guid
  if (!squadGuid || vList.len() == 0)
    return null

  let guid = findSelVehicle(vList.filter(@(v) v?.isShopItem != true), squadGuid)
  return guid ? findItemByGuid(vList, guid) : null
})

function updateVehicle(selVehicle) {
  let cur = viewVehicle.get()
  if (viewVehicle.get() != null) {
    let new = cur?.isShopItem ? vehicles.get().findvalue(@(item) item?.basetpl == cur.basetpl)
      : cur?.guid ? findItemByGuid(vehicles.get(), cur.guid)
      : null
    viewVehicle.set(new ?? selVehicle)
  } else
    viewVehicle.set(selVehicle)
}

subscribeAndInit(updateVehicle, selectedVehicle)

function setVehicleToSquad(squadGuid, vehicleGuid) {
  if (vehicleBySquad.get()?[squadGuid] == vehicleGuid)
    return

  set_vehicle_to_squad(vehicleGuid, squadGuid, @(_) updateBROnVehicleChange(squadGuid))
}

function selectVehicle(vehicle) {
  if (isChangesBlocked.get()) {
    showBlockedChangesMessage()
    return
  }
  let { canUse = false, statusText = null, growthId = null } = vehicle?.status
  if (!canUse) {
    let buttons = [{
      text = loc("Close"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
    }]
    if (growthId != null)
      buttons.append({
        text = loc("GoToGrowth")
        action = @() jumpToArmyGrowth(growthId)
        customStyle = { hotkeys = [["^J:Y"]] }
      })
    return showMsgbox({
      text = statusText
      buttons
    })
  }

  let squad = curSquad.get()
  if (squad != null)
    setVehicleToSquad(squad.guid, vehicle?.guid)

  vehicleClear()
}

let hasSquadVehicle = @(squadCfg) (squadCfg?.vehicleType ?? "") != ""

let squadsWithVehicles = Computed(function() {
  let { armyId = null } = selectVehParams.get()
  if (!armyId)
    return []

  let armyConfig = squadsCfgById.get()?[armyId]
  return (squadsByArmy.get()?[armyId] ?? [])
    .filter(@(squad) hasSquadVehicle(armyConfig?[squad.squadId]))
})

let curSquadId = Computed(@()
  selectVehParams.get()?.squadId ?? squadsWithVehicles.get()?[0].squadId)

function setCurSquadId(id) {
  let { squadId = null } = selectVehParams.get()
  if (squadId != null && squadId != id)
    selectVehParams.mutate(@(params) params.__update({ squadId = id }))
}

function goToSquad(squad) {
  if (squad != null)
    selectVehParams.mutate(@(params) params.__update({
      armyId = curArmy.get()
      squadId = squad
      isCustomMode = false
      isHitcamMode = false
    }))
}

return {
  viewVehicle
  selectedVehicle
  selectVehParams
  vehicles
  squadsWithVehicles
  curSquad
  curSquadId
  setCurSquadId
  curSquadArmy

  vehicleClear
  selectVehicle
  hasSquadVehicle
  getVehicleSquad
  goToSquad

  isCustomizeWndOpen
  closeCustomizeWnd

  AVAILABLE_IN_GROWTH
  IS_BUSY_BY_SQUAD
  CAN_PURCHASE
  LOCKED
  CANT_USE
  CAN_USE
}
