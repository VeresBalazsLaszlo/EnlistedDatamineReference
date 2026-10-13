import "io" as io
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/sqevents.nut" import mkCmdProfileJwtData
from "%enlSqGlob/data/profile_pubkey.nut" import profilePublicKey
from "json" import object_to_json_string
from "jwt" import decode
from "eventbus" import eventbus_subscribe, eventbus_send
from "%sqstd/json.nut" import loadJson
from "%ui/soldiers/model/state.nut" import playerSelectedSquads, allAvailableArmies, curArmy
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN
from "%ui/mpRoom/enlRoomState.nut" import isEventRoom
from "%ui/mpRoom/myRoomMemberParams.nut" import myArmy
from "dagor.debug" import debug, logerr
from "%ui/meta/clientApi.nut" import get_bots_data, get_profile_data_jwt_armies, get_profile_data_jwt_offer, debug_apply_booster_in_battle, debug_apply_test_drive_in_battle
from "%ui/battleData/missionCampaign.nut" import getCampaignOutfit
from "%ui/quickMatchQueue.nut" import testDriveOffer
from "%ui/offers/offersState.nut" import visibleOffersInWindow
from "%ui/hud/state/custom_profile.nut" import customProfile
from "%ui/ui_library.nut" import *

let logSd = with_prefix("[SEND_DATA] ")


let nextBattleData = Watched(null)

function decodeJwtAndHandleErrors(data) {
  let jwt        = data?.jwt ?? ""
  let jwtDecoded = decode(jwt, profilePublicKey)

  let jwtArmies = jwtDecoded?.payload.armies
  let jwtError = jwtDecoded?.error
  if (jwtArmies != null && jwtError == null)
    return {jwt, jwtArmies}

  logerr($"Error /*{jwtError}*/ during jwt profile decoding. See log for more details.")
  logSd(data)
  return null
}


function dumpArmies(data) {
  debug("Battle armies dump")
  foreach (armyId, armyData in data) {
    debug($"Army: {armyId}, {armyData.squads.len()} squads")
    foreach (squad in armyData.squads) {
      debug($"  Squad: {squad.squadId}, {squad.squad.len()} soldiers")
      foreach (soldier in squad.squad) {
        debug($"    Soldier {soldier.name} {soldier.surname} ({soldier.sClass} {soldier.level}) #{soldier.guid} ")
        foreach (slotId in ["primary", "secondary", "tertiary", "melee", "grenade"])
          debug($"      {slotId}: {soldier.human_weap__weapTemplates?[slotId] ?? ""}")
        debug($"      inventory: {", ".join(soldier.inventory.map(@(inv) inv?.gametemplate) )}")
        foreach (equipId, equipment in soldier.equipment)
          debug($"      {equipId}: {equipment?.gametemplate ?? ""}")
      }
    }
  }
}


function requestProfileDataJwtByOffer(offerGuid, cb) {
  function cbWrapper(data) {
    let res = decodeJwtAndHandleErrors(data)
    if (res == null) {
      logSd("requestProfileDataJwtByOffer empty data")
      cb("", {})
      return
    }

    let { jwt, jwtArmies } = res
    logSd($"requestProfileDataJwtByOffer jwt size: {jwt.len()}")
    dumpArmies(jwtArmies)
    cb(jwt, jwtArmies)
  }

  get_profile_data_jwt_offer(offerGuid, cbWrapper)
}


function requestProfileDataJwtByArmy(armies, outfitId, cb) {
  if (armies.len() <= 0) {
    logSd("requestProfileDataJwtByArmy no armies requested")
    return
  }

  let armiesToCurSquad = {}
  foreach (armyId in armies)
    armiesToCurSquad[armyId] <- playerSelectedSquads.get()?[armyId] ?? ""

  function cbWrapper(data) {
    let res = decodeJwtAndHandleErrors(data)
    if (res == null) {
      logSd("requestProfileDataJwtByArmy empty data")
      cb("", {})
      return
    }

    let { jwt, jwtArmies } = res
    logSd($"requestProfileDataJwtByArmy jwt size: {jwt.len()}")
    dumpArmies(jwtArmies)
    cb(jwt, jwtArmies)
  }

  get_profile_data_jwt_armies(armiesToCurSquad, outfitId, cbWrapper)
}


function splitStringBySize(str, maxSize) {
  assert(maxSize > 0)
  let result = []
  local start = 0
  let len = str.len()
  while (start < len) {
    let pieceSize = min(len - start, maxSize)
    result.append(str.slice(start, start + pieceSize))
    start += pieceSize
  }
  return result
}

function send(playerEid, jwt, data) {
  let jwtSplit = splitStringBySize(jwt, 4096)
  logSd($"Sent data for player {playerEid}, jwt size: {jwt.len()}, pieces: {jwtSplit.len()}")
  ecs.client_send_event(playerEid, mkCmdProfileJwtData({ jwt = jwtSplit }))
  eventbus_send("updateArmiesData", data)
}

function saveResultToJson(data, fileName, pretty = true) {
  fileName = $"{fileName}.json"
  let file = io.file(fileName, "wt+")
  file.writestring(object_to_json_string(data, pretty))
  file.close()
  console_print($"Saved json payload to {fileName}")
}

function saveJwtResultToJson(jwt, data, fileName, pretty = true) {
  saveResultToJson(data, fileName, pretty)

  fileName = $"{fileName}.jwt"
  let file = io.file(fileName, "wt+")
  file.writestring(jwt)
  file.close()
  console_print($"Saved jwt to {fileName}")
}

