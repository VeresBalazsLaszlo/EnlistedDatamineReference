require ecs
require ecs.safe
require soundHash
require soundSystem
require soundEvent
require sound_utils.modules.sound_player_common
require sound_utils.modules.sound_control_common
require gameLibs.pufd_events.pufd_events
require common_sounds.modules.common_sounds_events
require human_sounds.modules.human_steps_sound_common
require DngHuman
require game.utils.hero
require game.utils.team
require DagorMath
require DagorSystem
require math.base
require strings
require DngNet


[es(tag=sound, after=(sound_biome_puddle_queries_update, sound_begin_update_es), before=(human_steps_sound_update, sound_end_update_es))]
def human_steps_sound_states_from_human_net_phys(info : ParallelUpdateFrameDelayed;
                                                 human_net_phys : HumanActor;
                                                 animchar__animSpeed : float;
                                                 var human_steps_sound__moveState : int&;
                                                 var human_steps_sound__animSpeed : float&)

  human_steps_sound__moveState = int(human_net_phys.phys.currentState.moveState)
  human_steps_sound__animSpeed = animchar__animSpeed


def human_steps_sound_states_from_human_navmesh_phys_impl(speed : float;
                                                          navmesh_phys__walkSpeedModifier = 0.5;
                                                          var human_steps_sound__moveState : int&;
                                                          var human_steps_sound__animSpeed : float&)
  // navmesh_move_anim es related
  human_steps_sound__animSpeed = speed
  if speed > navmesh_phys__walkSpeedModifier * 1.1
    human_steps_sound__moveState = int(HUMoveState.EMS_RUN)
  elif speed > FLT_EPSILON
    human_steps_sound__moveState = int(HUMoveState.EMS_WALK)
  else
    human_steps_sound__moveState = int(HUMoveState.EMS_STAND)


[es(tag=sound, REQUIRE_NOT=(human_net_phys, human_net_phys, loc_snapshots__snapshotData), after=sound_begin_update_es, before=human_steps_sound_update)]
def human_steps_sound_states_from_human_navmesh_phys_offline(info : ParallelUpdateFrameDelayed;
                                                             navmesh_phys__currentWalkVelocity : float3;
                                                             navmesh_phys__walkSpeedModifier = 0.5;
                                                             var human_steps_sound__moveState : int&;
                                                             var human_steps_sound__animSpeed : float&)
  // navmesh_move_anim es related
  let speed = length(navmesh_phys__currentWalkVelocity)
  human_steps_sound_states_from_human_navmesh_phys_impl(speed, navmesh_phys__walkSpeedModifier, human_steps_sound__moveState, human_steps_sound__animSpeed)


[es(tag=sound, REQUIRE_NOT=human_net_phys, after=sound_begin_update_es, before=human_steps_sound_update)]
def human_steps_sound_states_from_human_navmesh_phys_online(info : ParallelUpdateFrameDelayed;
                                                            loc_snapshots__snapshotData : LocSnapshotsList;
                                                            navmesh_phys__walkSpeedModifier = 0.5;
                                                            var human_steps_sound__moveState : int&;
                                                            var human_steps_sound__animSpeed : float&)
  // navmesh_move_anim es related
  var speed = 0.
  let n = length(loc_snapshots__snapshotData)
  if n >= 2
    let begin = loc_snapshots__snapshotData[0].pos
    let end = loc_snapshots__snapshotData[n - 1].pos
    let time = float(loc_snapshots__snapshotData[n - 1].atTime - loc_snapshots__snapshotData[0].atTime)
    let vel = (end - begin) / time
    speed = length(vel)
  human_steps_sound_states_from_human_navmesh_phys_impl(speed, navmesh_phys__walkSpeedModifier, human_steps_sound__moveState, human_steps_sound__animSpeed)


def get_step_volume(distance_to_volume_friendly, distance_to_volume_enemy : float4;
                    team : int;
                    is_watched_sound : bool;
                    listener, pos : float3)

  if is_watched_sound
    return 1.

  let heroTeam = get_int(get_controlled_hero(), "team") ?? TEAM_UNASSIGNED
  let r = is_teams_friendly(team, heroTeam) ? distance_to_volume_friendly : distance_to_volume_enemy
  return cvt(distance(listener, pos), r.x, r.y, r.z, r.w)


def use_generator(enable_for_visible, enable_for_invisible, updatable, visible : bool; move_state : int; stand_state : HUStandState)
  if move_state == int(HUMoveState.EMS_ROTATE_LEFT) || move_state == int(HUMoveState.EMS_ROTATE_RIGHT) || stand_state == HUStandState.ESS_CRAWL
    return false
  if (!updatable || !visible) && enable_for_invisible
    return true
  return (move_state == int(HUMoveState.EMS_SPRINT) || move_state == int(HUMoveState.EMS_RUN)) && enable_for_visible


