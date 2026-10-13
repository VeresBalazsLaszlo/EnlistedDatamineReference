import "%ui/control/gui_buttons.nut" as JB
import "%ui/hud/state/voice_chat.nut" as membersSpeaking
import "%ui/userstats/serverTime.nut" as serverTime
import "%enlSqGlob/userInfo.nut" as userInfo
import "%ui/components/faComp.nut" as faComp
import "%ui/components/checkbox.nut" as checkbox
import "%ui/mpRoom/mkPlayerTooltip.nut" as mkPlayerTooltip
import "%ui/complaints/complainWnd.nut" as complain
import "%ui/components/spinner.nut" as spinner
from "%enlSqGlob/game_mods_constant.nut" import MOD_BY_VERSION_URL
from "%ui/components/contextMenu.nut" import addContextMenu
from "%ui/components/msgbox.nut" import showMsgbox, showMessageWithContent
from "%ui/style/fontsStyle.nut" import fontBody, fontHeading2
from "%ui/mpRoom/enlRoomState.nut" import roomMembers, room, startSession, connectToHost,
  canOperateRoom, leaveRoom, lobbyStatus, isLocalDedicated, canStartWithLocalDedicated,
  roomTeamArmies, cancelSessionStart, myInfoUpdateInProgress, isHostInGame, roomTeamsNumber
from "%ui/mainMenu/mkActiveBoostersMark.nut" import mkActiveBoostersMark
from "%ui/style/designConst.nut" import bigPadding, maxContentWidth, defTxtColor, commonBtnHeight,
  smallPadding, brightAccentColor, darkTxtColor, midPadding, startBtnWidth, accentColor, rowBg,
  isWide, disabledBgColor
from "%ui/style/colors.nut" import BtnActionBgDisabled, BtnActionTextNormal
from "%ui/gameModes/createEventRoomState.nut" import isEditEventRoomOpened
from "%ui/gameModes/eventModeStyle.nut" import verticalGap, localPadding, localGap
from "%ui/mpRoom/myRoomMemberParams.nut" import setMyArmy, curTeam, setMyTeam, canChangeTeam,
  isReady, setReady, hasBalanceCheckedByEntrance
from "%ui/soldiers/squads_list.ui.nut" import mkSquadsList
from "%ui/mainMenu/mkMenuScene.nut" import mkMenuScene
from "%ui/gameModes/eventModesPkg.nut" import footer, mkPanel, teamsColors, armyIconSize
from "%ui/gameModes/eventRoomInfo.nut" import mkEventRoomInfo
from "%ui/soldiers/components/armyPackage.nut" import mkArmySimpleIcon, mkArmyIcon
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/components/textButton.nut" import Regular
from "%ui/style/cursors.nut" import setTooltip
from "app" import get_session_id
from "%sqstd/math.nut" import abs
from "%ui/mpRoom/components/memberComps.nut" import memberName, mkStatusImg
from "%ui/state/client_user_rights.nut" import getPenaltyExpiredTime
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/gameModes/sandbox/customMissionState.nut" import requestModManifest, receivedModInfos
from "%dngscripts/platform.nut" import is_console
from "%ui/soldiers/army_select.ui.nut" import mkArmyBtn
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/ui_library.nut" import *

let { LobbyStatus } = require("%ui/mpRoom/enlRoomState.nut")
let memberStatuses = require("%ui/mpRoom/roomMemberStatuses.nut")

let startBtnSize = [startBtnWidth, hdpx(80)]
const spinnerSize = hdpx(30)
let waitingSpinner = spinner(spinnerSize)
const teamBlockHeaderHeight = hdpxi(48)
let rowHeight = hdpx(28)
let cellGap = isWide ? localGap : hdpx(5)
let startBtnStyle = {
  defBgColor = brightAccentColor
  defTxtColor = darkTxtColor
}

let needModDownloadButton = Computed(function() {
  if (is_console || canOperateRoom.get())
    return false
  let modId = room.get()?.public.modId
  if (modId != null && receivedModInfos.get().findindex(@(mods) mods.id == modId) == null)
    return true
  return false
})

