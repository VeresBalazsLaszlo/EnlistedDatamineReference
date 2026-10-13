import "%ui/components/armiesPresentation.nut" as armiesPresentation
import "%ui/soldiers/model/armyEffects.nut" as armyEffects
import "%ui/soldiers/model/squadsParams.nut" as squadsParams
import "%ui/meta/servProfile.nut" as servProfile
from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%enlSqGlob/userInfoState.nut" import userInfo, userInfoUpdate
from "%enlSqGlob/weapon_slots.nut" import weaponSlotsKeys, EWS_PRIMARY
from "dagor.memtrace" import set_huge_alloc_threshold
from "%sqstd/json.nut" import saveJson
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile, allArmiesInfo
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN
from "%ui/currency/premium.nut" import hasPremium
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/meta/clientApi.nut" import lastTransactId, add_army_exp, reset_profile, update_profile,
  update_partial, drop_items, soldiers_regenerate_view, add_squad, recreate_squad, add_all_squads,
  add_soldier, add_items, add_items_by_type, check_purchases, get_shop_item, remove_squad,
  add_outfit, set_squad_outfit_preset, make_squad_researches, force_squad_outfit_preset,
  exchange_exp_to_silver, global_gift_reset, add_booster, remove_booster
from "%ui/meta/servProfile.nut" import armies
from "%ui/meta/profile.nut" import curArmiesList, itemsByArmies, curArmiesListExt,
  commonArmy, curCampItems, curCampSoldiers, squadsByArmies, campItemsByLink
from "%ui/helpers/metalink.nut" import getObjectsByLinkSorted, getObjectsTableByLinkType,
  getItemIndex
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/components/mkSpecialItemIcon.nut" import SIGN_NONE, SIGN_PREMIUM, SIGN_EVENT
from "%ui/soldiers/model/rentedSquads.nut" import expiredRentedSquads
from "%ui/components/soldierClasses.nut" import getClassCfg
from "%ui/state/queueState.nut" import isInQueue
from "%ui/ui_library.nut" import *



let curArmiesStorage = mkOnlineSaveData("curArmies", @() {})
let setCurArmies = curArmiesStorage.setValue
let curArmies = curArmiesStorage.watch
let playerSelectedSquadsStorage = mkOnlineSaveData("playerSelectedSquads", @() {})
let setPlayerSelectedSquads = playerSelectedSquadsStorage.setValue
let playerSelectedSquads = playerSelectedSquadsStorage.watch
let roomArmy = mkWatched(persist, "roomArmy", null)

let allAvailableArmies = Computed(function() {
  return gameProfile.get()?.campaigns.map(@(campaign) campaign.armies.map(@(a) a.id)) ?? {}
})

let curArmy = Computed(function() {
  local armyId = roomArmy.get() ?? curArmies.get()?[COMMON_CAMPAIGN]
  if (!curArmiesList.get().contains(armyId))
    armyId = curArmiesList.get()?[0]
  return armyId
})

let canSwitchArmy = Computed(@() !isInQueue.get())

function selectArmy(army) {
  if (!canSwitchArmy.get())
    return

  let campaign = gameProfile.get()?.campaignByArmyId[army]
  if (campaign && curArmies.get()?[campaign] != army)
    setCurArmies(curArmies.get().__merge({ [campaign] = army }))
}

let curArmyData = Computed(@() armies.get()?[curArmy.get()])

const armyLimitsDefault = {
  maxSquadsInBattle = 1
  maxInfantrySquads = 1
  maxBikeSquads = 0
  maxVehicleSquads = 0
  maxTransportSquads = 0
  soldiersReserve = 0
  premSquadSlots = 0
}

