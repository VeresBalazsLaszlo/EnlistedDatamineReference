import "%ui/hud/state/isAnyMenuVisible.nut" as isAnyMenuVisible
import "%ui/notifications/mkServiceNotification.nut" as mkServiceNotification
from "dagor.time" import get_time_msec
from "%ui/notifications/serviceNotificationsList.nut" import serviceNotificationsList
from "%ui/ui_library.nut" import *

const SHOW_TIME_MSEC = 30000

let showInfo = mkWatched(persist, "showInfo", {})
let isNotificationsAttached = Watched(false)
let isNotificationsVisible = Computed(@() isNotificationsAttached.get() && !isAnyMenuVisible.get())

let getUid = @(notify) $"{notify.message}_{notify.till_timestamp}"
let messagesToShow = Computed(@() serviceNotificationsList.get()
  .filter(function(notify) {
    let { leftTime = SHOW_TIME_MSEC } = showInfo.get()?[getUid(notify)]
    return leftTime > 0
  }))

function addInfoOnce(showInfoV, notify) {
  let uid = getUid(notify)
  if (uid not in showInfoV)
    showInfoV[uid] <- { leftTime = SHOW_TIME_MSEC, hideTime = null }
  return showInfoV[uid]
}

function updateLeftTime() {
  let list = serviceNotificationsList.get()
  if (list.len() == 0)
    return
  let curTimeMsec = get_time_msec()
  let showInfoV = clone showInfo.get()
  if (!isNotificationsVisible.get())
    foreach (notify in list) {
      let info = addInfoOnce(showInfoV, notify)
      let { hideTime } = info
      if (hideTime != null)
        info.__update({
          hideTime = null
          leftTime = max(0, hideTime - curTimeMsec)
        })
    }
  else {
    local nextTimeMsec = null
    foreach (notify in list) {
      let info = addInfoOnce(showInfoV, notify)
      let { leftTime, hideTime } = info
      if (leftTime <= 0)
        continue
      if (hideTime == null)
        info.hideTime = curTimeMsec + leftTime
      else if (hideTime <= curTimeMsec)
        info.__update({ hideTime = null, leftTime = 0 })
      if (info.hideTime != null)
        nextTimeMsec = nextTimeMsec == null ? info.hideTime : min(nextTimeMsec, info.hideTime)
    }
    if (nextTimeMsec != null)
      gui_scene.resetTimeout(0.001 * (nextTimeMsec - curTimeMsec), updateLeftTime)
  }
  showInfo.set(showInfoV)
}
serviceNotificationsList.subscribe(@(_) updateLeftTime())
isNotificationsVisible.subscribe(@(_) updateLeftTime())

let serviceMessages = @() {
  watch = messagesToShow
  size = FLEX_H
  children = mkServiceNotification(messagesToShow.get(), {
    onAttach = @() isNotificationsAttached.set(true)
    onDetach = @() isNotificationsAttached.set(false)
    isInBattle = true
  })
}

return {
  hasServiceMessages = Computed(@() messagesToShow.get().len() > 0)
  serviceMessages
}