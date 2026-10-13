import "%ui/control/gui_buttons.nut" as JB
import "%ui/hud/state/voice_chat.nut" as membersSpeaking
import "%ui/chat/chatRoom.nut" as chatRoom
import "matching.errors" as matching_errors
from "%ui/style/fontsStyle.nut" import fontBody, fontSub, fontHeading2
from "%ui/mpRoom/enlRoomState.nut" import connectToHost, lobbyStatus, startSession, leaveRoom,
  destroyRoom, roomMembers, room, chatId, canOperateRoom, roomTeamArmies,
  startSessionWithLocalDedicated, canStartWithLocalDedicated
from "%ui/mpRoom/myRoomMemberParams.nut" import curTeam
from "%ui/components/textButton.nut" import Regular
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/style/designConst.nut" import smallPadding, bigPadding, sidePadding, defTxtColor,
  attentionTxtColor, blurBgColor, defBgColor, strokeStyle, hoverTitleTxtColor, activeTitleTxtColor
from "%ui/helpers/remap_nick.nut" import remap_nick
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon
from "%ui/ui_library.nut" import *
from "%ui/mpRoom/enlRoomState.nut" import LobbyStatus
from "%ui/roomSettings.nut" import minPlayers


function startSessionCb(response) {
  function reportError(text) {
    console_print(text)
    showMsgbox(text)
  }

  if (response?.accept == false) 
    reportError("Failed to start session in room: {0}".subst(response?.reason ?? ""))
  else if (response.error != 0)
    reportError("Failed to start session in room: Battle servers not found")

}

function leaveRoomCb(response) {
  if (response.error)
    showMsgbox("Failed to leave room: {0}".subst(matching_errors.error_string(response.error)))
}

function doLeaveRoom() {
  leaveRoom(leaveRoomCb)
}

function destroyRoomCb(response) {
  if (response.error)
    showMsgbox("Failed to destroy room: {0}".subst(matching_errors.error_string(response.error)))
}

function doDestroyRoom() {
  destroyRoom(destroyRoomCb)
}

function memberName(member) {
  let actColor = Computed(@() membersSpeaking.get()?[member.name] ? attentionTxtColor : defTxtColor)
  let prefix = member.squadNum == 0 ? "" : $"[{member.squadNum}] "
  let text = prefix + remap_nick(member.name)
  return @() {
    rendObj = ROBJ_TEXT
    watch = actColor
    text
    margin = smallPadding
    hplace = ALIGN_LEFT
    validateStaticText = false
    color = actColor.get()
  }.__update(fontBody)
}

let getArmyByTeam = @(armies, team) armies?[team][0] ?? ["ussr", "ger"]?[team]

const teamIconSize = hdpx(21)
function teamIcon(team) {
  let armyId = Computed(@() getArmyByTeam(roomTeamArmies.get(), team))
  return @() {
    watch = armyId
    size = array(2, teamIconSize)
    hplace = ALIGN_RIGHT
    children = armyId.get() == null ? null
      : mkArmyIcon(armyId.get(), teamIconSize, { margin = 0 })
  }
}

let memberInfo = @(member) {
  size = FLEX_H
  valign = ALIGN_CENTER
  children = [
    memberName(member)
    teamIcon(member?.public.team ?? 0)
  ]
}


