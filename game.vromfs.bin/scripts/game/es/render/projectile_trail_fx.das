require ecs
require DngPhysObj
require fx


[es(tag=render, on_appear)]
def projectile_trail_fx_on_appear(evt : Event;
                                  transform : float3x4;
                                  projectile_trail_fx__flightFxTemplate : string;
                                  var projectile_trail_fx__flightFxEid : EntityId&;
                                  shell__turn_dir : bool = false)
  var resultTm = transform
  if shell__turn_dir
    resultTm[0] = -transform[2]
    resultTm[2] = transform[0]
  projectile_trail_fx__flightFxEid = createEntity(projectile_trail_fx__flightFxTemplate) <| $(var init)
    set(init, "transform", resultTm)


[es(tag=render, on_disappear)]
def projectile_trail_fx_on_disappear(evt : Event;
                                     projectile_trail_fx__flightFxEid : EntityId)
  destroyEntity(projectile_trail_fx__flightFxEid)


[es(tag=render, no_order)]
def projectile_trail_fx_on_update(info : UpdateStageInfoAct;
                                  transform : float3x4;
                                  phys_obj_net_phys : PhysObjActor;
                                  projectile_trail_fx__flightFxEid : EntityId;
                                  shell__turn_dir : bool = false)
  var resultTm = transform
  if shell__turn_dir
    resultTm[0] = -transform[2]
    resultTm[2] = transform[0]
  query(projectile_trail_fx__flightFxEid) <| $ [es] (var effect : TheEffect)
    let vel = normalize(phys_obj_net_phys.phys.currentState.velocity)
    effect_set_velocity(effect, vel)
    effect_set_emitter_tm(effect, resultTm)
