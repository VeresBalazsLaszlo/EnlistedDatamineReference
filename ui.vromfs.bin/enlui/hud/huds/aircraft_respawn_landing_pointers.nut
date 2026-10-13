import "%ui/hud/huds/getPicture.nut" as getPicture
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/state/aircraft_respawn_landing_zones_state.nut" import landing_zones_GetWatched, landing_zones_Set
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR
from "%ui/state/safeArea.nut" import safeAreaVerPadding, safeAreaHorPadding
from "%ui/ui_library.nut" import *
from "dng.behaviors" import ZonePointers

const ZONE_ICON_COLOR = Color(0,0,0,255)

let baseZoneAppearAnims = [
  { prop=AnimProp.scale, from=[2.5,2.5], to=[1,1], duration=0.4, play=true }
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.2, play=true }
]

let animActive = [
  { prop=AnimProp.scale, from=[7.5,7.5], to=[1,1], duration=0.3, play=true }
  { prop=AnimProp.translate, from=[0,sh(20)], to=[0,0], duration=0.4, play=true, easing=OutQuart }
  { prop=AnimProp.opacity, from=0.0, to=1.0, duration=0.25, play=true }
]

let zSize = [fsh(3), fsh(3)]
let zIconSz = [zSize[0] / 1.5, zSize[1] / 1.5]
let zMargin = (zSize[0] / 1.5).tointeger()

let blur_back = {
  size = zSize
  rendObj = ROBJ_MASK
  image = Picture("ui/skin#white_circle.svg:{0}:{0}".subst(zSize[1].tointeger()))
  children = [{ size = FLEX rendObj = ROBJ_WORLD_BLUR color = Color(220, 220, 220, 255) }]
}

let mkZoneIcon = memoize(function(icon) {
  let zoneIconPic = getPicture(icon, zIconSz[0])
  if (zoneIconPic == null)
    return null

  return {
    rendObj = ROBJ_IMAGE
    size = zIconSz
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    color = ZONE_ICON_COLOR
    transform = const { pivot = [0.5, 0.5] }
    image = zoneIconPic
    animations = baseZoneAppearAnims
  }
})
let zTransitions = [{ prop=AnimProp.translate, duration=0.2 }]

let zoneCtor = @(eid, icon) {
  size = zSize
  margin = [0, zMargin]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  key = eid
  zoneData = { zoneEid = eid }
  children = {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = zSize
      children = [
        blur_back
        mkZoneIcon(icon)
      ]
    }
    transitions = zTransitions
    animations = animActive
  }
}

function distanceText(eid, radius) {
  return {
    rendObj = ROBJ_TEXT
    color = DEFAULT_TEXT_COLOR
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    pos = const [0, fsh(3.5)]
    size = const [fsh(5), fontH(100)]

    behavior = DngBhv.DistToSphere
    targetEid = eid
    radius
    minDistance = 0
  }.__update(fontSub)
}

const pointerColor = Color(200,200,200)
let animations = [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.3, playFadeOut=true, easing=InOutCubic }
]
let pic = Picture("ui/skin#target_pointer.avif")

let mkZonePointer = memoize(function(eid) {
  let state = landing_zones_GetWatched(eid)

  return function(){
    let {radius, icon} = state.get()
    return {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      size = 0

      key = eid
      data = {
        zoneEid = eid
      }
      transform = true
      children = {
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        data = {
          eid = eid
          priorityOffset = 10000
        }
        size = FLEX
        pos = const [0, -fsh(1)]
        behavior = [DngBhv.DistToPriority, Behaviors.OverlayTransparency]
        children = [
          {
            size = fsh(4.8)
            halign = ALIGN_CENTER
            transform = true

            children = {
              rendObj = ROBJ_IMAGE
              image = pic
              size = const [fsh(4), fsh(4.8)]
              pos = const [fsh(0.0), -fsh(0.35)]
              color = pointerColor
            }
          }
          zoneCtor(eid, icon)
          distanceText(eid, radius)
        ]
      }

      animations
    }
  }
})

let memoizedMap = mkMemoizedMapSet(mkZonePointer)

function pointers() {
  return {
    watch = [landing_zones_Set, safeAreaHorPadding, safeAreaVerPadding]
    size = [sw(100)-safeAreaHorPadding.get()*2 - fsh(6), sh(100) - safeAreaVerPadding.get()*2-fsh(8)]
    behavior = ZonePointers
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = memoizedMap(landing_zones_Set.get()).values()
  }
}

return pointers