function membersList() {
  let players = roomMembers.get()
    .filter(@(member) !member.public?.host)
    .sort(@(a, b) (a.public?.squadId ?? 0) <=> (b.public?.squadId ?? 0))

  local squadNum = 0
  local prevSquadId = null
  foreach (player in players) {
    let { squadId = null } = player.public
    if (squadId == null)
      player.squadNum <- 0
    else {
      if (squadId != prevSquadId) {
        squadNum += 1
        prevSquadId = squadId
      }
      player.squadNum <- squadNum
    }
  }
  return {
    watch = roomMembers
    size = const [flex(1), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = players.map(memberInfo)
  }
}


let roomHeader = {
  rendObj = ROBJ_SOLID
  size = const [FLEX, fsh(4)]
  color = defBgColor
  padding = smallPadding
  valign = ALIGN_CENTER
  children = function() {
    let watch = room
    local { roomId = null, public = {} } = room.get()
    if (roomId == null)
      return { watch }

    local scene = null
    if (roomId != null) {
      scene = public?.title
      if (scene == null) {
        scene = public?.scene
        if (scene != null)
          scene = scene.split("/")
        if (scene.len() > 0)
          scene = scene.top()
      }
    }
    let { cluster = "none", roomName = "-", creator = "" } = public
    return {
      watch
      rendObj = ROBJ_TEXT
      text = $"{roomName} ({scene}), {loc("Creator")}:{remap_nick(creator)}, {loc("server")}:{cluster}"
    }.__update(fontSub)
  }
}


function membersListRoot() {
  return {
    size = const [flex(1), FLEX]
    rendObj = ROBJ_FRAME
    color = Color(120,120,120)
    borderWidth = const [hdpx(1), 0]

    key = "members-list"
    clipChildren = true
    behavior = Behaviors.WheelScroll
    children = {
      size = FLEX
      flow = FLOW_VERTICAL
      children = membersList
    }
  }
}


function statusText() {
  local text = ""
  let curLobbyStatus = lobbyStatus.get()
  if (curLobbyStatus == LobbyStatus.ReadyToStart)
    text = loc("lobbyStatus/ReadyToStart", {
      num_players = minPlayers.get()
      start_game_btn = loc("lobby/startGameBtn")
    })
  else if (curLobbyStatus == LobbyStatus.NotEnoughPlayers)
    text = loc("lobbyStatus/NotEnoughPlayers")
  else if (curLobbyStatus == LobbyStatus.CreatingGame)
    text = loc("lobbyStatus/CreatingGame")
  else if (curLobbyStatus == LobbyStatus.GameInProgress)
    text = loc("lobbyStatus/GameInProgress")
  else if (curLobbyStatus == LobbyStatus.GameInProgressNoLaunched)
    text = loc("lobbyStatus/GameInProgressNoLaunched", { play = loc("lobby/playBtn") })
  else if (curLobbyStatus == LobbyStatus.WaitForDedicatedStart)
    text = loc("lobbyStatus/WaitForDedicatedStart")

  return {
    size = FLEX_H
    halign = ALIGN_CENTER
    watch = lobbyStatus
    children = {
      rendObj = ROBJ_TEXT
      text = text
      color = attentionTxtColor
    }.__update(fontBody)
  }
}


let startGameButton = Regular(loc("lobby/startGameBtn"), startSession,
  {
    hotkeys=[["^J:X"]]
    sound = {
      click  = "ui/enlist/start_game_click"
      hover  = "ui/enlist/button_highlight"
      active = "ui/enlist/button_action"
    }
  })

function actionButtons() {
  let lobbyStatusV = lobbyStatus.get()
  let buttons = []
  if (lobbyStatusV == LobbyStatus.ReadyToStart)
    buttons.append(startGameButton)

  if (lobbyStatusV == LobbyStatus.GameInProgressNoLaunched)
    buttons.append(Regular(loc("lobby/playBtn"), connectToHost))

  if (lobbyStatusV == LobbyStatus.ReadyToStart
      && canOperateRoom.get()
      && canStartWithLocalDedicated.get())
    buttons.append(Regular(loc("lobby/startDedicatedBtn"),
      @() startSessionWithLocalDedicated(startSessionCb)))

  buttons.append(Regular(loc("lobby/leaveBtn"), doLeaveRoom, {hotkeys=[[$"^{JB.B} | Esc"]]}))

  if (canOperateRoom.get())
    buttons.append(Regular(loc("lobby/destroyRoomBtn"), doDestroyRoom, {hotkeys=[["^J:Y"]]}))

  return {
    watch = [lobbyStatus, canOperateRoom, canStartWithLocalDedicated]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = buttons
  }
}

let getArmyColor = @(isSelected, sf)
  isSelected || (sf & S_HOVER) ? hoverTitleTxtColor : activeTitleTxtColor

let mkArmyName = @(armyId, isSelected = false, sf = 0) {
  rendObj = ROBJ_TEXT
  text = loc(armyId)
  color = getArmyColor(isSelected, sf)
  vplace = ALIGN_CENTER
}.__update(fontHeading2, strokeStyle)

let mkCustomArmyBtn = @(armyId, isSelected, onClick)
  watchElemState(@(sf) {
    rendObj = ROBJ_BOX
    size = SIZE_TO_CONTENT
    borderWidth = (isSelected || (sf & S_HOVER)) ? [0, 0, hdpx(4), 0] : 0
    behavior = isSelected ? null : Behaviors.Button
    sound = {
      hover = "ui/enlist/button_highlight"
      click = "ui/enlist/button_click"
    }
    onClick
    children = {
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      padding = hdpx(10)
      size = SIZE_TO_CONTENT
      vplace = ALIGN_BOTTOM
      children = [
        mkArmyIcon(armyId)
        mkArmyName(armyId, isSelected, sf)
      ]
    }
  })

let armyButtons = @() {
  watch = [roomTeamArmies, curTeam]
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = roomTeamArmies.get().map(function(_, team) {
    let armyId = getArmyByTeam(roomTeamArmies.get(), team)
    return armyId == null
      ? null
      : mkCustomArmyBtn(armyId, team == curTeam.get(), @() curTeam.set(team))
  })
}

function chatRoot() {
  return {
    watch = chatId
    size = const [flex(3), FLEX]
    children = chatRoom(chatId.get())
  }
}


function roomScreen() {
  return {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = const [sw(80), FLEX]
    hplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    color = blurBgColor
    children = {
      size = const [pw(90), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      padding = bigPadding
      gap = bigPadding
      flow = FLOW_VERTICAL
      children = [
        roomHeader
        statusText
        {
          flow = FLOW_HORIZONTAL
          size = const [FLEX, fsh(55)]
          gap = sidePadding
          children = [
            membersListRoot
            chatRoot
          ]
        }
        {
          halign = ALIGN_CENTER
          gap = bigPadding
          flow = FLOW_VERTICAL
          children = [
            armyButtons
            actionButtons
          ]
        }
      ]
    }
  }
}

return roomScreen
