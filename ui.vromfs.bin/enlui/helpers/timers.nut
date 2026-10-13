from "dagor.time" import get_time_msec
from "net" import get_sync_time
from "math" import ceil
from "%ui/ui_library.nut" import *

const defaultTimeStep = 0.016666
function mkCountdownTimer(endTimeWatch, curTimeFunc = get_sync_time, step = defaultTimeStep, timeProcess = @(v) v) {
  let countdownTimer = Watched(0)
  function updateTimer() {
    let cTime = curTimeFunc()
    countdownTimer.set(cTime)
    if ((endTimeWatch.get() ?? 0) > cTime)
      gui_scene.resetTimeout(step, callee(), endTimeWatch)
  }
  updateTimer()
  endTimeWatch.subscribe(@(_) updateTimer())
  return Computed(function() {
    let leftTime = max((endTimeWatch.get() ?? 0) - countdownTimer.get(), 0)
    return timeProcess(leftTime)
  })
}

function mkUpdateCb(updateDtFunc) {
  local curtime = 0
  local last_time = 0
  function updateCb() {
    curtime = get_time_msec() / 1000.0
    updateDtFunc(curtime - last_time)
    last_time = curtime
  }
  return updateCb
}

let setIntervalForUpdateFunc = @(interval, updateDtFunc, name = null) gui_scene.setInterval(interval, mkUpdateCb(updateDtFunc), name ?? updateDtFunc)

function mkTimerByDuration(duration, interval = defaultTimeStep, onStop = @() null) {
  let endTime = get_sync_time() + duration
  let countdown = Watched(0)
  function update() {
    let left = max(0, endTime - get_sync_time())
    countdown.set(left)
    if (left == 0) {
      gui_scene.clearTimer(callee())
      onStop()
    }
  }
  function stop() {
    gui_scene.clearTimer(update)
  }
  countdown.whiteListMutatorClosure(update)
  update()
  gui_scene.setInterval(interval, update)

  return { countDownTimer = countdown, stopCountDownTimer = stop }
}

return {
  mkCountdownTimer
  mkCountdownTimerPerSec = @(endTimeWatch) mkCountdownTimer(endTimeWatch, get_sync_time, 1.0, @(v) ceil(v).tointeger())
  setIntervalForUpdateFunc
  mkTimerByDuration
}
