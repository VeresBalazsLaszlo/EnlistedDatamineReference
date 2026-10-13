from "%dngscripts/globalState.nut" import nestWatched
from "%dngscripts/sound_system.nut" import sound_play

let serviceNotificationsList = nestWatched("serviceNotificationsList", [])
let serviceNotificationsListUpdate = @(v) serviceNotificationsList.set(v)
serviceNotificationsList.subscribe(@(_v) sound_play("ui/enlist/notification"))

return {serviceNotificationsList, serviceNotificationsListUpdate}
