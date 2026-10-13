import "%ui/control/gui_buttons.nut" as JB
import "%enlSqGlob/userInfo.nut" as userInfo
from "matching.errors" import OK, error_string
from "%ui/components/msgbox.nut" import removeMsgboxByUid, showMsgboxWithCloseButton, showMsgbox
from "%ui/state/roomState.nut" import joinRoom, isHostInGame
from "%ui/squad/squadState.nut" import squadId
from "%ui/gameModes/eventRoomsListState.nut" import selRoom
from "%ui/style/designConst.nut" import midPadding
from "%ui/ui_library.nut" import *

let textInput = require("%ui/components/textInput.nut")

local roomParams = Watched({})
const passwordMsgBoxUid = "room-password"

function joinCb(response) {
  let err = response.error
  if (err != OK) {
    let errStr = error_string(err)
    if (errStr == "SERVER_ERROR_ROOM_PASSWORD_MISMATCH")
      roomParams.mutate(@(v) v["isRetry"] <- true)
    else
      showMsgbox(loc("msgbox/failedJoinRoom", { error = loc($"error/{errStr}", errStr) }))
  }
  else {
    roomParams.set({})
    removeMsgboxByUid(passwordMsgBoxUid)
  }
}

let passwordHint = {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text = loc("options/password/hint")
  halign = ALIGN_CENTER
}

function showPasswordMsgbox(params){
  let roomPassword = Watched("")
  function tryToJoinRoom(){
    params["password"] <- roomPassword.get()
    joinRoom(params, true, joinCb)
  }
  let passwordInput = {
    size = const [sw(20), SIZE_TO_CONTENT]
    children = textInput(roomPassword, {
      placeholder = loc("enter_pass")
      maxChars = 16
      password = true
      onReturn = tryToJoinRoom
      onAttach = @(elem) set_kb_focus(elem)
      onEscape = function(){
        set_kb_focus(null)
        removeMsgboxByUid(passwordMsgBoxUid)
      }
    })
  }

  showMsgboxWithCloseButton({
    uid = passwordMsgBoxUid
    size = FLEX_H
    text = (params?.isRetry ?? false) ? loc("lobby/invalidPass") : loc("lobby/enterPass")
    children = {
      flow = FLOW_VERTICAL
      gap = midPadding
      children = [
        passwordInput
        passwordHint
      ]
    }
    buttons = [
      {
        text = loc("Proceed")
        action = tryToJoinRoom
        customStyle = {
          hotkeys = [[ "^J:Y", { description = { skip = true } } ]]
        }
      }
      {
        text = loc("Cancel")
        customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
      }
    ]
  })
}

roomParams.subscribe(@(v) v.len() > 0 ? showPasswordMsgbox(v): null)

function joinSelEventRoom() {
  let room = selRoom.get()
  if (room == null)
    return
  roomParams.set({})

  let params = { roomId = room.roomId.tointeger() }
  let isCreator = room?.creatorId == userInfo.get().userId
  if (squadId.get() != null)
    params.member <- { public = { squadId = squadId.get() } }

  if (!(room?.hasPassword ?? false))
    joinRoom(params, true, joinCb)
  else if (isCreator) {
    isHostInGame.set(false)
    joinRoom(params, true, joinCb)
  }
  else
    roomParams.set(params)
}

return {
  joinSelEventRoom
}