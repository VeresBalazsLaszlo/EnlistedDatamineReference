import "%ui/charClient/charClientEvent.nut" as CharClientEvent
import "profile_server" as profile_server
from "%ui/state/clientState.nut" import appId
from "%ui/ui_library.nut" import *


let logPSC = with_prefix("[profileServerClient] ")
const COMMON_HANDLER = "profile_server_request"

let handlers = {}
let client = CharClientEvent({
  name = "profile_server"
  sepServiceName = "profile"
  client = profile_server
  handlers
  isSingleHandler = true
})

function setHandler(func) {
  handlers[COMMON_HANDLER] <- func
}

function generateNextMessageId() {
  return client.generate_next_message_id()
}

function doRequest(action, params, args, messageId, token) {
  args.action <- $"das.{action}"
  args.messageId <- messageId
  args.appId <- appId
  args.profileId <- args?.headers?.userid
  args.transactId <- args?.headers?.transactid
  args.token <- token
  args.$rawdelete("headers") 

  logPSC($"Sending request {messageId}, method: {args.action}")

  client.requestEx(args, params)
}

return {
  generateNextMessageId
  doRequest
  setHandler
}
