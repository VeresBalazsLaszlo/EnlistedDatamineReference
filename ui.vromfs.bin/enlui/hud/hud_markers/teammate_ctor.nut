import "%ui/hud/state/engineers_in_squad.nut" as engineersInSquad
import "%ui/hud/components/teammateName.nut" as teammateName
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/dasenums.nut" import MedicHealState
from "%ui/hud/state/hudGameModes.nut" import forcedMinimalHud
from "dagor.math" import Point2
from "%ui/hud/state/local_player.nut" import localPlayerGroupMembers
from "%ui/hud/state/squad_members.nut" import selectedBotForOrderEid, isPersonalContextCommandMode, watchedHeroSquadEid
from "%ui/style/unit_colors.nut" import HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER, HUD_COLOR_GROUPMATE_BOT_INNER, HUD_COLOR_GROUPMATE_BOT_OUTER, HUD_COLOR_SQUADMATE_INNER, HUD_COLOR_SQUADMATE_OUTER, HUD_COLOR_MEDIC_HP_LOW
  , HUD_COLOR_MEDIC_HP_CRITICAL, HUD_COLOR_MEDIC_HP_OUTER, HUD_COLOR_SQUADMATE_DOWNED
from "%ui/helpers/remap_nick.nut" import remap_nick
from "%ui/components/decoratorsPresentation.nut" import frameNick
from "%ui/hud/state/soldier_class_state.nut" import heroSoldierKind
from "%ui/hud/state/medic_state.nut" import heroMedicMedpacks
from "%ui/hud/state/human_teammates.nut" import teammatesAvatarsSet, teammatesAvatarsGetWatched
from "%ui/hud/state/hudOptionsState.nut" import showTeammateName, showTeammateMarkers
from "%ui/hud/state/zombie_mode.nut" import isZombieMode
from "%ui/hud/state/travelModePlayersState.nut" import zombieModeTeamEids
from "%ui/hud/state/zombie_zones_state.nut" import isZombieObjectiveMode
from "%ui/contacts/contact.nut" import contactUserIds
from "%ui/ui_library.nut" import *

let { zombieModeTeamData } = require("%ui/hud/state/travelModePlayersState.nut")


let hpIconSize = [hdpxi(27), hdpxi(27)]
let syringeIconSize = [hdpxi(36), hdpxi(36)]

let downedIcon = {
  padding = hdpx(4)
  rendObj = ROBJ_VECTOR_CANVAS
  color = HUD_COLOR_SQUADMATE_DOWNED
  fillColor = 0xFF222222
  commands = [
    [VECTOR_WIDTH, hdpx(1)],
    [VECTOR_ELLIPSE, 50, 50, 50, 50]
  ]
  children = {
    size = syringeIconSize
    rendObj = ROBJ_IMAGE
    image = Picture("ui/skin#syringe.svg:{0}:{1}".subst(syringeIconSize[0], syringeIconSize[1]))
    color = HUD_COLOR_SQUADMATE_DOWNED
  }
}


function mkIcon(colorInner, colorOuter, sizeFactor) {
  let unitIconSize = [fsh(1*sizeFactor), fsh(1.25*sizeFactor)].map(@(v) v.tointeger())
  return {
    key = {}
    rendObj = ROBJ_IMAGE
    color = colorOuter
    image = Picture($"ui/skin#unit_outer.svg:{unitIconSize[0]}:{unitIconSize[1]}")
    size = unitIconSize
    minDistance = 0.5
    children = {
      rendObj = ROBJ_IMAGE
      color = colorInner
      image = Picture($"ui/skin#unit_inner.svg:{unitIconSize[0]}:{unitIconSize[1]}")
      size = unitIconSize
    }
    markerFlags = DngBhv.MARKER_SHOW_ONLY_IN_VIEWPORT
  }
}

let selectedIcon = mkIcon(HUD_COLOR_SQUADMATE_INNER, HUD_COLOR_SQUADMATE_OUTER, 2.0)
let notSelectedIcon = mkIcon(HUD_COLOR_SQUADMATE_INNER, HUD_COLOR_SQUADMATE_OUTER, 1.0)
let animSquadIcon = freeze([
  {prop = AnimProp.translate, from=[0, hdpx(25)], to=[0, 0], duration=0.5, play=true, loop=true, easing=OutBack}
])