let limitsByArmy = Computed(function() {
  let res = {}
  let armiesInfo = allArmiesInfo.get()
  let { premiumBonuses = null } = gameProfile.get()
  let effects = armyEffects.get()
  let hasPrem = hasPremium.get()

  foreach (armyId in curArmiesList.get()) {
    let limits = armyLimitsDefault.map(function(val, key) {
      local keyValue = (armiesInfo?[armyId][key] ?? val) + (effects?[armyId][key] ?? 0)
      if (hasPrem)
        keyValue += premiumBonuses?[key] ?? 0
      return keyValue
    })
    res[armyId] <- limits
  }

  return res
})

let curArmyLimits = Computed(@() limitsByArmy.get()?[curArmy.get()] ?? armyLimitsDefault)

let sortByIndex = @(a,b) getItemIndex(a) <=> getItemIndex(b)

let soldiersBySquad = Computed(@()
  getObjectsTableByLinkType(curCampSoldiers.get(), "squad")
    .map(@(list) list.sort(sortByIndex)))

let getItemOwnerGuid = @(item) (item?.links ?? {})
  .keys()
  .findvalue(@(guid) guid in curCampSoldiers.get() || guid in curCampItems.get())

function getItemOwnerSoldier(itemGuid) {
  foreach (guid, _ in curCampItems.get()?[itemGuid].links ?? {})
    if (guid in curCampSoldiers.get())
      return curCampSoldiers.get()[guid]
  return null
}

let vehicleBySquad = Computed(@()
  getObjectsTableByLinkType(curCampItems.get(), "curVehicle")
    .map(@(list) list[0]))


function mixSquadData(config, presentation) {
  let titleLocId = presentation?.titleLocId ?? "squad/defaultTitle"
  return {
    size = config?.size ?? 1 
    capacity = config?.size ?? 0
    squadType = config?.squadType ?? "unknown"
    vehicleType = config?.vehicleType ?? ""
    isParatroopers = config?.isParatroopers
    icon = presentation?.icon ?? ""
    image = presentation?.image ?? ""
    nameLocId = presentation?.nameLocId ?? "squad/defaultName"
    titleLocId
    manageLocId = presentation?.manageLocId ?? titleLocId
    premIcon = presentation?.premIcon
  }
}

let squadsByArmy = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesList.get()) {
    let configs = squadsCfgById.get()?[armyId]
    let squadsList = (squadsByArmies.get()?[armyId] ?? {})
      .values()
      .map(function(squad) {
        let squadGuid = squad.guid
        let squadId = squad.squadId
        let config = configs?[squadId]
        let curVehicle = vehicleBySquad.get()?[squadGuid]
        squad = squad.__merge(mixSquadData(config, getSquadPresentation(squadId, armyId)))

        let { sign = SIGN_NONE, battleExpBonus = 0 } = config
        if (sign == SIGN_PREMIUM)
          squad.premIcon = squad.premIcon ?? armiesPresentation?[armyId].premIcon
        if (battleExpBonus > 0)
          squad.battleExpBonus <- battleExpBonus

        squad.vehicle <- curCampItems.get()?[curVehicle?.guid]
        squad.squadSize <- soldiersBySquad.get()?[squadGuid].len() ?? 0
        return squad
      })
      .sort(sortByIndex)
    res[armyId] <- squadsList
  }
  return res
})

let lockedSquadsByArmy = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesList.get()) {
    let unlockedSquads = {}
    foreach (squad in (squadsByArmies.get()?[armyId] ?? {}))
      unlockedSquads[squad.squadId] <- true

    let squadsList = []
    res[armyId] <- squadsList
    foreach (squadId, config in squadsCfgById.get()?[armyId] ?? {}) {
      if (squadId in unlockedSquads || config?.isFake)
        continue

      let squad = mixSquadData(config, getSquadPresentation(squadId, armyId))
      squad.squadId <- squadId
      squad.size <- config.size
      squadsList.append(squad)
    }
  }
  return res
})

let armySquadsById = Computed(@() squadsByArmy.get().map(@(squads)
  squads.reduce(@(res, s) res.rawset(s.squadId, s), {})))

