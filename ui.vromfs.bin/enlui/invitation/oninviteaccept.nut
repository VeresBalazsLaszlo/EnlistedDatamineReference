from "%ui/components/msgbox.nut" import showMsgbox
from "eventbus" import eventbus_send, eventbus_subscribe
from "%ui/ui_library.nut" import *

eventbus_subscribe("ipc.onInviteAccepted",  @(_) showMsgbox({
  text = loc("xbox/onInviteAccepted") 
  buttons = [
    { text = loc("Yes"),
      action = @() eventbus_send("ipc.onBattleExitAccept", null),
      isCurrent = true
    },
    { text = loc("No"), isCurrent = false, isCancel = true }
  ]
}))

return
