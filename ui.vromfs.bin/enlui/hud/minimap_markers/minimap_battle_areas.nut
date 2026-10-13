from "%ui/hud/state/battle_areas_state.nut" import battleAreasPolygon, nextBattleAreasPolygon
from "math" import cos, PI
from "%ui/ui_library.nut" import *
from "minimap.behaviors" import MinimapCanvasPolygon

let mkPolygon = @(points, minimapState, size, animations = []) {
  color = Color(42, 42, 42) 
  fillColor = Color(0, 0, 0, 150)

  rendObj = ROBJ_VECTOR_CANVAS
  commands = [[VECTOR_INVERSE_POLY]]
  lineWidth = hdpx(2)

  minimapState
  size
  points
  behavior = MinimapCanvasPolygon
  animations
}

function mkEasing(pause) {
  let invCosInterval = pause < 1 ? 1 / (1 - pause) : 0
  return @(t) t < pause
    ? 0.0
    : 0.5 - cos(2*PI * (t - pause) * invCosInterval) * 0.5
}

let mkZoneAnim = @(duration, pause, from, to) {
  prop = AnimProp.opacity,
  from,
  to,
  duration,
  play = true
  loop = true,
  easing = mkEasing(duration > 0 ? (pause / duration) : 0),
}

const animDuration = 3.0
const animPause = 0.4

let oldZoneAnim = mkZoneAnim(animDuration, animPause, 1, 0)
let nextZoneAnim = mkZoneAnim(animDuration, animPause, 0, 1)

function makeZone(battleAreasPolygonVal, nextBattleAreasPolygonVal, minimap_state, map_size) {
  if ((nextBattleAreasPolygonVal?.len() ?? 0) == 0)
    return mkPolygon(battleAreasPolygonVal, minimap_state, map_size)
  return {children=[
    mkPolygon(battleAreasPolygonVal, minimap_state, map_size, [oldZoneAnim])
    mkPolygon(nextBattleAreasPolygonVal, minimap_state, map_size, [nextZoneAnim])
  ]}
}

let areasPolygons = Computed(@() battleAreasPolygon.get()==null ? null : {
  activeAreaPolygon=battleAreasPolygon.get(),
  nextAreaPolygon=nextBattleAreasPolygon.get()
})

return {
  watch = areasPolygons
  ctor = @(p) battleAreasPolygon.get() == null
    ? []
    : [makeZone(areasPolygons.get().activeAreaPolygon, areasPolygons.get().nextAreaPolygon, p.state, p.size)]
}
