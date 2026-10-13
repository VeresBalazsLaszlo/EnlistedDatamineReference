import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "dasevents" import CmdParatroopersPointDeleted, CmdPickParatroopersPoint, CmdTurnParatroopersCamera, CmdParatroopersSpawnConfirm, sendNetEvent
from "%ui/hud/state/respawnState.nut" import selectedRespawnGroupId, showSquadSpawn, paratroopersPointSelectorOn, paratroopersOn, isParatroopersSquad
from "net" import get_sync_time
from "%ui/hud/menus/battle_area_screen_projections.nut" import battleAreaScreenProjection, projectionOn
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/ui_library.nut" import *

let newPointSelectTimer = Watched(-1.)
let paratroopersPointExisted = Watched(false)

let showParatroopersPointProjection = Computed(@() !isReplay.get() && showSquadSpawn.get() && projectionOn.get())

function paratroopers_turn(on){
  paratroopersOn.set(on)
  selectedRespawnGroupId.mutate(@(v) v["paratroopers"] <- on ? 0 : -1)
  newPointSelectTimer.set(on ? get_sync_time() + 0.3 : -1.)
  paratroopersPointExisted.set(on)
}

function delete_paratroopers_icon() {
  ecs.g_entity_mgr.sendEvent(localPlayerEid.get(), CmdParatroopersPointDeleted())
  paratroopers_turn(false)
}

showSquadSpawn.subscribe(function(v){
  if (!v) {
    delete_paratroopers_icon()
    projectionOn.set(false)
  }
})

isParatroopersSquad.subscribe(@(v) sendNetEvent(localPlayerEid.get(), CmdTurnParatroopersCamera({paratroopersCameraOn = v})))

paratroopersPointSelectorOn.subscribe(function(v) {
  if (v || showSquadSpawn.get())
    sendNetEvent(localPlayerEid.get(), CmdTurnParatroopersCamera({paratroopersCameraOn = v}))
  if (!v)
    paratroopersOn.set(false)
  else
    paratroopers_turn(paratroopersPointExisted.get())
})

ecs.register_es("paratroopers_icon_created", {
  [CmdParatroopersSpawnConfirm] = function() {
    if (paratroopersPointSelectorOn.get())
      paratroopers_turn(true)
    }
  },
  { comps_rq = ["respawner"] }
)

function pick_paratroopers_point(event){
  ecs.g_entity_mgr.sendEvent(localPlayerEid.get(), CmdPickParatroopersPoint({coordX = event.screenX, coordY = event.screenY}))
}

function paratroopersPointSelectorPanel(){
  if (!showParatroopersPointProjection.get())
    return @(){}
  return  @(){
    size = const [sw(100), sh(100)]
    behavior = Behaviors.Button
    onClick = @(event) get_sync_time() < newPointSelectTimer.get() ? null : pick_paratroopers_point(event)
    children = [battleAreaScreenProjection]
    animations = [
      { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true }
      { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.3, playFadeOut = true }
    ]
  }
}

let paratroopers_point_ctor = {
  ctor = paratroopersPointSelectorPanel
  watch = [showParatroopersPointProjection]
}

return {
  paratroopers_point_ctor,
  delete_paratroopers_icon,
}
