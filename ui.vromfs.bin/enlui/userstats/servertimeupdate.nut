import "%ui/userstats/serverTime.nut" as time
from "dagor.time" import get_time_msec, format_unixtime
from "dagor.workcycle" import setInterval
from "%ui/ui_library.nut" import *

const TIME_FMT = "%d %b %Y %H:%M:%S GMT"

let gameStartServerTimeMsec = Watched(0)
let lastReceivedServerTime = Watched(0)

let strTime = @(ts) $"{format_unixtime(TIME_FMT, ts)} ({ts})"

let strCurrentTime = @()
  $"serverTime: {strTime(time.get())}, workTime: {get_time_msec() / 1000.0} sec"

function updateTime() {
  if (gameStartServerTimeMsec.get() <= 0)
    return

  let newTime = (gameStartServerTimeMsec.get() + get_time_msec()) / 1000
  
  if (newTime > time.get())
    time.set(newTime)
}

updateTime()
gameStartServerTimeMsec.subscribe(@(_t) updateTime())
setInterval(1.0, updateTime)

function serverTimeUpdate(timestampMsec, requestTimeMsec) {
  if (timestampMsec <= 0)
    return

  let isFirstTimeUpdate = gameStartServerTimeMsec.get() <= 0
  gameStartServerTimeMsec.set(timestampMsec - (3 * get_time_msec() - requestTimeMsec) / 2)
  lastReceivedServerTime.set(timestampMsec / 1000)
  if (isFirstTimeUpdate)
    log(strCurrentTime())
}

console_register_command(@() console_print(strCurrentTime()), "time.print")

return {
  serverTimeUpdate
}