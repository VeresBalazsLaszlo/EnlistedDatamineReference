import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/steam/steam_events_state.nut" import steamEvent, markEventSeen, onClose
from "%ui/ui_library.nut" import *

require("%ui/steam/steam_awards_wnd.nut")
let eventsConfig = require("%ui/steam/steam_events_config.nut")


const steamEventWndUID = "steam_event_wnd"


function closeWindow() {
  removeModalWindow(steamEventWndUID)
  onClose()
}

function showEventWindow(event) {
  let config = eventsConfig?[event]
  if (!config) {
    onClose()
    return
  }

  let { mkWindow } = config
  addModalWindow({
    key = steamEventWndUID
    size = FLEX
    onClick = @() null
    children = mkWindow(event, closeWindow)
  })
  markEventSeen(event, serverTime.get())
  sendBigQueryUIEvent($"steam_{event}_popup")
}

steamEvent.subscribe(function(v) {
  if (v)
    showEventWindow(v)
})

console_register_command(showEventWindow, "debug.steam_events_show")
