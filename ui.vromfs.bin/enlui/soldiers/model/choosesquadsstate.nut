import "%ui/components/armiesPresentation.nut" as armiesPresentation
import "%ui/control/gui_buttons.nut" as JB
import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/components/colorize.nut" as colorize
from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%ui/soldiers/model/state.nut" import soldiersBySquad, squadsByArmy, chosenSquadsByArmy,
  vehicleBySquad, limitsByArmy, armyLimitsDefault, curArmy, lockedSquadsByArmy
from "%ui/meta/clientApi.nut" import set_squad_order, sell_squad
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/components/mkSpecialItemIcon.nut" import SIGN_NONE, SIGN_PREMIUM, SIGN_EVENT
from "%ui/soldiers/model/readySoldiers.nut" import soldiersStatuses
from "%ui/soldiers/readyStatus.nut" import READY
from "%ui/researches/researchesState.nut" import allSquadsLevels
from "%ui/soldiers/model/unseenSquads.nut" import markSeenSquads
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix, itemNameFromTemplate
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/growth/growthState.nut" import growthSquadsByArmy, curGrowthConfig
from "%ui/soldiers/armySquadTier.nut" import updateBROnSquadsChange
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/soldiers/model/newItemsToShow.nut" import needNewItemsWindow
from "%ui/mainMenu/sectionsState.nut" import setCurSection, Section
from "%ui/soldiers/model/config/gameProfile.nut" import allArmiesInfo
from "%ui/style/designConst.nut" import brightAccentColor
from "%ui/soldiers/model/rentedSquads.nut" import expiredRentedSquads
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/helpers/metalink.nut" import getItemIndex, getLinkedArmyName
from "%sqstd/frp.nut" import subscribeList
from "%ui/ui_library.nut" import *

let justGainSquadId = Watched(null)
let selectedSquadId = Watched(null)
let sellingSquadId = Watched(null)
let previewSquads = Watched(null)
let squadsArmy = mkWatched(persist, "squadsArmy")
let curChosenSquads = Computed(@() chosenSquadsByArmy.get()?[squadsArmy.get()] ?? [])
let curUnlockedSquads = Computed(@() squadsByArmy.get()?[squadsArmy.get()] ?? [])
let squadsArmyLimits = Computed(@() limitsByArmy.get()?[squadsArmy.get()] ?? armyLimitsDefault)
let maxSquadsInBattle = Computed(@() squadsArmyLimits.get().maxSquadsInBattle)
let premSquadSlots = Computed(@() squadsArmyLimits.get().premSquadSlots)

let chosenSquads = mkWatched(persist, "chosen", [])
let reserveSquads = mkWatched(persist, "reserve", [])
let displaySquads = Computed(@() previewSquads.get() ?? clone chosenSquads.get())

let unlockedSquads = Computed(@() (clone chosenSquads.get()).extend(reserveSquads.get()))
let slotsCount = Computed(@() chosenSquads.get().len())


let sellableSquadsCfg = Computed(function() {
  let res = {}
  foreach (armyId, armySquadsCfg in squadsCfgById.get()) {
    res[armyId] <- {}
    foreach (squadId, squadCfg in armySquadsCfg) {
      let { silverSellCost = 0, sign = SIGN_NONE } = squadCfg
      if (sign != SIGN_PREMIUM && silverSellCost > 0)
        res[armyId][squadId] <- silverSellCost
    }
  }
  return res
})


let sellableSquads = Computed(function() {
  let res = {}
  let unlocked = unlockedSquads.get().filter(@(s) s != null)
  if (unlocked.len() == 0)
    return res

  let armyId = curArmy.get()
  let sellableCfg = sellableSquadsCfg.get()?[armyId] ?? {}
  let growthSquads = growthSquadsByArmy.get()?[armyId] ?? {}

  foreach (squad in unlocked) {
    let { squadId } = squad
    if (squadId in growthSquads)
      continue

    let silverSellCost = sellableCfg?[squadId] ?? 0
    if (silverSellCost > 0)
      res[squadId] <- silverSellCost
  }

  return res
})

let close = @() squadsArmy.set(null)

