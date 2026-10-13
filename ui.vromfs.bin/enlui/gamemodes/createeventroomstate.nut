import "%enlSqGlob/campaignToArmies.nut" as campaignToArmies
import "%ui/userstats/serverTime.nut" as serverTime
import "%enlSqGlob/userInfo.nut" as userInfo
import "matching.errors" as matching_errors
import "%ui/gameModes/getMissionInfo.nut" as getMissionInfo
import "%ui/options/crossnetwork_save.nut" as saveCrossnetworkPlayValue
from "%enlSqGlob/crossnetwork_state.nut" import isCrossplayOptionNeeded, crossnetworkPlay, availableCrossplayOptions, CrossplayState, CrossPlayStateWeight
from "%sqstd/frp.nut" import subscribeAndInit
from "%enlSqGlob/modsDownloadManager.nut" import getModStartInfo
from "%dngscripts/platform.nut" import platformAlias
from "dagor.debug" import logerr
from "%ui/options/onlineSettings.nut" import settings
from "%ui/clusterState.nut" import availableClusters, clusterLoc, oneOfSelectedClusters
from "%ui/gameModes/createEventRoomCfg.nut" import createEventRoomCfg, allModes, getValuesFromRule
from "%ui/soldiers/model/config/gameProfile.nut" import allArmiesInfo
from "%ui/state/roomState.nut" import createRoom, changeAttributesRoom, room, isInRoom, roomPasswordToJoin
from "%sqstd/table.nut" import getValInTblPath, setValInTblPath
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/gameModes/sandbox/customMissionState.nut" import receivedModInfos, modPath, fetchLocalModById
from "app" import set_matching_invite_data
from "%ui/currency/premium.nut" import hasPremium
from "%ui/components/itemsInfo.nut" import getCampaignTitle
from "%ui/ui_library.nut" import *
from "types" import Array

let gameLauncher = require("%ui/gameLauncher.nut")

let consoleAliases = ["sony", "xbox"]
let allAliases = ["pc", "sony", "xbox", "mobile"]
let currentPassword = Watched("")


const OPT_EDITBOX = "editbox"
const OPT_LIST = "list"
const OPT_CHECKBOX = "checkbox"
const OPT_MULTISELECT = "multiselect"
const MODDED_CONFIG_POSTFIX = "_MODDED"
const PASSWORD_MAX_LENGTH = 16

const SAVE_ID = "eventRoomParams"
let saved = Computed(@() settings.get()?[SAVE_ID])
function save(key, value) {
  if (saved.get()?[key] != value)
    settings.mutate(@(s) s[SAVE_ID] <- (s?[SAVE_ID] ?? {}).__merge({ [key] = value }))
}
let mkSave = @(key) @(value) save(key, value)

let isAnyModEnabled = @() modPath.get() != ""

let availableModes = Computed(function() {
  if (isAnyModEnabled()) {
    let modMode = receivedModInfos.get()?[modPath.get()].room_params.defaults.public.mode
    if (modMode != null)
      return [modMode]
  }
  return allModes.get()
})

let curMode = Computed(function() {
  let { mode = "SQUADS" } = saved.get()
  let curModes = availableModes.get()
  return curModes.contains(mode) ? mode : (curModes?[0] ?? "")
})

let curCfgName = Computed(function() {
  let moddedPostfix = modPath.get() == "" ? "" : MODDED_CONFIG_POSTFIX
  let cfgName = $"{curMode.get()}{moddedPostfix}"
  let availableConfigs = createEventRoomCfg.get().keys()
  return availableConfigs.contains(cfgName)
    ? cfgName
    : availableConfigs.contains(curMode.get())
      ? curMode.get()
      : (availableConfigs?[0] ?? "")
})

let curCfg = Computed(@() createEventRoomCfg.get()?[curCfgName.get()])

let isEditEventRoomOpened = mkWatched(persist, "isEditEventRoomOpened", false)
let isEditInProgress = Watched(false)
room.subscribe(function(v) { if (v != null) isEditEventRoomOpened.set(false) })

function getValuesByRule(rule, curValues) {
  let { override = [] } = rule
  local { values, isMultival } = getValuesFromRule(rule)
  foreach (ovr in override) {
    local isFit = true
    foreach (fName, fValue in ovr?.applyIf ?? {}) {
      if (fName not in curValues)
        return null 
      if (curValues[fName] != fValue) {
        isFit = false
        break
      }
    }
    if (!isFit)
      continue
    let ovrValues = getValuesFromRule(ovr).values
    if (ovrValues.len() > 0)
      values = ovrValues
  }
  return { values, isMultival }
}

