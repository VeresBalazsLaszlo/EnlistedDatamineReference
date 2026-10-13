from "eventbus" import eventbus_subscribe
from "%ui/ui_library.nut" import *

let speakingPlayers = mkWatched(persist, "speakingPlayers", {})
let order = persist("order", @() { val = 0 })

function onSpeakingStatus(who, is_speaking) {
  if (is_speaking) {
    if (who in speakingPlayers.get())
      return
    speakingPlayers.mutate(@(v) v[who] <- order.val++)
  }
  else {
    if (!(who in speakingPlayers.get()))
      return
    speakingPlayers.mutate(@(v) v.$rawdelete(who))
  }
}

eventbus_subscribe("voice.show_speaking", @(name) onSpeakingStatus(name, true))
eventbus_subscribe("voice.hide_speaking",  @(name) onSpeakingStatus(name, false))
eventbus_subscribe("voice.reset_speaking",  @(_) speakingPlayers.set({}))




return speakingPlayers
