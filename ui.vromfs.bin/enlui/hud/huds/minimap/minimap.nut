import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/components/controlHudHint.nut" import controlHudHint
from "%ui/hud/minimap_ctors.nut" import mmChildrenCtors, mmZombieEventChildrenCtors
from "%ui/hud/state/zombie_zones_state.nut" import isZombieObjectiveMode
from "%ui/ui_library.nut" import *
from "minimap" import MinimapState
from "minimap.behaviors" import Minimap

let mmContext = require("%ui/hud/huds/minimap/minimap_ctx.nut")


let minimapDefaultVisibleRadius = mkEcsComputed({
  comps = [["level__minimapDefaultVisibleRadius", ecs.TYPE_INT]]
  comps_rq = ["level"]
  defVal = 150
})

let mapSize = [hdpx(200), hdpx(200)]

let MMSHAPES = {
  SQUARE = {
    rendType = "square"
    rotate = 90
    minimapObjsTransform = {rotate=-90}
    blurBackMask = null
    clipChildren = true
    viewDependentRotation = false
  },
  CIRCLE = {
    blurBackMask = Picture("!ui/uiskin/white_circle.svg:{0}:{0}:K".subst(mapSize[0].tointeger()))
    rendType = "circle"
    rotate = 0
    minimapObjsTransform = {rotate=0}
    viewDependentRotation=true
    clipChildren = false
  }
}

let curMinimapShape = MMSHAPES.SQUARE
let minimapState = MinimapState({
  ctx = mmContext
  visibleRadius = minimapDefaultVisibleRadius.get()
  shape = curMinimapShape.rendType
})
minimapDefaultVisibleRadius.subscribe(@(r) minimapState.setVisibleRadius(r))
let mapTransform = { rotate = curMinimapShape.rotate }

let visCone = {
  size = FLEX
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP_VIS_CONE
  behavior = Minimap
}

let mapHotKey = {
  children = controlHudHint("HUD.BigMap")
  hplace = ALIGN_LEFT
  vplace = ALIGN_BOTTOM
  margin = hdpx(3)
  opacity = 0.7
}

let baseMap = {
  size = mapSize
  transform = mapTransform
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP
  behavior = Minimap
  children = visCone
}

let commonLayerParams = {
  state = minimapState
  size = mapSize
  isCompassMinimap = curMinimapShape.viewDependentRotation
  transform = curMinimapShape.minimapObjsTransform
  showHero = false
}

function mkMinimapLayer(ctorWatch, params) {
  return @() {
    watch = ctorWatch.watch
    size = FLEX
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    clipChildren = params?.clipChildren ?? curMinimapShape.clipChildren
    minimapState = minimapState
    transform = mapTransform
    behavior = Minimap
    children = ctorWatch.ctor(params)
  }
}

function makeMinimap() {
  let mmChildren = isZombieObjectiveMode.get() ? mmZombieEventChildrenCtors : mmChildrenCtors
  return {
    watch = isZombieObjectiveMode
    size = mapSize
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    clipChildren = curMinimapShape.clipChildren
    children = [ baseMap ]
      .extend(mmChildren.map(@(c) mkMinimapLayer(c, commonLayerParams)))
      .append(mapHotKey)
  }
}

return makeMinimap
