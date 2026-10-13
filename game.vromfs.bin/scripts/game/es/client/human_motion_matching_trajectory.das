require ecs
require app
require math.base
require AnimV20
require DngHuman
require DagorMath
require MotionMatching
require enlisted.events_enlisted

// Run after phys update because we want to use up to date phys parameters, like `moveSpeedMult` or `isWishToMove`
[es(tag=gameClient, after=after_net_phys_sync)]
def motion_matching_set_wish_speed(act : ParallelUpdateFrameDelayed;
                                   human_net_phys : HumanActor;
                                   var mm_trajectory__wishLinearVelocity : float3&)
  assume phys = human_net_phys.phys
  if phys.currentState.isWishToMove
    var wishSpeed = phys |> human_phys_getWalkSpeed(phys.currentState.standState, phys.currentState.moveState)
    let useMoveSpeedMult = (phys.currentState.standState != HUStandState.ESS_CROUCH &&
                            phys.currentState.standState != HUStandState.ESS_CRAWL &&
                            phys.currentState.standState != HUStandState.ESS_DOWNED)
    wishSpeed *= useMoveSpeedMult ? phys.currentState.moveSpeedMult : phys.currentState.crawlCrouchSpeedMult
    if phys.currentState.moveState == HUMoveState.EMS_SPRINT
      wishSpeed *= phys.currentState.sprintSpeedMult
      if phys.currentState.sprintLerpSpeedMult != 1.f
        let runSpeed = phys |> human_phys_getWalkSpeed(phys.currentState.standState, HUMoveState.EMS_RUN) * phys.currentState.moveSpeedMult
        wishSpeed = lerp(runSpeed, wishSpeed, phys.currentState.sprintLerpSpeedMult)
    mm_trajectory__wishLinearVelocity = normalize(phys.currentState.velocity - phys.currentState.standingVelocity) * wishSpeed
  else
    mm_trajectory__wishLinearVelocity = float3(0f)

[es(tag=gameClient, REQUIRE=mm_trajectory__customUpdate, after=mm_update_root_orientation_es,
    before=(before_animchar_update_sync, mm_trajectory_track_history))]
def motion_matching_update_trajectory(act : ParallelUpdateFrameDelayed;
                                      human_net_phys : HumanActor;
                                      animchar : AnimcharBaseComponent;
                                      mm_trajectory__linearVelocityViscosity : float;
                                      mm_trajectory__angularVelocityViscosity : float;
                                      var motion_matching__controller : MotionMatchingController;
                                      var mm_trajectory__prevPosition : float3&;
                                      var mm_trajectory__prevRotation : float4&;
                                      var mm_trajectory__currPosition : float3&;
                                      var mm_trajectory__currRotation : float4&;
                                      var mm_trajectory__linearVelocity : float3&;
                                      var mm_trajectory__angularVelocity : float3&;
                                      var mm_trajectory__wishRotation : float4&;
                                      var mm_trajectory__historyPositions : Point3List)
  assume curState = human_net_phys.phys.currentState
  // position and linear velocity update
  mm_trajectory__prevPosition = mm_trajectory__currPosition
  var animcharTm : float3x4
  animchar |> animchar_get_tm(animcharTm)
  mm_trajectory__currPosition = animcharTm[3]
  let curVelocity = (mm_trajectory__currPosition - mm_trajectory__prevPosition) / (act.dt + 0.00001f) - curState.standingVelocity
  mm_trajectory__linearVelocity = approach(mm_trajectory__linearVelocity, curVelocity, act.dt, mm_trajectory__linearVelocityViscosity)

  for historyPos in mm_trajectory__historyPositions
    historyPos += curState.standingVelocity * act.dt

  // rotation and angular velocity update
  mm_trajectory__prevRotation = mm_trajectory__currRotation
  assume prevState = human_net_phys.phys.previousState
  if curState.moveState == HUMoveState.EMS_STAND
    let bodyDir = float3(curState.bodyOrientDir.x, 0.0, curState.bodyOrientDir.y)
    mm_trajectory__wishRotation = normalize(quat_from_unit_arc(MotionMatching::FORWARD_DIRECTION.xyz, bodyDir))
  else
    mm_trajectory__wishRotation = math::quat(animcharTm)

  if curState.moveState == HUMoveState.EMS_ROTATE_LEFT || curState.moveState == HUMoveState.EMS_ROTATE_RIGHT
    // update rotation for trajectory from phys data to match animations better
    let interpK = get_phys_interpk_clamped(human_net_phys.phys, get_sync_time())
    let bodyDir = lerp(prevState.bodyOrientDir, curState.bodyOrientDir, float2(interpK))
    let bodyDir3d = normalize(float3(bodyDir.x, 0f, bodyDir.y))
    mm_trajectory__currRotation = normalize(quat_from_unit_arc(MotionMatching::FORWARD_DIRECTION.xyz, bodyDir3d))
    let q = quat(mm_trajectory__currRotation) * inverse(quat(mm_trajectory__prevRotation))
    var angles : float3
    quat_to_euler(q, angles.x, angles.y, angles.z)
    let currAngVelocity = float3(0f, safediv(angles.x, act.dt), 0f)
    mm_trajectory__angularVelocity = approach(mm_trajectory__angularVelocity, currAngVelocity, act.dt, 0.01)
  else
    simple_spring_damper_exact_q(mm_trajectory__currRotation, mm_trajectory__angularVelocity,
        mm_trajectory__wishRotation, mm_trajectory__angularVelocityViscosity, act.dt)

  if (curState.moveState == HUMoveState.EMS_ROTATE_LEFT ||
      curState.moveState == HUMoveState.EMS_ROTATE_RIGHT ||
      curState.moveState == HUMoveState.EMS_STAND)
    if curState.moveState != prevState.moveState
      motion_matching__controller.rootSynchronization = false
      motion_matching__controller.rootClamping = true
      motion_matching__controller.rootClampingMaxDistance = 0f
      motion_matching__controller.rootClampingMaxAngle = PI * 0.6f
  else
    let newLimit = approach(motion_matching__controller.rootClampingMaxAngle, 0f, act.dt, mm_trajectory__angularVelocityViscosity)
    let eps = 1e-5
    if motion_matching__controller.rootClampingMaxAngle >= eps && newLimit < eps
      motion_matching__controller.rootSynchronization = true
    motion_matching__controller.rootClampingMaxAngle = newLimit

  if motion_matching__controller.rootSynchronization
    motion_matching__controller.rootRotation = mm_trajectory__currRotation
