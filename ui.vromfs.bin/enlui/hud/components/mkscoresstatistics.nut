import "%ui/components/scrollbar.nut" as scrollbar
import "%ui/hud/style.nut" as style
import "%ui/components/checkbox.nut" as checkbox
import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/components/teamIcon.nut" import getArmyIcon
from "%enlSqGlob/crossnetwork_state.nut" import crossnetworkPlay, CrossplayState
from "%ui/style/fontsStyle.nut" import fontSub
from "matching.errors" import INVALID_SQUAD_ID, INVALID_SESSION_ID
from "%ui/style/cursors.nut" import setTooltip
from "%ui/hud/components/mkScoresStatisticsUtils.nut" import sortPlayers
from "%ui/hud/components/scoreTableColumns.nut" import getScoreTableColumns, LINE_H
from "%ui/style/designConst.nut" import smallPadding, bigPadding
from "%ui/ui_library.nut" import *

let HEADER_H = LINE_H
const MAX_ROWS_TO_SCROLL = 20
const MAX_ROWS_IN_REPLAY = 14

const borderWidth = hdpx(1)
const statisticsRowBgDarken = Color(0, 0, 0, 50)
const statisticsRowBgDisabled = Color(0, 0, 0, 20)
const statisticsRowBgLighten = Color(10, 10, 10, 50)
const statisticsRowBgHover = Color(25, 25, 25, 35)

const yourTeamColor = Color(18, 68, 91)
const enemyTeamColor = Color(107, 48, 45)

let statisticsScrollHandler = ScrollHandler()
let isDesertersHidden = Watched(false)

let crossPlayInfo = @(){
  watch = crossnetworkPlay
  rendObj = ROBJ_TEXT
  color = style.DEFAULT_TEXT_COLOR
  text = crossnetworkPlay.get() == CrossplayState.OFF ?  loc("crossplay/off")
    : crossnetworkPlay.get() == CrossplayState.CONSOLES ? loc("crossplay/consoles")
    : null
}.__update(fontSub)

function playerElem(columns, params, idx, playerData = null, borderColor = 0x00000000, slots=null, isMyTeam = false) {
  playerData = clone(playerData ?? {})
  let isInMatchingSlots = slots==null ? true : idx<slots
  playerData.isInMatchingSlots <- isInMatchingSlots
  local bgColor = (idx % 2) ? statisticsRowBgDarken : statisticsRowBgLighten
  if (!isInMatchingSlots)
    bgColor = statisticsRowBgDisabled
  idx ++
  let player = playerData?.player
  let stateFlags = Watched(0)

  return @() {
    key = player? playerData?.eid : null
    watch = stateFlags
    size = const [FLEX, LINE_H]
    flow = FLOW_HORIZONTAL
    gap = -borderWidth
    behavior = (player && params?.isInteractive) ? Behaviors.Button : null
    onElemState = @(sf) stateFlags.set(sf)
    children = columns.map(function (c) {
      if ((c?.showAlliesOnly ?? false) == true && isMyTeam == false)
        return null
      return {
        size = [c.width, FLEX]
        rendObj = ROBJ_BOX
        fillColor = stateFlags.get() & S_HOVER ? statisticsRowBgHover : bgColor
        borderWidth = const [0, borderWidth, 0, borderWidth]
        borderColor
        children = player ? c.mkContent(playerData, params, idx) : null
      }
    })
  }
}

let paneHeader = @(columns, params) {
  rendObj = ROBJ_SOLID
  size = [FLEX, HEADER_H]
  flow = FLOW_HORIZONTAL
  halign = ALIGN_RIGHT
  color = params.teamColor
  gap = -borderWidth
  children = columns.map(function(c) {
      let children = c.mkHeader(params)
      local override = c?.headerOverride ?? {}
      if (c?.locId != null)
        override = override.__merge({
          behavior = params.isInteractive ? Behaviors.Button : null
          inputPassive = true
          onHover = @(on) setTooltip(on ? loc(c.locId) : null)
        })
      return children == null ? null : {
        size = [c.width, FLEX]
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = children
      }.__update(override)
    })
}

let getEnemyTeam = @(teams, playerTeam) teams?.findvalue(@(_, teamId) teamId != playerTeam)

function mkTeamPanel(columns, players, params, minRows, bordersColor, slots, isMyTeam) {
  slots = slots ?? players.len()
  let ret = {
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = players.map(@(player, idx) playerElem(columns, params, idx, player, bordersColor, slots, isMyTeam))
      .extend(array(max(0, minRows - players.len()))
        .map(@(_, idx) playerElem(columns, params, idx + players.len(), null, bordersColor, slots, isMyTeam)))
    clipChildren = true
  }
  ret.children.append({
    size = const [FLEX, hdpx(1)]
    rendObj = ROBJ_SOLID
    color = bordersColor
  })

  return ret
}