let isDisbalanced = Computed(function() {
  let roomData = room.get()
  let playersTeamA = roomMembers.get().filter(@(player) player?.public.team == 0
    && player?.public.status == "IN_LOBBY_READY") ?? []
  let playersTeamB = roomMembers.get().filter(@(player) player?.public.team == 1
    && player?.public.status == "IN_LOBBY_READY") ?? []
  let playersOfCurTeam = roomMembers.get()
    .filter(@(player) player?.public.team == curTeam.get()) ?? []
  let playersOfEnemyTeam = roomMembers.get()
    .filter(@(player) player?.public.team == (1 - curTeam.get())) ?? []
  let maxDisbalance = roomData?.public.maxDisbalance ?? 0
  let disbalanceOfReadyPlayers = maxDisbalance != 0
    && abs(playersTeamA.len() - playersTeamB.len()) >= maxDisbalance
  return disbalanceOfReadyPlayers && playersOfCurTeam.len() > playersOfEnemyTeam.len()
})

let mkStatus = @(text) {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = accentColor
  behavior = Behaviors.TextArea
  text
}.__update(fontBody)

let mkStatusWithSpinner = @(text) {
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  gap = bigPadding
  children = [
    waitingSpinner
    {
      rendObj = ROBJ_TEXT
      color = accentColor
      text
    }.__update(fontBody)
  ]
}

let mkStatusDisbalance = @(public)
  mkStatus(loc("multiplayer/playersTeamDisbalance", {maxDisbalance = public?.maxDisbalance ?? 0}))

let mkStatusPlayers = @(public)
  mkStatus(loc("multiplayer/playersTeamLessThanMin", {minSize = public?.playersToStart ?? 0}))

let mkStatusWaiting = @(public) function() {
  let countDownTimer = (public?.sessionLaunchTime ?? 0) -  serverTime.get()
  return {
    watch = serverTime
    size = FLEX_H
    children = countDownTimer > 0
      ? mkStatus(loc("lobby/creatingBattleIn", {timeToStart = countDownTimer}))
      : mkStatusWithSpinner(loc("lobby/creatingBattle"))
  }
}

let statusCtor = {
  launched = "lobby/gameInProgress"
  ready_to_launch = "lobby/rdyToStart"
  game_in_progress = "memberStatus/inBattle"
  game_in_progress_no_launched = "memberStatus/inBattle"
  creating_game = @(public) mkStatusWaiting(public)
  teams_disbalanced = @(public) mkStatusDisbalance(public)
  not_enough_players = @(public) mkStatusPlayers(public)
  waiting_before_launch = @(public) mkStatusWaiting(public)
}.map(@(status) typeof status == "function" ? status : @(_) mkStatus(loc(status)))

let isMirrored = @(team) team == 1

let joinBtn = @(sf, team) {
  size = SIZE_TO_CONTENT
  rendObj = ROBJ_BOX
  hplace = isMirrored(team) ? ALIGN_LEFT : ALIGN_RIGHT
  valign = ALIGN_CENTER
  borderWidth = sf & S_HOVER ? hdpx(1) : 0
  halign = ALIGN_CENTER
  padding = midPadding
  children = {
    rendObj = ROBJ_TEXT
    text = loc("Join")
  }
}

function armyIconsBlock(shoudBeMirrowed, armies = []) {
  let armyIcons = armies.map(@(armyId) mkArmyIcon(armyId, armyIconSize, { margin = 0 }))
  return {
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    hplace = shoudBeMirrowed ? ALIGN_RIGHT : ALIGN_LEFT
    gap = smallPadding
    children = shoudBeMirrowed ? armyIcons.reverse() : armyIcons
  }
}

let teamBlockHeader = @(sf, team) function() {
  let children = [
    armyIconsBlock(isMirrored(team), roomTeamArmies.get()?[team] ?? [])
    team == curTeam.get() || !canChangeTeam.get() ? { size = FLEX } : joinBtn(sf, team)
  ]
  return {
    watch = [roomTeamArmies, curTeam, canChangeTeam]
    size = FLEX
    gap = localGap
    valign = ALIGN_CENTER
    padding = bigPadding
    children = isMirrored(team) ? children : children.reverse()
  }
}

