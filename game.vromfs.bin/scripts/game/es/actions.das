require ecs
require game.events_game
require game.es.action_common
require PhysVars

[es(tag=netClient, REQUIRE=actions)]
def actions_run_es(evt : RunActionCmd; eid : EntityId)
  run_action_by_id(eid, evt.id, evt.overridePropsId, -1, evt.overrideTime,
    evt.overrideAt, evt.actionPeriod, evt.progress, evt.timeMult)

[es(on_appear)]
def register_action_variation_var(evt : Event;
                                  var phys_vars : PhysVars;
                                  var human_anim__actionVariationVarId : int&)
  human_anim__actionVariationVarId = registerVar(phys_vars, "action_variation", 0.0)