[es(tag=sound, after=(sound_biome_puddle_queries_update, sound_begin_update_es), before=sound_end_update_es)]
def human_steps_sound_update(info : ParallelUpdateFrameDelayed)

  let listenerPos = get_listener_pos()

  query() <| $ [es(REQUIRE_NOT=deadEntity)] (eid : EntityId;
                                             sound_control__state : int = default_sound_control_state();

                                             transform : float3x4;
                                             is_watched_sound : bool;

                                             human_net_phys__states : int = int(StateFlag.ST_ON_GROUND);
                                             human_net_phys__isClimbing : bool = false;
                                             var human_net_phys : HumanActor?;

                                             animchar__animSpeed : float;
                                             animchar__updatable : bool;
                                             animchar__visible : bool;

                                             human_steps_sound__moveState : int;
                                             human_steps_sound__animSpeed : float;
                                             human_steps_sound__animSpeedMul : float;
                                             human_steps_sound__farawayThresholdSq : float;
                                             @shared_comp human_steps_sound__irqs : Array;

                                             var human_steps_sound__irqObjIdx : int&;
                                             var human_steps_sound__physStates : int&;
                                             var human_steps_sound__lastTimeOnGround : float&;

                                             var sound_biome_puddle_queries_vars__speedSq : float&;

                                             var human_steps_sound_generator__lastStepAt_cooldown : float2&;
                                             human_steps_sound_generator__walkRunSprint_stand_intervals : float3;
                                             human_steps_sound_generator__walkRunSprint_crouch_intervals : float3;
                                             human_steps_sound_generator__enableForVisible : bool;
                                             human_steps_sound_generator__enableForInvisible : bool;
                                             human_steps_sound_generator__enableAlways : bool)

    if !have_sound(sound_control__state) || is_faraway_step(is_watched_sound, transform[3], human_steps_sound__farawayThresholdSq, listenerPos)
      sound_biome_puddle_queries_vars__speedSq = 0.
      human_steps_sound__physStates = human_net_phys__states
      human_steps_sound__irqObjIdx = INVALID_IRQ_OBJ_IDX
      return

    var standState = HUStandState.ESS_STAND
    var moveState = human_steps_sound__moveState
    var animSpeed = human_steps_sound__animSpeed
    if human_net_phys != null
      standState = human_net_phys.phys.currentState.standState
      moveState = int(human_net_phys.phys.currentState.moveState)
      animSpeed = animchar__animSpeed

    // <find irqObjIdx using generator>
    var irqObjIdx = INVALID_IRQ_OBJ_IDX
    assume last_step_at = human_steps_sound_generator__lastStepAt_cooldown.x
    assume cooldown = human_steps_sound_generator__lastStepAt_cooldown.y
    let animspeed = animSpeed * human_steps_sound__animSpeedMul
    let useGenerator = (human_steps_sound_generator__enableAlways || use_generator(human_steps_sound_generator__enableForVisible, human_steps_sound_generator__enableForInvisible, animchar__updatable, animchar__visible, moveState, standState)) && animspeed > VERY_SMALL_NUMBER
    if moveState == int(HUMoveState.EMS_STAND) || standState == HUStandState.ESS_DOWNED || !read_state(StateFlag.ST_ON_GROUND, human_net_phys__states) || human_net_phys__isClimbing
      cooldown = min(cooldown + info.dt, 1.)
      irqObjIdx = INVALID_IRQ_OBJ_IDX
    else
      cooldown = max(0., cooldown - info.dt)
      if human_steps_sound__irqObjIdx == INVALID_IRQ_OBJ_IDX && !useGenerator
        irqObjIdx = INVALID_IRQ_OBJ_IDX
      elif useGenerator
        assume stand_intervals = human_steps_sound_generator__walkRunSprint_stand_intervals
        assume crouch_intervals = human_steps_sound_generator__walkRunSprint_crouch_intervals
        let intervals = (standState == HUStandState.ESS_CROUCH ? crouch_intervals : stand_intervals)
        let interval = (moveState == int(HUMoveState.EMS_SPRINT)) ? intervals.z : (moveState == int(HUMoveState.EMS_RUN)) ? intervals.y : intervals.x
        let step = safediv(interval, animspeed)
        cooldown = min(cooldown, step * 0.5)
        if info.curTime >= last_step_at + step
          last_step_at = info.curTime
          if cooldown <= 0.
            //logerr("[GENERATOR] moveState={moveState}  standState={standState} interval={interval} animSpeed={animspeed} curTime={info.curTime}")
            irqObjIdx = get_desc_id_from_human_state(moveState, standState, human_steps_sound__irqs)
      elif human_steps_sound__irqObjIdx != INVALID_IRQ_OBJ_IDX
        let irqCooldown = 0.2
        if (info.curTime - last_step_at) * animspeed >= irqCooldown
          last_step_at = info.curTime
          //logerr("[IRQ] stepDt={info.curTime - last_step_at} animSpeed={animspeed} moveState={moveState}  standState={standState}")
          irqObjIdx = human_steps_sound__irqObjIdx
    // </find irqObjIdx>

    human_steps_sound__irqObjIdx = INVALID_IRQ_OBJ_IDX
    sound_biome_puddle_queries_vars__speedSq = human_net_phys != null ? length_sq((*human_net_phys).phys.currentState.velocity.xz) : 0.

    let descId = human_steps_sound_update_states(info.curTime,
                                                 human_net_phys__states,
                                                 human_steps_sound__physStates,
                                                 human_steps_sound__lastTimeOnGround)

    if irqObjIdx == INVALID_IRQ_OBJ_IDX && empty(descId)
      return

    query(eid) <| $ [es] (sound_preset__isLoaded : bool;
                          sound_tags : Object;
                          team : int;

                          var sound_event_group : SoundEventGroup&;
                          human_steps_sound__traceStepOffsetLen : float2;
                          human_steps_sound__distanceToVolumeFriendly : float4;
                          human_steps_sound__distanceToVolumeEnemy : float4;

                          @shared_comp human_steps_sound__path : Object;
                          @shared_comp human_steps_sound__descs : Object;
                          @shared_comp human_steps_sound__stepFx : Object;

                          var human_steps_sound__waterDepth : float&;
                          var human_steps_sound__smid : int&;
                          var human_steps_sound__stepIdx : uint&;

                          sound_biome_puddle_queries__biomeId : int;
                          sound_biome_puddle_queries__puddleDepth : float;

                          human_steps_sound_occlusion__blob : SoundOcclusionBlob&)
      if !sound_preset__isLoaded
        return

      var desc : Object const? = null
      var shouldTraceEnemy = false
      if !empty(descId)
        desc = sound_player_common::get_desc(human_steps_sound__descs, descId)
        shouldTraceEnemy = false
      elif irqObjIdx != INVALID_IRQ_OBJ_IDX
        desc = human_steps_sound__irqs?[irqObjIdx] ?as Object
        shouldTraceEnemy = (human_steps_sound__stepIdx & 1u) != 0u
        ++human_steps_sound__stepIdx

        if (human_steps_sound__stepIdx & 3u) == 0u && desc != null
          let stepFxPath = human_steps_sound__stepFx[desc.name ?? ""] ?as Object
          if stepFxPath != null
            let handle = sound_player_common::play_path(*stepFxPath, sound_tags, is_watched_sound, transform[3], sound_hash(""), sound_event_group)
            attach_to_blob(handle, human_steps_sound_occlusion__blob)
            detach_occlusion(handle)

      if desc != null
        let volume = get_step_volume(human_steps_sound__distanceToVolumeFriendly, human_steps_sound__distanceToVolumeEnemy, team, is_watched_sound, listenerPos, transform[3])
        var handle = play_footstep(*desc,
                      human_steps_sound__path,
                      sound_tags,
                      volume,
                      eid,
                      transform[3],
                      transform[1],
                      shouldTraceEnemy,
                      is_watched_sound,
                      human_steps_sound__traceStepOffsetLen,
                      sound_biome_puddle_queries__biomeId,
                      sound_biome_puddle_queries__puddleDepth,
                      human_steps_sound__smid,
                      human_steps_sound__waterDepth,
                      human_net_phys,
                      "",
                      false)
        attach_to_blob(handle, human_steps_sound_occlusion__blob)
        detach_occlusion(handle)
        abandon(handle)