let mkSquadmateIcon = memoize(function(eid) {
  let selectedIco = freeze(selectedIcon.__merge({key = {}, transform = true, animations = animSquadIcon}))
  let notSelectedIco = freeze(notSelectedIcon.__merge({key = eid}))
  return function() {
    let isSelectedBotForOrders = selectedBotForOrderEid.get() == eid && isPersonalContextCommandMode.get()
    return {
      watch = [selectedBotForOrderEid, isPersonalContextCommandMode]
      children = isSelectedBotForOrders ? selectedIco : notSelectedIco
    }
  }
})

let healing_outer_ico = Picture($"ui/skin#healing_icon_outer.svg:{hpIconSize[0]}:{hpIconSize[1]}")
let healing_ico = Picture($"ui/skin#healing_icon.svg:{hpIconSize[0]}:{hpIconSize[1]}")
let innerMedIco = memoize(@(colorInner) freeze({
  rendObj = ROBJ_IMAGE
  color = colorInner
  image = healing_ico
  size = hpIconSize
}))
let outerMedIco = memoize(@(colorOuter) freeze({
  rendObj = ROBJ_IMAGE
  color = colorOuter
  image = healing_outer_ico
  size = hpIconSize
}))

let mkHpIcon = @(eid, colorInner, colorOuter) {
  key = eid
  size = hpIconSize
  minDistance = 0.5
  children = [
    outerMedIco(colorOuter)
    innerMedIco(colorInner)
  ]
}

let ammoBoxIconSize = [hdpxi(65), hdpxi(65)]
let build_ammo_ico = Picture($"ui/skin#building_ammo_box.svg:{ammoBoxIconSize[0]}:{ammoBoxIconSize[1]}")
let requestAmmoBoxIcon = freeze({
  rendObj = ROBJ_IMAGE
  color = Color(255, 255, 255, 255)
  image = build_ammo_ico
  size = ammoBoxIconSize
  minDistance = 0.5
})

let rallyPointIconSize = [hdpxi(65), hdpxi(65)]
let pic_rally = Picture($"ui/skin#custom_spawn_point.svg:{rallyPointIconSize[0]}:{rallyPointIconSize[1]}")
let requestRallyPointIcon = freeze({
  rendObj = ROBJ_IMAGE
  color = Color(255, 255, 255, 255)
  image = pic_rally
  size = rallyPointIconSize
  minDistance = 0.5
})

let teammateIcon = mkIcon(HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER, 1.0)
let groupmateBotIcon = mkIcon(HUD_COLOR_GROUPMATE_BOT_INNER, HUD_COLOR_GROUPMATE_BOT_OUTER, 1.0)

let displayMarkerOverHeadQuery = ecs.SqQuery("displayMarkerOverHeadQuery", {comps_rq=["vehicleDisplayMarkerOverHead"]})
let maxRange = Point2(10,10) 
let opRangeX = Point2(0.25, 0.35)
let opRangeY = Point2(0.25, 0.75)
let opRangeX_hardcore = Point2(0.125, 0.135)


let needShowMed = Computed(@() heroSoldierKind.get() == "medic" && heroMedicMedpacks.get() > 0)
let hasEngineers = Computed(@() engineersInSquad.get() > 0)


let mkTravelModeIconUi = @(eid) @() {
  watch = [zombieModeTeamEids, isZombieObjectiveMode]
  children = !isZombieObjectiveMode.get() || !zombieModeTeamEids.get().contains(eid)
    ? null
    : @() {
        watch = zombieModeTeamData[eid]
        children = (zombieModeTeamData[eid].get()?.isDowned ?? false) ? downedIcon : null
      }
}


