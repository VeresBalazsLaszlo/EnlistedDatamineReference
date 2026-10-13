require ecs
require game.es.input.input_events
require math.base

[es(tag=input, before=free_cam_es, REQUIRE=replay_camera__tpsFree)]
def replay_free_cam_input_action_es(evt : EventDaInputActionTriggered;
                                    free_cam_input__speedUp : uint16;
                                    free_cam_input__speedDown : uint16;
                                    free_cam_input__speedReset : uint16;
                                    free_cam__moveSpeedDefault : float;
                                    free_cam_input__toggleDir : uint16;
                                    free_cam_input__resetRoll : uint16;
                                    var replay_camera__currentRoll : float&;
                                    var free_cam__move_speed : float&;
                                    var replay_camera__useFixedDirection : bool&;
                                    free_cam__moveSpeedChangeFactor = 1.03)
  if evt.action == free_cam_input__speedUp
    free_cam__move_speed *= free_cam__moveSpeedChangeFactor
  elif evt.action == free_cam_input__speedDown
    free_cam__move_speed /= free_cam__moveSpeedChangeFactor
  elif evt.action == free_cam_input__speedReset
    free_cam__move_speed = free_cam__moveSpeedDefault
  elif evt.action == free_cam_input__toggleDir
    replay_camera__useFixedDirection = !replay_camera__useFixedDirection
  elif evt.action == free_cam_input__resetRoll
    replay_camera__currentRoll = 0.0

[es(after=replay_free_cam_input_action_es, REQUIRE=replay_camera__tpsFree, before=replay_tps_free_camera_follow_es)]
def replay_free_cam_movement_update_es(info : UpdateStageInfoAct;
                                       var free_cam__move : float2&;
                                       camera__active : bool;
                                       free_cam__move_speed : float;
                                       free_cam__shiftY : float;
                                       replay_camera__stopInertia : float;
                                       replay_camera__moveInertia : float;
                                       replay_camera__useFixedDirection : bool;
                                       replay_camera__fixedTransform : float3x4;
                                       replay_camera__trackingEnabled : bool = false;
                                       var replay_camera__freeLinVel : float3&;
                                       var transform : float3x4&;
                                       var replay_camera__offset : float3?)
  if !camera__active
    replay_camera__freeLinVel = float3()
    free_cam__move = float2()
    return

  var mov : float3
  if replay_camera__useFixedDirection
    mov = (replay_camera__fixedTransform[2] * free_cam__move.y + replay_camera__fixedTransform[0] * free_cam__move.x)
  else
    mov = (transform[2] * free_cam__move.y + transform[0] * free_cam__move.x)
  let movY = float3(0.0, 1.0, 0.0) * free_cam__shiftY
  mov += movY
  let inertion = length_sq(mov) < 1.0E-5 ? replay_camera__stopInertia : replay_camera__moveInertia
  replay_camera__freeLinVel = replay_camera__freeLinVel * inertion + mov * (free_cam__move_speed * (1. - inertion))
  if length_sq(replay_camera__freeLinVel) > 1.0E-5
    if replay_camera__trackingEnabled && replay_camera__offset != null
      *replay_camera__offset = *replay_camera__offset + replay_camera__freeLinVel * (1. / 60.)
    else
      transform[3] = transform[3] + replay_camera__freeLinVel * (1. / 60.)
  free_cam__move = float2()