let curUnlockedSquads = Computed(@() squadsByArmy.get()?[curArmy.get()] ?? [])

let lockedArmySquadsById = Computed(@() lockedSquadsByArmy.get().map(@(squads)
  squads.reduce(@(res, s) res.rawset(s.squadId, s), {})))

function hasMechanizedLimit(squads, expired, slotCnt, reqInfantry) {
  local totInfantryCount = 0
  local infantryCount = 0
  foreach (squad in squads) {
    let { guid, vehicleType = "" } = squad
    if (guid not in expired
        && (vehicleType == "" || vehicleType == "bike" || vehicleType == "jeep" || vehicleType == "truck")) {
      totInfantryCount++
      if (getItemIndex(squad) < slotCnt)
        infantryCount++
    }
  }
  return totInfantryCount >= reqInfantry && infantryCount < reqInfantry
}


let chosenSquadsByArmy = Computed(function() {
  let res = {}
  let armiesInfo = allArmiesInfo.get()
  let expired = expiredRentedSquads.get()
  let squadsCfg = squadsCfgById.get()
  foreach (armyId in curArmiesList.get()) {
    let reqInfantry = armiesInfo?[armyId].maxInfantrySquads ?? 0
    local {
      maxSquadsInBattle, premSquadSlots, maxInfantrySquads,
      maxBikeSquads, maxVehicleSquads, maxTransportSquads
    } = limitsByArmy.get()?[armyId] ?? armyLimitsDefault

    let firstPremSlotIdx = maxSquadsInBattle
    let lastSlotIdx = maxSquadsInBattle + premSquadSlots
    let armySquads = squadsByArmy.get()?[armyId] ?? []
    local maxMechanized = hasMechanizedLimit(armySquads, expired, lastSlotIdx, reqInfantry)
      ? maxSquadsInBattle - reqInfantry
      : maxVehicleSquads

    let squadsList = []
    foreach (squad in armySquads) {
      let { guid, vehicleType = "", squadId = "" } = squad
      if (guid in expired)
        continue

      let squadIdx = getItemIndex(squad)
      if (squadIdx >= lastSlotIdx)
        continue

      let isInPremSlot = squadIdx >= firstPremSlotIdx && squadIdx < lastSlotIdx
      let { sign = SIGN_NONE } = squadsCfg?[armyId][squadId]
      let canUsePremSlot = sign == SIGN_PREMIUM || sign == SIGN_EVENT

      if (isInPremSlot) {
        if (premSquadSlots <= 0 || !canUsePremSlot)
          continue

        if (vehicleType != "" && vehicleType != "bike" && vehicleType != "jeep" && vehicleType != "truck")
          maxMechanized--

        if (premSquadSlots > 0)
          premSquadSlots--
      }
      else {
        if (maxSquadsInBattle <= 0)
          continue

        if (vehicleType == "bike" || vehicleType == "jeep") {
          if (maxBikeSquads <= 0)
            continue
          maxBikeSquads--
        }
        else if (vehicleType == "truck") {
          if (maxTransportSquads <= 0)
            continue
          maxTransportSquads--
        }
        else if (vehicleType != "") {
          if (maxVehicleSquads <= 0 || maxMechanized <= 0)
            continue
          maxVehicleSquads--
          maxMechanized--
        }
        else {
          if (maxInfantrySquads <= 0)
            continue
          maxInfantrySquads--
        }

        if (maxSquadsInBattle > 0)
          maxSquadsInBattle--
      }

      squadsList.append(squad)

      if (maxSquadsInBattle <= 0 && premSquadSlots <= 0)
        break
    }

    res[armyId] <- squadsList
  }
  return res
})

let curChosenSquads = Computed(@() chosenSquadsByArmy.get()?[curArmy.get()] ?? [])

