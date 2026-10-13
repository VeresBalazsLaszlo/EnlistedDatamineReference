import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/soldiers/model/state.nut" import armies, armySquadsById, curSquadSoldiersInfo
from "%ui/soldiers/model/collectSoldierData.nut" import collectSoldierDataImpl
from "%ui/soldiers/model/soldierPerks.nut" import perksData
from "%ui/meta/profile.nut" import campItemsByLink, curCampSquads, curCampSoldiers
from "%ui/meta/servProfile.nut" import squads, soldiersLook
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfileLookCfg
from "%ui/soldiers/model/config/outfitConfig.nut" import equippedOutfitsForArmy,
  isOutfitAllowedByCampaignImpl, outfitSchemes
from "%ui/meta/perks/perksSchemesConfig.nut" import soldierSchemes
from "%ui/meta/clientApi.nut" import set_soldier_outfit_preset, soldier_reside
from "%ui/soldiers/model/config/soldierTrainingConfig.nut" import maxTrainByClass
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/ui_library.nut" import *

let curSoldierIdx = nestWatched("curSoldierIdx", null)
let defSoldierGuid = nestWatched("defSoldierGuid", null)


function collectSoldierData(soldier) {
  let outfitSchemesVal = outfitSchemes.get()
  let squadsVal = squads.get()
  let armySquadsByIdVal = armySquadsById.get()
  let squadsCfgByIdVal = squadsCfgById.get()
  let lookCfg = gameProfileLookCfg.get()

  return collectSoldierDataImpl(
    soldier, perksData.get(), curCampSquads.get(), armies.get(),
    sClassesCfg.get(), campItemsByLink.get(), soldiersLook.get(),
    equippedOutfitsForArmy.get().filter(
      @(outfit) isOutfitAllowedByCampaignImpl(outfit, soldier, outfitSchemesVal,
        squadsVal, armySquadsByIdVal, squadsCfgByIdVal, lookCfg)),
    soldierSchemes.get(), maxTrainByClass.get())
}

let curSoldiersDataList = Computed(function() {
  let perksDataVal = perksData.get()
  let curCampSquadsVal = curCampSquads.get()
  let armiesVal = armies.get()
  let sClassesCfgVal = sClassesCfg.get()
  let campItemsByLinkVal = campItemsByLink.get()
  let soldiersLookVal = soldiersLook.get()
  let equippedOutfitsForArmyVal = equippedOutfitsForArmy.get()
  let outfitSchemesVal = outfitSchemes.get()
  let maxTrainByClassVal = maxTrainByClass.get()
  let squadsVal = squads.get()
  let armySquadsByIdVal = armySquadsById.get()
  let squadsCfgByIdVal = squadsCfgById.get()
  let lookCfg = gameProfileLookCfg.get()

  return curSquadSoldiersInfo.get().map(@(soldier) collectSoldierDataImpl(
    soldier, perksDataVal, curCampSquadsVal, armiesVal,
    sClassesCfgVal, campItemsByLinkVal, soldiersLookVal,
    equippedOutfitsForArmyVal.filter(
      @(outfit) isOutfitAllowedByCampaignImpl(outfit, soldier, outfitSchemesVal,
        squadsVal, armySquadsByIdVal, squadsCfgByIdVal, lookCfg)),
    soldierSchemes.get(), maxTrainByClassVal))
})

let curSoldierInfo = Computed(@() curSoldiersDataList.get()?[curSoldierIdx.get()]
  ?? collectSoldierData(curCampSoldiers.get()?[defSoldierGuid.get()])
)

let curSoldierGuid = Computed(@() curSoldierInfo.get()?.guid)


console_register_command(@(campaignId)
  set_soldier_outfit_preset(curSoldierGuid.get() ?? "", campaignId),
  "meta.dressUpCurSoldierForCampaign")

console_register_command(function(tmpl) {
  let { guid = null } = curSoldierInfo.get()
  if (guid != null)
    soldier_reside([guid], tmpl)
}, "meta.resideCurSoldier")

console_register_command(function(tmpl) {
  let soldierGuids = curSquadSoldiersInfo.get().map(@(s) s.guid)
  soldier_reside(soldierGuids, tmpl)
}, "meta.resideCurSquad")

return {
  curSoldierIdx
  defSoldierGuid

  curSoldierInfo
  curSoldiersDataList
  curSoldierGuid

  collectSoldierData
}