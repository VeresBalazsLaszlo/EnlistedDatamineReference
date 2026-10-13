import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "dasevents" import CmdCreateMapPoint
from "%ui/ui_library.nut" import *

function mapCoordsToReal(event, minimapState){
  let rect = event.targetRect
  let elemW = rect.r - rect.l
  let elemH = rect.b - rect.t
  let relX = (event.screenX - rect.l - elemW*0.5) * 2 / elemW
  let relY = (event.screenY - rect.t - elemH*0.5) * 2 / elemH
  let worldPos = minimapState.mapToWorld(relY, relX) 
  return worldPos
}

function command(event, minimapState){
  let worldPos = mapCoordsToReal(event, minimapState)
  ecs.g_entity_mgr.sendEvent(localPlayerEid.get(), CmdCreateMapPoint({x = worldPos.x, z = worldPos.z}))
}

return {
  command
}