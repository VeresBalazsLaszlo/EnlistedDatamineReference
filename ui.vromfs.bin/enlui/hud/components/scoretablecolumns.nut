import "%ui/components/fontawesome.map.nut" as fa
import "%ui/hud/style.nut" as style
import "%ui/components/armiesPresentation.nut" as armiesPresentation
import "%ui/components/battleHeroAwardIcon.nut" as mkBattleHeroAwardIcon
import "%ui/hud/components/mkAwardsTooltip.nut" as mkAwardsTooltip
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/complaints/complainWnd.nut" as complain
import "%ui/requestForgiveFriendlyFire.nut" as forgive
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/battleHeroesAwards.nut" import BattleHeroesAward, awardPriority, isSoldierKindAward
from "%ui/style/fontsStyle.nut" import fontBody, fontSub, fontawesome
from "matching.errors" import INVALID_USER_ID, INVALID_SESSION_ID
from "%ui/helpers/remap_nick.nut" import remap_others
from "%sqstd/math.nut" import round_by_value
from "%ui/components/contextMenu.nut" import addContextMenu, closeLatestContextMenu
from "%ui/style/cursors.nut" import withTooltip
from "%ui/components/text.nut" import dtext
from "%ui/components/decoratorsPresentation.nut" import frameNick
from "%ui/components/rankPresentation.nut" import rankIconSize
from "dasevents" import SetReplayTarget
from "%ui/components/itemsInfo.nut" import getObjectName
from "%ui/components/soldiersUiComps.nut" import kindIcon, classTooltip
from "%ui/style/designConst.nut" import defTxtColor
from "%ui/ui_library.nut" import *

let colon = loc("ui/colon")
const LINE_H = hdpxi(40)
let NUM_COL_WIDTH = hdpx(45)
let SCORE_COL_WIDTH = hdpx(70)
let TEAM_ICON_SIZE = (0.7 * LINE_H).tointeger()
let bigGap = hdpx(10)
let smallPadding = hdpx(4)
let iconSize = (LINE_H - smallPadding).tointeger()
let tooltipBattleHeroAwardIconSize = [hdpxi(70), hdpxi(70)]

let canComplain = @(playerData) playerData.sessionId != INVALID_SESSION_ID && !playerData.isLocal

let canShowUserProfile = @(playerData) playerData.sessionId != INVALID_SESSION_ID
  && !playerData.isLocal


const TEAM0_TEXT_COLOR_HOVER = Color(210,220,255,120)
const TEAM1_TEXT_COLOR_HOVER = Color(255,220,220,120)
const MY_SQUAD_TEXT_COLOR_HOVER = Color(210,255,220,120)
const INVALID_COLOR = Color(100,100,100,100)
const INVALID_COLOR_HOVER = Color(160,160,160,100)

const disconnectedMultiplier = 0.5
const deserterMultiplier = 0.3
function playerColor(playerData, sf = 0) {
  let isHover = sf & S_HOVER

  if (playerData.isLocal)
    return isHover ? MY_SQUAD_TEXT_COLOR_HOVER : style.MY_SQUAD_TEXT_COLOR

  if (playerData.player.possessed == ecs.INVALID_ENTITY_ID)
    return isHover ? INVALID_COLOR_HOVER : INVALID_COLOR

  let disconnected = playerData.disconnected || !playerData?.isInMatchingSlots

  if (playerData.isAlly)
    return mul_color(
      isHover ? TEAM0_TEXT_COLOR_HOVER : style.TEAM0_TEXT_COLOR,
      disconnected ? disconnectedMultiplier : playerData.isDeserter ? deserterMultiplier : 1
    )

  return mul_color(
    isHover ? TEAM1_TEXT_COLOR_HOVER : style.TEAM1_TEXT_COLOR,
    disconnected ? disconnectedMultiplier : playerData.isDeserter ? deserterMultiplier : 1
  )
}

let rowText = @(text, width, playerData, sf = 0, override = {}) {
  size = [width, LINE_H]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = {
      rendObj = ROBJ_TEXT
      text
      color = playerColor(playerData, sf)
    }.__update(fontSub, override)
}

