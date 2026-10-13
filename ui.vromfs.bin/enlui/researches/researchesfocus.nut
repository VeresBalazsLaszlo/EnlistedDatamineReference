import "%ui/researches/researchesPresentation.nut" as prepareResearch
from "%ui/mainMenu/sectionsState.nut" import jumpToResearches
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/researches/researchesState.nut" import configResearches, armiesResearches, allResearchStatus, viewSquadId, selectedTable, selectedResearch, getSquadIdList
  , NOT_ENOUGH_EXP, CAN_RESEARCH, RESEARCHED
from "%ui/soldiers/model/state.nut" import armySquadsById
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/growth/growthState.nut" import growthSquadsByArmy
from "%ui/ui_library.nut" import *

let researchToShow = Watched(null)

let getClosestResearch = @(army_id, researches, statuses) researches 
    .map(@(res) res.__merge({ army_id, status = statuses?[res.research_id] }))
    .filter(@(res) res.status != RESEARCHED)
    .reduce(@(res, val) (res.status != CAN_RESEARCH && val.status == CAN_RESEARCH)
        || (res.status != NOT_ENOUGH_EXP && val.status == NOT_ENOUGH_EXP)
        || (res.line >= val.line && res.tier >= val.tier)
      ? val : res)

function focusResearch(research) {
  let { army_id = null, page_id = 0, research_id = null } = research
  let researchData = armiesResearches.get()?[army_id].researches[research_id]
  if (researchData == null)
    return

  let squadToOpen = getSquadIdList(research_id)
    .findvalue(@(squadId) squadId in armySquadsById.get()?[army_id])

  if (squadToOpen == null)
    return

  jumpToResearches()
  
  viewSquadId.set(squadToOpen)
  selectedTable.set(page_id)

  let context = {
    armyId = army_id
    squadId = squadToOpen
    squadsCfg = squadsCfgById.get()
    alltemplates = allItemTemplates.get()
  }
  let preparedResearch = prepareResearch(clone researchData, context)
  selectedResearch.set(preparedResearch)
  researchToShow.set(preparedResearch)
}

function findResearchById(research_id) {
  foreach (army_id, armyConfig in configResearches.get())
    foreach (squadList in armyConfig?.pages ?? {}) {
      let resFound = squadList.findvalue(@(res) research_id in (res?.tables ?? {}))
      if (resFound != null)
        return {
          army_id
          page_id = resFound?.page_id ?? 0
          research_id
        }
    }
  return null
}

let hasResearchSquad = @(armyId, researchData) getSquadIdList(researchData.research_id)
  .findvalue(@(squadId) squadId in armySquadsById.get()?[armyId]) != null

function findResearchesByFunc(armyId, checkFunc) {
  let researches = []
  let allResearches = armiesResearches.get()?[armyId].researches ?? {}
  foreach (researchData in allResearches)
    if (checkFunc(researchData))
      researches.append(researchData)

  return researches
}

function findSlotUnlockRequirement(soldier, slotType) {
  if (soldier == null || slotType == null)
    return null

  let armyId = getLinkedArmyName(soldier)
  let statuses = allResearchStatus.get()?[armyId] ?? {}
  let { sClass = "unknown" } = soldier
  let researches = findResearchesByFunc(armyId, @(researchData)
    (researchData?.effect.slot_unlock[sClass] ?? []).contains(slotType))

  let availResearches = researches.filter(@(r) hasResearchSquad(armyId, r))

  if (availResearches.len() > 0)
    return { research = getClosestResearch(armyId, availResearches, statuses) }

  if (researches.len() > 0) {
    let research = researches.top()
    return { squadId = getSquadIdList(research.research_id).findvalue(@(_) true) ?? "" }
  }
  return null
}

function findResearchesUpgradeUnlock(armyId, item) {
  if (item == null)
    return null
  let upgradetpl = item?.upgradeitem
  return findResearchesByFunc(armyId, @(researchData)
    (researchData?.effect.weapon_upgrades ?? []).contains(upgradetpl))
}

function findResearchTrainClass(soldier) {
  if (soldier == null)
    return null
  let armyId = getLinkedArmyName(soldier)
  let { sClass = "unknown" } = soldier
  let researches = findResearchesByFunc(armyId, @(r) (r?.effect.class_training[sClass] ?? 0) > 0)
    .filter(@(research) getSquadIdList(research.research_id)
      .findvalue(@(squadId) squadId in growthSquadsByArmy.get()?[armyId]) != null)
  return getClosestResearch(armyId, researches, allResearchStatus.get()?[armyId] ?? {})
}

console_register_command(@(researchId)
  focusResearch(findResearchById(researchId)), "meta.focusResearch")

return {
  researchToShow
  focusResearch
  findSlotUnlockRequirement
  findResearchesUpgradeUnlock
  findResearchTrainClass
  getClosestResearch
  hasResearchSquad
}
