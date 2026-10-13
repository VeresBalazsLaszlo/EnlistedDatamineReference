import "%dngscripts/ecs.nut" as ecs
from "%ui/style/fontsStyle.nut" import fontSub
from "math" import ceil
from "%ui/hud/state/local_player.nut" import localPlayerTeam, localPlayerGroupMembers
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid
from "%ui/hud/state/squad_members.nut" import watchedHeroSquadEid
from "%ui/hud/state/human_teammates.nut" import teammatesAvatarsGetWatched, groupmatesAvatarsSet, groupmatesAvatarsGetWatched, teammatesAvatarsNotGroupmatesSet
from "team" import TEAM_UNASSIGNED
from "%ui/style/unit_colors.nut" import MAP_COLOR_SQUADMATE, MAP_COLOR_GROUPMATE, MAP_COLOR_TEAMMATE
from "%ui/hud/state/hudOptionsState.nut" import hudMarkerEnable
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/contacts/contact.nut" import contactUserIds
from "%ui/ui_library.nut" import *

let unitArrowSz = [hdpxi(7), hdpxi(15)]
let teammateArrowSz = [hdpxi(18), hdpxi(18)]

let unit_arrow = Picture("ui/skin#unit_arrow.svg:{0}:{1}".subst(
    ceil(unitArrowSz[0]*1.3).tointeger(), ceil(unitArrowSz[1]*1.3).tointeger()))

let teammate_arrow = Picture("ui/skin#teammate_arrow.svg:{0}:{1}".subst(
    ceil(teammateArrowSz[0]*1.3).tointeger(), ceil(teammateArrowSz[1]*1.3).tointeger()))

let mkIcon = memoize(@(fillColor) freeze({
  rendObj = ROBJ_IMAGE
  color = fillColor
  image = unit_arrow
  pos = [0, -unitArrowSz[1] * 0.25]
  size = unitArrowSz
}))

let mkIconPlayerGroupmate = memoize(@(fillColor) freeze({
  rendObj = ROBJ_IMAGE
  color = fillColor
  image = teammate_arrow
  pos = [0, -unitArrowSz[1] * 0.1]
  size = teammateArrowSz
}))

let mkTextPlayerGroupmate = memoize(@(num) freeze({
  rendObj = ROBJ_TEXT
  color = Color(255, 255, 255)
  text = num
  fontSize = hdpx(24) * 0.4
  transform = {
    pivot = [0.5, 0.5]
    rotate = -90
  }
}.__update(fontSub)))

let mkBlinkAnimation = @(trigger) {
    animations = [{ prop=AnimProp.color, from=Color(200,50,50,250), to=Color(255,200,200), duration=0.5, trigger, loop=true, easing=Blink }]
}

function map_unit_ctor(eid, showHero=false) {
  let data = {
    eid
    dirRotate = true
  }
  let markerState = teammatesAvatarsGetWatched(eid)
  let blinkAnimation = mkBlinkAnimation(eid)
  let hideMarker = Computed(function(){
    let {isAlive=true, human_anim__vehicleSelected = ecs.INVALID_ENTITY_ID} = markerState.get()
    return !isAlive
      || !hudMarkerEnable.get()
      || (showHero && watchedHeroEid.get()==eid)
      || human_anim__vehicleSelected != ecs.INVALID_ENTITY_ID
  })
  let fillColorState = Computed(function(){
    let {
      squad_member__squad = ecs.INVALID_ENTITY_ID, team = TEAM_UNASSIGNED,
      squad_member__playerEid = ecs.INVALID_ENTITY_ID, userid = null, groupId = null
    } = markerState.get()
    let isSquadmate = squad_member__squad != ecs.INVALID_ENTITY_ID
      && squad_member__squad == watchedHeroSquadEid.get()

    if (isSquadmate)
      return MAP_COLOR_SQUADMATE

    let playerId = userid ?? groupId
    let isFriend = playerId != null && playerId.tostring() in contactUserIds.get()
    let isInLocalGroup = squad_member__playerEid in localPlayerGroupMembers.get()
    if (isFriend || isInLocalGroup)
      return MAP_COLOR_GROUPMATE

    if (team == localPlayerTeam.get())
      return MAP_COLOR_TEAMMATE

    if (isReplay.get())
      return null 

    return Color(0, 0, 0)
  })

  let watch = [hideMarker, fillColorState]
  return function() {
    if (hideMarker.get())
      return { watch }

    return {
      watch
      key = {}
      data
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = true
      children = fillColorState.get() == null ? null
        : mkIcon(fillColorState.get()).__merge(blinkAnimation)
    }
  }
}

function groupmate_number_ctor(eid) {
  let markerState = groupmatesAvatarsGetWatched(eid)
  let watch = [markerState, hudMarkerEnable]
  let data = { eid, dirRotate = false}
  return function() {
    if (!hudMarkerEnable.get() || !markerState.get()?.isAlive)
      return {watch}

    return {
      key = eid
      data
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = true
      children = mkTextPlayerGroupmate((markerState.get()?.player_group__memberIndex ?? 0) + 1)
    }
  }
}

function groupmate_marker_ctor(eid) {
  let markerState = groupmatesAvatarsGetWatched(eid)
  let watch = [markerState, hudMarkerEnable]
  let data = {eid, dirRotate = true}
  let blinkAnimation = mkBlinkAnimation(eid)
  let children = mkIconPlayerGroupmate(MAP_COLOR_TEAMMATE).__merge(blinkAnimation)
  return function() {
    if (!markerState.get()?.isAlive || !hudMarkerEnable.get())
      return {watch}

    return {
      watch
      key = eid
      data
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = true
      children
    }
  }
}

let memoizedMapNumbers = mkMemoizedMapSet(groupmate_number_ctor)
let memoizedMapMarkers = mkMemoizedMapSet(groupmate_marker_ctor)
let memoizedMapShowHero = mkMemoizedMapSet(@(eid) map_unit_ctor(eid, true))
let memoizedMapNoHero = mkMemoizedMapSet(@(eid) map_unit_ctor(eid, false))
return {
  groupmatesNumbers = {
    watch = groupmatesAvatarsSet
    ctor = @(_) memoizedMapNumbers(groupmatesAvatarsSet.get()).values()
  }
  groupmatesMarkers = {
    watch = groupmatesAvatarsSet
    ctor = @(_) memoizedMapMarkers(groupmatesAvatarsSet.get()).values()
  }
  teammatesMarkers = {
    watch = teammatesAvatarsNotGroupmatesSet
    ctor = @(p) p?.showHero
      ? memoizedMapShowHero(teammatesAvatarsNotGroupmatesSet.get()).values()
      : memoizedMapNoHero(teammatesAvatarsNotGroupmatesSet.get()).values()
  }
}