let mkHeaderIcon = memoize(function(image) {
  return freeze({
    size = [iconSize, iconSize]
    rendObj = ROBJ_IMAGE
    image = Picture(image.endswith(".svg") ? $"!{image}:{iconSize}:{iconSize}" : image)
  })
})

let mkIcon = @(ico, playerData, sf, fontSize = hdpx(20)) {
  vplace = ALIGN_CENTER
  rendObj = ROBJ_TEXT
  font = fontawesome.font
  text = fa[ico]
  color = playerColor(playerData, sf)
  fontSize
  padding = const [hdpx(2), 0]
}

let getFramedNick = @(player, isGroupmate)
  frameNick( 
    remap_others(player.name, !isGroupmate),
    player?.decorators__nickFrame
  )

const squadMemberIconSize = hdpxi(18)
let mkMemberIcon = @(txt, playerData, sf = 0) {
  size = const [SIZE_TO_CONTENT, LINE_H]
  halign = ALIGN_CENTER
  hplace = ALIGN_RIGHT
  valign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = const [squadMemberIconSize, squadMemberIconSize]
      image = Picture("ui/skin#squad_member.svg:{0}:{0}".subst(squadMemberIconSize))
      color = playerColor(playerData, sf)
    }
    {
      rendObj = ROBJ_TEXT
      padding = const [0,0,hdpx(1),hdpx(1)]
      text = txt
      color = Color(0,0,0)
    }.__update(fontSub)
  ]
}

const friendlyFireIconSize = hdpxi(18)
let friendlyFireIcon = {
  size = const [SIZE_TO_CONTENT, LINE_H]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = const [friendlyFireIconSize, friendlyFireIconSize]
      image = Picture("ui/skin#friendly_fire.svg:{0}:{0}".subst(friendlyFireIconSize))
      color = Color(255,0,0)
    }
  ]
}

function mkArmiesIcons(armies) {
  let icons = {}
  foreach (armyId in armies) {
    let { armyColorIcon = null } = armiesPresentation?[armyId]
    if (armyColorIcon != null)
      icons[armyColorIcon] <- true
  }
  return {
    margin = [0, 0, 0, bigGap]
    vplace = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    gap =  -0.35 * TEAM_ICON_SIZE
    children = icons.keys().map(@(icon) {
      rendObj = ROBJ_IMAGE
      size = [TEAM_ICON_SIZE, TEAM_ICON_SIZE]
      image = Picture($"{icon}:{TEAM_ICON_SIZE}:{TEAM_ICON_SIZE}")
    })
  }
}

function mkPlayerClass(playerData, isInteractive, sf) {
  let sKind = playerData.player?.controlled_soldier__sKind ?? ""
  let sClass = playerData.player?.controlled_soldier__sClass ?? ""
  let army = playerData.player?.army ?? ""

  if (sKind == "" || sClass == "" || army == "")
    return null

  return withTooltip({
      margin = [0, bigGap]
      hplace = ALIGN_RIGHT
      vplace = ALIGN_CENTER
      children = kindIcon(sKind, rankIconSize, playerColor(playerData, sf))
    },
    @() isInteractive ? classTooltip(army, sClass, sKind) : null
  )
}

function mkSpawnIcon(playerData, isInteractive, sf) {
  return withTooltip({
    rendObj = ROBJ_IMAGE
    margin = [0, bigGap]
    hplace = ALIGN_RIGHT
    vplace = ALIGN_CENTER
    size = [rankIconSize, rankIconSize]
    color = playerColor(playerData, sf)
    image = Picture($"ui/skin#spawn_point.svg:{rankIconSize}:{rankIconSize}")
  },
  @() !isInteractive ? null : tooltipCtor({
    rendObj = ROBJ_TEXT
    color = defTxtColor
    text = loc("soldier/picksSquad")
  }))
}

function mkPlayerBattleIcon(playerData, isInteractive, sf, params) {
  let { isReplay = false } = params
  if ((!playerData.isAlly || playerData.isDeserter || playerData.disconnected) && !isReplay)
    return null

  return mkPlayerClass(playerData, isInteractive, sf)
    ?? mkSpawnIcon(playerData, isInteractive, sf)
}

let queryPlayerGetSquad = ecs.SqQuery("query_player_get_squad", {
  comps_ro = [["respawner__squad", ecs.TYPE_EID]]
})

