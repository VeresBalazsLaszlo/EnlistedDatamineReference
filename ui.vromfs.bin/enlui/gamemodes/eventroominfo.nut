import "%ui/gameModes/getPlayersCountInRoomText.nut" as getPlayersCountInRoomText
import "%ui/gameModes/getMissionInfo.nut" as getMissionInfo
import "%ui/components/colorize.nut" as colorize
from "%enlSqGlob/crossnetwork_state.nut" import crossnetworkPlay, isCrossplayOptionNeeded, CrossplayState
from "string" import format
from "dagor.time" import unixtime_to_local_timetbl
from "%ui/gameModes/roomsPkg.nut" import txt, textArea
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import defTxtColor, titleTxtColor, smallPadding, midPadding, accentTitleTxtColor
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/clusterState.nut" import clusterLoc
from "%ui/gameModes/eventRoomsListState.nut" import selRoom
from "%ui/mpRoom/enlRoomState.nut" import isInRoom
from "%ui/helpers/remap_nick.nut" import remap_others
from "%ui/soldiers/model/config/gameProfile.nut" import allArmiesInfo
from "%ui/campaigns/armiesConfig.nut" import getArmyName
from "%ui/ui_library.nut" import *

let { lockIcon, iconInBattle, iconPreparingBattle } = require("%ui/gameModes/roomsPkg.nut")


const textAreaOffset = hdpx(10)
const infoRowHeight = hdpx(40)
const headerTxtColor = 0xFF808080

let defTxtStyle = {
  color = defTxtColor
}.__update(fontSub)

let headerTxtStyle = {
  color = headerTxtColor
}.__update(fontSub)

let accentTxtStyle = {
  color = accentTitleTxtColor
}.__update(fontSub)

const SHOW_MISSIONS_WHEN_HIDDEN = 3

let optLoc = @(v) v == null ? null : loc($"options/{v}", v)
let selRoomId = Computed(@() selRoom.get()?.roomId)
let hTxt = @(text) {
    rendObj = ROBJ_TEXT
    text
  }.__update(headerTxtStyle)

let mkInfoTextRow = @(header, text) {
    size = FLEX_H
    minHeight = infoRowHeight
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      hTxt($"{header}")
      txt(text).__update({ halign = ALIGN_RIGHT })
    ]
  }

let statusRow = @(icon, text){
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  children = [
    icon
    {
      rendObj = ROBJ_TEXT
      text
    }.__update(defTxtStyle)
  ]
}

let mkRoomStatusRow = @(status) {
  size = FLEX_H
  minHeight = infoRowHeight
  valign = ALIGN_CENTER
  children = [
    hTxt($"{loc("options/roomStatus")}")
    status == "launching" || status == "launched"
      ? statusRow(iconInBattle, loc("memberStatus/inBattle"))
      : statusRow(iconPreparingBattle, loc("lobby/preparationBattle"))
  ]
}

let mkShowMoreButton = @(count, cb) count <= 0 ? null
  : watchElemState(@(sf){
      rendObj = ROBJ_FRAME
      border = [0, 0, hdpx(1), 0]
      padding = const [hdpx(2), 0, hdpx(2), 0]
      size = FLEX_H
      behavior = Behaviors.Button
      flow = FLOW_HORIZONTAL
      margin = const [ hdpx(10), 0]
      onClick = cb
      children = txt(loc("options/showMore", { count })).__update({
        halign = ALIGN_CENTER,
        color = sf & S_HOVER ? titleTxtColor : defTxtColor
      })
  })

let getBoolText = @(value) value ? loc("quickchat/yes") : loc("quickchat/no")

function mkMissionText(v) {
  let mCfg = getMissionInfo(v)
  let mName = loc(mCfg.locId)
  let mTypeLocId = mCfg.typeLocId
  let mLabel = mTypeLocId == null ? mName
    : loc("missionNameWithType", { mName, mType = loc(mTypeLocId) })
  return txt(mLabel).__update({ halign = ALIGN_RIGHT,
                                behavior = Behaviors.Marquee,
                                delay = 3.0
                                speed = 30 })
}

let isMissionsExpanded = Watched(false)
let toggleMissionsExpand = @() isMissionsExpanded.set(!isMissionsExpanded.get())

selRoomId.subscribe(@(_) isMissionsExpanded.set(false))

function mkExpandedMissions(missions){
  if (missions.len() <= 0)
    return null
  let isOverflow = missions.len() > SHOW_MISSIONS_WHEN_HIDDEN
  return function(){
    let sliceNumber = isMissionsExpanded.get() && isOverflow
      ? missions.len()
      : SHOW_MISSIONS_WHEN_HIDDEN
    return {
      watch = isMissionsExpanded
      size = FLEX_H
      flow = FLOW_VERTICAL
      padding = [midPadding , 0]
      minHeight = infoRowHeight
      children = [hTxt($"{loc("options/missions")}")]
        .extend(missions.slice(0, sliceNumber).map(mkMissionText)
        .append(mkShowMoreButton(missions.len() - sliceNumber, toggleMissionsExpand)))
    }
  }
}

