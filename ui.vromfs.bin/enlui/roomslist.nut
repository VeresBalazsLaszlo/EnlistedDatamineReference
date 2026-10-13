import "%ui/components/scrollbar.nut" as scrollbar
import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/centeredText.nut" as centeredText
import "%ui/createRoom.nut" as createRoom
import "matching.errors" as matching_errors
from "%ui/modFiles.nut" import receivedFiles, requestedFiles, requestFilesByHashes
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/mpRoom/showCreateRoom.nut" import showCreateRoom
from "%ui/components/textButton.nut" import Regular, soundActive
from "%ui/components/msgbox.nut" import showMsgbox
from "math" import rand
from "%ui/style/colors.nut" import Inactive, SelectedItemBg, HoverItemBg
from "%sqstd/string.nut" import tostring_any
from "%ui/squad/squadState.nut" import squadId
from "%ui/state/clientState.nut" import gameLanguage
from "%ui/helpers/remap_nick.nut" import remap_others
from "%ui/style/designConst.nut" import bigPadding, blurBgColor
from "string" import strip
from "%ui/ui_library.nut" import *
from "%ui/state/roomState.nut" import joinRoom

let roomsListState = require("%ui/roomsListState.nut")
let textInput = require("%ui/components/textInput.nut")

let selectedRoom = Watched(null)

let scrollHandler = ScrollHandler()

function tryToJoin(roomInfo, cb, password="" ){
  let params = { roomId = roomInfo.roomId.tointeger() }
  if (squadId.get() != null)
    params.member <- { public = {squadId = squadId.get()} }
  if (roomInfo?.hasPassword)
    params.password <- strip(password)
  joinRoom(params, true, cb)
}

function mkFindSomeMatch(cb) {
  return function(){
    let candidates = []
    foreach (room in roomsListState.list.get()) {
      if (room?.hasPassword)
        continue
      if (room.membersCnt >= (room?.maxPlayers ?? 0) || !room.membersCnt)
        continue
      candidates.append(room)
    }

    if (!candidates.len()) {
      showMsgbox({
        text = loc("Cannot find existing game. Create one?")
        buttons = [
          { text = loc("Yes"), action = @() showCreateRoom.set(true), isCurrent = true }
          { text = loc("No"), customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }}
        ]
      })
    }
    else {
      let room = candidates[rand() % candidates.len()]
      tryToJoin(room, cb, "")
    }
  }
}

function fullRoomMsgBox(action) {
  showMsgbox({
    text = loc("msgboxtext/roomIsFull")
    buttons = [
      { text = loc("Yes"), action }
      { text = loc("No")}
    ]
  })
}

function joinCb(response) {
  if (response.error != matching_errors.OK){
    if (response.error == matching_errors.SERVER_ERROR_ROOM_FULL) {
      fullRoomMsgBox(mkFindSomeMatch(joinCb))
      return
    }

    showMsgbox(loc("msgbox/failedJoinRoom", "Failed to join room: {error}",
      { error = matching_errors.error_string(response.error) }))
  } else {
    selectedRoom.set(null)
  }
}
let findSomeMatch = mkFindSomeMatch(joinCb)

let doesCurrentRoomHasAllFiles = Computed(function(){
  local {modFiles="", mod=""} = selectedRoom.get()
  if (mod == "" || modFiles == "")
    return true
  let received = receivedFiles.get()
  modFiles = modFiles.split(";")
  foreach (hash in modFiles){
    if (hash not in received)
      return false
  }
  return true
})

let areCurrentRoomFilesAreDownloading = Computed(function(){
  local {modFiles="", mod=""} = selectedRoom.get()
  if (mod=="" || modFiles == "")
    return false
  modFiles = modFiles.split(";")
  foreach (hash in modFiles){
    if (hash in requestedFiles.get())
      return true
  }
  return false
})

