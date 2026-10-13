import "%ui/control/gui_buttons.nut" as JB
import "%ui/soldiers/model/squadsParams.nut" as squadsParams
import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
from "%ui/soldiers/model/state.nut" import soldiersBySquad, squadsByArmy, curArmy, armies
from "%ui/meta/profile.nut" import curCampSquads, curCampSoldiers, campItemsByLink
from "%ui/soldiers/model/collectSoldierData.nut" import collectSoldierDataImpl
from "%ui/soldiers/model/curSoldiersState.nut" import defSoldierGuid, collectSoldierData
from "%ui/meta/clientApi.nut" import manage_squad_soldiers, buy_apply_squad_soldiers, update_profile, lastRequests, swap_soldiers_equipment
from "%ui/soldiers/model/soldierActions.nut" import dismissReserveSoldiers
from "%ui/soldiers/model/reserve.nut" import allReserveSoldiers
from "%ui/soldiers/model/soldierPerks.nut" import perksData
from "%ui/meta/servProfile.nut" import soldiersLook
from "%ui/meta/perks/perksSchemesConfig.nut" import soldierSchemes
from "%ui/soldiers/model/all_items_templates.nut" import itemTypesInSlots
from "%ui/soldiers/model/reserveFilterPkg.nut" import filterConfig
from "%ui/soldiers/model/readySoldiers.nut" import READY, TOO_MUCH_CLASS, NOT_FIT_CUR_SQUAD, NOT_READY_BY_EQUIP, invalidEquipSoldiers
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%sqstd/timers.nut" import debounce
from "%sqstd/frp.nut" import subscribeList
from "%ui/components/soldierClasses.nut" import soldierClasses
from "%ui/soldiers/model/config/soldierTrainingConfig.nut" import maxTrainByClass
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/mainMenu/sectionsState.nut" import curSection
from "%ui/researches/researchesFocus.nut" import getClosestResearch, focusResearch
from "%ui/researches/researchesState.nut" import armiesResearches, allResearchStatus, RESEARCHED, GROUP_RESEARCHED
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/soldiers/model/unseenSoldiers.nut" import unseenSoldiers, markSoldierSeen
from "%ui/quickMatchQueue.nut" import isChangesBlocked, showBlockedChangesMessage
from "%ui/soldiers/armySquadTier.nut" import calcBROnSoldierChange
from "%ui/ui_library.nut" import *

let curSquadSoldierIdx = Watched(null)
let selectedSoldierGuid = Watched(null)
selectedSoldierGuid.subscribe(@(v) defSoldierGuid.set(v))
let isPurchaseWndOpened = Watched(false)
let curReserveFilter = Watched(null)

let soldiersSquadGuid = mkWatched(persist, "soldiersSquadGuid")
let soldiersArmy = Computed(function() {
  let squadObj = curCampSquads.get()?[soldiersSquadGuid.get()]
  return getLinkedArmyName(squadObj)
})
let soldiersSquad = Computed(@() (squadsByArmy.get()?[soldiersArmy.get()] ?? [])
  .findvalue(@(s) s.guid == soldiersSquadGuid.get()))
let curSquadSoldiers = Computed(@() soldiersBySquad.get()?[soldiersSquadGuid.get()] ?? [])
let reserveSoldiersByArmy = Computed(@() allReserveSoldiers.get()?[soldiersArmy.get()] ?? [])

let squadSoldiers = mkWatched(persist, "chosen", [])
let reserveSoldiers = mkWatched(persist, "reserve", [])
let soldiersSquadParams = Computed(@() squadsParams.get()?[soldiersArmy.get()][soldiersSquad.get()?.squadId])
let maxSquadSize = Computed(@() soldiersSquadParams.get()?.size ?? 1)

let ignoreStatuses = { [GROUP_RESEARCHED] = true, [RESEARCHED] = true }
let squadKindResearches = Computed(function() {
  let { squadId = null } = soldiersSquad.get()
  if (squadId == null)
    return {}

  let armyId = soldiersArmy.get()
  let statuses = allResearchStatus.get()?[armyId] ?? {}
  let researchesBySKind = {}
  foreach (research in armiesResearches.get()?[armyId].researches ?? {})
    foreach (sKind, amount in (research?.effect.squad_class_limit[squadId] ?? {}))
      if (amount > 0 && !(ignoreStatuses?[statuses?[research.research_id]] ?? false)) {
        if (sKind not in researchesBySKind)
          researchesBySKind[sKind] <- []
        researchesBySKind[sKind].append(research)
      }
  return researchesBySKind.map(@(list) getClosestResearch(armyId, list, statuses))
})

