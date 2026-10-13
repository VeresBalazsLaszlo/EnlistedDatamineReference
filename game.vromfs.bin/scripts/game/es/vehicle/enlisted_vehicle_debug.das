options no_aot
require ecs
require DngNet
require player
require DagorConsole
require DagorMath
require Plane
require dm
require DngDm
require AnimV20
require GeomNodeTree
require math.base
require math.ang

require game.utils.hero
require game.es.vehicle.vehicle_events
require game.es.server_debug_common
require game.es.vehicle.vehicle_seats_common
require game.es.net_console_macro
require game.es.flying_turret_common
require enlisted.events_enlisted
require gameLibs.console_commands.main.console_common
require common_shooter.es.vehicle.vehicle_damage_common
require daslib/strings_boost


// Target resolution: explicit ueid -> daeditor selection -> hero's seated vehicle.
// Camera-trace variants are in `enlisted_vehicle_client_debug.das` because DngCamera /
// GridCollision aren't on the dedicated server.
def resolve_target_ueid(ueid : uint) : uint
  if ueid != 0u
    return ueid
  var fallback = INVALID_ENTITY_ID
  query() <| $ [es(REQUIRE=daeditor__selected)] (eid : EntityId) { fallback = eid; }
  if fallback != INVALID_ENTITY_ID
    return uint(fallback)
  query() <| $ [es(REQUIRE=hero)] (human_anim__vehicleSelected : EntityId) { fallback = human_anim__vehicleSelected; }
  return uint(fallback)


// `detach_turret=true`: calls `do_detach_turret_server` directly because the
// auto-detach ES gates on `!fire_damage__isFatal`, which explosion_impl's
// DM_EFFECTS_MASK_ALL cascade sets via the fatal-fire effect on the ammo.
// `detach_turret=false`: sets losable_turret__suppressDetach so the auto-detach
// ES bails out cleanly (gates on `!suppressDetach`).
[console_cmd(name="vehicle.explosion")]
def vehicle_explosion(ueid : uint = 0u; detach_turret : bool = false)
  let resolvedUeid = resolve_target_ueid(ueid)

  if !is_server()
    exec_server_cmd("vehicle.explosion {resolvedUeid} {detach_turret}")
    return

  let vehicleEid = EntityId(resolvedUeid)
  if vehicleEid == INVALID_ENTITY_ID
    console_print("[vehicle.explosion] no vehicle found (pass ueid, select an entity in daeditor, or sit in a vehicle; use vehicle.explosion_cam for camera trace)")
    return
  if !detach_turret
    query(vehicleEid) <| $ [es] (var losable_turret__suppressDetach : bool&)
      losable_turret__suppressDetach = true
  sendEvent(vehicleEid, CmdExplosionFatal(offender = INVALID_ENTITY_ID, gunPropsId = -1, shellId = -1))
  if detach_turret
    var detachBone = "bone_turret"
    query(vehicleEid) <| $ [es] (losable_turret__detachBone : string = "bone_turret")
      detachBone = losable_turret__detachBone
    do_detach_turret_server(vehicleEid, detachBone)

// `full=true`: realistic cookoff -- starts a real burn on the first ammo DM part, engine
// cascades to CmdFireFatal then CmdExplosionFatal ~8s later. (Setting `fire_damage__isBurn=true`
// directly doesn't stick -- fire_damage_updater_es resets it next tick if no real burn entry.)
// `full=false`: visuals-only -- send CmdFireFatal without burn, tank catches fatal fire but
// never explodes. Useful for filming cookoff bursts in isolation.
[console_cmd(name="vehicle.cookoff")]
def vehicle_cookoff(ueid : uint = 0u; full : bool = true)
  let resolvedUeid = resolve_target_ueid(ueid)

  if !is_server()
    exec_server_cmd("vehicle.cookoff {resolvedUeid} {full}")
    return

  let tankEid = EntityId(resolvedUeid)
  if tankEid == INVALID_ENTITY_ID
    console_print("[vehicle.cookoff] no tank found (pass ueid, select an entity in daeditor, or sit in a vehicle; use vehicle.cookoff_cam for camera trace)")
    return

  if !full
    sendEvent(tankEid, CmdFireFatal(offender = INVALID_ENTITY_ID, gunPropsId = -1, shellId = -1))
    return

  query(tankEid) <| $ [es] (damage_model : DamageModel;
                            dm_phys_parts__ammoPartIds : IntList;
                            fire_damage__fireParamsPreset : string = "";
                            var fire_damage : FireDamageComponent&;
                            var fire_damage__isBurn : bool&;
                            var fire_damage__gunPropsId : int&;
                            var fire_damage__shellId : int&)
    if length(dm_phys_parts__ammoPartIds) == 0
      console_print("[vehicle.cookoff] tank has no ammo DM parts -- falling back to visuals-only")
      sendEvent(tankEid, CmdFireFatal(offender = INVALID_ENTITY_ID, gunPropsId = -1, shellId = -1))
      return
    vehicle_start_burn_part(tankEid, dm_phys_parts__ammoPartIds[0], INVALID_ENTITY_ID, -1, -1,
                            damage_model, fire_damage__fireParamsPreset,
                            fire_damage__isBurn, fire_damage__gunPropsId, fire_damage__shellId, fire_damage)

