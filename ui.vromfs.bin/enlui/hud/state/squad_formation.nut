import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/dasenums.nut" import SquadFormationSpread
from "dasevents" import sendNetEvent, RequestSquadFormation
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "settings" import save_settings, get_setting_by_blk_path, set_setting_by_blk_path
from "%dngscripts/common_queries.nut" import find_local_player
from "%ui/ui_library.nut" import *

let savedSquadFormationOrders = get_setting_by_blk_path("ai/squadFormationOrder") ?? {}
let DEFAULT_FORMATION = SquadFormationSpread.ESFN_STANDARD
let squadFormation = Watched(DEFAULT_FORMATION)


function applyNewFormation(squadEid, formation) {
  sendNetEvent(squadEid, RequestSquadFormation({spread=formation}))
  squadFormation.set(formation)
}

function saveSquadFormation(squadProfileId, formation) {
  savedSquadFormationOrders[squadProfileId] <- formation
  set_setting_by_blk_path("ai/squadFormationOrder", savedSquadFormationOrders)
  save_settings()
}


let heroSquadEidQuery = ecs.SqQuery("heroSquadEidQuery", {
  comps_ro=[["squad_member__squad", ecs.TYPE_EID]]
})

let squadProfileIdQuery = ecs.SqQuery("squadProfileIdQuery", {
  comps_ro=[["squad__squadProfileId", ecs.TYPE_STRING]]
})

function setSquadFormation(formation) {
  heroSquadEidQuery(controlledHeroEid.get(), function(_, comp) {
    let squadEid = comp.squad_member__squad
    applyNewFormation(squadEid, formation)
    squadProfileIdQuery(squadEid, @(_, prflComp) saveSquadFormation(prflComp.squad__squadProfileId, formation))
  })
}


function applyFormationOrderOnSpawnSquad(_evt, eid, comp) {
  if (comp.squad__ownerPlayer == ecs.INVALID_ENTITY_ID || comp.squad__ownerPlayer != find_local_player())
    return
  let squadProfileId = comp.squad__squadProfileId

  if (squadProfileId in savedSquadFormationOrders)
    applyNewFormation(eid, savedSquadFormationOrders[squadProfileId])
  else
    squadFormation.set(DEFAULT_FORMATION)
}

ecs.register_es("apply_squad_formation_order_es", {
    [[ecs.EventEntityCreated, ecs.EventComponentsAppear]] = applyFormationOrderOnSpawnSquad
  },
  { comps_ro = [["squad__squadProfileId", ecs.TYPE_STRING], ["squad__ownerPlayer", ecs.TYPE_EID]] },
  { tags = "gameClient" }
)

return {
  setSquadFormation
  squadFormation
}
