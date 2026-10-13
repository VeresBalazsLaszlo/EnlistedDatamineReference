import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/sqevents.nut" import mkCmdChatMessage
from "%ui/ui_library.nut" import *

function sendChatMsg(params) { 
  let evt = mkCmdChatMessage(params)
  ecs.client_msg_sink(evt)
}

function sendQuickChatSoundMsg(text, qmsg = null, sound = null) {
  sendChatMsg({mode = "qteam", text = text, qmsg = qmsg, sound = sound})
}

function sendItemHint(item_name, item_eid, item_count, item_owner_nickname) {
  sendChatMsg({mode="qteam", text= "squad/item_hint", qmsg={item=item_name, count = item_count, nickname = item_owner_nickname}, eid = item_eid})
}

return {
  sendQuickChatSoundMsg
  sendItemHint = sendItemHint
}