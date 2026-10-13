from "eventbus" import eventbus_subscribe
from "%ui/options/onlineSettings.nut" import save, sendToServer

eventbus_subscribe("app.shutdown", function(_) {
    save()
    sendToServer(true)
})
