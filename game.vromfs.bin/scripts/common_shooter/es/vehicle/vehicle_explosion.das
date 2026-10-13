require ecs
require app
require game.es.vehicle.vehicle_events
require dm
require vehicle
require DagorRandom
require DagorMath
require AnimV20
require GeomNodeTree
require math.base
require math.ang
require strings
require common_shooter.es.vehicle.vehicle_explosion_common

def on_damage_effect(eid : EntityId; is_exploded : bool; effects : int; offender : EntityId; gun_props_id : int; shell_id : int)
  if !is_exploded && (effects & (1 << int(DamageEffectType.DM_EFFECT_EXPL))) != 0
    sendEvent(eid, CmdExplosionFatal(offender = offender, gunPropsId = gun_props_id, shellId = shell_id))

[es(tag=server, REQUIRE=damage_model)]
def vehicle_hp_on_part_kill_explosion(evt : EventOnPartKillEffects; eid : EntityId; isExploded : bool; vehicle__isExplosionFatal : bool = true)
  if vehicle__isExplosionFatal
    on_damage_effect(eid, isExploded, evt.effects, evt.offender, evt.gunPropsId, evt.shellId)

[es(tag=server, REQUIRE=damage_model)]
def vehicle_hp_on_part_damage_explosion(evt : EventOnPartDamageEffects; eid : EntityId; isExploded : bool; vehicle__isExplosionFatal : bool = true)
  if vehicle__isExplosionFatal
    on_damage_effect(eid, isExploded, evt.effects, evt.offender, evt.gunPropsId, evt.shellId)

[es(tag=server, REQUIRE=damage_model, track=isExploded)]
def vehicle_kick_immune_crew_on_explosion(evt : Event;
                                          eid : EntityId;
                                          isExploded : bool;
                                          vehicle_seats__seatEids : EidList)
  if isExploded
    for seatEid in vehicle_seats__seatEids
      let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
      query(ownerEid) <| $ [es(REQUIRE_NOT=deadEntity)] (spawn_immunity__timer : float;
                                                         hitpoints__invulnerableTimeTo : float)
        if spawn_immunity__timer > 0.0 || hitpoints__invulnerableTimeTo > get_sync_time()
          sendEvent(eid, CmdKickFromVehicle(eid = ownerEid))

[es(tag=server, REQUIRE=damage_model, track=isExploded)]
def vehicle_spawn_explosion_env_effect(evt : Event;
                                       isExploded : bool;
                                       transform : float3x4;
                                       explosion_fx__envEffectName : string)
  if !isExploded || empty(explosion_fx__envEffectName)
    return
  createEntity(explosion_fx__envEffectName) <| $(var init)
    init |> set("transform", transform)

[es(tag=server, REQUIRE=damage_model, track=isExploded)]
def vehicle_velocity_bump_on_explosion(evt : Event;
                                       isExploded : bool;
                                       transform : float3x4;
                                       fire_damage__bumpOnExplosion : bool;
                                       fire_damage__explodeBumpVelRange : float2;
                                       var vehicle_net_phys : VehiclePhysActor&)
  if !isExploded || !fire_damage__bumpOnExplosion
    return
  let speed = rnd_float(fire_damage__explodeBumpVelRange.x, fire_damage__explodeBumpVelRange.y)
  let dir = -transform[1]
  vehicle_net_phys.phys |> wakeUp()
  let newVel = float3(vehicle_net_phys.phys.currentState.velocity) + dir * speed
  vehicle_net_phys.phys.currentState.velocity = DPoint3(newVel)

[es(REQUIRE=damage_model, track=isExploded, on_appear)]
def vehicle_open_hatches_on_explosion(evt : Event;
                                      eid : EntityId;
                                      isExploded : bool;
                                      fire_damage__openHatchesOnExplosion : bool;
                                      fire_damage__hatchAngles : Object;
                                      fire_damage__hatchPosOffsets : Object;
                                      fire_damage__hatchOpenChance : float;
                                      var fire_damage__hatchesOpened : bool&;
                                      var animchar : AnimcharBaseComponent)
  if !isExploded || !fire_damage__openHatchesOnExplosion || fire_damage__hatchesOpened
    return
  open_hatches_at_seed(eid, animchar, fire_damage__hatchAngles, fire_damage__hatchPosOffsets, fire_damage__hatchOpenChance)
  fire_damage__hatchesOpened = true
