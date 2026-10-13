import "%dngscripts/ecs.nut" as ecs
from "gameevents" import EventHeroChanged
from "%dngscripts/common_queries.nut" import get_controlled_hero
from "%ui/ui_library.nut" import *








let controlledHeroEid = Watched(ecs.INVALID_ENTITY_ID)

wlog(controlledHeroEid, "controlled: ")

ecs.register_es("controlled_hero_eid_init_es", {
  [["onInit", "onDestroy", "onChange"]] = function(_eid,comp){
    if (comp.is_local)
      controlledHeroEid.set(get_controlled_hero())
  }
}, {comps_track=[["possessed", ecs.TYPE_EID]], comps_ro=[["is_local", ecs.TYPE_BOOL]], comps_rq=["player"]})


ecs.register_es("controlled_hero_eid_es", {
  [EventHeroChanged] = function(evt, _eid, _comp){
    let e = evt[0]
    log($"controlledHeroEid = {e}")
    controlledHeroEid.set(e)
  }
}, {})

return{
  controlledHeroEid
}