function getGrowthData(growthId, isPremium, growthCfgs, templates, availShopItems) {
  if (growthId == null || growthId not in growthCfgs)
    return null

  let { col = 0, reward = null, shopItemsGuids = [] } = growthCfgs[growthId]
  let { itemTemplate = null } = reward

  let shopItemGuid = shopItemsGuids.findvalue(@(v) v in availShopItems)
  let res = { growthId, col, shopItemGuid }
  if (itemTemplate == null)
    return res

  let item = templates?[itemTemplate]
  if (item != null) {
    let lock = isPremium ? "growth/reqToBuyGrowth" : "growth/reqToResearchGrowth"
    res.lockTxt <- loc(lock, { reqText = itemNameFromTemplate(item) })
  }
  return res
}

let curArmyLockedSquadsData = Computed(function() {
  let armyId = curArmy.get()
  let growthCfgs = curGrowthConfig.get()
  let growthLinks = growthSquadsByArmy.get()?[armyId] ?? {}
  let templates = allItemTemplates.get()?[armyId] ?? {}
  let armyPremIcon = armiesPresentation?[armyId].premIcon
  let availShopItems = shopItems.get()

  let armySquadsCfg = squadsCfgById.get()?[armyId] ?? {}
  let squadsRes = (lockedSquadsByArmy.get()?[armyId] ?? [])
    .map(function(squad) {
      let { squadId } = squad
      let isPremium = armySquadsCfg?[squadId].sign == SIGN_PREMIUM
      let growthData = getGrowthData(growthLinks?[squadId], isPremium,
        growthCfgs, templates, availShopItems)
      local { premIcon = null } = getSquadPresentation(squadId, armyId)
      if (isPremium)
        premIcon = premIcon ?? armyPremIcon

      return squad.__merge({
        premIcon
        isPremium
        growthData
      })
    })
    .sort(@(a, b) b.isPremium <=> a.isPremium || a.squadId <=> b.squadId)

  return squadsRes
})

let prepareSquad = @(squad, cfg, squadsLevel) squad.__merge({
  level = squadsLevel?[squad.squadId] ?? 0
  manageLocId = squad?.manageLocId ?? cfg?.manageLocId
  icon = squad?.icon ?? cfg?.icon
  vehicle = squad?.vehicle
  squadSize = squad?.squadSize ?? soldiersBySquad.get()?[squad.guid].len() ?? 0
  battleExpBonus = cfg?.battleExpBonus ?? 0
})

let preparedSquads = Computed(function() {
  let visOrdered = clone curChosenSquads.get()
  foreach (squad in curUnlockedSquads.get())
    if (!curChosenSquads.get().contains(squad))
      visOrdered.append(squad)
  return visOrdered.map(@(squad) prepareSquad(squad, squadsCfgById.get()?[squadsArmy.get()][squad.squadId], allSquadsLevels.get()))
})

function updateSquadsList(_ = null) {
  let all = preparedSquads.get()
  if (all.len() == 0) {
    chosenSquads.mutate(@(v) v.clear())
    reserveSquads.mutate(@(v) v.clear())
    return
  }
  let byId = {}
  all.each(@(s) byId[s.squadId] <- s)

  let maxSlots = maxSquadsInBattle.get()
  let premSlots = premSquadSlots.get()
  let totalSlots = maxSlots + premSlots

  local chosen = chosenSquads.get().map(@(s) byId?[s?.squadId])
  local reserve = reserveSquads.get().map(@(s) byId?[s.squadId]).filter(@(s) s != null)

  let chosenCount = chosen.reduce(@(res, s) s != null ? res + 1 : res, 0)
  if (chosenCount == 0 && reserve.len() == 0) { 
    local slotIdx = 0
    foreach (squad in curChosenSquads.get()) {
      let squadIdx = getItemIndex(squad)
      while (slotIdx < squadIdx) {
        slotIdx++
        chosen.append(null)
      }
      chosen.append(squad)
      slotIdx++
    }
    reserve = all.slice(curChosenSquads.get().len())

    let gainSquadId = justGainSquadId.get()
    if (gainSquadId != null) {
      let gainSquadIdx = chosen.findindex(@(s) s?.squadId == gainSquadId)
      if (gainSquadIdx != null)
        reserve = [chosen.remove(gainSquadIdx)].extend(reserve)
    }
  }
  else {
    let left = clone byId
    chosen.each(function(s) { if (s != null) left.$rawdelete(s.squadId) })
    reserve.each(function(s) { if (s != null) left.$rawdelete(s.squadId) })
    foreach (squad in all)
      if (squad.squadId in left)
        reserve.append(squad)

    let len = chosen.len()
    if (len < totalSlots)
      for (local i = 0; i < totalSlots - len; i++)
        chosen.insert(len - premSlots, null)
  }

  if (chosen.len() != totalSlots)
    chosen.resize(totalSlots)

  chosenSquads.set(chosen)
  reserveSquads.set(reserve)
}