function doJoin() {
  let roomPassword = Watched("")
  let roomInfo = selectedRoom.get()
  if (roomInfo==null) {
    showMsgbox(loc("msgbox/noRoomTOJoin", "No room selected"))
    return
  }

  if (!doesCurrentRoomHasAllFiles.get()) {
    
    requestFilesByHashes(roomInfo.modFiles.split(";"))
    return
  }
  if (roomInfo && roomInfo?.hasPassword){
    function passwordInput() {
      local input = null

      if (roomInfo && roomInfo?.hasPassword) {
        input = textInput(roomPassword, {
          placeholder="password"
        })
      }

      return {
        key = "room-password"
        size = const [sw(20), SIZE_TO_CONTENT]
        children = input
      }
    }

    showMsgbox({
      text = loc("This room requires password to join")
      children = passwordInput
      buttons = [
        { text = loc("Proceed"), isCurrent = true,
          action = @() tryToJoin(roomInfo, joinCb, roomPassword.get()) }
        { text = loc("Cancel"), customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
      ]
    })
  }
  else
    tryToJoin(roomInfo, joinCb)
}


function itemText(text, options={}) {
  return {
    rendObj = ROBJ_TEXT
    text
    margin = fsh(1)
    size = ("pw" in options) ? [flex(options.pw), SIZE_TO_CONTENT] : SIZE_TO_CONTENT
  }.__update(fontSub)
}


let colWidths = [25, 35, 12, 8, 25]

function listItem(roomInfo) {
  let stateFlags = Watched(0)

  local roomName = roomInfo?.roomName ?? tostring_any(roomInfo.roomId)
  if (roomInfo?.hasPassword)
    roomName = $"{roomName}*"

  return function() {
    local color
    if (selectedRoom.get() && (roomInfo.roomId == selectedRoom.get().roomId))
      color = SelectedItemBg
    else
      color = stateFlags.get() & S_HOVER ? HoverItemBg : Color(0,0,0,0)

    let modTitle = roomInfo?.modTitles?[gameLanguage]
      ?? roomInfo?.modTitles.title ?? roomInfo?.mod ?? ""
    local { creator = "" } = roomInfo
    creator = creator != "" ? remap_others(creator) : loc("creator/auto")

    return {
      rendObj = ROBJ_SOLID
      color = color
      size = FLEX_H

      behavior = Behaviors.Button
      onClick = @() selectedRoom.set(roomInfo)
      onDoubleClick = doJoin
      onElemState = @(sf) stateFlags.set(sf)
      watch = [selectedRoom, stateFlags]
      key = roomInfo.roomId

      sound = soundActive

      flow = FLOW_HORIZONTAL
      children = [
        itemText(roomName, {pw=colWidths[0]})
        itemText(modTitle, {pw=colWidths[1]})
        itemText(loc(roomInfo?.sessionState ?? "no_session"), {pw=colWidths[2]})
        itemText(tostring_any(roomInfo.membersCnt), {pw=colWidths[3]})
        itemText(creator, {pw=colWidths[4]})
      ]
    }
  }
}


function listHeader() {
  return {
    hplace = ALIGN_CENTER
    size = FLEX_H
    pos = const [0, sh(11)]
    children = {
      size = FLEX_H
      margin = const [0, fsh(1), 0, 0]
      flow = FLOW_HORIZONTAL
      children = [
        itemText(loc("Name"), {pw=colWidths[0]})
        itemText(loc("Mod"), {pw=colWidths[1]})
        itemText(loc("Status"), {pw=colWidths[2]})
        itemText(loc("Players"), {pw=colWidths[3]})
        itemText(loc("Creator"), {pw=colWidths[4]})
      ]
    }
  }
}


let nameFilter = mkWatched(persist, "nameFilter", "")

let roomsListW = roomsListState.list
let filteredList = Computed(function() {
  let flt = nameFilter.get().tolower()
  if (flt.len() == 0)
    return clone roomsListW.get()
  return roomsListW.get().filter(function(room) {
    let roomName = room.public?.roomName || tostring_any(room.roomId)
    return (roomName.tolower().contains(flt))
  })
})

function listContent() {
  return {
    size = FLEX_H
    watch = filteredList
    flow = FLOW_VERTICAL
    children = filteredList.get().map(@(roomInfo) listItem(roomInfo))
  }
}


function roomsListComp() {
  return {
    size = const [FLEX, sh(60)]
    hplace = ALIGN_CENTER
    pos = const [0, sh(15)]

    rendObj = ROBJ_FRAME
    color = Inactive
    borderWidth = const [2, 0]

    key = "rooms-list"

    valign = ALIGN_CENTER

    children = scrollbar.makeVertScroll(listContent, {
      scrollHandler = scrollHandler
      rootBase = {
        size = FLEX
        margin = const [2, 0]
      }
    })
  }
}


function roomFilter() {
  return {
    size = const [FLEX, fsh(6)]

    vplace = ALIGN_BOTTOM
    halign = ALIGN_RIGHT

    flow = FLOW_HORIZONTAL
    onDetach = @() nameFilter.set("")
    onAttach = @() nameFilter.set("")
    children = [
      {
        size = [pw(colWidths[0] * 1.5), SIZE_TO_CONTENT]
        margin = const [0, hdpx(10), 0, 0]
        children = textInput.Underlined(nameFilter,
          {
            placeholder=loc("search by name")
            onEscape = @() nameFilter.set("")
          }.__update(fontSub))
      }
    ]
  }
}

function actionButtons() {
  local joinBtn
  if (selectedRoom.get()) {
    joinBtn = function(){
      let joinBtnTxt = doesCurrentRoomHasAllFiles.get()
        ? loc("Join")
        : areCurrentRoomFilesAreDownloading.get()
          ? loc("Downloading...")
          : loc("Download")
      return {
        watch = [areCurrentRoomFilesAreDownloading, doesCurrentRoomHasAllFiles]
        children = Regular(joinBtnTxt, doJoin, {hotkeys = [["^Enter"]]})
      }
    }
  }
  return {
    size = const [SIZE_TO_CONTENT, fsh(6.5)] 
    watch = [selectedRoom]
    padding = bigPadding
    gap = bigPadding
    vplace = ALIGN_BOTTOM
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL

    children = [
      Regular(loc("Find custom game"), findSomeMatch, {hotkeys=[["^J:Y"]]})
      Regular(loc("Create game"), @() showCreateRoom.set(true), {hotkeys=[["^J:X | Enter"]]})
      joinBtn
    ]
  }
}
let areThereRooms = Computed(@() roomsListW.get().len()>0)

function roomsListScreen() {
  local children = null

  if (roomsListState.error.get()) {
    children = [centeredText(loc("error/{0}".subst(roomsListState.error.get())))]
  }
  else if (!areThereRooms.get()) {
    children = [centeredText(loc("No custom games found")) actionButtons]
  }
  else {
    children = [
      listHeader
      @(){
        children = roomsListComp
        size = FLEX
      }
      {
        flow = FLOW_HORIZONTAL
        size = FLEX
        children = [actionButtons, roomFilter]
      }
    ]
  }

  return {
    children
    size = FLEX
    onAttach = @() roomsListState.isRefreshEnabled.set(true)
    onDetach = @() roomsListState.isRefreshEnabled.set(false)

    watch = [
      roomsListState.error
      roomsListState.isRequestInProgress
      areThereRooms
    ]
  }
}

function root() {
  let children = showCreateRoom.get() ?  createRoom : roomsListScreen
  return {
    size = const [sw(80), FLEX]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = blurBgColor
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    padding = hdpx(5)
    key = "rooms-list"

    children = children
    watch = showCreateRoom
  }
}

return root