let unavailableTeamHeaderText = {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  padding = bigPadding
  vplace = ALIGN_CENTER
  text = loc("mod/unavailableTeam")
}.__update(fontBody)

let unavailableTeamHeader = {
  rendObj = ROBJ_SOLID
  size = const [FLEX, teamBlockHeaderHeight]
  padding = [smallPadding, bigPadding]
  valign = ALIGN_CENTER
  color = disabledBgColor
  children = unavailableTeamHeaderText
}

function mkTeamBlockHeader(team, isAvailable) {
  if (!isAvailable)
    return unavailableTeamHeader

  function joinTeam() {
    if (!canChangeTeam.get())
      return

    setMyTeam(team)
  }
  return watchElemState(@(sf) {
    rendObj = ROBJ_SOLID
    size = const [FLEX, teamBlockHeaderHeight]
    behavior = Behaviors.Button
    onClick = @() joinTeam()
    padding = [smallPadding, bigPadding]
    valign = ALIGN_CENTER
    color = teamsColors[team].defBgColor
    children = teamBlockHeader(sf, team)
  })
}

let speakIcon = faComp("microphone")

function mkMemberStatus(status, name) {
  let { icon = null, iconColor = defTxtColor } = memberStatuses?[status]
  let isSpeaking = Computed(@() membersSpeaking.get()?[name] ?? false)
  return @() {
    watch = isSpeaking
    children = isSpeaking.get() ? speakIcon
      : icon != null ? mkStatusImg(icon, iconColor)
      : null
  }
}

function mkCell(column, player) {
  let { content, width = rowHeight, halign = ALIGN_CENTER } = column
  return {
    size = [width, rowHeight]
    halign
    valign = ALIGN_CENTER
    children = content(player)
  }
}

let columns = [
  {
    content = @(player) memberName(player.nameText, player.public?.nickFrame)
    width = FLEX
    halign = ALIGN_RIGHT
  }
  {
    content = @(player) "armies" in player.public ? mkArmySimpleIcon(player.public.army, armyIconSize, { margin = 0 }) : null
  }
  {
    content = @(player) mkMemberStatus(player.public?.status, player.name)
  }
]

let columnsMirrored = columns
  .map(@(col) "halign" not in col ? col
    : col.__merge({
        halign = col.halign == ALIGN_RIGHT ? ALIGN_LEFT
          : col.halign == ALIGN_LEFT ? ALIGN_RIGHT
          : ALIGN_CENTER
      }))
  .reverse()


function playersListRow(player, idx, team) {
  let cols = isMirrored(team) ? columnsMirrored : columns
  return watchElemState(@(sf) {
    rendObj = ROBJ_SOLID
    watch = membersSpeaking
    size = [FLEX, rowHeight]
    flow = FLOW_HORIZONTAL
    behavior = Behaviors.Button
    onClick = function(event) {
      let { userId } = userInfo.get()
      if (player.userId == userId)
        return

      addContextMenu(event.screenX + 1, event.screenY + 1, fsh(30), [{
        text = loc("btn/complain")
        action = @() complain(get_session_id() ?? 0, player.userId, player.name, player?.platform)
      }])
    }
    onHover = @(on) setTooltip(on ? mkPlayerTooltip(player) : null)
    padding = [0, cellGap]
    halign = isMirrored(team) ? ALIGN_LEFT : ALIGN_RIGHT
    valign = ALIGN_CENTER
    color = rowBg(sf, idx, false)
    gap = cellGap
    children = cols.map(@(c) mkCell(c, player))
  })
}

let unavailableTeamText = {
  rendObj = ROBJ_TEXTAREA
  size = FLEX
  behavior = Behaviors.TextArea
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  color = defTxtColor
  text = loc("mod/oneTeamDescription")
}.__update(fontBody)