[console_cmd(name="vehicle.explosion_crash")]
def vehicle_explosion_crash(ueid : uint = 0u)
  let resolvedUeid = resolve_target_ueid(ueid)

  if !is_server()
    exec_server_cmd("vehicle.explosion_crash {resolvedUeid}")
    return

  let vehicleEid = EntityId(resolvedUeid)
  if vehicleEid == INVALID_ENTITY_ID
    console_print("[vehicle.explosion_crash] no vehicle found (pass ueid, select an entity in daeditor, or sit in a vehicle; use vehicle.explosion_crash_cam for camera trace)")
    return
  sendEvent(vehicleEid, CmdCrashExplosionFatal(offender = INVALID_ENTITY_ID, crashType = int(CrashType.CRASH_TYPE_LAND)))


// Rotate every `hatch_*` bone to an absolute angle (degrees from rest pose). Idempotent --
// reads rest TM from `originalNodeTree`, writes `restTm * rot(angle)` so repeated calls don't
// accumulate. Pass 0 to reset. Purely visual, no server forwarding. Assumes hatch_* bones
// aren't driven by the anim graph -- a future anim-controlled hatch would need a per-frame
// freeze ES to survive animchar.act() clobbering.
[console_cmd(name="vehicle.open_hatches")]
def vehicle_open_hatches(angle_deg : float = 90.0; ueid : uint = 0u)
  let resolvedUeid = resolve_target_ueid(ueid)
  let vehicleEid = EntityId(resolvedUeid)
  if vehicleEid == INVALID_ENTITY_ID
    console_print("[vehicle.open_hatches] no vehicle found (pass ueid, select an entity in daeditor, or sit in a vehicle)")
    return
  var found = false
  var hatchCount = 0
  query(vehicleEid) <| $ [es] (var animchar : AnimcharBaseComponent)
    found = true
    let rotM = make_rot_cw_zyx(float3(deg_to_rad(-angle_deg), 0.0, 0.0))
    let nodeCount = int((*animchar.nodeTree).nodeCount)
    for boneIdx in range(nodeCount)
      let boneName = string(*animchar.nodeTree |> geomtree_getNodeName(boneIdx))
      if !starts_with(boneName, "hatch")
        continue
      var restTm : float3x4
      *animchar.originalNodeTree |> geomtree_getNodeTmScalar(boneIdx, restTm)
      *animchar.nodeTree |> geomtree_setNodeTmScalar(boneIdx, restTm * rotM)
      hatchCount++
    console_print("[vehicle.open_hatches] eid={vehicleEid} hatches={hatchCount} angle={angle_deg}deg")
  if !found
    console_print("[vehicle.open_hatches] entity {vehicleEid} has no animchar")


[net_console_cmd(name="vehicle.spawnInVehicle")]
def vehicle_spawn_debug(vehicleTempl : string; @net_hero hero_eid : EntityId; @net_player player_eid : EntityId)
  query(hero_eid) <| $ [es] (eid : EntityId;
                             transform : float3x4;
                             squad_member__squad : EntityId;
                             human_anim__vehicleSelected : EntityId)
    query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList)
      kick_from_vehicle(hero_eid, human_anim__vehicleSelected, vehicle_seats__seatEids)

    let finalizeCreation <- @ <| (vehicleEid : EntityId)
      sendEventImmediate(player_eid, CmdUseVehicleOnSpawn(possessed = eid, squad = squad_member__squad, vehicle = vehicleEid, seatOrderNo = 0))

    createEntity("{vehicleTempl}", finalizeCreation) <| $(var init : ComponentsInitializer)
      var tm = transform
      tm[3] += float3(0., 1., 0.)
      set(init, "transform", tm)

[net_console_cmd(name="vehicle.resupply")]
def debug_plane_resupply(@net_hero eid : EntityId)
  query(eid) <| $ [es] (human_anim__vehicleSelected : EntityId)
    send_net_event(human_anim__vehicleSelected, CmdResupplyVehicle())


[console_processor]
def vehicle_spawn_debug_cmd_processor(args : array<string>;
                                      collect : bool;
                                      var hints : ConsoleProcessorHints)
  let cmd = "vehicle.spawnInVehicle"
  if collect
    let inputs <- args[0] |> split(" ")
    if length(inputs) >= 2
      add_hints([CommandArgDesc(name="vehicleTempl", hintType=CommandArgHintType.TemplateName)],
                cmd, inputs, /*hints_count*/ 20, /*threshold_cam_distance_sq*/ 2500.0, hints)
  return false