let curSquadId = Computed(function() {
  local squadId = null
  let chosenSquads = curChosenSquads.get() ?? []
  if (chosenSquads.len() > 0) {
    squadId = playerSelectedSquads.get()?[curArmy.get()]
    if (!squadId || chosenSquads.findindex(@(s) s.squadId == squadId) == null)
      squadId = chosenSquads[0].squadId
  }
  return squadId
})

function setCurSquadId(squadId) {
  let armyId = curArmy.get()
  if (armyId && squadId != playerSelectedSquads.get()?[armyId])
    setPlayerSelectedSquads(playerSelectedSquads.get().__merge({ [armyId] = squadId }))
}

function getModSlots(item) {
  let res = []
  foreach (slotType, scheme in item?.equipScheme ?? {})
    if ((scheme?.listSize ?? 0) <= 0) 
      res.append({
        slotType = slotType
        scheme = scheme
        equipped = campItemsByLink.get()?[item.guid][slotType][0].guid
      })
  return res
}

let getScheme = @(item, slotType) item?.equipScheme[slotType]

let curSquad = Computed(@()
  curUnlockedSquads.get().findvalue(@(s) s.squadId == curSquadId.get()))

let curSquadParams = Computed(@()
  squadsParams.get()?[curArmy.get()][curSquadId.get()])

let curSquadSoldiersInfo = Computed(function() {
  let squad = curSquad.get()
  return squad != null
    ? getObjectsByLinkSorted(curCampSoldiers.get(), squad.guid, "squad")
    : []
})

let armoryByArmy = Computed(@() itemsByArmies.get()
  .map(@(list) list.filter(@(item) item.links.len() == 1)
    .values()))

let itemCountByArmy = Computed(function() {
  let res = {}
  foreach (armyId in curArmiesListExt.get()) {
    let armyCount = {}
    foreach (item in itemsByArmies.get()?[armyId] ?? []) {
      let { basetpl } = item
      armyCount[basetpl] <- (armyCount?[basetpl] ?? 0) + item.count
    }
    res[armyId] <- armyCount
  }
  return res
})

let armyItemCountByTpl = Computed(function() {
  return {}.__update(itemCountByArmy.get()?[curArmy.get()] ?? {},
    itemCountByArmy.get()?[commonArmy.get()] ?? {})
})


let curCampItemsCount = Computed(function() {
  local res = {}
  foreach (armyCount in itemCountByArmy.get()) {
    if (res.len() == 0) {
      res = clone armyCount
      continue
    }
    foreach (basetpl, count in armyCount)
      res[basetpl] <- (res?[basetpl] ?? 0) + count
  }
  return res
})

let curVehicle = Computed(@() vehicleBySquad.get()?[curSquad.get()?.guid].guid)

let getEquippedItemGuid = @(itemsByLink, soldierGuid, slotType, slotId = null)
  itemsByLink?[soldierGuid][slotType]
    .findvalue(@(item) ((slotId ?? -1) == -1 || slotId == getItemIndex(item)))
    .guid

let getSoldierByGuid = @(guid) curCampSoldiers.get()?[guid]

function resetProfile() {
  reset_profile(function(res) {
    debugTableData(res)
    check_purchases()
  })
}

function dumpProfile() {
  let { userId = -1 } = userInfo.get()
  if (userId < 0)
    return

  let path = $"enlisted_profile_{userId}.json"
  let prevSize = set_huge_alloc_threshold(66560 << 10)
  saveJson(path, servProfile.map(@(w) w.get()), { logger = log_for_user })
  set_huge_alloc_threshold(prevSize)
  console_print($"Current user profile saved to {path}")
}

function getSoldierItemSlots(guid, itemsByLink) {
  
  let res = []
  foreach (slotType, itemsList in itemsByLink?[guid] ?? {})
    foreach (item in itemsList)
      res.append({ item, slotType, slotId = getItemIndex(item) })
  return res
}

let getSoldierItem = @(guid, slot, campItems) campItems?[guid][slot][0]

