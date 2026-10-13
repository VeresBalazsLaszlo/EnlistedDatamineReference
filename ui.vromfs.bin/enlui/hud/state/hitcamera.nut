import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/menus/game_menu.nut" import showGameMenu
from "dasevents" import CmdShowHitcamera, EventOnHitCameraControlEvent
from "hitcamera" import HITCAMERA_RENDER_READY, HITCAMERA_RENDER_DONE
from "%ui/ui_library.nut" import *

let hitcameraEid = mkWatched(persist, "hitcameraEid")
let hitcameraTargetEid = mkWatched(persist, "hitcameraTargetEid")
let totalMembersBeforeShot = mkWatched(persist, "totalMembersBeforeShot", 0)
let deadMembers = mkWatched(persist, "deadMembers", 0)

function showHitcamera(eid, target) {
  hitcameraEid.set(eid)
  hitcameraTargetEid.set(target)
  ecs.g_entity_mgr.sendEvent(eid, CmdShowHitcamera())
}

function onInit(_evt, eid, comp) {
  comp["hitcamera__locked"] = true
  totalMembersBeforeShot.set(comp["hitcamera__totalMembersBeforeShot"])
  deadMembers.set(comp["hitcamera__deadMembers"])
  if (hitcameraEid.get() != null) {
    
    if (comp["hitcamera__target"] == hitcameraTargetEid.get())
      showHitcamera(eid, comp["hitcamera__target"])
    return
  }

  showHitcamera(eid, comp["hitcamera__target"])
}

let nextHitcameraQuery = ecs.SqQuery("nextHitcameraQuery", {
  comps_ro=[["hitcamera__target", ecs.TYPE_EID], ["hitcamera__renderState", ecs.TYPE_INT]]
  comps_rq=["hitcamera"]
})
function onDestroy(_evt, eid, _comp) {
  if (eid != hitcameraEid.get())
    return

  local nextTarget = null
  nextHitcameraQuery(function (nextEid, nextComp) {
    if (nextEid != eid && (nextTarget == null || nextComp["hitcamera__target"] == nextTarget) && nextComp["hitcamera__renderState"] == HITCAMERA_RENDER_READY) {
      showHitcamera(nextEid, nextComp["hitcamera__target"])
      nextTarget = nextComp["hitcamera__target"]
    }
  })

  if (nextTarget == null) {
    hitcameraEid.set(null)
    hitcameraTargetEid.set(null)
  }
}

function onChange(_evt, _eid, comp) {
  let renderState = comp["hitcamera__renderState"]
  if (renderState == HITCAMERA_RENDER_DONE)
    comp["hitcamera__locked"] = false
}

function onControlEvent(_evt, _eid, _comp) {
  
  
}

ecs.register_es("hitcamera_ui_es", {
  onInit = onInit,
  onDestroy = onDestroy,
  onChange = onChange,
  [EventOnHitCameraControlEvent] = onControlEvent,
},
{
  comps_track=[["hitcamera__renderState", ecs.TYPE_INT],["hitcamera__target", ecs.TYPE_EID]]
  comps_rw=[["hitcamera__locked", ecs.TYPE_BOOL]]
  comps_ro=[["hitcamera__totalMembersBeforeShot", ecs.TYPE_INT], ["hitcamera__deadMembers", ecs.TYPE_INT]]
  comps_rq=["hitcamera"]
},
{ tags="gameClient", before="hitcamera_destroy_non_locked_es" })

return {
  isVisible = Computed(@() hitcameraEid.get() != null && !showGameMenu.get())
  totalMembersBeforeShot = totalMembersBeforeShot
  deadMembers = deadMembers
}