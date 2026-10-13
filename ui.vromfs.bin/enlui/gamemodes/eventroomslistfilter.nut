from "%enlSqGlob/crossnetwork_state.nut" import isCrossplayOptionNeeded, crossnetworkPlay, CrossplayState, availableCrossplayOptions, CrossPlayStateWeight
from "%sqstd/frp.nut" import subscribeAndInit
from "dagor.debug" import logerr
from "%sqstd/underscore.nut" import unique
from "%ui/options/onlineSettings.nut" import settings
from "%ui/gameModes/createEventRoomCfg.nut" import createEventRoomCfg, allModes, getValuesFromRule
from "%ui/clusterState.nut" import availableClusters, clusterLoc
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN, allArmies
from "%ui/campaigns/armiesConfig.nut" import getArmyName
from "%ui/ui_library.nut" import *
from "types" import Array

const OPT_SWITCH = "switch"
const OPT_MULTISELECT = "multiselect"
const OPT_RADIO = "radioselect"

const SAVE_ID = "eventRoomFilter"
const MODE_ID = "public/mode"
let saved = Computed(@() settings.get()?[SAVE_ID])
function save(key, value) {
  if (saved.get()?[key] != value)
    settings.mutate(@(s) s[SAVE_ID] <- (s?[SAVE_ID] ?? {}).__merge({ [key] = value }))
}
function clearFilters() {
  if (saved.get() != null)
    settings.mutate(@(s) s.$rawdelete(SAVE_ID))
}
let curModes = Computed(@() (saved.get()?[MODE_ID] ?? []).filter(@(m) allModes.get().contains(m)))

let mkSave = @(key) @(value) save(key, value)

function getValuesByRule(rule, curValues) {
  let { values } = getValuesFromRule(rule)
  let { override = [] } = rule

  let res = []

  if (!(override instanceof Array)) {
    logerr($"Error in getValuesByRule. Override property must have array type.")
    return res;
  }

  local canApplyDefault = true
  for(local i = override.len() - 1; i >= 0; i--) {
    let ovr = override[i]
    let ovrValues = getValuesFromRule(ovr).values
    if (ovrValues.len() == 0)
      continue

    local isFit = true
    local isOverrideDefault = false
    foreach (fName, fValue in ovr?.applyIf ?? {}) {
      if (fName not in curValues)
        return null 
      local val = curValues[fName]
      if (val instanceof Array)
        val = val.len() == 1 ? val[0] : null 
      isFit = val == null || fValue == val
      if (isFit)
        isOverrideDefault = isOverrideDefault || val != null
      else
        break
    }
    if (isFit) {
      res.extend(ovrValues)
      canApplyDefault = canApplyDefault && !isOverrideDefault
    }
  }
  if (canApplyDefault)
    res.extend(values)
  return unique(res)
}

function updateValues(toTbl, fromTbl) {
  foreach (key, list in fromTbl)
    if (key in toTbl)
      toTbl[key].extend(list)
    else
      toTbl[key] <- clone list
}

let prevIfEqual = @(newValue, prevValue) isEqual(newValue, prevValue) ? prevValue : newValue
let prepareMergedValues = @(newTbl, prevTbl)
  newTbl.map(@(list, key) prevIfEqual(unique(list), prevTbl?[key]))

let optionsConfig = Computed(function(prev) {
  if (prev == FRP_INITIAL)
    prev = { curValues = {}, availValues = {} }

  let curValues = {}
  let availValues = {}

  let modesList = curModes.get().len() > 0 ? curModes.get() : allModes.get()
  foreach (mode in modesList) {
    let { rules = {} } = createEventRoomCfg.get()?[mode]
    let modeCurValues = {}
    let modeAvailValues = {}
    let leftKeys = rules.keys()
    while(leftKeys.len() > 0) {
      let leftKeysOnCycleStart = leftKeys.len()
      for(local i = leftKeys.len() - 1; i >= 0; i--) {
        let name = leftKeys[i]
        let values = getValuesByRule(rules[name], modeCurValues)
        if ((values?.len() ?? 0) == 0)
          continue

        modeCurValues[name] <- (saved.get()?[name] ?? []).filter(@(v) values.contains(v))
        modeAvailValues[name] <- values
        leftKeys.remove(i)
      }

      if (leftKeysOnCycleStart == leftKeys.len())
        break 
    }

    updateValues(curValues, modeCurValues)
    updateValues(availValues, modeAvailValues)
  }

  return {
    curValues = prepareMergedValues(curValues, prev.curValues)
    availValues = prepareMergedValues(availValues, prev.availValues)
  }
})

let mkToggleValue = @(id, curValues) function toggleValue(value, isChecked) {
  local res = saved.get()?[id]
  if (!(res instanceof Array))
    res = curValues.get()
  let idx = res.indexof(value)
  if ((idx != null) == isChecked)
    return
  res = clone res
  if (isChecked)
    res.append(value)
  else
    res.remove(idx)
  save(id, res)
}

