import "%ui/components/scrollbar.nut" as scrollbar
import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/components/textButton.nut" import Regular
from "%ui/chat/chatState.nut" import getChatLog
from "%ui/chat/chatApi.nut" import sendMessage
from "dagor.time" import format_unixtime
from "%ui/helpers/remap_nick.nut" import remap_nick
from "%ui/state/dirty_words_filter_state.nut" import dirtyWordsFilterState
from "%ui/ui_library.nut" import *

let textInput = require("%ui/components/textInput.nut")
let dirtyWordsFilter = require("%ui/chat/dirty_words/dirty_words_filter.nut")

const ColorInactive = Color(120,120,120)
function messageInLog(entry) {
  const fmtString = "%H:%M:%S"
  let isMyMessage = entry.sender.userId == userInfo.get()?.userId
  let text = !isMyMessage && dirtyWordsFilterState.get() ? dirtyWordsFilter.checkPhrase(entry.text)
    : entry.text
  return {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = $"[{format_unixtime(fmtString, entry.timestamp)}] {remap_nick(entry.sender.name)}: {text}"
    key = entry.timestamp
    margin = fsh(0.5)
    size = FLEX_H
  }.__update(fontSub)
}


function chatRoom(chatId) {
  if (chatId == null)
    return null

  let chatMessage = Watched("")


  let scrollHandler = ScrollHandler()


  function doSendMessage() {
    if (chatMessage.get() == "")
      return
    sendMessage(chatId, chatMessage.get())
    chatMessage.set("")
  }


  function chatInputField() {
    let options = {
      placeholder = loc("chat/inputPlaceholder")
      margin = 0
      onReturn = doSendMessage
    }.__update(fontSub)
    return {
      size = FLEX_H
      children = textInput(chatMessage, options)
    }
  }


  function chatInput() {
    return {
      flow = FLOW_HORIZONTAL
      size = FLEX_H
      valign = ALIGN_CENTER
      gap = fsh(1)
      children = [
        chatInputField
        Regular(loc("chat/sendBtn"), doSendMessage, fontSub)
      ]
    }
  }

  local lastScrolledTo = null

  function logContent() {
    let chatLog = getChatLog(chatId)?.data
    if (chatLog == null)
      return {}
    let messages = chatLog.get().map(messageInLog)
    let scrollTo = chatLog.get().len() ? chatLog.get().top().timestamp : null

    return {
      size = FLEX_H
      flow = FLOW_VERTICAL
      behavior = Behaviors.RecalcHandler

      watch = chatLog

      children = messages

      onRecalcLayout = function(_initial) {
        if (scrollTo && scrollTo != lastScrolledTo) {
          lastScrolledTo = scrollTo
          scrollHandler.scrollToChildren(@(desc) ("key" in desc) && (desc.key == scrollTo), 2, false, true)
        }
      }
    }
  }


  function chatLog() {
    return {
      size = FLEX

      rendObj = ROBJ_FRAME
      color = ColorInactive
      borderWidth = const [hdpx(1), 0]

      children = scrollbar.makeVertScroll(logContent, {scrollHandler = scrollHandler})
    }
  }

  return function () {
    if (!getChatLog(chatId))
      return {}

    return {
      size = FLEX
      flow = FLOW_VERTICAL
      gap = fsh(1)
      stopMouse = true

      children = [
        chatLog
        chatInput
      ]
    }
  }
}


return chatRoom