let querySoldierSquadMembers = ecs.SqQuery("query_soldier_squad_members", {
  comps_ro = [["squad__allMembers", ecs.TYPE_EID_LIST]]
})

let queryAliveSoldierName = ecs.SqQuery("query_alive_soldier_name", {
  comps_ro = [["name", ecs.TYPE_STRING], ["surname", ecs.TYPE_STRING]],
  comps_no=["deadEntity"]
})


function openReplayContextMenu(event, playerData) {
  let buttons = [{
    locId = "btn/replay/spectate"
    action = @() ecs.g_entity_mgr.sendEvent(playerData.eid, SetReplayTarget({}))
  }]

  let respSquad = queryPlayerGetSquad.perform(playerData.eid, @(_eid, comp) comp.respawner__squad)
  let allMembers = querySoldierSquadMembers.perform(respSquad, @(_eid, comp) comp.squad__allMembers.getAll()) ?? []
  if (allMembers.len() > 1)
    foreach (member in allMembers)
      queryAliveSoldierName.perform(member, @(eid, comp)
        buttons.append({
          text = loc("btn/replay/spectateHuman", { name = getObjectName(
            { name = comp.name, surname = comp.surname })})
          action = @() ecs.g_entity_mgr.sendEvent(eid, SetReplayTarget({}))
        })
      )

  addContextMenu(event.screenX + 1, event.screenY + 1, fsh(30), buttons)
}

function openContextMenu(event, playerData, localPlayerEid, params) {
  if (playerData?.player == null)
    return

  if (params?.isReplay) {
    openReplayContextMenu(event, playerData)
    return
  }

  let buttons = []

  if (playerData.canForgive)
    buttons.append({
      locId = "btn/forgive"
      action = @() forgive(localPlayerEid, playerData.eid)
    })

  let playerUid = playerData.player?.userid ?? INVALID_USER_ID

  buttons.extend((params?.mkContextMenuButton(playerData) ?? [])
    .filter(@(item) item?.mkIsVisible(playerUid.tostring()).get() ?? true)
    .map(@(item) item.__merge({action = @() item.action(playerUid.tostring())})))

  if (canShowUserProfile(playerData) && params?.showProfileCb)
    buttons.append({
      locId = "show_another_user_profile"
      action = @() params.showProfileCb({
        player = {
          name = playerData.player.name
          userid = playerUid.tointeger()
          nickFrame = playerData.player?.decorators__nickFrame ?? ""
          portrait = playerData.player?.decorators__portrait ?? ""
          rank = playerData.player?.player_info__military_rank ?? 0
          rating = playerData.player?.player_info__rating ?? 0
        }
      })
    })

  if (canComplain(playerData))
    buttons.append({
      locId = "btn/complain"
      action = @() complain(
        playerData.sessionId,
        playerUid,
        getFramedNick(playerData.player, playerData.isGroupmate),
        playerData.player?.platform
      )
    })

  addContextMenu(event.screenX + 1, event.screenY + 1, fsh(30), buttons)
}

