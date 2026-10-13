import "%ui/helpers/locByPlatform.nut" as locByPlatform
import "%ui/components/spinner.nut" as spinner
import "%ui/components/faComp.nut" as faComp
import "%ui/gameModes/getMissionInfo.nut" as getMissionInfo
import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/style/designConst.nut" import defTxtColor, titleTxtColor, smallPadding, midPadding, bigPadding, brightAccentColor, squadSlotBgActiveColor
from "%ui/components/textButton.nut" import FARegular, FASecondary
from "%ui/style/sounds.nut" import buttonSound
from "%ui/squad/squadState.nut" import squadMembers, isInvitedToSquad
from "%ui/contacts/contact.nut" import getContactNick
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/squad/squadManager.nut" import squadOnlineMembers
from "%ui/gameModes/eventRoomsListState.nut" import roomsList
from "%ui/ui_library.nut" import *
from "%ui/helpers/time.nut" import secondsToStringLoc


let contactContextMenu = require("%ui/contacts/contactContextMenu.nut")


let defNickStyle = { color = defTxtColor }.__update(fontBody)
let statusCommonStyle = fontBody
let waitingSpinner = spinner(hdpxi(14))


let playerStatusesIcons = freeze({
  inBattle = {
    icon = "star"
    color = 0xFFE4CF3F
    fontSize = hdpxi(14)
  }
  inSquad = {
    icon = "users"
    color = 0xFFE4CF3F
    fontSize = hdpxi(12)
  }
  online = {
    icon = "circle"
    color = 0xFF65FE7A
  }
  offline = {
    icon = "circle"
    color = 0xFFD9281D
  }
  unknown = {
    icon = "circle-o"
    color = defTxtColor
  }
})

let playerSquadStatuses = freeze({
  inBattle = {
    text = loc("contact/inBattle")
    color = titleTxtColor
    icon = "gamepad"
  }
  inSquad = {
    text = loc("contact/inSquad")
    color = titleTxtColor
  }
  leader = {
    text = loc("squad/Chief")
    color = brightAccentColor
    icon = "star"
  }
  offlineInSquad = {
    text = loc("contact/Offline")
    color = titleTxtColor
    icon = "times"
  }
  ready = {
    text = loc("contact/Ready")
    color = brightAccentColor
    icon = "check"
  }
  unready = {
    text = loc("contact/notReady")
    color = 0xFFC0C0C0
    icon = "times"
  }
  invited = {
    text = loc("contact/Invited")
    color = defTxtColor
  }
  unknown = {
    text = loc("contact/Unknown")
    color = defTxtColor
  }
  online = {
    text = loc("contact/Online")
    color = titleTxtColor
  }
  offline = {
    text = loc("contact/Offline")
    color = defTxtColor
  }
})


let mkText = @(text, override = {}) text == "" ? null : {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text
}.__update(fontSub, override)


let mkTextArea = @(text, override = {}) text == "" ? null : {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  color = defTxtColor
  text
}.__update(fontSub, override)


let userNickname = @(contact, override) {
  behavior = Behaviors.Marquee
  clipChildren = true
  rendObj = ROBJ_TEXT
  text = getContactNick(contact)
}.__update(override)


function statusIcon(presences) {
  let { online = null, inBattle = false, inSquad = false } = presences
  let iconToShow = online == null ? playerStatusesIcons.unknown
    : online && inBattle ? playerStatusesIcons.inBattle
    : online && inSquad ? playerStatusesIcons.inSquad
    : online ? playerStatusesIcons.online
    : playerStatusesIcons.offline
  let { icon, color, fontSize = hdpxi(10) } = iconToShow
  return faComp(icon, { fontSize, color })
}


function mkSquadMemberInfo(online, squadMember) {
  let { state, isLeader } = squadMember
  let { inBattle = false, ready = false } = state
  let { color, text, icon = null } = inBattle ? playerSquadStatuses.inBattle
      : isLeader ? playerSquadStatuses.leader
      : !online ? playerSquadStatuses.offlineInSquad
      : ready ? playerSquadStatuses.ready
      : playerSquadStatuses.unready
  return [
    icon != null ? faComp(icon, { fontSize = fontSub.fontSize, color }) : null
    mkText(text, { color })
  ]
}