let mkTeamBlockPlayersList = @(team) function() {
  let scrollAlign = isMirrored(team) ? ALIGN_LEFT : ALIGN_RIGHT
  return makeVertScroll(@() {
    watch = roomMembers
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = roomMembers.get().filter(@(val) val.public?.team == team)
      .map(@(player, idx) playersListRow(player, idx, team))
  },{
    scrollAlign
    styling = thinStyle
  })
}

let armiesChooseBlock = @() {
  watch = [roomTeamArmies, curTeam]
  flow = FLOW_HORIZONTAL
  children = roomTeamArmies.get()?[curTeam.get()].map(@(armyId)
    mkArmyBtn(armyId, Computed(@() armyId == curArmy.get()), setMyArmy))
}

let playersBlockHeader = @(teams, availableTeamsCount) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  children = teams.map(function(_, team) {
    let isAvailable = team <= availableTeamsCount - 1
    return mkTeamBlockHeader(team, isAvailable)
  }).insert(1, armiesChooseBlock)
}

let playersBlock = @(teams, availableTeamsCount) {
  size = FLEX
  flow = FLOW_HORIZONTAL
  gap = localPadding
  children = teams.map(function(_, team) {
    let isAvailable = team <= availableTeamsCount - 1
    return isAvailable ? mkTeamBlockPlayersList(team) : unavailableTeamText
  })
}


function leftBlock() {
  let squads_list = mkSquadsList()
  return {
    size = FLEX_V
    halign = ALIGN_CENTER
    children = squads_list
  }
}

let centralBlock = @() {
  watch = [roomTeamArmies, roomTeamsNumber]
  size = FLEX
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = [0, localPadding]
  gap = localGap
  children = [
    playersBlockHeader(roomTeamArmies.get(), roomTeamsNumber.get())
    playersBlock(roomTeamArmies.get(), roomTeamsNumber.get())
  ]
}

let mkStatusBlock = @(roomData, status) @() {
  watch = isDisbalanced
  size = FLEX_H
  children = isDisbalanced.get()
    ? statusCtor.teams_disbalanced(roomData?.public)
    : statusCtor?[status](roomData?.public)
}

let battleButtonParams = {
  size = startBtnSize
  halign = ALIGN_CENTER
  margin = 0
  borderWidth = hdpx(0)
  textParams = { rendObj=ROBJ_TEXT }.__update(fontHeading2)
  style = { BgNormal = accentColor }
  hotkeys = [["^J:Y", { description = { skip = true }}]]
}

let mkDisabledStyle = @(isClickable) {
    BgNormal = BtnActionBgDisabled
  }.__update(isClickable ? {} : {
      TextDisabled = BtnActionTextNormal
      BgDisabled = BtnActionBgDisabled
    })

let getInactiveBattleButtonParams = @(isClickable)
  battleButtonParams.__merge({
    isEnabled = isClickable
    style = mkDisabledStyle(isClickable)
  })

let infoSpinner = spinner(spinnerSize, 0.5,0xFF000000 ).__update({
  transform = true
  animations = [{ prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = InCubic }]
})

let infoUpdateSpinner = @() {
  watch = myInfoUpdateInProgress
  vplace = ALIGN_CENTER
  children = myInfoUpdateInProgress.get() ? infoSpinner : null
}

let mkButtonWithActiveBoostersMark = @(button) {
  size = FLEX_H
  children = [
    button
    button == null ? null : mkActiveBoostersMark({ hplace = ALIGN_RIGHT, pos = [hdpx(20), bigPadding] })
    infoUpdateSpinner
  ]
}

function showPenaltyWarn(expTime) {
  let timeText = Computed(function() {
    let time = expTime - serverTime.get()
    if (time <= 0)
      return loc("loneFighterNoPenalty")
    return loc("loneFighterPenalty", {
      time = secondsToHoursLoc(time)
    })
  })
  showMessageWithContent({
    content = @() {
      watch = timeText
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = timeText.get()
    }.__update(fontBody)
    buttons = [{ text = loc("Ok"), isCancel = true }]
  })
}