function calcSoldiersStatuses(squadParams, chosen, reserve, invalidEquip, kindResearches) {
  let maxClasses = squadParams?.maxClasses ?? {}
  let leftClasses = clone maxClasses

  let res = {}
  foreach (soldier in chosen) {
    if (soldier == null)
      continue
    let { sKind } = soldier
    local status = NOT_FIT_CUR_SQUAD | TOO_MUCH_CLASS
    if ((leftClasses?[sKind] ?? 0) > 0) {
      leftClasses[sKind]--
      status = READY
    }
    else if ((maxClasses?[sKind] ?? 0) > 0)
      status = TOO_MUCH_CLASS

    if (invalidEquip?[soldier.guid])
      status = status | NOT_READY_BY_EQUIP

    res[soldier.guid] <- status
  }
  foreach (soldier in reserve) {
    let { sKind = null } = soldier
    local status
    if ((maxClasses?[sKind] ?? 0) <= 0)
      status = sKind in kindResearches ? TOO_MUCH_CLASS
        : NOT_FIT_CUR_SQUAD | TOO_MUCH_CLASS
    else
      status = (leftClasses?[sKind] ?? 0) <= 0 ? TOO_MUCH_CLASS : READY
    if (invalidEquip?[soldier.guid])
      status = status | NOT_READY_BY_EQUIP
    res[soldier.guid] <- status
  }
  return res
}

let soldiersStatuses = Computed(@() calcSoldiersStatuses(soldiersSquadParams.get(),
  squadSoldiers.get(), reserveSoldiers.get(), invalidEquipSoldiers.get(),
  squadKindResearches.get()))

function applyFilter(reserve, filterFn, params, args = "") {
  let result = []
  let realIndices = []
  foreach (idx, soldier in reserve) {
    if (!filterFn(soldier, params, args))
      continue
    realIndices.append(idx)
    result.append(soldier)
  }
  return { result, realIndices, count = result.len() }
}

let reserveByFilterIds = Computed(function() {
  let reserve = reserveSoldiers.get()
  let statuses = soldiersStatuses.get()
  if (reserve.len() == 0 || statuses.len() == 0)
    return {}

  let params = {
    soldiersStatuses = statuses
    maxTrainByClass = maxTrainByClass.get()
    itemTypesInSlots = itemTypesInSlots.get()
    campItems = campItemsByLink.get()
  }

  let res = {}
  foreach (filter in filterConfig) {
    let { id = null, filterFn = null, inlineBtns = [], isTotalGroup = false } = filter
    if (id == null)
      continue

    let group = {}

    foreach (arg in inlineBtns)
      group[arg] <- applyFilter(reserve, filterFn, params, arg)

    if (inlineBtns.len() == 0 || !isTotalGroup)
      group[""] <- applyFilter(reserve, filterFn, params)

    res[id] <- group
  }

  return res
})

let reserveFilteredData = Computed(function() {
  let reserve = reserveSoldiers.get()
  let { id = "all", args = "" } = curReserveFilter.get()
  let { result = [], realIndices = {} } = reserveByFilterIds.get()?[id][args]
  let numHidden = reserve.len() - result.len()
  return {
    reserve = result
    numHidden
    realIndices
  }
})

let reserveFilteredSoldiers = Computed(function() {
  let { reserve } = reserveFilteredData.get()
  return reserve
})

let numHiddenSoldiers = Computed(function() {
  let { numHidden = 0 } = reserveFilteredData.get()
  return numHidden
})

let reserveSoldiersIndex = Computed(function() {
  let { realIndices = {} } = reserveFilteredData.get()
  return realIndices
})

let getRealIndex = @(curViewToReserve, idx) curViewToReserve?[idx] ?? idx

