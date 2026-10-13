from "%ui/soldiers/model/readySoldiers.nut" import soldiersStatuses, READY, OUT_OF_VEHICLE
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/soldiers/model/state.nut" import chosenSquadsByArmy, soldiersBySquad, curArmy, selectArmy, setCurSquadId
from "%ui/quickMatch.nut" import matchRandomTeam
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/ui_library.nut" import *


let showNotReadySquads = Watched(null)
let armiesForBattle = Computed(@() matchRandomTeam.get() ? curArmiesList.get() : [curArmy.get()])

function calcSquadReady(squad, soldiers, statuses) {
  let unreadySoldiers = soldiers.filter(@(s) statuses?[s.guid] != null && statuses[s.guid] != READY
    && !(statuses[s.guid] & OUT_OF_VEHICLE))
  let notReadyCount = unreadySoldiers.len()
  let minCount = squad.size
  let canBattle = (soldiers.len() - notReadyCount) >= minCount
  let unreadyMsgs = []
  if (!canBattle)
    unreadyMsgs.append(loc("notReadySquad/notEnoughSoldiers", { minCount }))
  if (unreadySoldiers.len() > 0)
    unreadyMsgs.append(loc("notReadySquad/hasNotReadySoldiers", { notReadyCount }))
  return { isReady = unreadyMsgs.len() == 0, canBattle, unreadySoldiers, unreadyMsgs, squad }
}

function getNotReadySquadsInfo(armiesList, chosenSquads, soldiers, statuses) {
  let res = []
  foreach (armyId in armiesList)
    foreach (squad in chosenSquads?[armyId] ?? []) {
      let readyData = calcSquadReady(squad, soldiers?[squad.guid] ?? [], statuses)
      if (!readyData.isReady)
        res.append(readyData)
    }
  return res
}

function showCurNotReadySquadsMsg(onContinue) {
  let notReadyInfo = getNotReadySquadsInfo(armiesForBattle.get(), chosenSquadsByArmy.get(),
    soldiersBySquad.get(), soldiersStatuses.get())
  if (notReadyInfo.len() == 0)
    onContinue()
  else
    showNotReadySquads.set({ notReady = notReadyInfo, onContinue = onContinue })
}

function goToSquadAndClose(squad) {
  showNotReadySquads.set(null)
  let armyId = getLinkedArmyName(squad)
  if (!curArmiesList.get().contains(armyId))
    return
  selectArmy(armyId)
  let { squadId } = squad
  if ((chosenSquadsByArmy.get()?[armyId] ?? []).findvalue(@(s) s.squadId == squadId) != null)
    setCurSquadId(squadId)
}

return {
  showCurNotReadySquadsMsg
  goToSquadAndClose
  showNotReadySquads
}