function mkBattleButton(text, onClick, params = {}) {
  local action = onClick
  let penaltyExpTime = getPenaltyExpiredTime("USERSTATS", "USERSTATS", "LONE_FIGHTERS") ?? 0
  if (room.get()?.public.mode == "LONE_FIGHTERS" && penaltyExpTime.get() != 0) {
    action = @() showPenaltyWarn(penaltyExpTime.get())
  }
  return mkButtonWithActiveBoostersMark(Regular(text, action, battleButtonParams.__merge(params)))
}
let mkInactiveBattleButton = @(text, onClick)
  mkButtonWithActiveBoostersMark(
    Regular(text, onClick, getInactiveBattleButtonParams(onClick != null)))

let localDedicCheckbox = checkbox(isLocalDedicated,
  {
    text = loc("Start local dedicated")
    color = defTxtColor
  }.__update(fontBody))


let readyButton = mkBattleButton(loc("contact/Ready"), function() {
  let penaltyExpTime = getPenaltyExpiredTime("USERSTATS", "USERSTATS", "LONE_FIGHTERS") ?? 0
  if (room.get()?.public.mode == "LONE_FIGHTERS" && penaltyExpTime.get() != 0) {
    showPenaltyWarn(penaltyExpTime.get())
    return
  }
  setReady(true)
}, { style = startBtnStyle })

let waitingMsgbox = @() showMsgbox({
    text = loc("msg/waitingInProgress")
    buttons = [{ text = loc("Close"), isCancel = true,
      customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }]
  })

let notReadyButton = @(isWaitLauch) mkInactiveBattleButton(loc("contact/notReady"),
  @() isWaitLauch ? waitingMsgbox() : setReady(false))
let disbalanceButton = mkInactiveBattleButton(loc("lobby/disbalance"), null)