function mkOption(id, locId, valToString = @(v) v) {
  let allValues = Computed(@() optionsConfig.get().availValues?[id])
  let curValues = Computed(@() optionsConfig.get().curValues?[id] ?? [])
  return {
    id
    optType = OPT_MULTISELECT
    locId
    valToString
    allValues
    curValues
    setValue = mkSave(id)
    toggleValue = mkToggleValue(id, curValues)
  }
}

let optionLoc = @(v) loc($"options/{v}", v)
let filterByList = @(res, filterList)
  res?.filter(@(v) filterList.contains(v))





let optDifficulty = mkOption("public/difficulty", "options/difficulty", optionLoc)

let optCrossplay = mkOption("public/crossplay", "options/crossplay", @(v) loc($"option/crossplay/{v}"))
function updateOptCrossplay(val) {
  if (!val)
    optCrossplay.__update({ allValues = Watched(null) })
  else {
    let cpAVBase = optCrossplay.allValues
    let cpCVBase = optCrossplay.curValues
    let cpAllValues = Computed(function() {
      let values = cpAVBase.get()
      if (values == null
          || crossnetworkPlay.get() == CrossplayState.OFF
          || availableCrossplayOptions.get().findvalue(@(v) !values.contains(v)) != null)
        return null 
      let curWeight = CrossPlayStateWeight?[crossnetworkPlay.get()] ?? 100
      return availableCrossplayOptions.get().filter(@(v) (CrossPlayStateWeight?[v] ?? 100) <= curWeight)
    })
    let cpCurValues = Computed(function() {
      let all = cpAllValues.get()
      let defaultValue = [crossnetworkPlay.get()]
      if (all == null)
        return defaultValue
      let value = cpCVBase.get().filter(@(v) all.contains(v))
      return value.len() > 0 ? value : defaultValue
    })
    optCrossplay.__update({ allValues = cpAllValues, curValues = cpCurValues, optType = OPT_RADIO })
  }
}

subscribeAndInit(updateOptCrossplay, isCrossplayOptionNeeded)

let optMode = mkOption(MODE_ID, "current_mode", loc)
optMode.__update({ allValues = allModes, curValues = curModes })

let optArmiesA = mkOption("public/armiesTeamA", "options/armiesA", @(armyId) getArmyName(armyId))
let armiesAllValuesBaseA = optArmiesA.allValues
let armiesCurValuesBaseA = optArmiesA.curValues
optArmiesA.__update({
  allValues = Computed(@() filterByList(armiesAllValuesBaseA.get(), allArmies.get()[COMMON_CAMPAIGN]))
  curValues = Computed(@() filterByList(armiesCurValuesBaseA.get(), allArmies.get()[COMMON_CAMPAIGN]))
})

let optArmiesB = mkOption("public/armiesTeamB", "options/armiesB", @(armyId) getArmyName(armyId))
let armiesAllValuesBaseB = optArmiesB.allValues
let armiesCurValuesBaseB = optArmiesB.curValues
optArmiesB.__update({
  allValues = Computed(@() filterByList(armiesAllValuesBaseB.get(), allArmies.get()[COMMON_CAMPAIGN]))
  curValues = Computed(@() filterByList(armiesCurValuesBaseB.get(), allArmies.get()[COMMON_CAMPAIGN]))
})

const optClusterId = "cluster"
let curClusters = Computed(@() filterByList(saved.get()?[optClusterId] ?? [], availableClusters.get()))
let optCluster = {
  id = optClusterId
  optType = OPT_MULTISELECT
  locId = "quickMatch/Server"
  valToString = clusterLoc
  allValues = availableClusters
  curValues = curClusters
  setValue = mkSave(optClusterId)
  toggleValue = mkToggleValue(optClusterId, curClusters)
}

let locOn = loc($"option/on")
let locOff = loc($"option/off")

const optFullRoomsId = "fullRooms"
let optFullRooms = {
  id = optFullRoomsId
  optType = OPT_SWITCH
  locId = "rooms/HideFull"
  valToString = @(v) v ? locOn : locOff
  curValue = Computed(@() saved.get()?[optFullRoomsId] ?? false)
  setValue = mkSave(optFullRoomsId)
}

const optModRoomsId = "ModRooms"
let optModRooms = {
  id = optModRoomsId
  optType = OPT_SWITCH
  locId = "rooms/HideMods"
  valToString = @(v) v ? locOn : locOff
  curValue = Computed(@() saved.get()?[optModRoomsId] ?? false)
  setValue = mkSave(optModRoomsId)
}

const optPasswordRoomsId = "PasswordRooms"
let optPasswordRooms = {
  id = optPasswordRoomsId
  optType = OPT_SWITCH
  locId = "rooms/HidePasswordRooms"
  valToString = @(v) v ? locOn : locOff
  curValue = Computed(@() saved.get()?[optPasswordRoomsId] ?? false)
  setValue = mkSave(optPasswordRoomsId)
}

console_register_command(clearFilters, "customRooms.resetFilter")

return {
  OPT_MULTISELECT
  OPT_RADIO

  optMode
  optDifficulty
  optCrossplay
  optCluster
  optFullRooms
  optModRooms
  optPasswordRooms
  optArmiesA
  optArmiesB
}