import "%ui/hud/state/artillery_strikes_es.nut" as artilleryStrikes
from "dagor.math" import Point3
from "%ui/ui_library.nut" import *




let zeroPos = Point3(0, 0, 0)

function makeZone(zone, minimap_state, map_size) {
  let worldPos = zone?["pos"] ?? zeroPos
  let radius = zone?["radius"] ?? 0.0
  let ellipseCmd = [VECTOR_ELLIPSE, 50, 50, 50, 50]
  const fillColor = Color(84, 24, 24, 5)

  let cmd = [
      [VECTOR_FILL_COLOR, fillColor],
      [VECTOR_WIDTH, 0],
      ellipseCmd,
    ]

  let updCacheTbl = {
    data = {
      worldPos
      clampToBorder = false
    }
  }

  return {
    transform = const { pivot = [0.5, 0.5] }
    rendObj = ROBJ_VECTOR_CANVAS
    lineWidth = hdpx(0)
    color = Color(0, 0, 0, 0)
    fillColor

    behavior = Behaviors.RtPropUpdate
    rtAlwaysUpdate = false
    size = map_size
    commands = cmd

    update = function() {
      let realVisRadius = minimap_state.getVisibleRadius()
      let canvasRadius = radius / realVisRadius * 50.0

      ellipseCmd[3] = canvasRadius
      ellipseCmd[4] = canvasRadius

      updCacheTbl.data.worldPos <- worldPos
      return updCacheTbl
    }
  }
}

return {
  watch = artilleryStrikes
  ctor = function(p) {
    let {state=null, size=null} = p
    return artilleryStrikes.get().values().map(@(zone) makeZone(zone, state, size))
  }
}
