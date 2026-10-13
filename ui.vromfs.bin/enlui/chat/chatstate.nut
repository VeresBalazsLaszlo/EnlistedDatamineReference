from "%dngscripts/globalState.nut" import nestWatched
from "matching.api" import matching_listen_notify
from "eventbus" import eventbus_subscribe
from "%ui/ui_library.nut" import *

let chatLogs = {}

function getChatLog(chatId) {
  if (!(chatId in chatLogs)) {
    let key = $"chat_{chatId}"
    let w = nestWatched(key, [])
    chatLogs[chatId] <- {data = w, update = @(v) w.set(v)}
  }
  return chatLogs[chatId]
}

function clearChatState(chatId) {
  if (chatId in chatLogs) {
    chatLogs[chatId].update([])
    
    
    
    
  }
}

let chat_handlers = {
  ["chat.chat_message"] = function(params) {
    let chatLog = getChatLog(params.chatId)
    chatLog.update([].extend(chatLog.data.get(), params.messages))
  },
  ["chat.user_joined"] = function(params) {
    log($"{params.user.name} joined chat")
  },
  ["chat.user_leaved"] = function(params) {
    log($"{params.user.name} leaved from chat")
  }
}

function subscribeHandlers() {
  foreach (k, v in chat_handlers) {
    matching_listen_notify(k)
    eventbus_subscribe(k, v)
  }
}

return {
  getChatLog
  clearChatState
  subscribeHandlers
}
