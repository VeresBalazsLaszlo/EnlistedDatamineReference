from "%ui/matchingClient.nut" import matchingCall
from "matching.api" import matching_listen_notify
from "eventbus" import eventbus_subscribe
from "%ui/ui_library.nut" import *

let handlers = {}

matching_listen_notify("postbox.notify_mail")
eventbus_subscribe("postbox.notify_mail", function(mail_obj) {
  let { subj = "" } = mail_obj.mail
  if (subj not in handlers)
    log($"handler for {subj} not registered")
  else
    handlers[subj](mail_obj)
})

function postboxSubscribe(subj, cb) {
  handlers[subj] <- cb
}

let postboxMarkRead = @(mail_id) matchingCall("postbox.notify_read", null, { mail_id })

let postboxSendMessage = @(user_id, mail)
  matchingCall("postbox.add_mail", null, { user_id, mail })

return {
  postboxMarkRead
  postboxSubscribe
  postboxSendMessage
}
