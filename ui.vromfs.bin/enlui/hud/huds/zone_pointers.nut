import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/capZones.nut" import getZoneWatch, visibleCurrentCapZonesEids, capZones
from "%ui/hud/style.nut" import TEAM1_COLOR_FG, DEFAULT_TEXT_COLOR
from "%ui/state/safeArea.nut" import safeAreaHorPadding, safeAreaVerPadding
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/hud/state/respawnState.nut" import showSquadSpawn, respawnSelectedEid
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid, watchedTeam
from "%ui/hud/components/capzone.nut" import capzoneWidget
from "%ui/hud/replay/replayState.nut" import canShowGameHudInReplay
from "%ui/ui_library.nut" import *
from "dng.behaviors" import ZonePointers
from "%ui/hud/state/vehicle_state.nut" import isOwnerInMobileRespawn
from "%ui/hud/state/building_tool_state.nut" import showCapzonesDistForPreview

const pointerColor = Color(200,200,200)
let iconSz = [hdpxi(32), hdpxi(24)]
const gap = hdpx(5)

let capzoneSettings = {canHighlight=false}

let visibleZoneEids = Computed(function(prev) {
  let capzones = capZones.get()
  let watchedhero = watchedHeroEid.get()
  let n = visibleCurrentCapZonesEids.get().filter(@(_, eid)
      capzones?[eid].heroInsideEid != watchedhero
      || watchedhero == ecs.INVALID_ENTITY_ID
      || watchedhero == null
    )
  if (!isEqual(n, prev))
    return n
  return prev
})

let isZonesInReplayHidden = Computed(@() isReplay.get() && !canShowGameHudInReplay.get())

let distanceText = memoize(function(eid, fromEid = ecs.INVALID_ENTITY_ID) {
  return freeze({
    rendObj = ROBJ_TEXT
    color = DEFAULT_TEXT_COLOR
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    pos = const [0, fsh(3.5)]
    size = const [fsh(5), SIZE_TO_CONTENT]

    behavior = DngBhv.DistToEntity
    targetEid = eid
    fromEid
    minDistance = 3.0
  })
})

let distIconSize = [hdpxi(16), hdpxi(16)]

let respDistIcon = {
  rendObj = ROBJ_IMAGE
  size = distIconSize
  image = Picture($"ui/skin#custom_spawn_point.svg:{distIconSize[0]}:{distIconSize[1]}")
  keepAspect = KEEP_ASPECT_FIT
  color = DEFAULT_TEXT_COLOR
}

let mkRespDist = @(distance) distance < 0 ? null
  : {
      hplace = ALIGN_CENTER
      valign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      gap
      pos = const [0, -fsh(3.5)]
      children = [
        respDistIcon
        distance <= 0 ? null : {
          rendObj = ROBJ_TEXT
          text = distance
          color = DEFAULT_TEXT_COLOR
        }
      ]
      transform = true
      animations = [
        {prop=AnimProp.translate, from=[0, fsh(1.5)], to=[0, 0], easing=OutQuad, duration=0.2, play=true}
        {prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.2, play=true}
      ]
    }

let defIcon = {
  rendObj = ROBJ_IMAGE
  size = iconSz
  image = Picture("ui/skin#waypoint.svg:{0}:{1}".subst(iconSz[0], iconSz[1]))
}
let mkZoneIcon = memoize(@(eid, title, icon, isDefendZone) (!isDefendZone && (title ?? "") == "" && (icon ?? "") == "")
    ? defIcon.__merge({ key = eid })
    : null,
  1
)

let mkPointer = @(capturingAndDefend) freeze({
  rendObj = ROBJ_IMAGE
  image = Picture("ui/skin#target_pointer.avif")
  size = const [fsh(4), fsh(4.8)]
  pos = const [fsh(0.05), -fsh(0.34)]
  color = pointerColor
  key = capturingAndDefend
  animations = capturingAndDefend ? [
      { prop=AnimProp.color, from=pointerColor, to=TEAM1_COLOR_FG, duration=0.6, play=true, loop=true, easing=CosineFull}
    ] : null
})

let pointerCapturingAndDefend = mkPointer(true)
let pointer = mkPointer(false)
let animations = [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic}
  { prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true, easing=InOutCubic}
]






















let behavior = [DngBhv.DistToPriority, Behaviors.OverlayTransparency]
let size = 0
let childSize = [fsh(4.8), fsh(4.8 + 2.0)]

function mkZonePointer(eid) {
  let capzone = capzoneWidget(eid, capzoneSettings)
  let zoneWatch = getZoneWatch(eid)
  let {title=null, icon=null, iconOffsetY=0.0} = zoneWatch.get()
  let watch = [watchedTeam, zoneWatch, showSquadSpawn, respawnSelectedEid, isOwnerInMobileRespawn, showCapzonesDistForPreview]
  let childData = {
    eid
    priorityOffset = 10000
    opacityCenterRelativeDist = 0.05
    opacityCenterMinMult = 0.5
  }
  let data = {
    zoneEid = eid
    yOffs = iconOffsetY
  }
  let capturingKey = {}
  let nkey = {}
  return function() {
    let zone = zoneWatch.get()
    if (zone == null)
      return { watch }

    let heroTeam = watchedTeam.get()
    let { isCapturing, curTeamCapturingZone, attackTeam, heroMobileRespawnDist } = zone
    let mobileRespDist = (isOwnerInMobileRespawn.get() || showCapzonesDistForPreview.get()) ? mkRespDist(heroMobileRespawnDist) : null
    let isDefendZone = (attackTeam >= 0 && attackTeam != heroTeam)
    let zoneIcon = mkZoneIcon(eid, title, icon, isDefendZone)
    let showCapturing = isCapturing
      && (attackTeam == heroTeam || (curTeamCapturingZone != heroTeam && attackTeam!=heroTeam))
    let distance = !showSquadSpawn.get() ? distanceText(eid)
      : respawnSelectedEid.get() != ecs.INVALID_ENTITY_ID ? distanceText(eid, respawnSelectedEid.get())
      : null
    return {
      watch
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size
      key = showCapturing ? capturingKey : nkey
      data
      transform = true
      children = {
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        data  = childData
        size = childSize
        pos = const [0, -fsh(1)]
        behavior
        children = [
          {
            size = fsh(4.8)
            halign = ALIGN_CENTER
            transform = true
            children = showCapturing && isDefendZone ? pointerCapturingAndDefend : pointer
          }
          capzone
          zoneIcon
          distance
          mobileRespDist
        ]
      }

      animations
    }
  }
}

let zonePointersWatch = [visibleZoneEids, safeAreaHorPadding, isZonesInReplayHidden,
  isZonesInReplayHidden]
let memoizedMap = mkMemoizedMapSet(mkZonePointer)

function zonePointers() {

  let children = isZonesInReplayHidden.get() ? null : memoizedMap(visibleZoneEids.get()).values()

  return {
    watch = zonePointersWatch
    size = [sw(100)-safeAreaHorPadding.get()*2 - fsh(6), sh(100) - safeAreaVerPadding.get()*2-fsh(8)]
    behavior = ZonePointers
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children
  }
}

return zonePointers