function leaveRoomConfirm() {
  showMsgbox({
    text = loc("msg/leaveRoomConfirm")
    buttons = [
      { text = loc("Yes"),
        action = function() {
          hasBalanceCheckedByEntrance.set(false)
          leaveRoom()
        },
        isCurrent = true }
      { text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
    ]
  })
}

function notEnoughPlayersMsg(public) {
  showMsgbox({
    text = mkStatus(loc("multiplayer/playersTeamLessThanMin", {minSize = public?.minSize ?? 0}))
    buttons = [
      { text = loc("Ok"), isCancel = true }
    ]
  })
}

let backButton = {
  size = [FLEX, commonBtnHeight]
  children = Regular(loc("BackBtn"), leaveRoomConfirm, {
    size = FLEX
    hotkeys = [[$"^{JB.B} | Esc", { action = leaveRoomConfirm , description = { skip = true } }]]
  })
}


function startSessionWithMsg() {
  let hasAllReady = roomMembers.get().findvalue(@(m) !(m?.public.isReady ?? false)) == null
  let penaltyExpTime = getPenaltyExpiredTime("USERSTATS", "USERSTATS", "LONE_FIGHTERS") ?? 0
  if (room.get()?.public.mode == "LONE_FIGHTERS" && penaltyExpTime.get() != 0) {
    showPenaltyWarn(penaltyExpTime.get())
    return
  }
  if (hasAllReady)
    startSession()
  else
    showMsgbox({
      text = loc("msg/notAllPlayersReady")
      buttons = [
        { text = loc("Yes"), action = startSession, isCurrent = true }
        { text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
      ]
    })
}

let mkStartButton = @(status, canOperate, roomData, isWaitLauch) function() {
  local children = null
  let readyBtn = isReady.get() ? notReadyButton(isWaitLauch) : readyButton
  if (status == LobbyStatus.ReadyToStart || status == LobbyStatus.TeamsDisbalanced)
    children = canOperate
        ? [
            canStartWithLocalDedicated.get() ? localDedicCheckbox : null
            mkBattleButton(loc("lobby/startGameBtn"), startSessionWithMsg, {
              style = startBtnStyle
            })
          ]
      : isDisbalanced.get()
        ? disbalanceButton
      : readyBtn
  else if (status == LobbyStatus.GameInProgressNoLaunched)
    children = mkBattleButton(loc("lobby/playBtn"), function() {
      isHostInGame.set(true)
      connectToHost()
    })
  else if (status == LobbyStatus.NotEnoughPlayers)
    children = canOperate ? mkInactiveBattleButton(loc("not_enough_players"),
      @() notEnoughPlayersMsg(roomData?.public))
    : readyBtn
  else if (status == LobbyStatus.WaitForDedicatedStart)
    children = canOperate
      ? {
          size = [SIZE_TO_CONTENT, startBtnSize[1]]
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
          color = accentColor
          rendObj = ROBJ_TEXT
          text = loc("Wait for dedicated start")
        }
      : readyBtn
  else if (status != LobbyStatus.GameInProgress)
    children = canOperate ? null : readyBtn

  return {
    watch = [canStartWithLocalDedicated, isReady, roomMembers, curTeam, isDisbalanced]
    size = [startBtnSize[0], SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children
  }
}

let changeAttributesRoomBtn = {
  size = [FLEX, commonBtnHeight]
  children = Regular(loc("changeAttributesRoom"), @() isEditEventRoomOpened.set(true), {
    size = FLEX
    hotkeys = [["^J:X", {  description = { skip = true } }]]
  })
}

let cancelButton = {
  size = [FLEX, commonBtnHeight]
  children = Regular(loc("Cancel"), @() cancelSessionStart(), {
    size = FLEX
    hotkeys = [[$"^{JB.B} | Esc",
      { action = cancelSessionStart , description = { skip = true } }]]
  })
}

let membersCount = Computed(@()
  roomMembers.get().filter(@(player) player.public?.host == null).len())

function rightBlock() {
  let roomData = room.get()
  let status = lobbyStatus.get()
  let canOperate = canOperateRoom.get()
  let isWaitLauch = status == LobbyStatus.WaitingBeforeLauch
  let hasBackBtn = !canOperate || !isWaitLauch
  let hasCancelBtn = canOperate && isWaitLauch
  let isGameInPrepare = status == LobbyStatus.ReadyToStart
    || status == LobbyStatus.NotEnoughPlayers
    || status == LobbyStatus.TeamsDisbalanced
  let canChangeRoom = canOperate && isGameInPrepare

  return {
    watch = [room, membersCount, lobbyStatus, canOperateRoom, needModDownloadButton]
    size = [startBtnSize[0], FLEX]
    flow = FLOW_VERTICAL
    gap = verticalGap
    children = [
      mkPanel({
        size = FLEX
        children = mkEventRoomInfo(roomData.public.__merge({
          membersCnt = membersCount.get()
        }))
      })
      {
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = [
          mkStatusBlock(roomData, status)
          mkStartButton(status, canOperate, roomData, isWaitLauch)
          needModDownloadButton.get()
            ? Regular(loc("mods/downloadFromLobby"), function() {
                let { modId, modVersion } = room.get().public
                let urlToDownload = MOD_BY_VERSION_URL.subst(modId, modVersion)
                requestModManifest(urlToDownload)
              }, { size = FLEX_H })
            : null
          canChangeRoom ? changeAttributesRoomBtn : null
          hasCancelBtn ? cancelButton
            : hasBackBtn ? backButton
            : null
        ]
      }
    ]
  }
}
let lobbyContent = {
  size = FLEX
  flow = FLOW_HORIZONTAL
  maxWidth = maxContentWidth
  hplace = ALIGN_CENTER
  gap = bigPadding
  transform = true
  children = [
    leftBlock
    centralBlock
    rightBlock
  ]
}

let topBar = {
  size = FLEX
}

let lobbyWindow = mkMenuScene(topBar, lobbyContent, footer)

function createdRoomWnd() {
  return {
    size = FLEX
    halign = ALIGN_CENTER
    rendObj = ROBJ_WORLD_BLUR_PANEL
    fillcolor = Color(250,250,150,255)
    children = lobbyWindow
  }
}

return createdRoomWnd