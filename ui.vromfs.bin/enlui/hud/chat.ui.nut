import "%ui/components/scrollbar.nut" as scrollbar
import "%ui/control/gui_buttons.nut" as JB
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "team" import TEAM_UNASSIGNED
from "%ui/hud/style.nut" import CONTROL_BG_COLOR, TEAM1_TEXT_COLOR, TEAM0_TEXT_COLOR
from "%ui/hud/state/interactive_state.nut" import setInteractiveElement
from "%ui/hud/state/local_player.nut" import localPlayerTeam, localPlayerName
from "%ui/hud/state/chat_state.nut" import switchSendModesAllowed
from "%ui/helpers/remap_nick.nut" import remap_others
from "%dngscripts/sound_system.nut" import sound_play_oneshot
from "%ui/style/colors.nut" import UserNameColor
from "%ui/components/decoratorsPresentation.nut" import frameNick
from "%ui/components/msgbox.nut" import hasMsgBoxes
from "%ui/state/biggerFontsState.nut" import biggerFontsState
from "%ui/hud/state/hudOptionsState.nut" import chatInputEnabled
from "%ui/ui_library.nut" import *

import "%ui/hud/state/chat.nut" as chatState


let showChatInput = mkWatched(persist, "showChatInput", false)

const inputBoxHeight = fsh(8)
const systemMessageColor = Color(225,35,35)

let itemTextAnim = [



]

let itemGap = {size=const [0,hdpx(1)]}

let itemAnim = [
  { prop=AnimProp.opacity, from=1.0, to=0, duration=0.6, playFadeOut=true}
  { prop=AnimProp.scale, from=[1,1], to=[1,0.01], delay=0.4, duration=0.6, playFadeOut=true}
]

function chatItem(item, params = {}) {
  let { team, name, sendMode, text, send_mode = null, nickFrame = "" } = item
  let color = send_mode == "system" ? systemMessageColor
    : team == TEAM_UNASSIGNED ? 0xFFFFFFFF
    : team == localPlayerTeam.get() ? TEAM0_TEXT_COLOR
    : TEAM1_TEXT_COLOR

  let rowChildren = []
  if (name != "") {
    let nameParams = sendMode != "all" ? null
      : { rendObj = ROBJ_TEXT, color = color, text = $"[{loc("chat/all")}]" }
    rowChildren.append(nameParams, {
      rendObj = ROBJ_TEXT,
      color = name == localPlayerName.get() ? UserNameColor : color,
      text = $"{frameNick(remap_others(name), nickFrame)}: "
    })
  }
  rowChildren.append({
    size = FLEX_H
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    color
    text
    preformatted = FMT_IGNORE_TAGS
  })

  return {
    size = FLEX_H
    key = item
    rendObj = ROBJ_WORLD_BLUR
    color = Color(200,200,200,200)
    children = {
      flow = FLOW_HORIZONTAL
      key = item
      transform = { pivot = [0, 1.0] }
      size = FLEX_H
      animations = (params?.noanim) ? null : itemTextAnim
      children = rowChildren
    }
    transform = { pivot = [0, 0] }
    animations = (params?.noanim) ? null :itemAnim
  }
}

local lastScrolledTo = null
let scrollHandler = ScrollHandler()

function chatLogContent() {
  let logLines = chatState.logState.get().map(@(line) chatItem(line, { noanim = true }))
  let scrollTo = chatState.logState.get().len() ? chatState.logState.get().top() : null
  return {
    watch = chatState.logState
    key = "chatLog"
    size = FLEX_H
    minHeight = SIZE_TO_CONTENT
    clipChildren = true
    gap = itemGap
    flow = FLOW_VERTICAL
    children = logLines
    behavior = Behaviors.RecalcHandler
    onRecalcLayout = function(_initial) {
      if (scrollTo && scrollTo != lastScrolledTo) {
        lastScrolledTo = scrollTo
        scrollHandler.scrollToChildren(@(desc) ("key" in desc) && (desc.key == scrollTo), 2, false, true)
      }
    }
  }
}

