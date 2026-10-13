from "%ui/hud/state/vehicle_state.nut" import inPlane
from "%ui/ui_library.nut" import *

const DEFAULT_PLANE_MAP_RADIUS = 2500
const DEFAULT_GROUND_MAP_RADIUS = 350

let bigmapDefaultVisibleRadius = Computed(@() inPlane.get() ? DEFAULT_PLANE_MAP_RADIUS : DEFAULT_GROUND_MAP_RADIUS)

return {
  bigmapDefaultVisibleRadius
}