function updateSoldiersList(sort = false) {
  if (curSquadSoldiers.get().len() == 0 && reserveSoldiersByArmy.get().len() == 0) {
    squadSoldiers.mutate(@(v) v.clear())
    reserveSoldiers.mutate(@(v) v.clear())
    return
  }
  let byGuid = {}
  curSquadSoldiers.get().each(@(s) byGuid[s.guid] <- s)
  reserveSoldiersByArmy.get().each(@(s) byGuid[s.guid] <- s)

  local chosen = squadSoldiers.get().map(@(s) byGuid?[s?.guid])
    .filter(@(s) s != null)
  local reserve = reserveSoldiers.get().map(@(s) byGuid?[s.guid])
    .filter(@(s) s != null)

  local needSort = sort
  if (chosen.len() == 0 && reserve.len() == 0) { 
    chosen = clone curSquadSoldiers.get()
    reserve = clone reserveSoldiersByArmy.get()
    needSort = true
  }
  else {
    chosen.each(function(s) { if (s != null) byGuid.$rawdelete(s.guid) })
    reserve.each(@(s) byGuid.$rawdelete(s.guid))
    foreach (soldier in curSquadSoldiers.get())
      if (soldier.guid in byGuid)
        reserve.append(soldier)

    foreach (soldier in reserveSoldiersByArmy.get())
      if (soldier.guid in byGuid)
        reserve.append(soldier)
  }

  let count = maxSquadSize.get()
  if (chosen.len() < count)
    chosen.resize(count)
  else if (chosen.len() > count) {
    reserve = chosen.slice(count).extend(reserve)
    chosen = chosen.slice(0, count)
  }

  
  let perksDataVal = perksData.get()
  let curCampSquadsVal = curCampSquads.get()
  let armiesVal = armies.get()
  let sClassesCfgVal = sClassesCfg.get()
  let campItemsByLinkVal = campItemsByLink.get()
  let soldiersLookVal = soldiersLook.get()
  let soldierSchemesVal = soldierSchemes.get()
  let maxTrainByClassVal = maxTrainByClass.get()

  let objInfo = curCampSoldiers.get()
  reserve = reserve.map(@(s) collectSoldierDataImpl(objInfo?[s.guid] ?? s,
    perksDataVal, curCampSquadsVal, armiesVal,
    sClassesCfgVal, campItemsByLinkVal, soldiersLookVal,
    {},
    soldierSchemesVal, maxTrainByClassVal))

  chosen = chosen.map(@(s) s == null ? null : collectSoldierData(objInfo?[s.guid] ?? s))

  if (needSort) {
    let statuses = calcSoldiersStatuses(soldiersSquadParams.get(),
      chosen, reserve, invalidEquipSoldiers.get(), squadKindResearches.get())
    reserve.sort(@(a, b) statuses[a.guid] <=> statuses[b.guid]
      || b.level <=> a.level
      || a.sKind <=> b.sKind
      || a.sClass <=> b.sClass)
  }

  squadSoldiers.set(chosen)
  reserveSoldiers.set(reserve)
}

let updateSoldiersListDebounced = debounce(@() updateSoldiersList(), 0.05)
let updateSoldiersListAndSortDebounced = debounce(@() updateSoldiersList(true), 0.05)
subscribeList(updateSoldiersListDebounced, curSquadSoldiers, reserveSoldiersByArmy, maxSquadSize, curCampSoldiers, campItemsByLink)
updateSoldiersList()

function moveIndex(list, idxFrom, idxTo) {
  let res = clone list
  let val = res.remove(idxFrom)
  res.insert(idxTo, val)
  return res
}

let getSClassName = @(sClass) loc(soldierClasses?[sClass].locId ?? "unknown")

function getCantTakeReason(soldier, soldiersList, idxTo) {
  let { sKind } = soldier
  let reqResearch = squadKindResearches.get()?[sKind]
  let maxClass = soldiersSquadParams.get()?.maxClasses[sKind] ?? 0
  if (maxClass <= 0)
    return {
      msgText = loc("msg/maxClassInSquadIsZero", {
        sClass = getSClassName(sKind)
      })
      reqResearch
    }

  let tgtKind = soldiersList?[idxTo].sKind
  if (sKind == tgtKind)
    return null

  let count = soldiersList.filter(@(s) s?.sKind == sKind).len()
  if (count < maxClass)
    return null

  return {
    msgText = loc("msg/maxClassInSquadIsFull", {
      sClass = getSClassName(sKind), count = maxClass
    })
    reqResearch
  }
}

function getCanTakeSlots(soldier, soldiersList) {
  let { sKind } = soldier
  let maxClass = soldiersSquadParams.get()?.maxClasses[sKind] ?? 0
  if (maxClass <= 0)
    return array(soldiersList.len(), false)

  let classCount = soldiersList.filter(@(s) s?.sKind == sKind).len()
  if (classCount != maxClass)
    return array(soldiersList.len(), classCount < maxClass)
  return soldiersList.map(@(s) s?.sKind == sKind)
}

