from "%ui/components/soldierClasses.nut" import getClassCfg
from "%ui/soldiers/model/state.nut" import curArmy, curSquadSoldiersInfo, curSquadId
from "%ui/researches/researchesState.nut" import researchStatuses, RESEARCHED, configResearches
from "%ui/ui_library.nut" import *

let machineGunByArmy = {
  ussr = "stationary_dshk_1942"
  ger = "stationary_mg_131"
  usa = "stationary_browning_m2"
  jap = "stationary_type_93_hmg"
}

const HEAVY_MGUN_RESEARCH_KEY = "5"

function searchInResearchesForSquad(research, squadId){
  foreach(r in research)
    foreach(researchEffect in r.tables)
      if (researchEffect.effect?.building_unlock[squadId][HEAVY_MGUN_RESEARCH_KEY] == true)
        return researchEffect.research_id
  return null
}


let hasMgunTable = Computed(function(){
  let res = {}
  foreach(armyId, research in configResearches.get()){
    let resArmy = {}
    foreach(squadId,  researchesForSquad in research.pages){
      let mGunResearch = searchInResearchesForSquad(researchesForSquad, squadId)
      if (mGunResearch)
        resArmy[squadId] <- mGunResearch
    }
    res[armyId] <- resArmy
  }
  return res
})

let enginObjectToPlace = Computed(function() {
  let hasEngineer = curSquadSoldiersInfo.get().findindex(@(s)
    getClassCfg(s.sClass).kind == "engineer"
  ) != null
  if (!hasEngineer)
    return null

  let researchIdWithMgun = hasMgunTable.get()?[curArmy.get()][curSquadId.get()]
  if (!researchIdWithMgun)
    return null

  if (researchStatuses.get()?[researchIdWithMgun] != RESEARCHED)
    return null

  let machineGun = machineGunByArmy?[curArmy.get()]
  return machineGun != null ? [machineGun] : null
})

return {
  enginObjectToPlace
}