function parseMatchingError(loc_base, response) {
  if (response.error != matching_errors.SERVER_ERROR_GENERIC)
    return loc(loc_base, { responce_error = matching_errors.error_string(response.error)}) 

  let errorId = response.error_id
  let errorInfo = response?.info
  let errorIdStr = loc(loc_base, { responce_error = errorId})
  if (errorInfo == null)
    return errorIdStr

  return $"{errorIdStr}\nparam: {errorInfo?.param}\n{errorInfo?.detail}"
}

let getDefValue = @(defaults, id) getValInTblPath(defaults, id.split("/"))
let prevIfEqual = @(newValue, prevValue)
  isEqual(newValue, prevValue) ? prevValue : newValue

let optionsConfig = Computed(function(prev) {
  if (prev == FRP_INITIAL)
    prev = { curValues = {}, optionsInfo = {} }

  let curValues = {}
  let optionsInfo = {}
  let { defaults = {} } = curCfg.get()
  let rules = (curCfg.get()?.rules ?? {}).__merge(
    receivedModInfos.get()?[modPath.get()].room_params.rules ?? {})
  let leftKeys = rules.keys()
  while(leftKeys.len() > 0) {
    let leftKeysOnCycleStart = leftKeys.len()
    for(local i = leftKeys.len() - 1; i >= 0; i--) {
      let name = leftKeys[i]
      let rule = rules[name]
      let { values = null, isMultival = false } = getValuesByRule(rule, curValues)
      if (values == null)
        continue

      if (values.len() == 0) {
        
        if ("max_strlen" in rule) {
          let optInfo = {
            optType = OPT_EDITBOX
            maxChars = rule.max_strlen
          }
          optionsInfo[name] <- prevIfEqual(optInfo, prev.optionsInfo?[name])
        }
        leftKeys.remove(i)
        continue
      }

      local curValue = saved.get()?[name]
      let valueType = rule?.type ?? type(values[0])
      if (isMultival)
        curValue = prevIfEqual(
          curValue instanceof Array ? curValue.filter(@(v) values.contains(v))
            : values.contains(curValue) ? [curValue]
            : (getDefValue(defaults, name) ?? values),
          prev.curValues?[name])
      else if (!values.contains(curValue)) {
        let newVal = getDefValue(defaults, name)
        curValue = values.contains(newVal) ? newVal : values?[0]
      }
      if (curValue == null) {
        logerr($"Create room param /*{name}*/ does not have default value. (mode = /*{curCfgName.get()}*/)")
        continue
      }

      curValues[name] <- curValue
      let optInfo = {
        values
        optType = isMultival ? OPT_MULTISELECT
          : valueType == "bool" ? OPT_CHECKBOX
          : OPT_LIST
      }
      optionsInfo[name] <- prevIfEqual(optInfo, prev.optionsInfo?[name])
      leftKeys.remove(i)
    }

    if (leftKeysOnCycleStart == leftKeys.len()) {
      let txt = ", ".join(leftKeys)
      logerr($"Unable to process create room options because of bad filters in override or empty values list. (mode = /*{curCfgName.get()}*/) /*{txt}*/")
      break
    }
  }

  return {
    curValues
    optionsInfo
  }
})

