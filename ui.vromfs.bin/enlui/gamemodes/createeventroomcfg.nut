from "eventbus" import eventbus_subscribe
from "matching.api" import matching_listen_notify
from "%ui/matchingClient.nut" import matchingCall
from "string" import endswith
from "%ui/httpPkg.nut" import getPlatformId
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/gameModes/sandbox/customMissionState.nut" import isFullSonyClient
from "%ui/ui_library.nut" import *

let allRoomCfg = nestWatched("allRoomCfg", [])
let isRoomCfgActual = nestWatched("isRoomCfgActual", false)
let isRoomCfgLoading = Watched(false)

const MODDED_CONFIG_POSTFIX = "_MODDED"

let createEventRoomCfg = Computed(function() {
  let cfg = {}
  foreach (tpl in allRoomCfg.get()) {
    let id = tpl?["template-id"]
    if (id != null && ("rules" in tpl))
      cfg[id] <- tpl
  }
  return cfg
})

let isModsAvailable = Computed(function(){
  if (!isFullSonyClient.get())
    return false

  let roomCfg = createEventRoomCfg.get()
  if (roomCfg.len() <= 0)
    return true

  let modsSettings = roomCfg.filter(@(settings)
    endswith(settings?["template-id"], MODDED_CONFIG_POSTFIX))
  let restrictedPlatforms = {}
  modsSettings.each(@(settings)
    restrictedPlatforms.__update(settings.rules?["public/restrictPlatforms"] ?? {}))
  return getPlatformId() not in restrictedPlatforms
})

let allModes = Computed(@()
  createEventRoomCfg.get().keys()
  .filter(@(key) createEventRoomCfg.get()[key]?.defaults.public.mode == key)
  .sort(@(a, b) b <=> a))

































































































































































function getValuesFromRule(rule) {
  local values = []
  local isMultival = false
  if ("oneOf" in rule)
    values = rule.oneOf
  else if ("anyOf" in rule) {
    values = rule.anyOf
    isMultival = true
  }
  else if ("range" in rule) {
    if ((rule.range?.len() ?? 0) >= 2)
      for(local i = rule.range[0]; i <= rule.range[1]; i++)
        values.append(i)
  }
  else if (rule?.type == "bool")
    values = [true, false]
  return { values, isMultival }
}

function mSubscribe(id, cb) {
  matching_listen_notify(id)
  eventbus_subscribe(id, cb)
}

function onRoomCfgResult(resp) {
  isRoomCfgLoading.set(false)
  if (resp.error != 0)
    return
  allRoomCfg.set(resp?.result ?? [])
  isRoomCfgActual.set(true)
}

function actualizeRoomCfg() {
  if (isRoomCfgActual.get() || isRoomCfgLoading.get())
    return

  isRoomCfgLoading.set(true)
  matchingCall("mrooms.fetch_lobby_templates", onRoomCfgResult)
}
mSubscribe("mrooms.lobby_templates_changed", @(_notify) isRoomCfgActual.set(false))

return {
  createEventRoomCfg
  isRoomCfgActual
  actualizeRoomCfg
  allModes
  getValuesFromRule
  isModsAvailable
}