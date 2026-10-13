import "%ui/components/spinner.nut" as spinner
import "%ui/components/exclamation.nut" as exclamation
import "%ui/gameModes/getPlayersCountInRoomText.nut" as getPlayersCountInRoomText
import "%ui/components/faComp.nut" as faComp
from "%ui/gameModes/eventRoomsListState.nut" import curSorting, roomsListError, isRequestInProgress, selectRoom, isRefreshEnabled, roomsList, selRoom
from "string" import format
from "dagor.time" import unixtime_to_local_timetbl
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import defTxtColor, rowBg, midPadding, commonBtnHeight, titleTxtColor, activeTxtColor, isWide, accentTitleTxtColor
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/gameModes/roomsPkg.nut" import txt
from "%ui/gameModes/eventModeStyle.nut" import lockIconSize
from "%ui/gameModes/joinEventRoom.nut" import joinSelEventRoom
from "%ui/gameModes/sandbox/customMissionOfferState.nut" import featuredModsRoomsList
from "%ui/components/textButton.nut" import soundDefault
from "%ui/helpers/time.nut" import secondsToStringLoc
from "%ui/style/cursors.nut" import withTooltip
from "%ui/helpers/remap_nick.nut" import remap_others
from "%ui/soldiers/components/armyPackage.nut" import mkArmySimpleIcon
from "%ui/campaigns/armiesConfig.nut" import getArmyName
from "%ui/ui_library.nut" import *
from "types" import String

let { lockIcon, iconPreparingBattle, iconInBattle, iconMod } = require("%ui/gameModes/roomsPkg.nut")

let waitingSpinner = spinner()

const rowHeight = hdpx(28)
const armyIconHeight = hdpxi(20)
const IN_BATTLE = "launched"
let emptyRoomsInfo = @() {
  size = FLEX
  watch = [roomsListError, isRequestInProgress]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    exclamation(roomsListError.get() != null ? loc($"error/{roomsListError.get()}")
      : loc("noRoomsFound"))
    isRequestInProgress.get() ? waitingSpinner : { size = const [0, hdpx(80)] }
  ]
  animations = [{ prop = AnimProp.opacity, from = 0, to = 1, easing = InCubic, duration = 0.5, play = true }]
}

let isFull = @(room) (room?.membersCnt ?? 0) >= (room?.maxPlayers ?? 0)
let battleIcon = withTooltip(iconInBattle, @() loc("memberStatus/inBattle"))
let preparationIcon = withTooltip(iconPreparingBattle, @() loc("lobby/preparationBattle"))
let modIcon = withTooltip(iconMod, @() loc("mods/roomDescription"))

const creatorColumnWidth  = flex(0.8)
const armiesColumnWidth = flex(0.5)
let playersColumnWidth  = isWide ? flex(0.3) : flex(0.2)
let gameModeColumnWidth = isWide ? flex(2)   : flex(0.9)
const statusColumnWidth = flex(0.6)
const batlleTimeWidth = hdpx(90)

let columnsTable = {
  armies = {
    cell = function(r) {
      let { armiesTeamA = [], armiesTeamB = [] } = r
      let armiesToShow = clone armiesTeamA
      armiesTeamB.each(function(v) {
        if (!armiesToShow.contains(v))
          armiesToShow.append(v)
      })
      return {
        size = const [armiesColumnWidth, SIZE_TO_CONTENT]
        flow = FLOW_HORIZONTAL
        children = armiesToShow.map(@(armyId)
          withTooltip(mkArmySimpleIcon(armyId, armyIconHeight), @() getArmyName(armyId)))
      }
    }
    label = loc("options/armies")
    width = armiesColumnWidth
    sortFunc = @(a, b) (b?.armies.len() ?? 0) <=> (a?.armies.len() ?? 0)
      || (a?.army ?? "") <=> (b?.army ?? "")
  }
  creator = {
    cell = @(r) txt(remap_others(r?.creator ?? ""), creatorColumnWidth)
    label = loc("Creator")
    width = creatorColumnWidth
    sortFunc = @(a, b) (a?.creator ?? "") <=> (b?.creator ?? "")
  }
  players = {
    cell = @(r) txt(getPlayersCountInRoomText(r), playersColumnWidth)
    label = loc("Players")
    width = playersColumnWidth
    defSorting = true
    sortFunc = @(a, b) isFull(b) <=> isFull(a)
      || (b?.membersCnt ?? 0) <=> (a?.membersCnt ?? 0)
  }
  mode = {
    cell = @(r) txt(r?.modName ?? loc(r.mode ?? ""), gameModeColumnWidth)
    label = loc("current_mode")
    width = gameModeColumnWidth
    sortFunc = @(a, b) loc(a.mode ?? "") <=> loc(b.mode ?? "")
  }
  status = {
    cell = function(r) {
      let { launcherState = null, cTime = 0, timeInBattle = 0 } = r
      let isLobbyLaunched = launcherState == IN_BATTLE
      let isLobbyLaunching = launcherState == "launching"
      let tm = unixtime_to_local_timetbl(cTime)
      return {
        size = const [statusColumnWidth, SIZE_TO_CONTENT]
        valign = ALIGN_BOTTOM
        flow = FLOW_HORIZONTAL
        gap = midPadding
        children = [
          isLobbyLaunched || isLobbyLaunching ? battleIcon : preparationIcon
          timeInBattle > 0 && isLobbyLaunched
            ? withTooltip(txt(secondsToStringLoc(timeInBattle), batlleTimeWidth, accentTitleTxtColor),
                @() loc("looby/battleTime"))
            : txt(loc("In lobby"), batlleTimeWidth)
          withTooltip(txt(format("%02d:%02d", tm.hour, tm.min), hdpx(70)),
            @() loc("lobby/creationTime"))
        ]
      }
    }
    label = loc("lobby/status")
    width = statusColumnWidth
    defSorting = true
    sortFunc = @(a, b) ((b?.launcherState == IN_BATTLE) <=> (a?.launcherState == IN_BATTLE)
        && (b?.sessionLaunchTime ?? -1) <=> (a?.sessionLaunchTime ?? -1))
      || (b?.cTime ?? 0) <=> (a?.cTime ?? 0)
  }
  isPrivate = {
    cell = @(r) {
      size = [lockIconSize, SIZE_TO_CONTENT]
      children = r?.hasPassword != null ? withTooltip(lockIcon, @() loc("options/private")) : null
    }
    label = lockIcon
    width = lockIconSize
    sortFunc = @(a, b) (a?.hasPassword == null) <=> (b?.hasPassword == null)
  }
  isMod = {
    cell = @(r) {
      size = [lockIconSize + midPadding, SIZE_TO_CONTENT]
      padding = [0, midPadding, 0, 0]
      halign = ALIGN_LEFT
      hplace = ALIGN_LEFT
      children = r?.scene == null ? modIcon : null
    }
    label = ""
    width = lockIconSize + midPadding
    sortFunc = @(a, b) (a?.scene == null) <=> (b?.scene == null)
  }
}

