import "%ui/control/gui_buttons.nut" as JB
import "%ui/userstats/serverTime.nut" as serverTime
import "%enlSqGlob/userInfo.nut" as userInfo
import "%ui/unlocks/isNewbie.nut" as isNewbie
import "%ui/currency/premiumWnd.nut" as premiumWnd
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/helpers/time.nut" import TIME_DAY_IN_SECONDS, secondsToHoursLoc, TIME_HOUR_IN_SECONDS
from "%ui/currency/premium.nut" import hasPremium, premiumEndTime, premiumActiveTime
from "%ui/options/onlineSettings.nut" import onlineSettingUpdated
from "%ui/components/msgbox.nut" import showMsgbox, showMessageWithContent
from "%ui/bigQueryEvents.nut" import sendBigQueryUIEvent
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/meta/servProfile.nut" import premium
from "%ui/components/wndManager.nut" import registerWnd, Wnd
from "%ui/components/wndPermissionFlags.nut" import canShowWindows, autoClose
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *

let EXPIRING_TIME = TIME_DAY_IN_SECONDS * 15
let MAX_WAIT_TIME = TIME_DAY_IN_SECONDS * 7

let nextTimeToWarn = mkOnlineSaveData("nextTimeToWarnPremium", @() 0)
let setNextTimeToWarn = nextTimeToWarn.setValue
let timeToWarnStorage = nextTimeToWarn.watch
let needToWarn = nestWatched("needToWarnPremium", false)

let dataReady = Computed(@() !isNewbie.get() && needToWarn.get()
  && userInfo.get() != null
  && onlineSettingUpdated.get())
let needToShowWarn = registerWnd({
  dataWatch = dataReady
  showWatch = canShowWindows
  closeWatch = autoClose
  name = Wnd.PREM_EXPIRE
})
let needToCheckTime = keepref(Computed(@() premium.get().len() > 0 && onlineSettingUpdated.get()))


function showExpiringWarn() {
  let timeText = Computed(function(){
    let timeTillExpiration = premiumActiveTime.get()
    if (timeTillExpiration <= 0)
      return loc("premium/premiumSuggest")
    return loc("premium/premiumSuggestSoon", { time = secondsToHoursLoc(timeTillExpiration) })
  })
  showMessageWithContent({
    content = @() {
      watch = timeText
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = timeText.get()
    }.__update(fontBody)
    buttons = [
      {
        text = loc("Ok")
        action = function() {
          premiumWnd()
          sendBigQueryUIEvent("open_premium_window", "premium_expiring")
        }
        customStyle = { hotkeys = [["^J:Y"]] }
      }
      {
        text = loc("Cancel")
        isCurrent = true
        isCancel = true
        customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
      }
    ]
  })
}


function showExpiredWarn() {
  showMsgbox({
    text = loc("premium/premiumSuggest")
    buttons = [
      {
        text = loc("Ok")
        action = function() {
          premiumWnd()
          sendBigQueryUIEvent("open_premium_window", "premium_expired")
        }
        customStyle = { hotkeys = [["^J:Y"]] }
      }
      {
        text = loc("Cancel")
        isCurrent = true
        isCancel = true
        customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
      }
    ]
  })
}


local setNextWarnTime

function updateTime(delay) {
  gui_scene.resetTimeout(delay, setNextWarnTime)
  setNextTimeToWarn(serverTime.get() + delay)
}

setNextWarnTime = function() {
  let nextWarn = timeToWarnStorage.get()
  let curTime = serverTime.get()
  if (hasPremium.get()) {
    let activeTime = premiumActiveTime.get()
    if (activeTime < TIME_DAY_IN_SECONDS) {
      let lastHourPremium = activeTime - TIME_HOUR_IN_SECONDS
      if (lastHourPremium < 0)
        needToWarn.set(true)
      else
        updateTime(lastHourPremium)
      return
    }
    if (activeTime <= EXPIRING_TIME && curTime - nextWarn >= TIME_DAY_IN_SECONDS) {
      
      updateTime(TIME_DAY_IN_SECONDS)
      needToWarn.set(true)
    }
    return
  }
  if (curTime < nextWarn)
    return
  let timeWithoutPremium = curTime - premiumEndTime.get()
  if (timeWithoutPremium < TIME_DAY_IN_SECONDS) {
    
    updateTime(TIME_DAY_IN_SECONDS)
    needToWarn.set(true)
    return
  }
  if (timeWithoutPremium > TIME_DAY_IN_SECONDS) {
    let time = timeWithoutPremium <= MAX_WAIT_TIME ? TIME_DAY_IN_SECONDS : MAX_WAIT_TIME
    updateTime(time)
    needToWarn.set(true)
  }
}

function showWarning() {
  if (premiumActiveTime.get() > 0)
    showExpiringWarn()
  else
    showExpiredWarn()
  defer(@() needToWarn.set(false))
}

needToCheckTime.subscribe(@(v) v ? setNextWarnTime() : null)
hasPremium.subscribe(@(_v) setNextWarnTime())
needToShowWarn.subscribe(@(v) v ? showWarning() : null)

console_register_command(function(time) {
  setNextTimeToWarn(serverTime.get() + time)
  setNextWarnTime()
}, "meta.addPremiumWarningTime")