function getDemandingSlots(slotId, ownerInfo, itemsByLink) {
  let { guid, equipScheme = {} } = ownerInfo
  let equipGroup = equipScheme?[slotId].atLeastOne ?? ""
  let res = {}
  if (equipGroup == "")
    return res

  foreach (slotType, slotScheme in equipScheme)
    if (slotScheme?.atLeastOne == equipGroup) 
      res[slotType] <- getEquippedItemGuid(itemsByLink, guid, slotType)
  return res
}

function getDemandingSlotsInfo(owner, slotType) {
  let { atLeastOne = "" } = owner?.equipScheme[slotType]
  return atLeastOne != "" ? loc($"equipDemand/{atLeastOne}") : ""
}

let unequippableSlots = {
  paratrooper = ["secondary"]
}

function canChangeEquipmentInSlot(soldierClass, weaponSlot) {
  let { isPremium = false, kind = "unknown" } = getClassCfg(soldierClass)
  return (!isPremium || weaponSlot != weaponSlotsKeys[EWS_PRIMARY])
    && !unequippableSlots?[kind].contains(weaponSlot)
}


console_register_command(drop_items, "meta.dropCrate")
console_register_command(@() update_profile(), "meta.updateProfile")
console_register_command(@() update_partial(lastTransactId.get()), "meta.updatePartial")
console_register_command(@(transactId) update_partial(transactId), "meta.updatePartialTransaction")

console_register_command(soldiers_regenerate_view, "meta.soldiersRegenerateView")
console_register_command(@(exp) add_army_exp(curArmy.get(), exp), "meta.addCurArmyExp")
console_register_command(global_gift_reset, "meta.globalGiftReset")
console_register_command(add_squad, "meta.addSquad")
console_register_command(recreate_squad, "meta.recreateSquad")
console_register_command(remove_squad, "meta.removeSquad")
console_register_command(@() add_all_squads(curArmy.get()), "meta.addAllSquads")
console_register_command(@(shopId) get_shop_item(shopId), "meta.getFromShop")
console_register_command(@(sClass, tier) add_soldier(curArmy.get(), sClass, tier), "meta.addSoldier")

console_register_command(@(booster) add_booster(booster), "meta.addBooster")
console_register_command(@(booster, seconds) add_booster(booster, seconds), "meta.addBoosterWithTime")
console_register_command(remove_booster, "meta.removeBooster")

console_register_command(@(itemTmpl) add_items(itemTmpl, 1), "meta.addItem")
console_register_command(@(itemTmpl, count) add_items(itemTmpl, count), "meta.addItems")
console_register_command(@(count) exchange_exp_to_silver(curArmy.get(), count), "meta.exchangeExpToSilver")
console_register_command(@(itemTmpl) add_outfit(itemTmpl, 1), "meta.addOutfit")
console_register_command(@(campaignId) set_squad_outfit_preset(curSquad.get()?.guid, campaignId), "meta.dressUpCurSquadForCampaign")
console_register_command(@(presetId) force_squad_outfit_preset(curSquad.get()?.guid, presetId), "meta.forceDressUpCurSquadByPreset")
console_register_command(@(squadId)
  make_squad_researches(curArmy.get(), squadId), "meta.makeSquadResearches")

