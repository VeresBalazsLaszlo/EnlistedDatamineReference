import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/options/onlineSettings.nut" import settings
from "%ui/helpers/time.nut" import TIME_DAY_IN_SECONDS
from "%ui/ui_library.nut" import *

const DONT_SHOW_TODAY_ID = "dontShowToday"

let dontShowToday = Computed(@() settings.get()?[DONT_SHOW_TODAY_ID] ?? {})

let curDaySeconds = Watched(0)

function recalcDay() {
  let time = serverTime.get()
  let today = (time / TIME_DAY_IN_SECONDS) * TIME_DAY_IN_SECONDS
  curDaySeconds.set(today)
  gui_scene.resetTimeout(today + TIME_DAY_IN_SECONDS - time, recalcDay)
}


serverTime.subscribe(function(t) {
  if (t <= 0)
    return
  serverTime.unsubscribe(callee())
  recalcDay()
})


function setDontShowToday(key, value) {
  let list = clone dontShowToday.get()

  if (value)
    list[key] <- curDaySeconds.get()
  else
    list.$rawdelete(key)

  settings.mutate(@(v) v[DONT_SHOW_TODAY_ID] <- list)
}


let getDontShowToday = @(key) (dontShowToday.get()?[key] ?? 0) == curDaySeconds.get()


function mkDontShowTodayComp(key) {
  return Computed(function(){
    return (dontShowToday.get()?[key] ?? 0) == curDaySeconds.get()
  })
}

console_register_command(@() settings.mutate(@(v) v[DONT_SHOW_TODAY_ID] <- {}), "dontShowAgain.reset")

return {
  setDontShowToday
  getDontShowToday
  mkDontShowTodayComp
}