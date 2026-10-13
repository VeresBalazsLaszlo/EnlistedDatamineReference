import "regexp2" as regexp2
from "%enlSqGlob/game_mods_constant.nut" import MOD_DOMAIN_NAME, MOD_BY_VERSION_URL
from "%enlSqGlob/modsDownloadManager.nut" import downloadMod, removeMod, loadModList, getModManifest
from "statsd" import send_counter
from "%ui/featureFlags.nut" import showModsInCustomRoomCreateWnd
from "settings" import get_setting_by_blk_path
from "%dngscripts/platform.nut" import is_sony
from "%ui/ui_library.nut" import *

let modPath = mkWatched(persist, "modPath", "")
let isFullSonyClient = persist("isFullSonyClient", @() Watched(!is_sony))
let receivedModInfos = Watched({})
let modDownloadShowProgress = Watched(false)
let modDownloadMessage = Watched("")
let hasBeenUpdated = Watched(false)

let isModAvailable = Computed(@()(get_setting_by_blk_path("isModAvailable") ?? true)
  && showModsInCustomRoomCreateWnd.get()
  && isFullSonyClient.get())

let availDomains = "({0})".subst("|".join([
  "enlisted-sandbox.gaijin.ops"
  "sandbox.enlisted.net"
  MOD_DOMAIN_NAME
].map(@(u) u.replace(".", @"\."))))
let reUrlPath = regexp2(@"^https?:\/\/{0}\/post\/\w{16}\/manifest\/.*\/$".subst(availDomains))

let fileDownloadQueue = Watched({})

fileDownloadQueue.subscribe(function(v) {
  if (modDownloadShowProgress.get() && v.len() == 0) {
    modDownloadMessage.set(loc("mods/downloadCompleted"))
    modDownloadShowProgress.set(false)
  }
})

function updateModList() {
  receivedModInfos.set(loadModList())
  let keys = receivedModInfos.get().keys()
  if (keys.len() != 0) {
    modPath.set(keys[keys.len() - 1])
  }
}

hasBeenUpdated.subscribe(@(v) v ? updateModList() : null)

function requestModManifest(modId, cbOnSuccess = null, cbOnFailed = null, tags = ["client", "shared"]) {
  if (modId == "" || modId == null)
    return

  if (!reUrlPath.match(modId)) {
    modDownloadMessage.set("mods/InvalidUrlFormat")
    return
  }

  modDownloadShowProgress.set(true)
  modDownloadMessage.set("")
  downloadMod(modId, function(manifest, contents) {
    modDownloadShowProgress.set(false)
    updateModList()
    if (cbOnSuccess) {
      cbOnSuccess(manifest, contents)
    }
  }, function(error_msg, http_code) {
    modDownloadMessage.set(error_msg)
    send_counter("event_file_mod_receive_error", 1, { http_code })
    if (cbOnFailed) {
      cbOnFailed()
    }
  }, tags)
}

function fetchLocalModById(mod_id, cbOnSuccess = null, cbOnFailed = null) {
  let manifest = getModManifest(mod_id)
  if (manifest == null) {
    modDownloadMessage.set("mods/FailedLoadManifest")
    return
  }
  let url = MOD_BY_VERSION_URL.subst(mod_id, manifest.version)
  requestModManifest(url, cbOnSuccess, cbOnFailed, ["client", "shared", "server"])
}

function deleteMod(mod_id){
  removeMod(mod_id)
  receivedModInfos.mutate(@(receivedMods) receivedMods.$rawdelete(mod_id))
}

return {
  hasBeenUpdated
  modPath
  receivedModInfos
  requestModManifest
  modDownloadShowProgress
  modDownloadMessage
  deleteMod
  isModAvailable
  fetchLocalModById
  isFullSonyClient
}