function isTransferAvailable(soldier, isFromReserve = false) {
  if (soldier == null)
    return true
  let { sClass } = soldier
  if (sClassesCfg.get()?[sClass].isTransferLocked ?? false) {
    showMsgbox(loc(isFromReserve ? "msg/cantReplaceClassSoldier" : "msg/cantMoveClassSoldier",
      { sClass = getSClassName(sClass) }))
    return false
  }
  return true
}

function sendSoldierActionToBQ(eventType, soldier, squadGuid = "") {
  if (soldier == null)
    return

  let { guid, level, sClass } = soldier
  sendBigQueryUIEvent("soldier_management", null, {
    eventType
    squadGuid
    army = soldiersArmy.get()
    soldierGuid = guid
    soldierLevel = level
    soldierClass = sClass
  })
}

function changeSoldierOrderByIdx(idxFrom, idxTo) {
  if (isChangesBlocked.get()) {
    showBlockedChangesMessage()
    return
  }
  let curViewToReserve = reserveSoldiersIndex.get()
  let maxSize = maxSquadSize.get()
  let watchFrom = idxFrom < maxSize ? squadSoldiers : reserveSoldiers
  if (idxFrom >= maxSize) {
    idxFrom -= maxSize
    idxFrom = getRealIndex(curViewToReserve, idxFrom)
  }
  let watchTo = idxTo < maxSize ? squadSoldiers : reserveSoldiers
  if (idxTo >= maxSize) {
    idxTo -= maxSize
    idxTo = getRealIndex(curViewToReserve, idxTo)
  }
  if (watchFrom == watchTo) {
    sendSoldierActionToBQ("change_order", watchFrom.get()[idxFrom], soldiersSquadGuid.get())
    watchFrom.set(moveIndex(watchFrom.get(), idxFrom, idxTo))
    return
  }

  if (watchFrom == squadSoldiers) {
    let squadSoldier = squadSoldiers.get()?[idxFrom]
    if (squadSoldier == null)
      return

    if (!isTransferAvailable(squadSoldier))
      return

    reserveSoldiers.mutate(@(list) list.insert(idxTo, squadSoldiers.get()[idxFrom]))
    squadSoldiers.mutate(@(list) list[idxFrom] = null)
    return
  }

  let reserveSoldier = reserveSoldiers.get()[idxFrom]
  let cantChangeReason = getCantTakeReason(reserveSoldier, squadSoldiers.get(), idxTo)
  if (cantChangeReason == null) {
    let prevSoldier = squadSoldiers.get()[idxTo]
    if (!isTransferAvailable(prevSoldier, true))
      return

    sendSoldierActionToBQ("move_to_squad", reserveSoldier, soldiersSquadGuid.get())
    squadSoldiers.mutate(@(list) list[idxTo] = reserveSoldier)
    reserveSoldiers.mutate(function(list) {
      if (prevSoldier != null)
        list[idxFrom] = prevSoldier
      else
        list.remove(idxFrom)
    })
    if (reserveSoldier.equipSchemeId == prevSoldier?.equipSchemeId)
      showMsgbox({
        text = loc("swapSoldiersEquipmentConfirm")
        buttons = [
          { text = loc("Yes"), action = @()
            swap_soldiers_equipment(reserveSoldier.guid, prevSoldier.guid) }
          { text = loc("No"), isCancel = true}
        ]
      })
    return
  }

  local { msgText, reqResearch } = cantChangeReason
  let buttons = [{ text = loc("Ok"), isCurrent = true }]
  if (reqResearch != null) {
    buttons.append({
      text = loc("GoToResearch")
      action = @() focusResearch(reqResearch)
    })
    msgText = "{0}\n\n{1}".subst(msgText, loc("msg/needResearchToAddClassToSquad"))
  }

  sendSoldierActionToBQ("failed_management", reserveSoldier, soldiersSquadGuid.get())
  showMsgbox({
    text = msgText
    buttons
  })
}

function moveSoldierImpl(guid, direction, moveFn, watch, view = null) {
  let source = watch.get()
  let list = view ?? source
  let idx = list.findindex(@(s) s?.guid == guid)
  if (idx == null)
    return false

  let newIdx = idx + direction
  if (newIdx in list)
    watch.set(moveFn(source, idx, newIdx))
  return true
}