subscribeList(updateSquadsList, preparedSquads, maxSquadsInBattle, premSquadSlots)
updateSquadsList()


preparedSquads.subscribe(function(uSquads) {
  if (uSquads.findvalue(@(s) s.squadId == selectedSquadId.get()) != null)
    return
  selectedSquadId.set(uSquads?[0].squadId)
})

function moveIndex(list, idxFrom, idxTo) {
  let res = clone list
  let val = res.remove(idxFrom)
  res.insert(idxTo, val)
  return res
}

let squadPlaceReasonData = {
  limit = {
    type = "limit"
    getErrorText = @() loc("msg/cantTakeExpiredSquad")
  }
  squadTypeFull = @(squadType, maxSquads) {
    type = $"{squadType}Full"
    squadType
    getErrorText = @() loc($"msg/{squadType}Full", { maxSquads })
  }
  squadPrem = {
    type = "squadPrem"
    getErrorText = @() loc("msg/cantTakeNotPremSquad")
    buttons = [
      {
        text = loc("btn/gotoLogistics")
        action = function() {
          setCurSection(Section.SHOP)
          close()
        }
        isCurrent = true
      }
    ]
  }
  onlyPremSlot = {
    type = "onlyPremSlot"
    getErrorText = @() loc("msg/cantPlaceInUsualSlot")
  }
}

let getSquadTypeLimitId = @(vehicleType) vehicleType == "bike" || vehicleType == "jeep" ? "maxBikeSquads"
  : vehicleType == "truck" ? "maxTransportSquads"
  : vehicleType != "" ? "maxVehicleSquads"
  : "maxInfantrySquads"

function isSquadExpired(squad) {
  let { expireTime = 0 } = squad
  return expireTime > 0 && expireTime < serverTime.get()
}

function getCantTakeSquadReasonDataImpl(squad, squadsList, idxTo, maxSlots, limits, squadsCfg) {
  if (isSquadExpired(squad))
    return squadPlaceReasonData.limit

  let { vehicleType = "", squadId = "" } = squad
  let armyId = getLinkedArmyName(squad)
  let { sign = 0, squadType = "" } = squadsCfg?[armyId][squadId]

  if (idxTo >= maxSlots) {
    if (sign == SIGN_PREMIUM || sign == SIGN_EVENT)
      return null
    else
     return squadPlaceReasonData.squadPrem
  } else if (squadType == "saboteur") {
    return squadPlaceReasonData.onlyPremSlot
  }

  local curCount = 0
  let typeId = getSquadTypeLimitId(vehicleType)
  foreach (idx, s in squadsList) {
    if (s == null || idx == idxTo || idx >= maxSlots)
      continue

    let squadTypeId = getSquadTypeLimitId(s?.vehicleType ?? "")
    if (typeId == squadTypeId)
      ++curCount
  }

  let maxType = limits[typeId]
  if (curCount >= maxType)
    return squadPlaceReasonData.squadTypeFull(typeId, maxType)

  return null
}

let getCantTakeSquadReasonData = @(squad, squadsList, idxTo)
  getCantTakeSquadReasonDataImpl(squad, squadsList, idxTo,
    maxSquadsInBattle.get(), squadsArmyLimits.get(),
    squadsCfgById.get())

let getCantTakeReason = @(squad, squadsList, idxTo)
  getCantTakeSquadReasonData(squad, squadsList, idxTo)?.getErrorText()