function saveToFile(teamArmy = null, pretty = true) {
  let cb = @(jwt, data) saveJwtResultToJson(jwt, data, "sendArmiesData", pretty)
  if (teamArmy == null) {
    let requestArmies = []
    foreach (armies in allAvailableArmies.get())
      requestArmies.extend(armies)
    requestProfileDataJwtByArmy(requestArmies, getCampaignOutfit(), cb)
  }
  else
    requestProfileDataJwtByArmy([teamArmy], getCampaignOutfit(), cb)
}

let mkJwtArmiesCbNoRetries = @(cb) function(data) {
  let res = decodeJwtAndHandleErrors(data)
  if (res == null) {
    logSd("mkJwtArmiesCbNoRetries empty data")
    cb("", {})
    return
  }

  let {jwt, jwtArmies} = res
  logSd($"mkJwtArmiesCbNoRetries jwt size: {jwt.len()}")
  cb(jwt, jwtArmies)
}

let findArmy = @(armies, allArmies) armies.findvalue(@(a) allArmies.contains(a))

function chooseFromArmies(armies) {
  let allArmies = allAvailableArmies.get()?[COMMON_CAMPAIGN] ?? []
  logSd("chooseFromArmies armies:", armies, "allArmies:", allArmies)
  let selArmyId = isEventRoom.get() ? myArmy.get() : curArmy.get()
  let armyId = armies.findvalue(@(a) a == selArmyId) ?? findArmy(armies, allArmies)
  if (armyId == null)
    logerr($"chooseFromArmies: no available armies in requested armies. armies: /*{",".join(armies)}*/, current: /*{selArmyId}*/")
  let resArmyId = armyId ?? armies.top()
  logSd($"selArmyId: {selArmyId}, armyId: {armyId}, result: {resArmyId}")
  return resArmyId ? [resArmyId] : []
}

eventbus_subscribe("requestArmiesData", function(msg) {
  let { playerEid, armies } = msg
  let cb = @(jwt, data) send(playerEid, jwt, data)

  if (testDriveOffer.get() != null) {
    logSd($"requestProfileDataJwtByOffer {testDriveOffer.get()}")
    requestProfileDataJwtByOffer(testDriveOffer.get(), cb)
  }
  else if (armies.contains(nextBattleData.get()?.armyId)) {
    logSd("nextBattleData armies:", armies, ", selected:", nextBattleData.get()?.armyId)
    cb(nextBattleData.get().jwt, nextBattleData.get().data)
  }
  else {
    let teamArmies = chooseFromArmies(armies)
    logSd("requestProfileDataJwtByArmy armies:", armies, ", selected:", teamArmies)
    requestProfileDataJwtByArmy(teamArmies, getCampaignOutfit(), function(jwt, data) {
      let { path = "", isJoined = false } = customProfile.get()
      if (path == "") {
        logSd("requestProfileDataJwtByArmy empty data")
        cb(jwt, data)
        return
      }

      let customArmies = loadJson(path)
      if (isJoined)
        foreach (armyId, armyData in customArmies) {
          if (armyId in data)
            customArmies[armyId] = data[armyId].__update(armyData)
        }
      logSd($"requestProfileDataJwtByArmy jwt size: {jwt.len()}")
      cb(jwt, customArmies)
    })
  }

  nextBattleData.set(null)
})


function debugApplyBoosterInBattle() {
  let armyId = curArmy.get()
  requestProfileDataJwtByArmy([armyId], getCampaignOutfit(), function(_jwt, data) {
    let boosters = (data?[armyId].boosters ?? []).map(@(b) b.guid)
    console_print($"Boosters applied in army {armyId}: ", ", ".join(boosters))
    debug_apply_booster_in_battle(boosters)
  })
}


function debugApplyTestDriveInBattle() {
  let offer = visibleOffersInWindow.get().findvalue(@(o) (o?.testDrives ?? 0) > 0)
  if (offer != null) {
    let armyId = curArmy.get()
    requestProfileDataJwtByOffer(offer.guid, function(_jwt, data) {
      let offerGuid = data?[armyId].offerGuid
      if (offerGuid != null) {
        debug_apply_test_drive_in_battle(offerGuid)
      }
    })
  }
}

function setNextBattleData(armyId, jwt, data) {
  dumpArmies(data)
  nextBattleData.set({ armyId, jwt, data })
}

console_register_command(@(armyId)
  requestProfileDataJwtByArmy([armyId], getCampaignOutfit(), @(_jwt, data)
    debugTableData(data, { recursionLevel = 7, printFn = debug }) ?? logSd("Done")
  ), "profileData.debugArmyData")

console_register_command(@(pretty) saveToFile(null, !!pretty),
  "profileData.profileToJson",
  "[pretty] If set to true, then you will get a beautiful json output")

console_register_command(debugApplyBoosterInBattle, "profileData.debugApplyBoosterInBattle")
console_register_command(debugApplyTestDriveInBattle, "profileData.debugApplyTestDriveInBattle")

console_register_command(function(outfitId) {
  let armyId = curArmy.get()
  let cb = @(jwt, data) saveJwtResultToJson(jwt, data, $"army_{armyId}_{outfitId}")
  requestProfileDataJwtByArmy([armyId], outfitId, cb)
}, "meta.dumpGameProfile")

console_register_command(function(armyId, outfitId) {
  let cb = @(data) saveResultToJson(data, $"bots_{armyId}_{outfitId}")
  get_bots_data(armyId, outfitId, cb)
}, "meta.dumpBotsProfile")

return {
  saveJwtResultToJson
  mkJwtArmiesCbNoRetries
  setNextBattleData
}