function unit(eid, showMed) {
  let infoState = teammatesAvatarsGetWatched(eid)
  let watch = [
    infoState, hasEngineers, forcedMinimalHud, watchedHeroSquadEid, isZombieMode,
    localPlayerGroupMembers, showTeammateName, showTeammateMarkers, contactUserIds
  ]
  if (showMed)
    watch.append(needShowMed)

  let travelModeIconUi = mkTravelModeIconUi(eid)
  return function() {
    let info = infoState.get()
    if (!info.isAlive)
      return { watch }

    let vehicle = info?["human_anim__vehicleSelected"] ?? ecs.INVALID_ENTITY_ID
    if (vehicle != ecs.INVALID_ENTITY_ID){
      let vehicleNeedDisplayMarker = displayMarkerOverHeadQuery(vehicle, @(_, __) true ) ?? false
      if (!vehicleNeedDisplayMarker)
        return { watch }
    }

    let isSquadmate = info.squad_member__squad != ecs.INVALID_ENTITY_ID
      && info.squad_member__squad == watchedHeroSquadEid.get()
    let isBot = info.possessedByPlr == ecs.INVALID_ENTITY_ID

    let userId = info?.userid ?? info?.groupId
    let isFriend = userId != null && userId.tostring() in contactUserIds.get()
    let isInLocalGroup = info.squad_member__playerEid in localPlayerGroupMembers.get()
    let isGroupmate = !isSquadmate && (isInLocalGroup || isFriend)

    let minHud = forcedMinimalHud.get()
    let showName = info?.name && (isGroupmate || isZombieMode.get()) && !isBot && showTeammateName.get()
    let nameComp = showName
      ? teammateName(eid,
          frameNick(remap_nick(info?.name), info?["decorators__nickFrame"]),
          HUD_COLOR_TEAMMATE_INNER)
      : null

    let icon = isSquadmate ? mkSquadmateIcon(eid)
      : isBot && isGroupmate ? groupmateBotIcon
      : teammateIcon
    let iconHpColor = info.medic__healState == MedicHealState.MHS_NEED_REVIVE ? HUD_COLOR_MEDIC_HP_CRITICAL
      : info.medic__healState == MedicHealState.MHS_NEED_HEAL ? HUD_COLOR_MEDIC_HP_LOW
      : null
    let hasEngineerInPlayerSquad = hasEngineers.get()
    let isRequestAmmoBoxMarkerEnabled = hasEngineerInPlayerSquad
      && info["human_quickchat__requestAmmoBoxMarkerShowUpTo"] > 0.0
    let isRequestRallyPointMarkerEnabled = hasEngineerInPlayerSquad
      && info["human_quickchat__requestRallyPointMarkerShowUpTo"] > 0.0

    let maxHealIconDistance = minHud ? 25 : 30
    let maxTeammateIconDistance = minHud ? 100 : 1000
    let isReviveInZombieMod = showMed && info.medic__healState == MedicHealState.MHS_NEED_REVIVE && isZombieMode.get()

    let data = isReviveInZombieMod
      ? {
          eid
          maxDistance = 30
          clampToBorder = isReviveInZombieMod
          yOffs = 0.25
        }
      : {
          eid
          opacityForInvisibleAnimchar = 0.4
          minDistance = showMed ? 0 : maxHealIconDistance
          maxDistance = showMed ? maxHealIconDistance : maxTeammateIconDistance
          distScaleFactor = 0.5
          clampToBorder = false
          yOffs = 0.25
          opacityRangeViewDistance = minHud ? 1.0 : 20.0
          opacityRangeX = showName && !minHud
            ? maxRange
            : minHud ? opRangeX_hardcore : opRangeX
          opacityRangeY = showName ? maxRange : opRangeY
        }

    return {
      watch
      data
      key = {}
      sortOrder = eid
      transform = true
      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      size = 0
      children = {
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            gap = hdpx(2)
            children = [
              isRequestAmmoBoxMarkerEnabled ? requestAmmoBoxIcon : null
              isRequestRallyPointMarkerEnabled ? requestRallyPointIcon : null
            ]
          }
          travelModeIconUi
          nameComp
          !showTeammateMarkers.get()
            ? { size = const [hdpxi(10), hdpxi(13)] }
            : ((showMed && needShowMed.get() && iconHpColor) || isReviveInZombieMod
                ? mkHpIcon(eid, iconHpColor, HUD_COLOR_MEDIC_HP_OUTER)
                : icon)
        ]
      }
    }
  }
}

let mapAvatarsMed = mkMemoizedMapSet(@(eid) unit(eid, true))
let mapAvatars = mkMemoizedMapSet(@(eid) unit(eid, false))

return {
  teammates_markers_ctor = {
    watch = teammatesAvatarsSet
    ctor = function() {
      let v = teammatesAvatarsSet.get()
      return mapAvatarsMed(v).values().extend(mapAvatars(v).values())
    }
  }
}