let canTakeSquad = @(squad, squadsList, idxTo, maxSlots, limits, squadsCfg)
  getCantTakeSquadReasonDataImpl(squad, squadsList, idxTo, maxSlots, limits, squadsCfg) == null

function sendSquadActionToBQ(eventType, squadGuid, squadId) {
  sendBigQueryUIEvent("squad_management", null, {
    eventType
    squadGuid
    squadId
    army = squadsArmy.get()
  })
}


function showSquadOrderError(guid, squadIdFrom, cantChangeReason, buttons = []) {
  sendSquadActionToBQ("failed_management", guid, squadIdFrom)
  showMsgbox({
    uid = "change_squad_order"
    text = cantChangeReason
    buttons = [{ text = loc("Ok"), isCancel = true }].extend(buttons)
  })
}

function changeSquadOrderByUnlockedIdx(idxFrom, idxTo) {
  let maxSlots = maxSquadsInBattle.get()
  let activeSquadsCount = maxSlots + premSquadSlots.get()
  let watchFrom = idxFrom < activeSquadsCount ? chosenSquads : reserveSquads
  if (idxFrom >= activeSquadsCount)
    idxFrom -= activeSquadsCount

  let { guid = null } = watchFrom.get()?[idxFrom]
  let squadIdFrom = watchFrom.get()?[idxFrom].squadId
  let watchTo = idxTo < activeSquadsCount ? chosenSquads : reserveSquads
  if (idxTo >= activeSquadsCount)
    idxTo -= activeSquadsCount

  if (watchFrom == watchTo) {
    if (watchFrom == chosenSquads) {
      let squads = chosenSquads.get()
      local reason = null
      if (idxFrom < maxSlots && idxTo >= maxSlots) {
        let squadFrom = squads[idxFrom]
        let reasonFrom = squadFrom == null ? null : getCantTakeSquadReasonData(squadFrom, squads, idxTo)
        let squadTo = squads[idxTo]
        let reasonTo = squadTo == null ? null : getCantTakeSquadReasonData(squadTo, squads, idxFrom)
        reason = reasonFrom || reasonTo
      }
      else if (idxFrom >= maxSlots && idxTo < maxSlots) {
        let squadFrom = squads[idxFrom]
        let reasonFrom = squadFrom == null ? null : getCantTakeSquadReasonData(squadFrom, squads, maxSlots - 1)
        let squadTo = chosenSquads.get()[maxSlots - 1]
        let reasonTo = squadTo == null ? null : getCantTakeSquadReasonData(squadTo, squads, idxFrom)
        reason = reasonFrom || reasonTo
      }
      if (reason != null) {
        showSquadOrderError(guid, squadIdFrom, reason?.getErrorText(), reason?.buttons ?? [])
        return
      }
    }
    watchFrom.set(moveIndex(watchFrom.get(), idxFrom, idxTo))
    markSeenSquads(squadsArmy.get(), [squadIdFrom])
    sendSquadActionToBQ("change_order", guid, squadIdFrom)
    return
  }

  if (watchFrom == chosenSquads) {
    if (chosenSquads.get()[idxFrom] == null)
      return
    reserveSquads.mutate(@(list) list.insert(idxTo, chosenSquads.get()[idxFrom]))
    chosenSquads.mutate(function(list) { list[idxFrom] = null })
    markSeenSquads(squadsArmy.get(), [squadIdFrom])
    sendSquadActionToBQ("move_to_reserve", guid, squadIdFrom)
    return
  }

  if (idxFrom not in reserveSquads.get())
    return

  let checkSquad = reserveSquads.get()[idxFrom]
  let reason = getCantTakeSquadReasonData(checkSquad, chosenSquads.get(), idxTo)
  if (reason == null) {
    let prevSquad = chosenSquads.get()[idxTo]
    chosenSquads.mutate(@(list) list[idxTo] = reserveSquads.get()[idxFrom])
    reserveSquads.mutate(function(list) {
      if (prevSquad)
        list[idxFrom] = prevSquad
      else
        list.remove(idxFrom)
    })
    markSeenSquads(squadsArmy.get(), [squadIdFrom])
    sendSquadActionToBQ("move_to_squad", guid, squadIdFrom)
    return
  }

  showSquadOrderError(guid, squadIdFrom, reason?.getErrorText(), reason?.buttons ?? [])
}