let DROP_COMMANDS = {
  addAllVehicles          = ["vehicle"]
  addAllSemiautos         = ["semiauto", "carbine_tanker", "assault_semi"]
  addAllShotguns          = ["shotgun"]
  addAllSniperBoltactions = ["boltaction"]
  addAllSniperSemiautos   = ["semiauto_sniper"]
  addAllBoltactions       = ["boltaction_noscope"]
  addAllGrenadeRifles     = ["rifle_grenade_launcher", "rifle_at_grenade_launcher"]
  addAllAntitankRifles    = ["antitank_rifle"]
  addAllGrenadeLaunchers  = ["grenade_launcher"]
  addAllInfantryLaunchers = ["infantry_launcher"]
  addAllRocketLaunchers   = ["launcher"]
  addAllMachineguns       = ["mgun"]
  addAllSubmachineguns    = ["submgun", "carbine_pistol"]
  addAllAssaultrifles     = ["assault_rifle"]
  addAllFlareguns         = ["flaregun"]
  addAllMortars           = ["mortar"]
  addAllFlamethrowers     = ["flamethrower"]
  addAllScopes            = ["scope"]
  addAllPistols           = ["sideweapon"]
  addAllMedkits           = ["medkits", "medic_medkits"]
  addAllGrenades          = ["grenade", "explosion_pack", "molotov", "tnt_block_exploder",
                             "impact_grenade", "smoke_grenade", "incendiary_grenade"]
  addAllMines             = ["antipersonnel_mine", "antitank_mine", "lunge_mine"]
  addAllRepairKits        = ["repair_kit"]
  addAllMelee             = ["melee", "shovel", "axe", "sword"]
  addAllBayonet           = ["bayonet"]
  addAllBackpacks         = ["backpack", "small_backpack", "small_grenade_pouch", "big_grenade_pouch", "small_ammo_pouch", "big_ammo_pouch"]
  addAllBinoculars        = ["binoculars_usable"]
  addAllFlasks            = ["flask_usable"]
}
let COMMON_ARMY_DROP_COMMANDS = {
  addAllTickets           = ["ticket"]
  addAllBoosters          = ["booster"]
}
let COUNT_OVERRIDES = {
  addAllTickets = 10
}
foreach (cmd, drop in DROP_COMMANDS) {
  let types = drop
  let count = COUNT_OVERRIDES?[cmd] ?? 1
  console_register_command(@() add_items_by_type(curArmy.get(), types, count), $"meta.{cmd}")
}
foreach (cmd, drop in COMMON_ARMY_DROP_COMMANDS) {
  let types = drop
  let count = COUNT_OVERRIDES?[cmd] ?? 1
  console_register_command(@() add_items_by_type(commonArmy.get(), types, count), $"meta.{cmd}")
}

console_register_command(function() {
  let dropTable = {
    [curArmy.get()] = DROP_COMMANDS,
    [commonArmy.get()] = COMMON_ARMY_DROP_COMMANDS
  }
  foreach (armyId, typeList in dropTable)
    foreach (cmd, types in typeList)
      add_items_by_type(armyId, types, COUNT_OVERRIDES?[cmd] ?? 1)
}, "meta.addAll")

local storedToken
console_register_command(function() {
  let uiv = userInfo.get()
  if (storedToken) {
    userInfoUpdate(uiv.__merge({ token = storedToken }))
    storedToken = null
  } else {
    storedToken = uiv.token
    userInfoUpdate(uiv.__merge({ token = null }))
  }
  console_print(storedToken ? "Token removed" : "Token restored")
}, "net.toggleToken")


return {
  resetProfile
  dumpProfile
  armies
  curSquadId
  setCurSquadId
  curUnlockedSquads
  chosenSquadsByArmy
  curChosenSquads
  limitsByArmy
  armyLimitsDefault
  curArmyLimits
  curSquad
  curSquadParams
  curSquadSoldiersInfo
  curCampItemsCount
  itemCountByArmy
  armyItemCountByTpl
  playerSelectedSquads
  getModSlots
  getScheme
  getSoldierByGuid
  getSoldierItemSlots
  getSoldierItem
  getDemandingSlots
  getDemandingSlotsInfo

  squadsByArmy
  lockedSquadsByArmy
  armySquadsById
  lockedArmySquadsById

  curArmy
  selectArmy
  setRoomArmy = @(armyId) roomArmy.set(armyId)
  curArmyData
  armoryByArmy
  curVehicle
  allAvailableArmies
  canSwitchArmy

  vehicleBySquad
  soldiersBySquad
  getItemOwnerGuid
  getItemOwnerSoldier

  getEquippedItemGuid
  canChangeEquipmentInSlot
}
