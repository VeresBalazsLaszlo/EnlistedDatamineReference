from "%ui/notifications/serviceNotificationsList.nut" import serviceNotificationsList
from "%ui/hud/state/chat.nut" import pushSystemMsg
from "%sqstd/frp.nut" import subscribeAndInit
from "%ui/ui_library.nut" import *

let shown = persist("shown", @() {})

let pushNewNotifications = @(notifications)
  notifications.each(function(notify) {
    let { message, uid } = notify
    if (uid in shown)
      return
    shown[uid] <- true
    pushSystemMsg(message)
  })

subscribeAndInit(pushNewNotifications, serviceNotificationsList)