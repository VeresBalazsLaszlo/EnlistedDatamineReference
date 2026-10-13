from "%ui/debriefing/debriefingState.nut" import debriefingData
from "%sqstd/json.nut" import loadJson, saveJson, object_to_json_string
from "%ui/ui_library.nut" import *

let dbgData = Watched(null)
let dbgShow = Watched(false)
let dbgShowAnim = Watched(null)
dbgShow.subscribe(function(v) {
  if (!v)
    dbgData.set(null)
})

function loadPostProcess(debrData) {
  if (typeof debrData?.players != "table")
    return

  let players = {}
  foreach (id, player in debrData.players)
    players[id.tointeger()] <- player
  debrData.players = players
}
const defSavePath = "debriefing_enlisted.json"
let saveDebriefing = @(path = defSavePath)
  saveJson(path, debriefingData.get(), {logger = log_for_user})

function loadDebriefing(path = defSavePath) {
  let data = loadJson(path, { logger = log_for_user })
  if (data == null)
    return false

  loadPostProcess(data)
  data.isDebug <- true
  dbgData.set(data)
  dbgShow.set(true)
  return true
}

function mkSessionPath(sessionId, path = defSavePath) {
  let parts = path.split("/")
  local filename = parts.pop()
  let idx = filename.indexof(".")
  if (idx == null)
    return $"{path}_{sessionId}"
  path = "/".join(parts)
  filename = "{0}_{1}{2}".subst(filename.slice(0, idx), sessionId, filename.slice(idx))
  return path == "" ? filename : $"{path}/{filename}"
}
let saveDebriefingBySession = @()
  saveDebriefing(mkSessionPath(debriefingData.get()?.sessionId ?? "0"))

console_register_command(@() saveDebriefing(), "ui.debriefing_save")
console_register_command(@() loadDebriefing(), "ui.debriefing_load")
console_register_command(@() saveDebriefingBySession(), "ui.debriefing_save_by_session")
console_register_command(@(sessionId) loadDebriefing(mkSessionPath(sessionId)),
  "ui.debriefing_load_by_session")
console_register_command(@()
  loadDebriefing("../prog/enlist/debriefing/samples/debriefing_sample.json"),
  "ui.debriefing_sample")
console_register_command(@(v) dbgShowAnim.set(v), "ui.debriefing_set_show_anim")

function saveDebriefingToLog(dData) {
  if (dData?.isDebug)
    return
  let { sessionId = "0" } = dData
  let jsonstr = object_to_json_string(dData, true)
  log($"Debriefing for session {sessionId } json:\n======\n{jsonstr}======")
}

function saveDebriefingToFile(dData, path) {
  if (dData?.isDebug)
    return
  let { sessionId = "0" } = dData
  let sessionPath = mkSessionPath(sessionId, path)
  saveDebriefing(sessionPath)
  log($"Debriefing for session {sessionId } saved as {sessionPath}")
}

return {
  dbgData
  dbgShow
  dbgShowAnim
  saveDebriefingToFile
  saveDebriefingToLog
}