import "datacache" as datacache
from "eventbus" import eventbus_subscribe, eventbus_subscribe_onehit
from "%ui/state/appState.nut" import isInBattleState
from "app" import load_replay_meta_info
from "%ui/replay/replayDownloadState.nut" import REPLAY_DOWNLOAD_PROGRESS, REPLAY_DOWNLOAD_FAILED, REPLAY_DOWNLOAD_SUCCESS, replayDownload
from "%ui/replay/replaySettings.nut" import records, isReplayProtocolValid, initReplayStorage

let logRP = require("%enlSqGlob/library_logs.nut").with_prefix("[Replay] ")

let DATACACHE_ERROR_TO_TEXT = {
  [datacache.ERR_MEMORY_LIMIT] = "replay/memoryLimit",
  [datacache.ERR_ABORTED] = "replay/userAborted",
}

eventbus_subscribe("replay.download", function(params) {
  if (replayDownload.get().downloadRequestId != "") 
    return

  let { url = null } = params
  if (url == null) {
    replayDownload.mutate(function (v) {
      v.state = REPLAY_DOWNLOAD_FAILED
      v.stateText = "replay/EmptyUrl"
      v.contentLen = -1
    })
    return
  }

  eventbus_subscribe_onehit($"datacache.headers.{url}", function(result) {
    replayDownload.mutate(function (v) {
      v.contentLen = (result?["Content-Length"] ?? -1).tointeger()
    })
  })

  eventbus_subscribe_onehit($"datacache.{url}", function(result) {
    logRP($"Replay '{url}' download result: ", result)
    if (result?.error) {
      replayDownload.mutate(function (v) {
        v.state = REPLAY_DOWNLOAD_FAILED
        v.stateText = DATACACHE_ERROR_TO_TEXT?[result?.error_code] ?? "replay/HttpError"
        v.downloadRequestId = ""
        v.contentLen = -1
      })
      return
    }

    replayDownload.set({
      state = REPLAY_DOWNLOAD_SUCCESS
      stateText = isInBattleState.get() ? "replay/replayStartHint" : "replay/downloadSuccess"
      filename = result.path
      downloadRequestId = ""
      contentLen = -1
    })

    let replayInfo = load_replay_meta_info(result.path)
    if (!replayInfo)
      replayDownload.mutate(function (v) {
        v.state = REPLAY_DOWNLOAD_FAILED
        v.stateText = "replay/InvalidMeta"
        v.downloadRequestId = ""
        v.contentLen = -1
      })
    else if (records.get().findindex(@(v) v.id == result.path) == -1)
      records.mutate(@(v) v.append({
        title = result.path.split("/").top()
        id = result.path
        isValid = isReplayProtocolValid(replayInfo)
        recordInfo = replayInfo
      }))
  })
  replayDownload.set({
    state = REPLAY_DOWNLOAD_PROGRESS
    stateText = ""
    filename = ""
    downloadRequestId = "records"
    contentLen = -1
  })
  initReplayStorage()
  datacache.request_entry("records", url)
})