foreach (id, column in columnsTable) {
  columnsTable[id].name <- id
  if (column?.defSorting)
    curSorting.set({column, isReverse = false})
}

let columns = ["status", "creator", "mode", "armies", "players", "isMod", "isPrivate"]

let mkRoomRow = @(room, idx, isSelected) watchElemState(@(sf) {
  size = const [FLEX, rowHeight]
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  padding = [0, midPadding]
  rendObj = ROBJ_SOLID
  color = rowBg(sf, idx, isSelected)
  gap = isWide ? 0 : midPadding
  children = columns.map(@(ctor) columnsTable[ctor].cell(room))

  behavior = Behaviors.Button
  onClick = @() selectRoom(room.roomId)
  onDoubleClick = joinSelEventRoom
  sound = soundDefault
})

let cellHeaderColor = @(sf, col) curSorting.get().column == col ? titleTxtColor
  : sf & S_HOVER ? activeTxtColor
  : defTxtColor

let headerTxt = @(column) watchElemState(@(sf) {
  size = [column.width, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  behavior = column?.sortFunc ? Behaviors.Button : null
  onClick = @() curSorting.get().column == column
    ? curSorting.mutate(@(val) val.isReverse = !val.isReverse)
    : curSorting.set({column, isReverse = false})
  valign = ALIGN_CENTER
  children = [
    !(column.label instanceof String) ? column.label : {
      rendObj = ROBJ_TEXT
      color = cellHeaderColor(sf, column)
      text = column.label
    }.__update(fontBody)
    curSorting.get().column == column
      ? faComp(curSorting.get().isReverse? "caret-up" : "caret-down", {
          color = cellHeaderColor(sf, column)
          padding = const [0, 0, 0, hdpx(5)]
          fontSize = fontBody.fontSize
          valign = ALIGN_CENTER
        })
      : null
  ]
})


let eventRoomsListHeaderRow = @(cols){
  size = [FLEX, commonBtnHeight]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  padding = midPadding
  color = Color(0,0,0)
  gap = isWide ? 0 : midPadding
  children = cols.map(@(column) headerTxt(columnsTable[column]))
}

let scrollHandler = ScrollHandler()

let mkRoomsList = @(list, selectedRoom, key) @() {
  watch = [list, selectedRoom]
  flow = FLOW_VERTICAL
  size = FLEX
  onAttach = @() isRefreshEnabled.set(true)
  onDetach = @() isRefreshEnabled.set(false)
  key
  children = list.get().len() == 0
    ? emptyRoomsInfo
    : [
        eventRoomsListHeaderRow(columns)
        makeVertScroll({
          size = FLEX_H
          flow = FLOW_VERTICAL
          children = list.get().map(@(r, i) mkRoomRow(r, i, r == selectedRoom.get()))
        },
        {
          needReservePlace = false
          scrollHandler
        })
      ]
}


let eventRoomsList = mkRoomsList(roomsList, selRoom, "commonLobbies")
let modsRoomsList = mkRoomsList(featuredModsRoomsList, selRoom, "modsLobbies")

return {
  eventRoomsList
  modsRoomsList
}