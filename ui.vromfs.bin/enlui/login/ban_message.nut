from "%sqstd/math.nut" import ceil
from "%ui/style/fontsStyle.nut" import fontBody
from "net" import get_sync_time
from "%ui/style/designConst.nut" import largePadding, sidePadding, defTxtColor
from "%ui/components/msgbox.nut" import removeMsgboxByUid
from "%ui/helpers/time.nut" import secondsToHoursLocFull
from "%ui/login/login_cb.nut" import showStageErrorMsgBox
from "%ui/ui_library.nut" import *

const ONE_YEAR_SECONDS = 365 * 24 * 60 * 60
const BAN_MESSAGE_WINDOW_UID = "banMsg"

let mkText = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = defTxtColor
}.__update(fontBody)

let mkTextArea = @(text) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  maxWidth = sw(80)
  text
  color = defTxtColor
}.__update(fontBody)

function closeWindow() {
  removeMsgboxByUid(BAN_MESSAGE_WINDOW_UID)
}

function mkTextWithCounter(locId, duration, timeLeft) {
  let endTime = (timeLeft ?? 0) + get_sync_time()
  let countdown = Watched(timeLeft)

  function updateTimer() {
    let v = max(0, ceil(endTime - get_sync_time()))
    countdown.set(v)
    if (v == 0) {
      gui_scene.clearTimer(callee())
      closeWindow()
    }
  }

  if (timeLeft) {
    updateTimer()
    gui_scene.setInterval(1.0, updateTimer)
  }

  return function() {
    let left = countdown.get()
    return left == 0 ? null
      : {
          watch = countdown
          rendObj = ROBJ_TEXT
          text = loc(locId, { time = duration, timeLeft = secondsToHoursLocFull(left) })
          onDetach = function() {
            gui_scene.clearTimer(updateTimer)
          }
        }.__update(fontBody)
  }
}

function showBanMessage(detailsData, state) {
  let { message = "", duration = 0, category = null, left = null, details = null } = detailsData

  let durationSeconds = duration.tointeger() / 1000
  let isPermanent = durationSeconds > ONE_YEAR_SECONDS
  let time = secondsToHoursLocFull(durationSeconds)
  let timeLeft = (left == null || isPermanent) ? null
    : ceil(left.tointeger() / 1000.0)
  let reason = loc($"ban/reason/{category}", "")

  let info = @(_) {
    flow = FLOW_VERTICAL
    padding = [sidePadding, 0]
    gap = largePadding
    halign = ALIGN_CENTER
    children = [
      timeLeft ? mkTextWithCounter("ban/timed", time, timeLeft) : mkText(loc("ban/permanent"))
      details == "AUTOKICK" ? mkTextArea(loc("ban/autokick")) : null
      reason != "" ? mkTextArea(loc("ban/reason", { reason })) : null
      message != "" ? mkTextArea(loc("ban/comment", { message })) : null
    ]
  }

  showStageErrorMsgBox(loc("error/BANNED"), state, info, BAN_MESSAGE_WINDOW_UID)
}


return showBanMessage
