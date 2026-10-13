from "%ui/options/bigQuery.nut" import bqSendEvent
from "%ui/ui_library.nut" import *

let debugBigQuery = mkWatched(persist, "debugBigQuery", false)

let internalSend = @(event, params)
  debugBigQuery.get() ? console_print($"bqSendEvent {event}", params) : bqSendEvent(event, params)

function sendBigQueryUIEvent(eventType, srcWindow = null, srcComponent = null) {
  let params = { }
  if (srcWindow != null)
    params.source_window <- srcWindow
  if (srcComponent != null)
    params.source_component  <- srcComponent
  internalSend(eventType, params)
}

console_register_command(function() {
  let isDebug = !debugBigQuery.get()
  console_print($"bqSendEvent debugging is {isDebug ? "ON" : "OFF"}")
  debugBigQuery.set(isDebug)
}, "debug.bqSendEvent_toggle")

return {
  sendBigQueryUIEvent
}