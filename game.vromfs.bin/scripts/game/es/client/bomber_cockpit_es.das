require ecs
require math
require vehicle
require DagorMath
require GeomNodeTree
require AnimV20
require DagorSystem
require Plane
require DngPlane
require DaWeaponProps
require BombImpactCalculator
require enlisted.events_enlisted
require app

[es(tag=gameClient)]
def bomber_cockpit_monitor_bomb_ammo_es(info : ParallelUpdateFrameDelayed;
                                        turret_control__gunEids : EidList;
                                        var bomber_cockpit__hasLoadedBombs : bool&)
  var hasBombs = false
  for gunEid in turret_control__gunEids
    if hasBombs
      break
    query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret__triggerGroup : int; gun__ammo : int)
      if turret__triggerGroup == int(PlaneTrigger.BOMBS) && gun__ammo > 0
        hasBombs = true
  bomber_cockpit__hasLoadedBombs = hasBombs

[es(tag=gameClient, on_appear, after=plane_turret_init_triggers, REQUIRE=resolvedTurret)]
def bomber_cockpit_init_impact_calc_es(evt : Event;
                                       turret__owner : EntityId;
                                       turret__triggerGroup : int;
                                       gun__curShellId : ShellPropIds)
  if turret__triggerGroup != int(PlaneTrigger.BOMBS)
    return
  query(turret__owner) <| $ [es] (plane_net_phys : PlaneActor;
                                  var bomb_impact_calculator : BombImpactCalculator&;
                                  var bomber_cockpit__impactCalcInited : bool&)
    let p2 = float2(0., 0.)
    if !bomber_cockpit__impactCalcInited && bomb_impact_calculator_init(bomb_impact_calculator, plane_net_phys.phys, int(gun__curShellId.shellId), 0.0, 0.0, p2, 0.0, 30)
      bomber_cockpit__impactCalcInited = true

[es(tag=gameClient)]
def bomber_cockpit_update_impact_calc_es(info : ParallelUpdateFrameDelayed;
                                         bomber_cockpit__impactCalcInited : bool;
                                         bomber_cockpit__active : bool;
                                         var bomb_impact_calculator : BombImpactCalculator&;
                                         var bomber_cockpit__lookAtPos : float3&;
                                         var turretAimPos : float3&;
                                         var isTurretAimPosValid : bool&;
                                         var vehicle_sight__opacity : float&)
  if !bomber_cockpit__impactCalcInited || !bomber_cockpit__active
    return
  let p2 = float2(0., 0.)
  bomb_impact_calculator_update(bomb_impact_calculator, get_sync_time(), info.dt, 0.0, false, p2, 0.0)
  bomber_cockpit__lookAtPos = bomb_impact_calculator.impactPoint
  turretAimPos = bomber_cockpit__lookAtPos
  isTurretAimPosValid = true
  vehicle_sight__opacity = 1.0

[es(tag=gameClient, on_appear)]
def bomber_cockpit_resolve_node_es(evt : Event;
                                   eid : EntityId;
                                   animchar : AnimcharBaseComponent;
                                   bomber_cockpit__cameraNodeName : string;
                                   var bomber_cockpit__cameraNodeId : int&)
  bomber_cockpit__cameraNodeId = geomtree_findNodeIndex(*animchar.nodeTree, bomber_cockpit__cameraNodeName)
  if bomber_cockpit__cameraNodeId < 0
    logerr("[bomber_cockpit] node /*{bomber_cockpit__cameraNodeName}*/ not found for /*{eid}*/ /*{getEntityTemplateName(eid)}*/")

[es(tag=gameClient, track=vehicleCameraType)]
def bomber_cockpit_reset_active_on_camera_change_es(evt : Event;
                                                    vehicleCameraType : int;
                                                    var bomber_cockpit__active : bool&)
  if vehicleCameraType != int(VehicleCameraType.VEHICLE_CAMERA_DRIVER) && vehicleCameraType != int(VehicleCameraType.VEHICLE_CAMERA_BOMBER_COCKPIT)
    bomber_cockpit__active = false

[es(tag=gameClient)]
def bomber_cockpit_update_can_toggle_es(info : ParallelUpdateFrameDelayed;
                                        vehicleCameraType : int;
                                        bomber_cockpit__hasLoadedBombs : bool;
                                        bomber_cockpit__impactCalcInited : bool;
                                        var bomber_cockpit__canToggle : bool&)
  bomber_cockpit__canToggle = (vehicleCameraType == int(VehicleCameraType.VEHICLE_CAMERA_DRIVER) &&
                              bomber_cockpit__impactCalcInited && bomber_cockpit__hasLoadedBombs)
