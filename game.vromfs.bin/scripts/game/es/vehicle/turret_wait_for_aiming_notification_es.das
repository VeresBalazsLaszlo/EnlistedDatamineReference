require game.es.events
require vehicle
require turrets
require DngWeapon
require game.utils.hero
require app
require ecs
require DngNet
require game.events_game
require math.base
require DagorMath
require DagorMathUtils


[es(tag=gameClient, REQUIRE=(resolvedTurret, turret_wait_for_aiming), track=turret_input__shootFlag)]
def turret_wait_for_aiming_notification_es(evt : Event;
                                           turret__owner : EntityId;
                                           turret_input__shootFlag : bool;
                                           turret_state : TurretState;
                                           turret__waitForAimingAngleDeg : float = 2.0)
  if !turret_input__shootFlag
    return

  let wishDir = angles_to_dir(float2(-turret_state.wishAngles.x, turret_state.wishAngles.y))
  let isAimed = dot(turret_state.shoot.dir, wishDir) >= cos(deg_to_rad(turret__waitForAimingAngleDeg))
  if isAimed
    return

  query(turret__owner) <| $ [es] (vehicle__localControls : VehicleControlsState;
                                  shootingBlockNotificationTime : int;
                                  var lastBlockNotificationAtTime : float&)
    let curTime = get_sync_time()
    let nextNotificationAtTime = lastBlockNotificationAtTime + float(shootingBlockNotificationTime)
    if curTime < nextNotificationAtTime || !can_control_turrets(vehicle__localControls)
      return

    send_net_event(get_controlled_hero(),
      CmdHeroLogEvent(event = "vehicle_turret_wait_for_aiming",
                      text = "vehicle/wait_for_aiming",
                      ttl = shootingBlockNotificationTime))
    lastBlockNotificationAtTime = curTime