let countAssistActions = @(data)
  ( (data?["scoring_player__assists"] ?? 0)
  + (data?["scoring_player__tankKillAssists"] ?? 0)
  + (data?["scoring_player__bikeKillAssists"] ?? 0)
  + (data?["scoring_player__apcKillAssists"] ?? 0)
  + (data?["scoring_player__planeKillAssists"] ?? 0)
  + (data?["scoring_player__aiPlaneKillAssists"] ?? 0)
  + (data?["scoring_player__tankKillAssistsAsCrew"] ?? 0)
  + (data?["scoring_player__bikeKillAssistsAsCrew"] ?? 0)
  + (data?["scoring_player__apcKillAssistsAsCrew"] ?? 0)
  + (data?["scoring_player__planeKillAssistsAsCrew"] ?? 0)
  + (data?["scoring_player__aiPlaneKillAssistsAsCrew"] ?? 0)
  + (data?["scoring_player__crewKillAssists"] ?? 0)
  + (data?["scoring_player__crewTankKillAssists"] ?? 0)
  + (data?["scoring_player__crewBikeKillAssists"] ?? 0)
  + (data?["scoring_player__crewApcKillAssists"] ?? 0)
  + (data?["scoring_player__crewPlaneKillAssists"] ?? 0)
  + (data?["scoring_player__crewAiPlaneKillAssists"] ?? 0)
  + (data?["scoring_player__hostedOnSoldierSpawns"] ?? 0)
  + (data?["scoring_player__reviveAssists"] ?? 0)
  + (data?["scoring_player__healAssists"] ?? 0)
  + (data?["scoring_player__barrageBalloonDestructions"] ?? 0)
  + (data?["scoring_player__builtMedBoxRefills"] ?? 0)
  + (data?["scoring_player__vehicleRepairs"] ?? 0)
  + (data?["scoring_player__vehicleExtinguishes"] ?? 0)
  + (data?["scoring_player__enemyBuiltFortificationDestructions"] ?? 0)
  + (data?["scoring_player__enemyBuiltGunDestructions"] ?? 0)
  + (data?["scoring_player__enemyBuiltUtilityDestructions"] ?? 0)
  + (data?["scoring_player__landings"] ?? 0)
  + (data?["scoring_player__longRangeKills"] ?? 0)
  + (data?["scoring_player__apcSpot"] ?? 0)
  + (data?["scoring_player__apcSpotSpy"] ?? 0)
  + (data?["scoring_player__buildingSpot"] ?? 0)
  + (data?["scoring_player__buildingSpotSpy"] ?? 0)
  + (data?["scoring_player__tankSpot"] ?? 0)
  + (data?["scoring_player__tankSpotSpy"] ?? 0) )

let ENGINEER_STATS = [
 { id = "builtRallyPointUses" }
 { id = "builtStructures" }
 { id = "builtGunKills" }
 { id = "builtGunKillAssists" }
 { id = "builtGunTankKills" }
 { id = "builtGunTankKillAssists" }
 { id = "builtGunBikeKills" }
 { id = "builtGunBikeKillAssists" }
 { id = "builtGunApcKills" }
 { id = "builtGunApcKillAssists" }
 { id = "builtGunPlaneKills" }
 { id = "builtGunAiPlaneKills" }
 { id = "builtGunPlaneKillAssists" }
 { id = "builtGunAiPlaneKillAssists" }
 { id = "builtBarbwireActivations" }
 { id = "builtCapzoneFortificationActivations" }
 { id = "builtAmmoBoxRefills" }
 { id = "ownedMobileSpawnUses" }
].apply(@(stat) {id = stat.id, scoringPlayerId = $"scoring_player__{stat.id}"})

let countEngineerActions = @(data)
  ENGINEER_STATS.reduce(@(sum, stat) sum + (data?[stat.scoringPlayerId] ?? 0), 0)

let countCapzoneKills = @(data)
  ( (data?["scoring_player__attackKills"] ?? 0)
  + (data?["scoring_player__defenseKills"] ?? 0) )

let mkPlayerName = @(playerData, sf) rowText(
  getFramedNick(playerData.player, playerData.isGroupmate),
  FLEX,
  playerData,
  sf,
  {
    size = FLEX_H
    hplace = ALIGN_LEFT
    padding = [0, smallPadding]
    behavior = sf & S_HOVER ? Behaviors.Marquee : null
  })

function selectDisplayedAward(isBattleHero, awards) {
  if (isBattleHero)
    return BattleHeroesAward.PLAYER_BATTLE_HERO
  let priorityAward = awards.reduce(@(a,b) awardPriority[a] > awardPriority[b] ? a : b)
  return isSoldierKindAward(priorityAward) && awards.len() > 1
    ? BattleHeroesAward.MULTISPECIALIST
    : priorityAward
}

function mkBattleHeroAwardWidget(player, isAlly) {
  local awards = player?.awards ?? []
  if (awards.len() == 0)
    return null
  let isBattleHero = isAlly && (player?.isBattleHero ?? false)
  let displayedAward = selectDisplayedAward(isBattleHero, awards)
  if (isBattleHero)
    awards = [{icon = BattleHeroesAward.PLAYER_BATTLE_HERO, text = "debriefing/tooltipScoreTableBattleHero" }].extend(awards)
  if (displayedAward == BattleHeroesAward.MULTISPECIALIST)
    awards = [{icon = BattleHeroesAward.MULTISPECIALIST, text = "debriefing/tooltipScoreTableMultispecialist" }].extend(awards)
  return withTooltip(mkBattleHeroAwardIcon(displayedAward, [LINE_H,LINE_H]),
    @() mkAwardsTooltip(awards, tooltipBattleHeroAwardIconSize))
}

