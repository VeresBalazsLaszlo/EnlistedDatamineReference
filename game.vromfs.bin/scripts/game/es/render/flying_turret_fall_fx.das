require ecs
require app
require PhysObj
require DagorMath
require math.base
require DngPhysObj
require CollRes
require enlisted.events_enlisted


[es(tag=render, on_appear)]
def flying_turret_fall_fx_on_appear(evt : Event;
                                    flying_turret_fall_fx__cooldownOnAppear : float;
                                    var flying_turret_fall_fx__nextTime : float&)
  flying_turret_fall_fx__nextTime = get_sync_time() + flying_turret_fall_fx__cooldownOnAppear


[es(tag=render, on_appear, REQUIRE=disableUpdate)]
def flying_turret_fall_fx_on_disable(evt : Event;
                                     var flying_turret_fall_fx__prevSpeed : float&)
  flying_turret_fall_fx__prevSpeed = 0.


[es(tag=render, REQUIRE_NOT=disableUpdate)]
def flying_turret_fall_fx_update(evt : ParallelUpdateFrameDelayed;
                                 transform : float3x4;
                                 collres : CollisionResource;
                                 phys_obj_net_phys : PhysObjActor;
                                 flying_turret_fall_fx__effectTemplate : string;
                                 flying_turret_fall_fx__minSpeedDrop : float;
                                 flying_turret_fall_fx__minSpeed : float;
                                 flying_turret_fall_fx__cooldown : float;
                                 var flying_turret_fall_fx__prevSpeed : float&;
                                 var flying_turret_fall_fx__nextTime : float&)
  var curSpeed = length_sq(float3(phys_obj_net_phys.phys.currentState.velocity))
  let prevSpeed = flying_turret_fall_fx__prevSpeed
  if curSpeed == 0.
    flying_turret_fall_fx__prevSpeed = 0.
    return
  curSpeed = sqrt(curSpeed)
  flying_turret_fall_fx__prevSpeed = curSpeed
  if prevSpeed < flying_turret_fall_fx__minSpeed
    return
  let drop = prevSpeed - curSpeed
  if drop < flying_turret_fall_fx__minSpeedDrop || evt.curTime < flying_turret_fall_fx__nextTime
    return
  flying_turret_fall_fx__nextTime = evt.curTime + flying_turret_fall_fx__cooldown
  var spawnTm = IDENT_TM
  spawnTm[3] = (transform * BBox3(collres.vFullBBox)).center
  createEntity(flying_turret_fall_fx__effectTemplate) <| $(var init : ComponentsInitializer)
    set(init, "transform", spawnTm)
