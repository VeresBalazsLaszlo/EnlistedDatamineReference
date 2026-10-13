import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/components/colorize.nut" as colorize
from "%sqstd/string.nut" import hexStringToInt
from "%ui/style/designConst.nut" import warningColor
from "%ui/notifications/matchingNotifications.nut" import subscribe
from "%ui/notifications/serviceNotificationsList.nut" import serviceNotificationsList, serviceNotificationsListUpdate
from "%ui/ui_library.nut" import *
from "types" import String

const DEF_LIFE_TIME = 300

function filterOldAndStartTimer() {
  let curTime = serverTime.get()
  let newList = serviceNotificationsList.get().filter(@(n) n.till_timestamp > curTime)
  if (newList.len() != serviceNotificationsList.get().len())
    serviceNotificationsListUpdate(newList)

  let nextNotifyTime = newList.reduce(@(res, n) res <= 0 ? n.till_timestamp : min(res, n.till_timestamp), 0)
  if (nextNotifyTime > 0)
    gui_scene.resetTimeout(nextNotifyTime - curTime, filterOldAndStartTimer)
}
filterOldAndStartTimer()

subscribe("web-service", function(ev) {
  if (ev?.func != "show_chat_message")
    return
  local { message = null, till_timestamp = 0, color = 0 } = ev?.params
  if (message == null || (till_timestamp > 0 && till_timestamp <= serverTime.get()))
    return

  if (color instanceof String)
    color = hexStringToInt(color)
  message = colorize(color == 0 ? warningColor : color | 0xFF000000, message)

  if (till_timestamp <= 0)
    till_timestamp = serverTime.get() + DEF_LIFE_TIME
  let snl = serviceNotificationsList.get()
  snl.append({ message, till_timestamp, uid = $"{message}_{till_timestamp}"})
  serviceNotificationsListUpdate(snl)
  filterOldAndStartTimer()
})