function mkTwoColumnsTable(columns, allies, enemies, params, minRows) {
  let { isAllEnemies } = params
  let myTeamStr = params.myTeam.tostring()
  let enemyTeamData = getEnemyTeam(params?.teams, myTeamStr)
  let enemySlots = params?.teamsSlots[enemyTeamData?.teamId]
  let alliesSlots = params?.teamsSlots[params.myTeam]
  let hasAllies = allies.len() > 0 || alliesSlots != null
  let hasEnemies = enemies.len() > 0 || enemySlots != null
  if (!hasAllies && !hasEnemies)
    return null
  let { isReplay = false} = params
  let maxRowsCount = isReplay ? MAX_ROWS_IN_REPLAY : MAX_ROWS_TO_SCROLL

  let scrollWidth = params.scrollIsPossible && minRows > maxRowsCount ? fsh(1) : 0
  let myTeamData = params?.teams[myTeamStr]
  let alliesHeader = !hasAllies ? null : paneHeader(columns, {
    armies = myTeamData?.armies,
    teamIcon = getArmyIcon(myTeamData?.armyId),
    teamText = isAllEnemies ? loc("multiplayerscores/title")
      : isReplay ? loc(myTeamData?.armies[0])
      : loc("debriefing/your_team"),
    addChild = params.additionalHeaderChild?(true)
    teamColor = yourTeamColor
    isInteractive = params?.isInteractive ?? false
  })

  let enemiesHeader = !hasEnemies ? null : paneHeader(columns, {
    armies = enemyTeamData?.armies,
    teamIcon = getArmyIcon(enemyTeamData?.armyId),
    teamText = isReplay ? loc(enemyTeamData?.armies[0]) : loc("debriefing/enemy_team"),
    addChild = params.additionalHeaderChild?(false)
    teamColor = enemyTeamColor
    isInteractive = params?.isInteractive ?? false
  })

  let maxRows = max(enemies.len(), allies.len(), enemySlots ?? 0, alliesSlots ?? 0 )
  let teams = []
  if (hasAllies)
    teams.append(mkTeamPanel(columns, allies, params, maxRows, yourTeamColor, alliesSlots, true))
  if (hasEnemies)
    teams.append(mkTeamPanel(columns, enemies, params, maxRows, enemyTeamColor, enemySlots, false))

  return [
    {
      size = [params.width - scrollWidth, SIZE_TO_CONTENT]
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      hplace = ALIGN_LEFT
      children = [
        alliesHeader
        enemiesHeader
      ]
    }
    params.scrollIsPossible && minRows > maxRowsCount
      ? scrollbar.makeVertScroll({
          size = [params.width - scrollWidth, SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = teams
        },
        {
          size = [FLEX, maxRowsCount * LINE_H]
          scrollHandler = statisticsScrollHandler
        })
      : {
          size = FLEX_H
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = teams
        }
  ]
}

let STATISTICS_VIEW_PARAMS = {
  localPlayerEid = ecs.INVALID_ENTITY_ID
  localPlayerGroupId = INVALID_SQUAD_ID
  localPlayerGroupMembers = null
  myTeam = 1
  width = fsh(132)
  showBg = false
  scrollIsPossible = false
  additionalHeaderChild = null 
  hotkeys = null
  title = null
  interactiveTip = null
  sessionId = INVALID_SESSION_ID
  showDisconnected = false
  scorePrices = {}
  canHideDeserters = false
  isTeamsUnited = false
  isAllEnemies = false
  friends = null
}

function mkTable(players, params = STATISTICS_VIEW_PARAMS) {
  params = STATISTICS_VIEW_PARAMS.__merge(params)

  let { myTeam, localPlayerEid, localPlayerGroupId, localPlayerGroupMembers,
    canHideDeserters, isTeamsUnited, isAllEnemies, friends } = params
  let hasGroupId = localPlayerGroupId != INVALID_SQUAD_ID
  let columns = getScoreTableColumns(params.missionType)
  let hasDeserters = players.findvalue(@(player) player?.isDeserter ?? false) != null
  let hideDesertersObject = hasDeserters && canHideDeserters
    ? {
        padding = [0, bigPadding]
        children = checkbox(isDesertersHidden,
          { text = loc("option/hideDeserters") }.__update(fontSub),
          { setValue = @(_) isDesertersHidden.set(!isDesertersHidden.get()) })
      }
    : null

  return function() {
    let allies = []
    let enemies = []
    let hasGroupMembers = (localPlayerGroupMembers?.len() ?? 0) > 1
    foreach (eid, player in players) {
      if ("team" not in player)
        continue

      let { team, userid = null, result = null, groupId = null, isDeserter = false,
        disconnected = false, player__roomOwner = false, playerBotWithoutStat = null } = player

      if ((isDeserter && isDesertersHidden.get()) || playerBotWithoutStat != null)
        continue

      let playerId = (userid ?? groupId ?? -1).tostring()

      let isGroupmate = hasGroupId && hasGroupMembers && groupId == localPlayerGroupId
      let isAlly = team == myTeam && (!isAllEnemies || isGroupmate)
      let res = {
        player
        eid
        isAlly
        isLocal = eid == localPlayerEid
        isGroupmate
        isFriend = playerId in friends
        sessionId = params.sessionId
        disconnected = params.showDisconnected ? disconnected : false
        isDeserter
        roomOwner = player__roomOwner
        canForgive = params?.canForgivePlayers?[eid.tostring()] ?? false
        haveSessionResult = result != null
      }

      if (isAlly || isTeamsUnited)
        allies.append(res)
      else
        enemies.append(res)
    }

    sortPlayers(allies, params.missionType)
    sortPlayers(enemies, params.missionType)

    let minRows = max(allies.len(), enemies.len())
    return {
      key = "scores"
      watch = isDesertersHidden
      flow = FLOW_VERTICAL
      hotkeys = params.hotkeys
      children = [
        crossPlayInfo
        { size = [params.width, SIZE_TO_CONTENT], children = params.title }
        {
          size = [params.width, SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          halign = ALIGN_BOTTOM
          children = mkTwoColumnsTable(columns, allies, enemies, params, minRows)
        }
        hideDesertersObject
        params.interactiveTip
      ]
    }.__update(!params.showBg ? const {} : {
      rendObj = ROBJ_WORLD_BLUR
      padding = const [0, hdpx(10), hdpx(10), hdpx(10)]
      color = Color(150, 150, 150, 255)
    })
  }
}

return mkTable
