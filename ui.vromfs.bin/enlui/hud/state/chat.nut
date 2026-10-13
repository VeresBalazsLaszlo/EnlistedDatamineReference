import "%enlSqGlob/userInfo.nut" as userInfo
import "%ui/helpers/obsceneFilter.nut" as obsceneFilter
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/sqevents.nut" import EventSqChatMessage, mkCmdChatMessage
from "%ui/helpers/timers.nut" import setIntervalForUpdateFunc
from "matching.errors" import INVALID_USER_ID
from "team" import TEAM_UNASSIGNED
from "%ui/contacts/contactsWatchLists.nut" import blockedUids
from "%ui/helpers/platformUtils.nut" import canInterractCrossPlatform
from "%ui/state/dirty_words_filter_state.nut" import dirtyWordsFilterState
from "%ui/state/appState.nut" import isInBattleState
from "%ui/ui_library.nut" import *
from "types" import Table

let dirtyWordsFilter = require("%ui/chat/dirty_words/dirty_words_filter.nut")

let lines = mkWatched(persist, "lines", [])
let totalLines = mkWatched(persist, "totalLines", 0)
let logState = mkWatched(persist, "logState", [])
let outMessage = mkWatched(persist, "outMessage", "")
let sendMode = mkWatched(persist, "sendMode", "team")

isInBattleState.subscribe(function(v) {
  if (v)
    logState.set([])
})

function updateChat(dt) {
  foreach (rec in lines.get())
    rec.ttl -= dt
  let newLines = lines.get().filter(@(rec) rec.ttl > 0)
  if (newLines.len() != lines.get().len())
    lines.set(newLines)
}

setIntervalForUpdateFunc(0.45, updateChat)

function pushMsg(sender_team, name_from, user_id_from, text, send_mode, qmsg, nickFrame = "") {
  if ( user_id_from in blockedUids.get()
    || (qmsg == null && name_from != "" && !canInterractCrossPlatform(name_from, false)) )
    return

  totalLines.modify(@(v) v + 1)
  let l = lines
  const MAX_LINES = 10
  const MAX_LOG_LINES = 1000
  let rec = {
    team = sender_team
    name = name_from
    userId = user_id_from
    text = text
    sendMode = send_mode
    nickFrame
  }

  l.mutate(function(val) {
    val.append(rec.__merge({ttl=15.0}))
    if (val.len()>MAX_LINES) {
      val.remove(0)
    }
  })

  logState.mutate(function(val) {
    val.append(rec)
    if (val.len()>MAX_LOG_LINES) {
      val.remove(0)
    }
  })
}

function sendChatCmd(params = {mode="team", text=""}) {
  params = params.__merge({mode=params?.mode ?? "team"})
  let evt = mkCmdChatMessage(params)
  ecs.client_msg_sink(evt)
}


async function sendMessage(params){
  let filtered = await obsceneFilter(params.text)
  params.text = filtered
  sendChatCmd(params)
}

function mkTextFromQchatMsg(data) {
  
  return (data?.qmsg instanceof Table)
      ? loc(data?.text ?? "", data.qmsg.__merge({item=loc(data.qmsg?.item ?? "", {count = data.qmsg?.count, nickname = data.qmsg?.nickname})}))
      : data?.text ?? ""
}

function onChatMessage(evt, _eid, _comp) {
  let data = evt?.data
  if (data==null)
    return

  let {
    qmsg = null,
    mode = "team",
    team = 0,
    name = "unknown",
    senderUserId = INVALID_USER_ID
    nickFrame = ""
  } = data

  let isMyMessage = senderUserId == userInfo.get()?.userId
  let text = mkTextFromQchatMsg(data)
  let filtered = !isMyMessage && dirtyWordsFilterState.get() ? dirtyWordsFilter.checkPhrase(text)
    : text
  pushMsg(team, name, senderUserId, filtered, mode, qmsg, nickFrame)
}

ecs.register_es("chat_client_es", {
    [EventSqChatMessage] = onChatMessage
  }, {comps_rq = ["msg_sink"]}
)

return freeze({
  lines
  totalLines
  logState
  outMessage
  sendMode
  sendChatCmd

  update = updateChat
  pushMsg
  pushSystemMsg = @(msg) pushMsg(TEAM_UNASSIGNED, "", INVALID_USER_ID, msg, "system", null)
  sendMessage
})