function moveCurSoldier(direction) {
  let guid = selectedSoldierGuid.get()
  if (guid == null)
    return

  if (moveSoldierImpl(guid, direction, moveIndex, squadSoldiers))
    return

  moveSoldierImpl(guid,
    direction,
    function(list, idx, newIdx) {
      let indices = reserveSoldiersIndex.get()
      return moveIndex(list, getRealIndex(indices, idx), getRealIndex(indices, newIdx))
    },
    reserveSoldiers,
    reserveFilteredSoldiers.get())
}

function soldierToReserveByIdx(idx) {
  if (isChangesBlocked.get()) {
    showBlockedChangesMessage()
    return
  }
  if (idx == null)
    return

  let soldier = squadSoldiers.get()[idx]
  if (!isTransferAvailable(soldier))
    return

  sendSoldierActionToBQ("move_to_reserve", soldier)
  reserveSoldiers.mutate(@(v) v.insert(0, soldier))
  squadSoldiers.mutate(@(v) v[idx] = null)
}

function curSoldierToReserve() {
  let guid = selectedSoldierGuid.get()
  if (guid == null)
    return

  let idx = squadSoldiers.get().findindex(@(s) s?.guid == guid)
  soldierToReserveByIdx(idx)
}

function curSoldierToSquad() {
  if (isChangesBlocked.get()) {
    showBlockedChangesMessage()
    return
  }

  let guid = selectedSoldierGuid.get()
  if (guid == null)
    return

  let idx = reserveSoldiers.get().findindex(@(s) s.guid == guid)
  if (idx == null)
    return

  let newIdx = squadSoldiers.get().indexof(null)
  if (newIdx == null) {
    showMsgbox(loc("msg/squadSoldiersFull"))
    return
  }

  let soldier = reserveSoldiers.get()[idx]
  let cantChangeReason = getCantTakeReason(soldier, squadSoldiers.get(), newIdx)
  if (cantChangeReason == null) {
    squadSoldiers.mutate(@(v) v[newIdx] = soldier)
    reserveSoldiers.mutate(@(v) v.remove(idx))
    return
  }

  local { msgText, reqResearch } = cantChangeReason
  let buttons = [{ text = loc("Ok"), isCurrent = true }]
  if (reqResearch != null) {
    buttons.append({
      text = loc("GoToResearch")
      action = @() focusResearch(reqResearch)
    })
    msgText = "{0}\n\n{1}".subst(msgText, loc("msg/needResearchToAddClassToSquad"))
  }

  showMsgbox({
    uid = "change_soldiers_order"
    text = msgText
    buttons
  })
}

function close() {
  curReserveFilter.set(null)
  selectedSoldierGuid.set(null)
  soldiersSquadGuid.set(null)
  isPurchaseWndOpened.set(false)
  markSoldierSeen(curArmy.get(), unseenSoldiers.get().keys())
}

function applySoldierManageImpl(cb) {
  let minCount = soldiersSquad.get()?.size ?? 1
  squadSoldiers.modify(@(v) v.filter(@(s) s != null))
  for(local i = squadSoldiers.get().len() - 1; i >= 0; i--) {
    let soldier = squadSoldiers.get()[i]
    let { isTransferLocked = false } = sClassesCfg.get()?[soldier.sClass]
    if (soldiersStatuses.get()?[soldier.guid] == READY || isTransferLocked)
      continue
    squadSoldiers.mutate(@(v) v.remove(i))
    reserveSoldiers.mutate(@(v) v.insert(0, soldier))
  }
  for(local i = squadSoldiers.get().len(); i < minCount; i++) {
    let idx = reserveSoldiers.get().findindex(@(s) soldiersStatuses.get()?[s.guid] == READY)
    if (idx == null)
      break
    let soldier = reserveSoldiers.get()[idx]
    let { isTransferLocked = false } = sClassesCfg.get()?[soldier.sClass]
    if (isTransferLocked)
      continue
    reserveSoldiers.mutate(@(v) v.remove(idx))
    squadSoldiers.mutate(@(v) v.append(soldier))
  }

  let newSquadSoldiers = squadSoldiers.get()
  let selectedGuid = selectedSoldierGuid.get()
  let inSquadIdx = newSquadSoldiers.findindex(@(s) s.guid == selectedGuid)
  if (inSquadIdx != null)
    curSquadSoldierIdx.set(inSquadIdx)
  else if ((curSquadSoldierIdx.get() ?? 0) >= newSquadSoldiers.len())
    curSquadSoldierIdx.set(null)

  if (curSquadSoldiers.get().len() == squadSoldiers.get().len()) {
    local hasChanges = false
    foreach (idx, soldier in curSquadSoldiers.get())
      if (soldier.guid != squadSoldiers.get()[idx].guid) {
        hasChanges = true
        break
      }
    if (!hasChanges) {
      cb()
      return
    }
  }

  log($"manage_squad_soldiers: armyId = {soldiersArmy.get()}, squadGuid = {soldiersSquadGuid.get()}")
  log($"To squad ({squadSoldiers.get().len()}) = ", squadSoldiers.get().map(@(s) s.guid))
  log($"To reserve ({reserveSoldiers.get().len()}) = ", reserveSoldiers.get().map(@(s) s.guid))
  log("lastRequests: ")
  debugTableData(lastRequests.get(), { recursionLevel = 7 })
  let squadGuid = soldiersSquadGuid.get() 
  manage_squad_soldiers(soldiersArmy.get(),
    soldiersSquadGuid.get(),
    squadSoldiers.get().map(@(s) s.guid),
    reserveSoldiers.get().map(@(s) s.guid),
    function(res) {
      if (res?.error == null) {
        calcBROnSoldierChange(squadGuid)
        return
      }
      
      log($"Request update_profile after fail change soldiers order")
      update_profile()
    })
  cb()
}

