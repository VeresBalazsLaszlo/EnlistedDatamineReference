from "eventbus" import eventbus_subscribe
from "app" import get_app_id
from "%ui/ui_library.nut" import *

let { char_request = null } = require("%ui/charClient/charClient.nut")

let submitComplain = kwarg(function(userId, name, sessionId, complainType, user_comment, lang, appId) {
  let request = {
    appid = appId
    complainer_appid = get_app_id()
    offender_appid = appId
    offender_userid = userId
    offender_name = name
    session_id = sessionId.tostring()
    category = complainType
    user_comment
    lang
    details_json = "{\"complainId\":\"{0}\"}".subst(complainType)
  }

  const add_publisher = true
  let token = null

  char_request?(
    "cln_complaint",
    request,
    function(response) {
      log($"[COMPLAIN] on {name} ({userId}), type = {complainType}, in session {sessionId}, message = {user_comment}, lang = {lang}")
      log("[COMPLAIN] result: ", response)
    }, token, add_publisher
  )
})

eventbus_subscribe("penitentiary.complain", @(data) submitComplain(data))
