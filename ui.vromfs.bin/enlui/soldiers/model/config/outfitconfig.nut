from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/helpers/metalink.nut" import getLinkedArmyName, getLinkedSquadGuid, isLinkedTo,
  isObjectHaveLinkTypeToAny, getFirstLinkByType
from "%ui/meta/servProfile.nut" import soldiersOutfit, armies
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfileLookCfg
from "%ui/soldiers/model/state.nut" import curArmy, armySquadsById, curSquadId, squadsByArmy
from "%ui/soldiers/model/config/soldierResideConfig.nut" import resideCustomization
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/ui_library.nut" import *

let outfitShopTypes = mkComputedConfigGet("outfit_shop", {})
let outfitSchemes = mkComputedConfigGet("outfit_schemes", {})

let LOCKED_DRESS_UP_SLOTS = { head = true, hair = true }

let isObjAvailableForCampaign = @(item, campaignId) isLinkedTo(item, campaignId)
  || isObjectHaveLinkTypeToAny(item, LOCKED_DRESS_UP_SLOTS)

let ownedOutfitsByArmy = Computed(function() {
  let outfits = {}
  let templates = {}

  foreach (outfit in soldiersOutfit.get()) {
    let armyId = getLinkedArmyName(outfit)
    if (armyId not in outfits) {
      outfits[armyId] <- []
      templates[armyId] <- {}
    }
    outfits[armyId].append(outfit)
    templates[armyId][outfit.basetpl] <- true
  }

  foreach (armyId, squadsList in squadsByArmy.get()) {
    let squadsCfg = squadsCfgById.get()?[armyId]
    if (armyId not in templates)
      templates[armyId] <- {}
    foreach (squad in squadsList) {
      let { expireTime = 0 } = squad
      if (expireTime > 0)
        continue
      let { allowOutfits = [] } = squadsCfg?[squad.squadId]
      foreach (basetpl in allowOutfits)
        templates[armyId][basetpl] <- true
    }
  }

  return { outfits, templates }
})


function getOutfitIdByCampaign(squadsCfg, armyId, squadId, campaignId = null) {
  let { soldierTemplatePreset = {} } = squadsCfg?[armyId][squadId]
  if (soldierTemplatePreset.len() == 1)
    return soldierTemplatePreset.values()[0]

  local suitableCampaignId = campaignId
  if (campaignId not in soldierTemplatePreset) {
    let { campaignReplaceTemplate = {} } = armies.get()?[armyId]
    if (campaignId in campaignReplaceTemplate)
      suitableCampaignId = campaignReplaceTemplate[campaignId]
  }

  return soldierTemplatePreset?[suitableCampaignId] ?? ""
}

function getSquadLook(armyId, squadId, armySquadsInfo, lookCfg, field) {
  let campaign = armySquadsInfo?[armyId][squadId].campaignOutfit ?? ""
  foreach (look in lookCfg?[campaign] ?? [])
    if (look.armies.contains(armyId))
      return look?[field] ?? campaign
  return campaign
}


let getSquadOutfit = @(armyId, squadId, armySquadsInfo, lookCfg)
  getSquadLook(armyId, squadId, armySquadsInfo, lookCfg, "outfit")

let getSquadCamo = @(armyId, squadId, armySquadsInfo, lookCfg)
  getSquadLook(armyId, squadId, armySquadsInfo, lookCfg, "camouflage")

function getCustomizeScheme(squadsCfg, outfitSchemesVal, armyId, squadId, campaignId = null) {
  let outfitPresetId = getOutfitIdByCampaign(squadsCfg, armyId, squadId, campaignId)
  return outfitSchemesVal?[outfitPresetId] ?? {}
}

function isOutfitAllowedByCampaignImpl(outfit, soldier, outfitSchemesVal,
  squadsVal, armySquadsByIdVal, squadsCfgByIdVal, lookCfg) {
  if (!soldier)
    return false

  let armyId = getLinkedArmyName(soldier)
  let squadGuid = getLinkedSquadGuid(soldier)
  let { squadId = "" } = squadsVal?[squadGuid]
  let campaignOutfit = getSquadOutfit(armyId, squadId, armySquadsByIdVal, lookCfg)
  if (!isObjAvailableForCampaign(outfit, campaignOutfit))
    return false

  let { gametemplate = null } = soldier
  let scheme = {}.__update(getCustomizeScheme(squadsCfgByIdVal, outfitSchemesVal,
    armyId, squadId, campaignOutfit), resideCustomization.get()?[gametemplate] ?? {})

  let slotId = outfit?.links[soldier.guid] ?? ""
  if (slotId == "")
    return false
  return (scheme?[slotId] ?? []).contains(outfit.basetpl)
}

let freeOutfitsForArmy = Computed(function() {
  let armyId = curArmy.get()
  let squadOutfit = getSquadOutfit(armyId,
    curSquadId.get(),
    armySquadsById.get(),
    gameProfileLookCfg.get())

  let res = []
  let armyOutfits = ownedOutfitsByArmy.get().outfits?[armyId] ?? []
  foreach (outfit in armyOutfits)
    if ((outfit?.links.len() ?? 0) <= 1
        || squadOutfit == ""
        || isObjAvailableForCampaign(outfit, squadOutfit))
      res.append(outfit)
  return res
})

let equippedOutfitsForArmy = Computed(@() freeOutfitsForArmy.get()
  .filter(@(outfit) (outfit?.links.len() ?? 0) > 1))

function getSquadCamoByVehicle(vehicle, squadsByArmiesV, armySquadsByIdV, lookCfg) {
  let armyId = getLinkedArmyName(vehicle)
  let squadGuid = getFirstLinkByType(vehicle, "curVehicle")
  let { squadId = null } = squadsByArmiesV?[armyId][squadGuid]
  return squadId == null ? null
    : getSquadCamo(armyId, squadId, armySquadsByIdV, lookCfg)
}

return {
  outfitShopTypes
  outfitSchemes
  ownedOutfitsByArmy
  freeOutfitsForArmy
  equippedOutfitsForArmy

  isOutfitAllowedByCampaignImpl

  getCustomizeScheme
  getSquadOutfit
  getSquadCamo
  isObjAvailableForCampaign

  getSquadCamoByVehicle
}