let mkToggleValue = @(id, cfg, curValue) function toggleValue(value, isChecked) {
  if (cfg.get()?.optType != OPT_MULTISELECT) {
    logerr($"Try to call addValue/removeValue for not multiselect option: /*{id}*/")
    return
  }
  local res = saved.get()?[id]
  if (!(res instanceof Array))
    res = curValue.get()
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

function mkOption(id, locId, valToString = @(v) v, typeToString = @(v) v) {
  let staticInfo = { locId }
  let cfg = Computed(@() optionsConfig.get().optionsInfo?[id].__merge(staticInfo))
  let curValue = Computed(@() optionsConfig.get().curValues?[id])
  return {
    id
    cfg
    curValue
    setValue = mkSave(id)
    valToString
    typeToString
    toggleValue = mkToggleValue(id, cfg, curValue)
  }
}

let optionLoc = @(v) loc($"options/{v}", v)
let getBoolText = @(value) value ? loc("quickchat/yes") : loc("quickchat/no")





let optIsPrivate = mkOption("public/isPrivate", "options/private")
let optDifficulty = mkOption("public/difficulty", "options/difficulty", optionLoc)
let optMaxPlayers = mkOption("public/maxPlayers", "options/maxPlayers")
let optBotCount = mkOption("public/botpop", "options/botCount")
let optVoteToKick = mkOption("public/voteToKick", "options/voteToKick", getBoolText)
let optTeamArmies = mkOption("public/teamArmies", "options/teamArmies", optionLoc)
let teamArmies = optTeamArmies.curValue

const optModeId = "mode"
let optMode = {
  id = optModeId
  cfg = Computed(@() { locId = "current_mode", optType = OPT_LIST, values = availableModes.get() })
  curValue = curMode
  isEditAllowed = false
  setValue = mkSave(optModeId)
  valToString = loc
}

const optPasswordId = "password"
let optPassword = {
  id = optPasswordId
  cfg = Computed(@() {
    locId = "options/password",
    optType = OPT_EDITBOX,
    maxChars = curCfg.get()?.rules[optPasswordId].max_strlen ?? PASSWORD_MAX_LENGTH
    isHidden = !(hasPremium.get() || isInRoom.get())
  })
  curValue = currentPassword
  isEditAllowed = false
  password = true
  charMaskTypes = "lat; integer"
  setValue = @(val) currentPassword.set(val)
  optDummy = loc("password_access")
  placeholder = loc("create_pass")
}

const optCampId = "public/campaigns"
let optCampStatic = { locId = "options/campaigns" }
let campCfg = Computed(function() {
  let res = optionsConfig.get().optionsInfo?[optCampId]
  let modInfo = receivedModInfos.get()?[modPath.get()]
  let modHash = modInfo?.content[0].hash 
  if (res == null || modHash != null)
    return null
  return res.__merge(optCampStatic, { values = res.values })
})

let choosedCampaign = Computed(@() optionsConfig.get().curValues?[optCampId])

let optCampaigns = {
  id = optCampId
  cfg = campCfg
  curValue = choosedCampaign
  setValue = mkSave(optCampId)
  valToString = @(c) getCampaignTitle(c)
}

const optClusterId = "public/cluster"
let optCluster = {
  id = optClusterId
  cfg = Computed(@() { locId = "quickMatch/Server", optType = OPT_LIST, values = availableClusters.get() })
  curValue = Computed(function() {
    let res = saved.get()?[optClusterId]
    return availableClusters.get().contains(res) ? res : oneOfSelectedClusters.get()
  })
  setValue = mkSave(optClusterId)
  valToString = clusterLoc
}

const optArmyIdA = "public/armiesTeamA"
let armiesACfg = Computed(function() {
  let res = optionsConfig.get().optionsInfo?[optArmyIdA]
  if (res == null)
    return res
  return res.__merge({ locId = "options/armiesA" })
})
let armiesA = Computed(@() optionsConfig.get().curValues?[optArmyIdA])
let optArmiesA = {
  id = optArmyIdA
  cfg = armiesACfg
  curValue = armiesA
  setValue = mkSave(optArmyIdA)
  toggleValue = mkToggleValue(optArmyIdA, armiesACfg, armiesA)
  valToString = @(a) loc($"country/{allArmiesInfo.get()[a].country}")
}

const optArmyIdB = "public/armiesTeamB"
let armiesBCfg = Computed(function() {
  let res = optionsConfig.get().optionsInfo?[optArmyIdB]
  if (res == null)
    return res
  return res.__merge({ locId = "options/armiesB" })
})
let armiesB = Computed(@() optionsConfig.get().curValues?[optArmyIdB])
let optArmiesB = {
  id = optArmyIdB
  cfg = armiesBCfg
  curValue = armiesB
  setValue = mkSave(optArmyIdB)
  toggleValue = mkToggleValue(optArmyIdB, armiesBCfg, armiesB)
  valToString = @(a) loc($"country/{allArmiesInfo.get()[a].country}")
}

const optMissionsId = "public/scenes"
let optMissionsCfg = Computed(@() optionsConfig.get().optionsInfo?[optMissionsId]
  .__merge({ locId = "options/missions" }))
let optMissionsCurValue = Computed(function() {
  let res = optionsConfig.get().curValues?[optMissionsId]
  return typeof res == "table" ? [] : res
})

let missions = Computed(function(prev) {
  let { values = [], optType = null } = optMissionsCfg.get()
  if (optType != OPT_MULTISELECT)
    return optMissionsCurValue.get()

  let res = (optMissionsCurValue.get() ?? []).filter(@(m) values.contains(m))
  return prevIfEqual(res, prev)
})

let optMissions = {
  id = optMissionsId
  cfg = optMissionsCfg
  curValue = missions
  setValue = mkSave(optMissionsId)
  typeToString = @(s) loc(getMissionInfo(s).typeLocId)
  toggleValue = mkToggleValue(optMissionsId, optMissionsCfg, optMissionsCurValue)
  valToString = @(s) loc(getMissionInfo(s).locId)
}

const cpId = "public/crossplay"
const cpLocId = "options/crossplay"
let optCrossplay = mkOption(cpId, cpLocId, @(v) loc($"option/crossplay/{v}"))
let cpCfgBase = optCrossplay.cfg
optCrossplay.__update({ isEditAllowed = false })

function updateOptCrossplay(val) {
  if (!val)
    optCrossplay.__update({ cfg = Watched(null) })
  else {
    let cpCfg = Computed(function() {
      let { optType = null, values = null } = cpCfgBase.get()
      if (optType != OPT_LIST
          || availableCrossplayOptions.get().findvalue(@(v) !values?.contains(v)) != null)
        return null 
      return cpCfgBase.get().__merge({ values = availableCrossplayOptions.get() })
    })
    optCrossplay.__update({
      cfg = cpCfg
      curValue = crossnetworkPlay
      setValue = saveCrossnetworkPlayValue
    })
  }
}

subscribeAndInit(updateOptCrossplay, isCrossplayOptionNeeded)

function getCrossPlatformsList() {
  let all = optionsConfig.get().optionsInfo?["public/crossPlatform"].values
  if (all == null)
    return []
  let allowTbl = {}
  let curCP = crossnetworkPlay.get()
  let aliasesList = curCP == CrossplayState.ALL ? allAliases
    : curCP == CrossplayState.CONSOLES ? consoleAliases
    : [platformAlias]

  let curCPWeight = CrossPlayStateWeight?[curCP] ?? 100
  foreach (cpVal, cpWeight in CrossPlayStateWeight)
    if (curCPWeight <= cpWeight)
      foreach (alias in aliasesList)
        allowTbl[$"{alias}_{cpVal}"] <- true

  return all.filter(@(p) p in allowTbl)
}


function isScenesNull() {
  local scenes = missions.get() ?? []
  if (scenes.len() == 0) {
    scenes = optMissions.cfg.get()?.values ?? []
    if (scenes.len() == 0) {
      return true
    }
  }
  return false
}

function isModsNull() {
  let mods = receivedModInfos.get() ?? []
  return mods.len() == 0
}

function mkTeamArmies(camps, tArmies) {
  let isHistorical = tArmies == "historical"
  let armiesAllies = {}
  let armiesAxis = {}

  foreach (campId in camps) {
    let { allies = [], axis = [] } = campaignToArmies?[campId]
    foreach (armyA in allies)
      armiesAllies[armyA] <- true
    foreach (armyB in axis)
      armiesAxis[armyB] <- true
  }
  if (isHistorical)
    return [armiesAllies.keys(), armiesAxis.keys()]

  armiesAllies.__update(armiesAxis)
  return [armiesAllies.keys(), armiesAllies.keys()]
}

function createEventRoom() {
  if (isEditInProgress.get())
    return

  if (isModsNull() && isScenesNull()) {
    logerr("Can't create room because missions list and mods list is empty")
    return
  }

  let roomParams = {
    lobby_template = curCfgName.get()
    public = {
      cTime = serverTime.get()
    }
  }

  foreach (opt in [
    optIsPrivate
    optDifficulty
    optMaxPlayers
    optBotCount
    optVoteToKick
    optCrossplay
    optCluster
    optMissions
    optArmiesA
    optArmiesB
    optTeamArmies
    optCampaigns
    optPassword
  ])
    if (opt.cfg.get() != null && opt.curValue.get() != "")
      setValInTblPath(roomParams, opt.id.split("/"),
        opt.curValue.get() instanceof Array && opt.curValue.get().len() == 0
          ? opt.cfg.get().values
          : opt.curValue.get())

  let publicOptions = roomParams.public
  publicOptions.creatorId <- userInfo.get().userIdStr
  let modInfo = receivedModInfos.get()?[modPath.get()]
  let modHash = modInfo?.content[0].hash 
  let modId = modInfo?.id
  if (isAnyModEnabled() && modHash != null) {
    let modName = modInfo?.title
    let modDescription = modInfo?.description
    let modVersion = modInfo?.version
    let modAuthor = modInfo?.authors[0]
    let modCampaigns = modInfo?.room_params.rules[optCampId].anyOf
    let tArmies = teamArmies.get()
    let armies = mkTeamArmies(modCampaigns, tArmies)
    let armiesTeamA = armies[0]
    let armiesTeamB = armies[1]
    let numTeams = modInfo?.room_params.defaults.public.numTeams ?? 2
    publicOptions.__update({ modId, modHash, modName, modDescription, modVersion, modAuthor,
      armiesTeamA, armiesTeamB, numTeams })
  }
  let crossPlatform = getCrossPlatformsList()
  if (crossPlatform.len() > 0)
    publicOptions.crossPlatform <- crossPlatform

  isEditInProgress.set(true)
  if (modPath.get() != "" && optMaxPlayers.curValue.get() <= 1) {
    fetchLocalModById(modId, function(manifest, contents) {
      set_matching_invite_data({ mode_info = publicOptions })
      gameLauncher.startGame({ modId }.__merge(getModStartInfo(manifest, contents)))
      isEditInProgress.set(false)
    }, function() {
      isEditInProgress.set(false)
    })
    return
  }

  createRoom(roomParams,
    function onResult(response) {
      isEditInProgress.set(false)
      isEditEventRoomOpened.set(false)
      if (response.error != 0)
        showMsgbox(parseMatchingError("customRoom/failCreate", response))
      if (response?.public.hasPassword ?? false){
        let password = optPassword.curValue.get()
        let roomId = response.roomId
        roomPasswordToJoin.mutate(@(v) v[roomId] <- password)
      }
    })
}

function updateAttributesEventRoom() {
  if (isEditInProgress.get())
    return

  if (isModsNull() && isScenesNull()) {
    logerr("Can't change room's attributes because missions list and mods list is empty")
    return
  }

  let roomParams = {
    lobby_template = curCfgName.get()
    public = {
      cTime = serverTime.get()
    }
  }

  foreach (opt in [
    optIsPrivate
    optDifficulty
    optMaxPlayers
    optBotCount
    optVoteToKick
    optCrossplay
    optCluster
    optMissions
    optArmiesA
    optArmiesB
    optTeamArmies
    optCampaigns
    optPassword
  ])
    if (opt.cfg.get() != null && (opt?.isEditAllowed ?? true)) {
      let path = opt.id.split("/")
      let newParam = opt.curValue.get() instanceof Array && opt.curValue.get().len() == 0
        ? opt.cfg.get().values
        : opt.curValue.get()
      let oldParam = getValInTblPath(room.get(), path)

      if (!isEqual(oldParam, newParam))
        setValInTblPath(roomParams, path, newParam)
    }

  if (roomParams.len() == 0)
    return isEditEventRoomOpened.set(false)

  isEditInProgress.set(true)
  changeAttributesRoom(roomParams,
    function onResult(response) {
      isEditInProgress.set(false)
      if (response.error != 0)
        return showMsgbox(parseMatchingError("customRoom/failChange", response))
      isEditEventRoomOpened.set(false)
    })
}

let editEventRoom = @() isInRoom.get() ? updateAttributesEventRoom() : createEventRoom()

console_register_command(@() isEditEventRoomOpened.set(!isEditEventRoomOpened.get()), "openCreateEventRoomWnd")

return {
  OPT_EDITBOX
  OPT_LIST
  OPT_CHECKBOX
  OPT_MULTISELECT

  optIsPrivate
  optMode
  optDifficulty
  optMaxPlayers
  optBotCount
  optVoteToKick
  optCrossplay
  optMissions
  optCluster
  optArmiesA
  optArmiesB
  optCampaigns
  optPassword

  isInRoom
  isEditInProgress
  isEditEventRoomOpened
  editEventRoom
  currentPassword
}