function mkTotalScoreTooltip(title, stats, data, prices) {
  if (prices.len() == 0)
    return null
  let score = stats.reduce(@(sum, stat) sum + (data?[stat.scoringPlayerId] ?? 0) * (prices?[stat.id] ?? 0), 0)
  return tooltipCtor(
    dtext($"{title}{colon}{score}", {padding = const [0, hdpx(10)]}.__update(fontBody))
  )
}

let COLUMN_PLAYER_NUM = {
  width = NUM_COL_WIDTH
  mkHeader = @(_) null
  mkContent = @(playerData, _params, idx) rowText(playerData?.isInMatchingSlots ? idx.tostring() : null, FLEX, playerData)
}
let COLUMN_PLAYER_NAME = {
  width = FLEX
  mkHeader = @(p) [
    p.teamIcon != null ? {
          rendObj = ROBJ_IMAGE
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
          size = [TEAM_ICON_SIZE, TEAM_ICON_SIZE]
          image = Picture("{0}:{1}:{1}".subst(p.teamIcon, TEAM_ICON_SIZE))
          margin = [0, 0, 0, bigGap]
        }
      : (p.armies?.len() ?? 0) > 0 ? mkArmiesIcons(p.armies)
      : null
    {
      rendObj = ROBJ_TEXT
      margin = [0, bigGap, 0, bigGap]
      text = p.teamText
    }.__update(fontBody)
    p.addChild
  ]
  headerOverride = { flow = FLOW_HORIZONTAL, halign = ALIGN_LEFT }
  mkContent = @(playerData, params, _idx) watchElemState(function(sf) {
    let {
      isLocal, isDeserter, isFriend, canForgive, player, isGroupmate, isAlly = true
    } = playerData
    let { isInteractive = false } = params

    return {
      size = FLEX
      flow = FLOW_HORIZONTAL
      behavior = isInteractive ? Behaviors.Button : null
      onClick = @(event) openContextMenu(event, playerData, params.localPlayerEid, params)
      onDetach = closeLatestContextMenu
      children = [
        {
          flow = FLOW_HORIZONTAL
          padding = [0, smallPadding]
          size = FLEX
          children = [
            isDeserter ? mkIcon("chain-broken", playerData, sf) : null
            !isLocal && isFriend ? mkIcon("users", playerData, sf, hdpx(14)) : null
            canForgive ? friendlyFireIcon : null
            isDeserter ? null : mkBattleHeroAwardWidget(player, isAlly ?? true)
            mkPlayerName(playerData, sf)
          ]
        }
        isGroupmate
          ? mkMemberIcon((player.memberIndex + 1).tostring(), playerData, sf)
              .__update({ padding = [0, bigGap] })
          : null
        mkPlayerBattleIcon(playerData, isInteractive, sf, params)
      ]
    }
  })
}

