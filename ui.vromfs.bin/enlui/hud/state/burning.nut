import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let def = {
  isPuttingOut = false
  force = 0.0
  maxForce = 0.0
}

let heroBurning = mkEcsComputed({
  comps = [
    ["burning__force", ecs.TYPE_FLOAT],
    ["burning__isPuttingOut", ecs.TYPE_BOOL],
    ["burning__maxForce", ecs.TYPE_FLOAT],
  ]
  comps_rq = ["hero"]
  comps_no = ["deadEntity"]
})

let burningState = Computed(function() {
  let state = heroBurning.get()
  if (state == null)
    return def
  return {
    force = state.burning__force
    isPuttingOut = state.burning__isPuttingOut
    maxForce = state.burning__maxForce
  }
})

return burningState