import "%dngscripts/ecs.nut" as ecs
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *

let planeControlModeState = nestWatched("planeControlModeState", null)
let planeControlModeStateUpdate = @(v) planeControlModeState.set(v)

let comps = {
  comps_rq=["input__enabled"]
  comps_rw = [
    ["plane_input__mouseAimEnabled", ecs.TYPE_BOOL],
    ["plane_input__simpleJoyEnabled", ecs.TYPE_BOOL]
  ]
}

let findPlaneInputQuery = ecs.SqQuery("findPlaneInputQuery", comps)

function setControlMode(_, comp) {
  if (planeControlModeState.get() == null)
    return
  comp["plane_input__simpleJoyEnabled"] = false
  comp["plane_input__mouseAimEnabled"] = false
  if (planeControlModeState.get()?.isMouseAimEnabled)
    comp["plane_input__mouseAimEnabled"] = true
  else if (planeControlModeState.get()?.isSimpleJoyEnabled)
    comp["plane_input__simpleJoyEnabled"] = true
}

planeControlModeState.subscribe(@(_mode) findPlaneInputQuery.perform(setControlMode))

ecs.register_es("set_preferred_plane_control", {
  onInit = setControlMode
}, comps, {tags="input"})

return {
  planeControlModeStateUpdate
}