let chatLog = {
  size = FLEX
  flow = FLOW_VERTICAL
  children = scrollbar.makeVertScroll(chatLogContent, {scrollHandler = scrollHandler})
  vplace = ALIGN_BOTTOM
}

function chatContent() {
  let children = chatState.lines.get().map(chatItem)

  return {
    key = "chatContent"
    size = FLEX
    clipChildren = true
    valign = ALIGN_BOTTOM
    gap = itemGap
    flow = FLOW_VERTICAL
    watch = [chatState.lines, localPlayerTeam]
    children
  }
}


function inputBox() {
  let textInput = {
    rendObj = ROBJ_SOLID
    color = CONTROL_BG_COLOR
    vplace = ALIGN_TOP
    size = FLEX_H

    children = [
      function() {
        return {
          rendObj = ROBJ_TEXT
          size = const [FLEX, fontH(120)]
          margin = fsh(0.5)
          text = chatState.outMessage.get()
          watch = chatState.outMessage
          behavior = Behaviors.TextInput
          onChange = @(text) chatState.outMessage.set(text)
          onAttach = @(elem) capture_kb_focus(elem)
          onReturn = function() {
            if (chatState.outMessage.get().len()>0) {
              chatState.sendMessage({
                mode = chatState.sendMode.get(),
                text = chatState.outMessage.get()
              })
            }
            chatState.outMessage.set("")
            showChatInput.set(false)
          }
          hotkeys = [
            [$"^{JB.B} | Esc", function() {
              chatState.outMessage.set("")
              showChatInput.set(false)
            }, "Close chat"]
          ]
        }.__update(fontSub)
      }
    ]
  }

  function sendModeText(mode) {
    return mode == "all" ? loc("chat/all")
      : mode == "team" ? loc("chat/team")
      : "???"
  }

  let modesHelp = {
    vplace = ALIGN_BOTTOM
    size = const [FLEX, fsh(3)]
    children = [
      {
        rendObj = ROBJ_TEXT
        vplace = ALIGN_CENTER
        text = loc("chat/help/short")
        color = Color(180, 180, 180, 180)
      }.__update(fontSub)
      @() {
        rendObj = ROBJ_TEXT
        vplace = ALIGN_CENTER
        hplace = ALIGN_RIGHT
        watch = chatState.sendMode
        text = sendModeText(chatState.sendMode.get())
      }.__update(fontBody)
    ]
  }

  function switchSendModes() {
    let newMode = chatState.sendMode.get() == "all" ? "team" : "all"
    if (switchSendModesAllowed.get())
      chatState.sendMode.set(newMode)
  }

  return {
    size = const [FLEX, inputBoxHeight]
    flow = FLOW_VERTICAL
    watch = switchSendModesAllowed

    hotkeys = switchSendModesAllowed.get() ? [ ["^Tab", switchSendModes] ] : null

    children = [
      textInput
      switchSendModesAllowed.get() ? modesHelp : null
    ]
  }
}


let hasInteractiveChat = Computed(@() showChatInput.get() && chatInputEnabled.get())

hasInteractiveChat.subscribe(@(new_val) setInteractiveElement("chat", new_val))

hasMsgBoxes.subscribe(function(shown_any) {
  
  if (shown_any) {
    chatState.outMessage.set("")
    showChatInput.set(false)
  }
})


let inputBoxDummy = {size=const [FLEX, inputBoxHeight]}

let chatRoot = @() {
  key = "chat"
  watch = [hasInteractiveChat, biggerFontsState]
  size = [FLEX, biggerFontsState.get() ? fsh(22) : fsh(24)]
  flow = FLOW_VERTICAL
  children = hasInteractiveChat.get()
    ? [ chatLog, inputBox ]
    : [ chatContent, inputBoxDummy ]
}

chatState.totalLines.subscribe(@(_) sound_play_oneshot("ui/new_log_message"))

return {
  chatRoot
  showChatInput
}