[es(tag=sound, REQUIRE_NOT=deadEntity)]
def human_steps_sound_irq(evt : CmdSoundStepIrq;
                          var human_steps_sound__irqObjIdx : int&)
  human_steps_sound__irqObjIdx = evt.objIdx


[es(tag=sound, on_appear)]
def human_steps_sound_on_appear(evt : Event;
                                human_steps_sound__tag : string;
                                var sound_flags : Object&)
  raise_sound_tag(human_steps_sound__tag, sound_flags)


[es(tag=sound, on_event=ParallelUpdateFrameDelayed)]
def human_steps_sound_occlusion(evt : Event;
                                sound_control__state : int;
                                is_watched_sound : bool = false;
                                isAlive : bool = true;
                                var human_steps_sound_occlusion__blob : SoundOcclusionBlob&;
                                human_steps_sound_occlusion__blobRadius : float;
                                transform : float3x4)
  let shouldPlay = have_sound(sound_control__state) && !is_watched_sound && isAlive
  if shouldPlay
    let pos = transform[3] + transform[1] * human_steps_sound_occlusion__blobRadius
    if is_inside_active_occlusion_range(pos)
      if is_valid_handle_value(human_steps_sound_occlusion__blob)
        set_pos(human_steps_sound_occlusion__blob, pos)
      else
        human_steps_sound_occlusion__blob |> create_blob(pos, 0./*attach radius*/, human_steps_sound_occlusion__blobRadius)
      return
  if is_valid_handle_value(human_steps_sound_occlusion__blob)
    human_steps_sound_occlusion__blob |> delete_blob()