function checkSquadStatus() {
  let selCount = squadSoldiers.get().filter(@(s) s != null).len()
  let readyCount = squadSoldiers.get()
    .filter(@(s) s != null && soldiersStatuses.get()?[s.guid] == READY)
    .len()
  let hasReady = reserveSoldiers.get()
    .findvalue(@(s) soldiersStatuses.get()?[s.guid] == READY) != null
  let minCount = soldiersSquad.get()?.size ?? 1
  return readyCount < minCount && hasReady ? loc("msg/notFullSoldiersAtApply", { minCount })
    : readyCount < selCount ? loc("msg/haveUnreadySoldiers", { count = selCount - readyCount })
    : null
}

function applySoldierManage(cb = @() null) {
  let msg = checkSquadStatus()
  if (msg == null)
    applySoldierManageImpl(cb)
  else
    showMsgbox({
      text = msg
      buttons = [
        { text = loc("Ok"), action = @() applySoldierManageImpl(cb), isCurrent = true }
        { text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
      ]
    })
}

function buyAndFillSoldiers(squadGuid, squadGuids, reserveGuids, buySoldiers, payItems) {
  buy_apply_squad_soldiers(squadGuid,
    squadGuids,
    reserveGuids,
    buySoldiers,
    payItems,
    function(res) {
      if (res?.error != null)
        return
      squadSoldiers.mutate(@(v) v.clear())
      reserveSoldiers.mutate(@(v) v.clear())
      updateSoldiersList()
      calcBROnSoldierChange(squadGuid)
    })
}

let dismissGuids = Watched(null)
let isDismissInProgress = Computed(@() (dismissGuids.get()?.len() ?? 0) > 0)
function dismissSoldiers(armyId, guidsList, cb = null) {
  if (isDismissInProgress.get())
    return

  dismissGuids.set(guidsList)
  dismissReserveSoldiers(armyId, guidsList, function(_) {
    dismissGuids.set(null)
    cb?()
  })
}

curSection.subscribe(@(_) soldiersSquad.get() == null ? null
  : checkSquadStatus() == null ? applySoldierManageImpl(close)
  : close())

return {
  openChooseSoldiersWnd = function(squadGuid, selSoldierGuid = null) {
    soldiersSquadGuid.set(squadGuid)
    selectedSoldierGuid.set(selSoldierGuid)
  }
  closeChooseSoldiersWnd = close
  applySoldierManage
  buyAndFillSoldiers
  updateSoldiersListAndSort = updateSoldiersListAndSortDebounced

  soldiersSquad
  maxSquadSize
  soldiersSquadParams
  squadSoldiers
  reserveSoldiers
  reserveFilteredSoldiers

  soldiersStatuses
  selectedSoldierGuid
  curReserveFilter
  numHiddenSoldiers
  reserveByFilterIds

  changeSoldierOrderByIdx
  moveCurSoldier
  soldierToReserveByIdx
  curSoldierToReserve
  curSoldierToSquad
  getCanTakeSlots
  dismissSoldiers
  isDismissInProgress
  dismissGuids
  curSquadSoldierIdx
  isPurchaseWndOpened
}