function mkInviteMemberInfo() {
  let { color, text } = playerSquadStatuses.invited
  return [
    waitingSpinner
    mkText(text, { color })
  ]
}

function mkMemberInfo(presences) {
  let { online = false, inBattle = false, inSquad = false } = presences
  let texts = []
  if (inBattle)
    texts.append(playerSquadStatuses.inBattle.text)
  if (inSquad)
    texts.append(playerSquadStatuses.inSquad.text)
  if (texts.len() == 0)
    texts.append(online ? playerSquadStatuses.online.text : playerSquadStatuses.offline.text)
  return [
    { size = const [hdpx(16), 0] }
    mkText(", ".join(texts))
  ]
}


let statusBlock = @(presences, contact) function() {
  let { uid } = contact
  let online = uid in squadOnlineMembers.get()
  let squadMember = squadMembers.get()?[uid]
  let isInvited = isInvitedToSquad.get()?[uid]
  return {
    watch = [ squadMembers, isInvitedToSquad, squadOnlineMembers ]
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    valign = ALIGN_CENTER
    children = squadMember != null ? mkSquadMemberInfo(online, squadMember)
      : isInvited ? mkInviteMemberInfo()
      : mkMemberInfo(presences)
  }
}


function contactActionButton(action, userId, mkTooltip) {
  let btnCtor = "action" in action ? FARegular : FASecondary
  return btnCtor(action.icon, @() action?.action(userId), {
    size = hdpx(36)
    key = userId
    skipDirPadNav = true
    btnWidth = hdpx(36)
    hint = mkTooltip?(userId) ?? {
      rendObj = ROBJ_TEXT
      text = locByPlatform(action.locId)
    }.__update(statusCommonStyle)
  })
}


function onContactClick(event, contact, contextMenuActions) {
  if (event.button >= 0 && event.button <= 2)
    contactContextMenu.open(contact, event, contextMenuActions)
}


let gapFlex = freeze({ size = FLEX })
function mkContactBlock(
  contact, contextMenuActions = [], inContactActions = [], presences = {}, isFlex = true
) {
  let group = ElemGroup()
  let { userId } = contact

  let actionsButtons = {
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    hplace = ALIGN_RIGHT
    children = inContactActions.map(function(action) {
      let { mkIsVisible, mkTooltip = null } = action
      let isVisible = mkIsVisible(userId)
      return @() {
        watch = isVisible
        halign = ALIGN_RIGHT
        children = !isVisible.get() ? null : contactActionButton(action, userId, mkTooltip)
      }
    })
  }

  let player = {
    size = FLEX_V
    flow = FLOW_VERTICAL
    gap = gapFlex
    valign = ALIGN_CENTER
    children = [
      {
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        valign = ALIGN_CENTER
        children = [
          {
            size = const [hdpx(16), SIZE_TO_CONTENT]
            halign = ALIGN_CENTER
            children = statusIcon(presences)
          }
          userNickname(contact, defNickStyle)
        ]
      }
      statusBlock(presences, contact)
    ]
  }

  return {
    size = isFlex ? FLEX : FLEX_V
    children = watchElemState(@(sf) {
      watch = isGamepad
      rendObj = ROBJ_WORLD_BLUR_PANEL
      size = isFlex ? FLEX : FLEX_V
      fillColor = sf & S_HOVER ? squadSlotBgActiveColor : null
      padding = [midPadding, bigPadding]
      gap = bigPadding
      valign = ALIGN_CENTER
      behavior = Behaviors.Button
      xmbNode = XmbNode({
        canFocus = true
        scrollToEdge = true
        wrap = false
      })
      onClick = @(event) onContactClick(event, contact, contextMenuActions)
      stopHover = true
      group
      sound = buttonSound
      children = [
        player
        !isGamepad.get() && (sf & S_HOVER) ? actionsButtons : null
      ]
    })
  }
}


let baseTooltipStyle = { color = defTxtColor }.__update(fontSub)
let titleTooltipStyle = { color = titleTxtColor }.__update(fontBody)
let accentTooltipStyle = { color = brightAccentColor }.__update(fontSub)
let missionImgSize = [hdpxi(200), hdpxi(150)]


