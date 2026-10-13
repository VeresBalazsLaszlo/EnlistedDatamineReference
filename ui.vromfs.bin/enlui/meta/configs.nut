import "%enlSqGlob/userInfo.nut" as userInfo
from "%enlSqGlob/offline_mode.nut" import disableRemoteNetServices
from "%sqstd/json.nut" import saveJson, loadJson
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *
from "eventbus" import eventbus_send, eventbus_subscribe
from "dagor.memtrace" import set_huge_alloc_threshold
from "dagor.time" import get_time_msec

let serverConfigs = nestWatched("serverConfig", {}, true)

const DISABLE_NETWORK_CONFIG = "disable_network_config.json"

if (disableRemoteNetServices) {
  log($"Setting up external config {DISABLE_NETWORK_CONFIG}")
  let prevSize = set_huge_alloc_threshold(66560 << 10)
  serverConfigs.set(loadJson(DISABLE_NETWORK_CONFIG))
  set_huge_alloc_threshold(prevSize)
}

function updateAllConfigs(configs) {
  if (!configs || disableRemoteNetServices)
    return

  let prevSize = set_huge_alloc_threshold(66560 << 10)
  
  let t0 = get_time_msec()
  deduplicate_object(configs)
  let t1 = get_time_msec()
  
  
  log($"Setting up network config, time: {t1-t0} ms")
  serverConfigs.set(freeze(configs))
  set_huge_alloc_threshold(prevSize)
}
serverConfigs.whiteListMutatorClosure(updateAllConfigs)

let getConfigFilename = @(userId) $"enlisted_config_{userId}.json"

function dumpConfig(name = null) {
  let { userId = -1 } = userInfo.get()
  if (userId < 0)
    return

  let path = name ?? getConfigFilename(userId)
  saveJson(path, serverConfigs.get(), { logger = log_for_user })
  console_print($"Current configuration saved to {path}")
}

function loadConfig(name = null) {
  let { userId = -1 } = userInfo.get()
  if (userId < 0)
    return

  let path = name ?? getConfigFilename(userId)
  console_print($"Loading configuration from {path}")
  updateAllConfigs(loadJson(path, { logger = log_for_user }))
}

const EVENT_SAVE_DISABLE_NETWORK_DATA = "meta.saveDisableRemoteNetServices"

console_register_command(@() eventbus_send(EVENT_SAVE_DISABLE_NETWORK_DATA, null), EVENT_SAVE_DISABLE_NETWORK_DATA)
eventbus_subscribe(EVENT_SAVE_DISABLE_NETWORK_DATA, @(_) dumpConfig(DISABLE_NETWORK_CONFIG))

console_register_command(dumpConfig, "meta.dumpConfig")
console_register_command(loadConfig, "meta.loadConfig")

let _allowed_get_types = {"string":"string", "array":"array"}
function mkComputedConfigGet(keyOrPath, def = null) {
  let t = type(keyOrPath)
  assert(t in _allowed_get_types, @() $"'{t}' not allowed type for computedGet, should be string or array as path in table")
  if ( t == "string")
    return Computed(@() serverConfigs.get()?[keyOrPath] ?? def)
  return Computed(function() {
    local res = serverConfigs.get()
    foreach(k in keyOrPath) {
      if (k not in res)
        return def
      res = res[k]
    }
    return res
  })
}

let mkComputedConfigView = @(func) Computed(@() func(serverConfigs.get()))

return {
  serverConfigs
  updateAllConfigs
  EVENT_SAVE_DISABLE_NETWORK_DATA
  mkComputedConfigGet
  mkComputedConfigView
  hasServerConfigs = Computed(@() (serverConfigs.get()?.len() ?? 0) > 0)
}
