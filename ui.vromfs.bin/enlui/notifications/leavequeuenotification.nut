import "%ui/control/gui_buttons.nut" as JB
from "%ui/components/msgbox.nut" import showMsgbox, isMsgboxInList, removeMsgboxByUid
from "%ui/quickMatchQueue.nut" import leaveQueue, isInQueue
from "%ui/ui_library.nut" import *

const MSG_UID = "leave_queue_msgbox"

function leaveQueueNotification(watch, setValue = null, askLeave = @() true) {
  setValue = setValue ?? @(v) watch.set(v)
  local last = watch.get()

  function showLeaveMsgBox() {
    if (isMsgboxInList(MSG_UID))
      return
    showMsgbox({
      uid = MSG_UID
      text = loc("msg/cancel_queue_question"),
      buttons = [
        { text = loc("Ok"),
          action = @() leaveQueue()
          isCurrent = true
        }
        { text = loc("Cancel")
          action = @() setValue(last)
          isCancel = true
          customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
        }
      ]
    })
  }

  isInQueue.subscribe(function(val) {
    if (val)
      return
    removeMsgboxByUid(MSG_UID)
    last = watch.get()
  })

  watch.subscribe(function(val) {
    if (val == last)
      return
    if (!isInQueue.get()) {
      last = val
      return
    }
    if (askLeave())
      showLeaveMsgBox()
  })
}

return kwarg(leaveQueueNotification)