let mkArmyListItem = @(armyId) @() {
  watch = allArmiesInfo
  size = FLEX_H
  halign = ALIGN_RIGHT
  children = txt(getArmyName(armyId), SIZE_TO_CONTENT)
}

let mkArmyList = @(armies) {
  size = FLEX_H
  minHeight = infoRowHeight
  padding = const [textAreaOffset, 0, 0, 0]
  children = [
    hTxt($"{loc("options/armies")}")
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      children = armies.map(mkArmyListItem)
    }
  ]
}

function mkRoomCreateTime(room) {
  let tm = unixtime_to_local_timetbl(room?.cTime ?? 0)
  return {
    size = FLEX_H
    minHeight = infoRowHeight
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      hTxt($"{loc("options/createTime")}")
      !room?.isPrivate ? null
        : lockIcon.__merge({
            halign = ALIGN_RIGHT
          })
      txt(format("%02d:%02d", tm.hour, tm.min)).__update({ halign = ALIGN_RIGHT })
    ]
  }
}

let reducedXpWarning = textArea(loc("rooms/reducedXpNotEnoughPlayersWarning"),
  { color = titleTxtColor })
let modsXpWarning = textArea(loc("mods/econRules"), { color = titleTxtColor })
let modDescription = @(description) {
  size = FLEX_H
  margin = const [0,0, hdpx(20), 0]
  children = textArea(
    loc("mods/modDescription", { description = colorize(defTxtColor, description) }),
    { color = headerTxtColor }
  )
}

let mkModHeader = @(name, mode) {
  flow = FLOW_VERTICAL
  size = FLEX_H
  gap = midPadding
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      size = FLEX_H
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = name
    }.__update(accentTxtStyle)
    {
      rendObj = ROBJ_TEXT
      hplace = ALIGN_CENTER
      text = mode
    }.__update(defTxtStyle)
  ]
}

function mkRoomInfo(room){
  let isMod = room?.scene == null
  let { armiesTeamA = [], armiesTeamB = [] } = room
  let armies = clone armiesTeamA
  armiesTeamB.each(function(v) {
    if (!armies.contains(v))
      armies.append(v)
  })

  return @() {
    watch = [crossnetworkPlay, isInRoom, isCrossplayOptionNeeded]
    size = FLEX_H
    flow = FLOW_VERTICAL
    padding = [0, smallPadding]
    children = [
      isMod ? mkModHeader(room?.modName,  loc(room?.mode ?? "")) : null
      mkRoomCreateTime(room)
      isInRoom.get() ? null : mkRoomStatusRow(room?.launcherState ?? "")
      mkInfoTextRow(loc("rooms/Creator"), remap_others(room?.creator ?? ""))
      mkInfoTextRow(loc("current_mode"), loc(room?.mode ?? ""))
      mkInfoTextRow(loc("options/difficulty"), optLoc(room?.difficulty))
      mkArmyList(armies)
      mkInfoTextRow(loc("rooms/PlayersInRoom"), getPlayersCountInRoomText(room))
      mkInfoTextRow(loc("options/botCount"), room?.botpop ?? 0)
      room?.crossplay != null && isCrossplayOptionNeeded.get() && crossnetworkPlay.get() != CrossplayState.OFF
        ? mkInfoTextRow(loc("options/crossplay"), loc($"option/crossplay/{room.crossplay}"))
        : null
      room?.voteToKick == null ? null
        : mkInfoTextRow(loc("options/voteToKick"), getBoolText(room?.voteToKick))
      mkInfoTextRow(loc("quickMatch/Server"), clusterLoc(room?.cluster ?? ""))
      isMod ? mkInfoTextRow(loc("options/numTeams"), room?.numTeams ?? 2) : null
      isMod ? modDescription(room?.modDescription ?? "") : null
      mkExpandedMissions(room?.scenes ?? [])
      isMod ? modsXpWarning : reducedXpWarning
    ]
  }
}

let mkEventRoomInfo = @(room) makeVertScroll(mkRoomInfo(room), { styling = thinStyle })

let curEventRoomInfo = @(){
  watch = selRoomId
  size = FLEX
  children = selRoomId.get() == null
    ? txt(loc("noRoomSelected"))
      .__update({ halign = ALIGN_CENTER, vplace = ALIGN_CENTER })
    : @() {
        watch = selRoom
        size = FLEX
        children = mkEventRoomInfo(selRoom.get())
      }
}

return {
  mkEventRoomInfo
  curEventRoomInfo
}