function changeList() {
  let squadId = selectedSquadId.get()
  if (squadId == null)
    return

  local idx = chosenSquads.get().findindex(@(s) s?.squadId == squadId)
  if (idx != null) {
    markSeenSquads(squadsArmy.get(), [squadId])
    reserveSquads.mutate(@(v) v.insert(0, chosenSquads.get()[idx]))
    chosenSquads.mutate(function(v) { v[idx] = null })
    return
  }

  idx = reserveSquads.get().findindex(@(s) s.squadId == squadId)
  if (idx == null)
    return

  let newIdx = chosenSquads.get().findindex(@(s) s == null)
  if (newIdx == null) {
    showMsgbox(loc("msg/battleSquadsFull"))
    return
  }
  let cantChangeReason = getCantTakeReason(reserveSquads.get()[idx], chosenSquads.get(), newIdx)
  if (cantChangeReason != null) {
    showMsgbox({
      uid = "change_squad_order"
      text = cantChangeReason
    })
    return
  }

  markSeenSquads(squadsArmy.get(), [squadId])
  chosenSquads.mutate(function(v) { v[newIdx] = reserveSquads.get()[idx] })
  reserveSquads.mutate(@(v) v.remove(idx))
}

function findLastIndexToTakeSquad(squad) {
  let res = chosenSquads.get().findindex(@(s) s == null)
  if (res != null && getCantTakeReason(squad, chosenSquads.get(), res) == null)
    return res

  for(local i = chosenSquads.get().len() - 1; i >= 0; i--)
    if (getCantTakeReason(squad, chosenSquads.get(), i) == null)
      return i

  return -1
}

let selectedSquad = Computed(@()
  curUnlockedSquads.get().findvalue(@(squad) squad.squadId == selectedSquadId.get()))

let selectedSquadSoldiers = Computed(function() {
  if (needNewItemsWindow.get())
    return null

  let squadGuid = selectedSquad.get()?.guid
  if (squadGuid == null)
    return null

  let statuses = soldiersStatuses.get()
  return (soldiersBySquad.get()?[squadGuid] ?? [])
    .filter(@(soldier) statuses?[soldier?.guid] == READY)
})

let selSquadVehicleGameTpl = Computed(@()
  trimUpgradeSuffix(vehicleBySquad.get()?[selectedSquad.get()?.guid].gametemplate))


function applyAndCloseImpl(reqAutoFill = true) {
  let maxSlots = maxSquadsInBattle.get()
  let maxPremSlots = premSquadSlots.get()

  let chosen = []
  let prems = []
  let reserve = []
  let guidToSquad = {}
  foreach (idx, squad in unlockedSquads.get()) {
    if (idx < maxSlots)
      chosen.append(squad?.guid)
    else if ((idx >= maxSlots && idx < maxSlots + maxPremSlots))
      prems.append(squad?.guid ?? "")
    else
      reserve.append(squad?.guid ?? "")

    if (squad != null)
      guidToSquad[squad.guid] <- squad
  }

  if (reqAutoFill) {
    let squadsCfg = squadsCfgById.get()
    let squadList = chosenSquads.get()
    let armyLimits = squadsArmyLimits.get()
    chosen.apply(function(guid, idx) {
      if (guid != null || reserve.len() == 0)
        return guid

      let replaceidx = reserve.findindex(@(v)
        canTakeSquad(guidToSquad[v], squadList, idx, maxSlots, armyLimits, squadsCfg))
      if (replaceidx != null)
        return reserve.remove(replaceidx)
      return null
    })
  }

  let guids = chosen.filter(@(v) v != null).resize(maxSlots, "") 

  prems.resize(maxPremSlots, "")
  guids.extend(prems, reserve)

  let armyId = squadsArmy.get()
  markSeenSquads(armyId, guidToSquad.map(@(s) s.squadId))

  updateBROnSquadsChange(armyId, chosenSquads.get())
  set_squad_order(armyId, guids)
  close()
}

function sellSquad(armyId, squadGuid, silverCost) {
  if (sellingSquadId.get())
    return
  sellingSquadId.set(squadGuid)
  sell_squad(armyId, squadGuid, silverCost, @(_) sellingSquadId.set(null))
}