let COLUMN_KILLS = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#statistics_kills_icon.svg"
  field = "scoring_player__kills"
  locId = "scoring/kills"
}
let COLUMN_VEHICLE_KILLS = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#kills_technics_icon.svg"
  locId = "scoring/killsVehicles"
  mkContent = @(playerData, _params, _idx) rowText((playerData.player?["scoring_player__tankKills"] ?? 0)
    + (playerData.player?["scoring_player__apcKills"] ?? 0)
    + (playerData.player?["scoring_player__planeKills"] ?? 0)
    + (playerData.player?["scoring_player__bikeKills"] ?? 0)
    + (playerData.player?["scoring_player__aiPlaneKills"] ?? 0), FLEX, playerData)
}
let COLUMN_ASSISTS = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#kills_assist_icon.svg"
  mkContent = @(playerData, _params, _idx)
    rowText(round_by_value(countAssistActions(playerData.player), 0.1), FLEX, playerData)
  locId = "scoring/killsAssist"
}
let COLUMN_ENGINEER = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#engineer.svg"
  mkContent = @(playerData, params, _idx)
    withTooltip(rowText(countEngineerActions(playerData.player), FLEX, playerData),
      @() mkTotalScoreTooltip(loc("scoring/engineerActionTooltip"), ENGINEER_STATS, playerData.player, params?.scorePrices ?? {}))
  locId = "scoring/engineerActions"
}
let COLUMN_KILLS_IN_CAPZONE = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#zone_defense_icon.svg"
  mkContent = @(playerData, _params, _idx) rowText(countCapzoneKills(playerData.player), FLEX, playerData)
  locId = "scoring/killsCapzoneDefenseOrAttack"
}
let COLUMN_CAPTURES = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#captured_zones_icon.svg"
  locId = "scoring/captures"
  mkContent = @(playerData, _params, _idx)
    rowText(round_by_value(playerData.player?["scoring_player__captures"] ?? 0, 0.1),
      FLEX, playerData)
}
let COLUMN_DEATH = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#lb_deaths.avif"
  field = "scoring_player__squadDeaths"
  locId = "scoring/deathsSquad"
}
let COLUMN_SCORE = {
  width = SCORE_COL_WIDTH
  headerIcon = "ui/skin#lb_score.avif"
  field = "score"
  locId = "scoring/total"
}
let COLUMN_GUN_GAME_LEVEL = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#research/secondary_weap_slot_upgrade_icon.svg"
  locId = "scoring/gunGameLevel"
  mkContent = @(playerData, _params, _idx)
    rowText(1 + (playerData.player?["scoring_player__gunGameLevelup"] ?? 0),
      FLEX, playerData)
}
let COLUMN_ZOMBIE_KILLS = {
  width = NUM_COL_WIDTH
  headerIcon = "ui/skin#statistics_kills_icon.svg"
  locId = "scoring/kills"
  field = "scoring_player__zombieKills"
}
let COLUMN_ZOMBIE_DOORS_SCORE = {
  width = SCORE_COL_WIDTH
  headerIcon = "ui/skin#events/sinful_soul_icon.svg"
  locId = "scoring/sinful_souls"
  field = "scoring_player__zombieDoorsScore"
}

let allColumns = [
  COLUMN_PLAYER_NUM
  COLUMN_PLAYER_NAME
  COLUMN_KILLS
  COLUMN_VEHICLE_KILLS
  COLUMN_ASSISTS
  COLUMN_ENGINEER
  COLUMN_KILLS_IN_CAPZONE
  COLUMN_CAPTURES
  COLUMN_DEATH
  COLUMN_SCORE
  COLUMN_GUN_GAME_LEVEL
  COLUMN_ZOMBIE_DOORS_SCORE
  COLUMN_ZOMBIE_KILLS
]
allColumns.each(function(c) {
  c.mkHeader <- c?.mkHeader ?? @(_) mkHeaderIcon(c.headerIcon)
  c.mkContent <- c?.mkContent
    ?? @(playerData, _params, _idx) rowText(playerData.player?[c.field].tostring() ?? "0", FLEX, playerData)
})

let columnsDefault = [
  COLUMN_PLAYER_NUM
  COLUMN_PLAYER_NAME
  COLUMN_KILLS
  COLUMN_VEHICLE_KILLS
  COLUMN_ASSISTS
  COLUMN_ENGINEER
  COLUMN_KILLS_IN_CAPZONE
  COLUMN_CAPTURES
  COLUMN_DEATH
  COLUMN_SCORE
]

let columnsGunGame = [
  COLUMN_PLAYER_NUM
  COLUMN_PLAYER_NAME
  COLUMN_KILLS
]

let columnsZombieMod = [
  COLUMN_PLAYER_NUM
  COLUMN_PLAYER_NAME
  COLUMN_ZOMBIE_DOORS_SCORE
  COLUMN_ZOMBIE_KILLS
  COLUMN_VEHICLE_KILLS
  COLUMN_DEATH
]

let columnsByGameMode = {
  gun_game = columnsGunGame
  zombie_mode = columnsZombieMod
}

function getScoreTableColumns(key) {
  return columnsByGameMode?[key] ?? columnsDefault
}

return freeze({
  LINE_H
  getScoreTableColumns
})