function mkBattleTimeTxtObj(sTime) {
  if (sTime == 0 || sTime > serverTime.get())
    return null

  let battleTimeTxt = Computed(@() secondsToStringLoc(serverTime.get() - sTime))
  return @() {
    watch = battleTimeTxt
    flow = FLOW_HORIZONTAL
    gap = smallPadding
    children = [
      mkText(loc("looby/battleTime"))
      mkText(battleTimeTxt.get(), accentTooltipStyle)
    ]
  }
}


function mkMissionInfo(scene, army, sTime, isLobby = false, mode = "", addObject = null) {
  let missionInfo = scene == "" ? null : getMissionInfo(scene)
  let { locId = null, image = null } = missionInfo

  let armyObject = army == "" ? null
    : {
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = [
          mkText(loc("army"))
          mkText(loc($"{army}/full"), accentTooltipStyle)
        ]
      }

  let missionNameTxt = locId == null ? loc("lobby/missionNotDefined") : loc(locId)
  let missionType = missionInfo?.type ?? ""
  let typeTxt = missionType == "" ? "" : loc($"missionType/{missionType}")
  let modeTxt = mode == "" ? "" : loc("ui/parentheses", { text = mode })

  return {
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    valign = ALIGN_CENTER
    children = [
      image == null ? null
        : {
            rendObj = ROBJ_IMAGE
            size = missionImgSize
            image = Picture(image)
            keepAspect = KEEP_ASPECT_FILL
          }
      {
        size = const [hdpx(320), SIZE_TO_CONTENT]
        flow = FLOW_VERTICAL
        gap = bigPadding
        margin = [bigPadding, 0]
        children = [
          {
            flow = FLOW_VERTICAL
            children = [
              mkText(loc(isLobby ? "joinLobbyTooltipHeader" : "joinMissionTooltipHeader"),
                baseTooltipStyle)
              mkText(missionNameTxt, accentTooltipStyle)
            ]
          }
          {
            size = FLEX_H
            flow = FLOW_VERTICAL
            children = [
              {
                flow = FLOW_HORIZONTAL
                gap = smallPadding
                children = [
                  mkText(loc("current_mode"))
                  mkText(typeTxt, accentTooltipStyle)
                ]
              }
              mkTextArea(modeTxt, accentTooltipStyle)
              armyObject
              mkBattleTimeTxtObj(sTime)
              addObject
            ]
          }
        ]
      }
    ]
  }
}


function mkJoinToFriendTooltip(presences) {
  let { roomId = null, scene = "", lobby = false, army = "", sTime = 0 } = presences

  let children = []
  if (lobby) {
    if (roomId != null) {
      children.append( mkText(loc("contacts/join_battle"), titleTooltipStyle) )
      children.append(function() {
        let room = roomsList.get().findvalue(@(r) r.roomId == roomId.tostring())
        if (room == null)
          return { watch = roomsList }

        let {
          mode, maxPlayers, membersCnt, modName = null, launcherState = null, hasPassword = false
        } = room
        let hasLaunched = launcherState == "launched"
        let roomInfoObjects = [
          mkText(loc("playersCountTotalText", {
            count = membersCnt, total = maxPlayers
          }))
          mkText(loc(hasLaunched ? "lobby/gameInProgress"
            : "lobby/preparationBattle"), accentTooltipStyle)
        ]
        let curScene = scene != "" ? scene
          : hasLaunched ? (room?.scene ?? "")
          : ""
        return {
          watch = roomsList
          flow = FLOW_VERTICAL
          children = [
            hasPassword ? faComp("lock", { fontSize = hdpx(20) }) : null
            mkMissionInfo(curScene, army, sTime, true, modName ?? loc(mode ?? ""), {
              size = FLEX_H
              flow = FLOW_VERTICAL
              margin = [bigPadding, 0, 0, 0]
              children = roomInfoObjects
            })
          ]
        }
      })
    }
  }
  else {
    children.append({
      children = mkMissionInfo(scene, army, sTime)
    })
  }

  return {
    flow = FLOW_VERTICAL
    gap = midPadding
    valign = ALIGN_CENTER
    children
  }
}

return {
  mkContactBlock
  mkJoinToFriendTooltip
}