function sumInfantrySquads(res) {
  local count = 0
  foreach (typeId in ["", "bike", "jeep", "truck"])
    count += res?[typeId] ?? 0
  return count
}

function applyAndClose() {
  let expired = expiredRentedSquads.get()
  let armyId = squadsArmy.get()
  let squadsCfg = squadsCfgById.get()?[armyId]

  function sumByVehicleType(res, squad) {
    let { vehicleType = "", guid = null, squadId = "" } = squad
    let { squadType = "" } = squadsCfg?[squadId]
    if (squad != null && guid not in expired && squadType != "saboteur")
      res[vehicleType] <- (res?[vehicleType] ?? 0) + 1
    return res
  }

  let selectedSquads = chosenSquads.get().reduce(sumByVehicleType, {})
  let selectedInfantry = sumInfantrySquads(selectedSquads)
  let totalSquads = unlockedSquads.get().reduce(sumByVehicleType, {})
  let totalInfantry = sumInfantrySquads(totalSquads)

  let selectedTotal = selectedSquads.reduce(@(res, count) res + count, 0)

  let { maxInfantrySquads = totalInfantry } = allArmiesInfo.get()?[armyId]
  let reqInfantry = min(totalInfantry, maxInfantrySquads)

  let minSlots = allArmiesInfo.get()?[armyId].maxSquadsInBattle
    ?? armyLimitsDefault.maxSquadsInBattle
  let maxSlots = maxSquadsInBattle.get()

  let canApplyCurrent = selectedInfantry >= reqInfantry
    && (selectedTotal >= curChosenSquads.get().len() || selectedTotal >= maxSlots)

  let msgTextList = [loc("msg/notFullSquadsAtApply")]
  if (selectedInfantry < reqInfantry)
    msgTextList.append(colorize(brightAccentColor,
      loc("msg/notFullSquadsAtApplyInfantryError", { count = reqInfantry })))

  if (canApplyCurrent) {
    applyAndCloseImpl(false)
    return
  }

  let buttons = []
  if (selectedInfantry >= reqInfantry) {
    if (selectedTotal < minSlots)
      buttons.append({ text = loc("sqManage/minimum"), action = @() applyAndCloseImpl(false),
      customStyle = { hotkeys = [["^J:X"]] }
    })
    else
      buttons.append({ text = loc("sqManage/current"), action = @() applyAndCloseImpl(false),
      customStyle = { hotkeys = [["^J:X"]] }
    })
  }
  buttons.append({
    text = loc("sqManage/full"), action = @() applyAndCloseImpl(), isCurrent = true,
    customStyle = { hotkeys = [["^J:Y"]] }
  })
  buttons.append({
    text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
  })
  showMsgbox({
    text = "\n\n".join(msgTextList)
    buttons
  })
}

function getUnlockedSquadsBySquadIds(squadIdsList) {
  return squadIdsList
    .map(@(squadId) unlockedSquads.get().findvalue(@(squad) squad?.squadId == squadId))
    .filter(@(squad) squad != null)
}

return {
  openChooseSquadsWnd = function(army, selSquadId, isNew = false) {
    selectedSquadId.set(selSquadId)
    justGainSquadId.set(isNew ? selSquadId : null)
    squadsArmy.set(army)
  }
  closeChooseSquadsWnd = close
  applyAndClose
  squadsArmy
  squadsArmyLimits
  maxSquadsInBattle
  premSquadSlots
  unlockedSquads
  sellableSquads
  curArmyLockedSquadsData
  chosenSquads
  reserveSquads
  previewSquads
  displaySquads
  slotsCount
  changeSquadOrderByUnlockedIdx
  moveIndex
  changeList
  getCantTakeReason
  canTakeSquad
  findLastIndexToTakeSquad
  showSquadOrderError
  squadPlaceReasonData

  selectedSquadId
  selectedSquadSoldiers
  selSquadVehicleGameTpl
  sendSquadActionToBQ
  getUnlockedSquadsBySquadIds
  getCantTakeSquadReasonData
  sellSquad
  sellingSquadId
}
