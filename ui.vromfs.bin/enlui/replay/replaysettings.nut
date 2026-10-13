import "%ui/control/gui_buttons.nut" as JB
import "datacache" as datacache
from "%enlSqGlob/modsDownloadManager.nut" import getModStartInfo
from "%enlSqGlob/game_mods_constant.nut" import MOD_BY_VERSION_URL
from "%enlSqGlob/replay_state.nut" import currentReplayInfo, currentReplayInfoUpdate
from "dagor.fs" import scan_folder, file_exists
from "%sqstd/underscore.nut" import flatten
from "%ui/featureFlags.nut" import showReplayTabInProfile
from "app" import load_replay_meta_info, replay_play
from "net" import NET_PROTO_VERSION, get_replay_proto_version
from "settings" import get_setting_by_blk_path
from "%ui/components/msgbox.nut" import showMsgbox
from "system" import remove
from "%ui/gameModes/sandbox/customMissionState.nut" import requestModManifest
from "%ui/ui_library.nut" import *


let allowProtoMismatch = get_setting_by_blk_path("replay/allowProtoMismatch") ?? false
let storageLimitMB = get_setting_by_blk_path("replay/storageLimitMB") ?? 300

let replayStorageInited = Watched(false)
function initReplayStorage() {
  if (replayStorageInited.get())
    return

  datacache.init_cache("records",
  {
    mountPath = "records"
    maxSize = storageLimitMB << 20
    manualEviction = true
    timeoutSec = -1
  })
  replayStorageInited.set(true)
}

const defaultRecordFolder = "replays/"
let recordsFolders = [
  defaultRecordFolder,
]

let currentRecord = Watched(null)
let records = Watched([])
let isReplayTabHidden = Computed(@() !showReplayTabInProfile.get())


let isReplayProtocolValid = @(meta) meta?.replay_version == get_replay_proto_version(NET_PROTO_VERSION)

function getFiles() {
  initReplayStorage()
  let recordFiles = datacache.get_all_entries("records").map(function(v) {
    let fname = v.path.split("/").top()
    let recordInfo = load_replay_meta_info(v.path ?? "")
    let isValid = isReplayProtocolValid(recordInfo)
    return { title = fname, id = v.path, key = v.key, isValid, recordInfo }
  })

  recordFiles.extend(recordsFolders.map(@(root) scan_folder({
      root
      vromfs = false
      realfs = true
      recursive = true
      files_suffix = "*.erpl"
    }).map(function(v) {
      let fname = v.split("/").top()
      let recordInfo = load_replay_meta_info(v ?? "")
      let isValid = isReplayProtocolValid(recordInfo)
      return { title = fname, id = v, isValid, recordInfo }
    })
  ))

  return flatten(recordFiles)
}


let updateReplays = @() records.set(getFiles())

function deleteReplay(replayPath){
  initReplayStorage()
  let record = records.get().findvalue(@(v) v.id == replayPath)
  if (record == null)
    return
  if (record?.key != null)
    datacache.del_entry("records", record.key)
  else if (file_exists(replayPath))
    remove(replayPath)
  currentRecord.set(null)
  updateReplays()
}

function replay_play_ex(meta, path, start_time, mod_info) {
  
  let mission_name = meta?["mission_name"]
  let synthesizedScene = (mission_name != null) ? $"gamedata/scenes/{mission_name}.blk" : ""
  replay_play(path, start_time, mod_info, synthesizedScene)
}

function replayPlayWithMod(meta, path, start_time) {
  let modId = meta?.modId
  if (modId == null) {
    currentReplayInfoUpdate({
      path
      mod_info = null
      mission_name = meta?["mission_name"]
    })
    replay_play_ex(meta, path, start_time, null)
    return
  }
  requestModManifest(MOD_BY_VERSION_URL.subst(modId, meta?.modVersion ?? 1), function(manifest, contents) {
    currentReplayInfoUpdate({
      path
      mod_info = { modId }.__merge(getModStartInfo(manifest, contents))
      mission_name = meta?["mission_name"]
    })
    replay_play_ex(meta, path, start_time, currentReplayInfo.get()["mod_info"])
  })
}

function replayPlay(path) {
  let buttons = [{
    text = loc("Ok")
    isCancel = true
    customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
  }]
  let replayInfo = load_replay_meta_info(path)
  if (!replayInfo) {
    showMsgbox({
      text = loc("replay/InvalidMeta"),
      buttons
    })
    return
  }

  if (isReplayProtocolValid(replayInfo)) {
    replayPlayWithMod(replayInfo, path, 0)
    return
  }

  if (allowProtoMismatch)
    buttons.append({
      text = loc("replay/playAnyway")
      action = @() replayPlayWithMod(replayInfo, path, replayInfo?.first_human_spawn_time ?? 0)
      isCurrent = true
    })

  showMsgbox({
    text = loc("replay/protocolMisMatchDoYouWantStart"),
    buttons
  })
}

return {
  currentRecord
  defaultRecordFolder
  isReplayTabHidden
  replayPlay
  deleteReplay
  records
  updateReplays
  isReplayProtocolValid
  initReplayStorage
}