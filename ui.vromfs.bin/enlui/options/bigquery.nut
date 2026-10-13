import "%enlSqGlob/userInfo.nut" as userInfo
from "json" import object_to_json_string
from "onlineStorage" import add_bigquery_record, send_to_server
from "%ui/options/onlineSettings.nut" import startSendToSrvTimer, sendToServer
from "%ui/ui_library.nut" import *

let isInstantSendToServer = mkWatched(persist, "isInstantSend", false)
let alreadySend = mkWatched(persist, "alreadySend", {})

let sendRecordToServer = @() isInstantSendToServer.get() ? send_to_server() : startSendToSrvTimer()

userInfo.subscribe(function(uInfo) {
  if (uInfo == null)
    alreadySend.mutate(@(v) v.clear())
})

let wrapToString = @(val) typeof val == "string" ? val : object_to_json_string(val, false)

function sendEvent(event, params = null) {
  add_bigquery_record(event, wrapToString(params ?? ""))
  sendRecordToServer()
}

console_register_command(
  function() {
    sendToServer()
    isInstantSendToServer.set(!isInstantSendToServer.get())
    log("isInstantSendToServer = ", isInstantSendToServer.get())
  },
  "bigQuery.instantSend")

return {
  bqSendEvent = sendEvent
}
