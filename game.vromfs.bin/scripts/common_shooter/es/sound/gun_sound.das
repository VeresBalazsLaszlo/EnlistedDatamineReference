require ecs
require ecs.safe
require app
require soundEvent
require soundHash
require soundSystem
require weapon_sounds.modules.weapon_sounds_events
require common_sounds.modules.common_sounds_events
require common_shooter.es.sound.gun_sound_common
require gameLibs.pufd_events.pufd_events
require sound_utils.modules.sound_player_common
require sound_utils.modules.sound_utils_events
require common_shooter.events_common_shooter
require Gun
require DagorMath
require DagorSystem


def is_oneshot(gun : Gun; firing_mode : uint)
  return gun_getFiringMode(gun, int(firing_mode)).modeType != EFiringModeType.EFM_AUTOMATIC


def abandon_shot_loop(var sound_event : SoundEvent&; turret__owner : EntityId)
  if is_valid_handle_value(sound_event)
    set_var_optional(sound_event, "shot", 0.)
    query(turret__owner) <| $ [es] (var gun_owner_sound_event_group : SoundEventGroup&)
      remove_sound(gun_owner_sound_event_group, sound_event)
    abandon(sound_event)


def get_smid_from_gun_owner(gun__owner : EntityId) : int
  var smid = 0
  query(gun__owner) <| $ [es] (human_steps_sound__smid : int)
    smid = human_steps_sound__smid
  return smid


def on_launch(launch_pos : float3;
              firing_mode : uint;
              gun : Gun;
              time_between_shots : float;
              force_oneshot, force_oneshot_enemy : bool;
              var sound_event : SoundEvent&;
              time_between_shots_mad : float2;
              var shot_loop_timeout : float&;
              gun__owner : EntityId;
              turret__owner : EntityId;
              shot_path : Object;
              tags : Object;
              gun_sound__blob : SoundOcclusionBlob&)

  let isWatched = is_watched_gun_sound(gun__owner)
  if sound_event.enabled != isWatched
    abandon_shot_loop(sound_event, turret__owner)
    sound_event.enabled = isWatched

  let forceOneshot = isWatched ? force_oneshot : force_oneshot_enemy
  let isOneshot = forceOneshot || is_oneshot(gun, firing_mode)
  var isLoop = false

  if isOneshot
    abandon_shot_loop(sound_event, turret__owner)
    let path = make_gun_shot_sound_path_str(shot_path, tags, isWatched, true)
    var handle = sound_player_common::play_name_path(path, "", launch_pos, false/*is_abandon*/)
    if isWatched
      set_var_optional(handle, "mat", float(get_smid_from_gun_owner(gun__owner)))
    attach_to_blob(handle, gun_sound__blob)
    abandon(handle)
  else
    isLoop = is_valid_handle_value(sound_event)
    if !is_valid_handle_value(sound_event)
      let path = make_gun_shot_sound_path_str(shot_path, tags, isWatched, false)
      var hasGroup = false
      query(turret__owner) <| $ [es] (var gun_owner_sound_event_group : SoundEventGroup&)
        hasGroup = true
        if !has_sound(gun_owner_sound_event_group, path, "")
          sound_event |> reset(sound_player_common::play_name_path_impl(path, "", launch_pos, false))
          if get_num_sounds(gun_owner_sound_event_group) < get_max_capacity(gun_owner_sound_event_group)
            add_sound(gun_owner_sound_event_group, sound_hash(""), float3(0., 0., 0.), sound_event, 0)
          else
            sound_debug("gun_owner_sound_event_group max capacity reached ({get_num_sounds(gun_owner_sound_event_group)}), sound will flange")
      if !hasGroup
        sound_event |> reset(set_var_optional_and_play("shot", 1., "", path, launch_pos))

    if is_valid_handle_value(sound_event)
      set_pos(sound_event, launch_pos)
      if isWatched
        set_var_optional(sound_event, "mat", float(get_smid_from_gun_owner(gun__owner)))
      set_var_optional(sound_event, "shot", 1.)
      attach_to_blob(sound_event, gun_sound__blob)

  broadcastEvent(EventOnWeaponSound(pos = launch_pos, isLoop = isLoop))
  shot_loop_timeout = time_between_shots * time_between_shots_mad.x + time_between_shots_mad.y


[es(tag=sound, REQUIRE=gunSound, on_event=(CmdStopShoot, CmdNetStopShoot))]
def gun_sound__on_stop_shot(evt : Event;
                            gun_sound__event : SoundEvent&)
  set_var_optional(gun_sound__event, "shot", 0.)


[es(tag=sound, REQUIRE=gunSound)]
def gun_sound_on_shot(evt : EventShot;
                      gun : Gun;
                      gun__timeBetweenShots : float = 0.;
                      gun_sound__forceOneshot : bool;
                      gun_sound__forceOneshotEnemy : bool;
                      var gun_sound__event : SoundEvent&;
                      gun_sound__playerTimeBetweenShotsMad : float2;
                      var gun_sound__shotLoopTimeout : float&;
                      gun__owner : EntityId;
                      turret__owner = INVALID_ENTITY_ID;
                      @shared_comp gun_sound__shotPath : Object;
                      sound_tags : Object;
                      gun_sound__blob : SoundOcclusionBlob&)
  if sound_banks_is_master_preset_loaded()
    on_launch(evt.launchDesc.tm[3],
              evt.launchDesc.firingMode,
              gun,
              gun__timeBetweenShots,
              gun_sound__forceOneshot,
              gun_sound__forceOneshotEnemy,
              gun_sound__event,
              gun_sound__playerTimeBetweenShotsMad,
              gun_sound__shotLoopTimeout,
              gun__owner,
              turret__owner,
              gun_sound__shotPath,
              sound_tags,
              gun_sound__blob)


[es(tag=sound, REQUIRE=gunSound)]
def gun_sound_on_net_shot(evt : CmdNetShot;
                          gun : Gun;
                          gun__timeBetweenShots : float = 0.;
                          gun_sound__forceOneshot : bool;
                          gun_sound__forceOneshotEnemy : bool;
                          var gun_sound__event : SoundEvent&;
                          gun_sound__netTimeBetweenShotsMad : float2;
                          var gun_sound__shotLoopTimeout : float&;
                          gun__owner : EntityId;
                          turret__owner = INVALID_ENTITY_ID;
                          @shared_comp gun_sound__shotPath : Object;
                          sound_tags : Object;
                          gun_sound__blob : SoundOcclusionBlob&)
  if sound_banks_is_master_preset_loaded()
    on_launch(evt.tm[3],
              evt.firingMode,
              gun,
              gun__timeBetweenShots,
              gun_sound__forceOneshot,
              gun_sound__forceOneshotEnemy,
              gun_sound__event,
              gun_sound__netTimeBetweenShotsMad,
              gun_sound__shotLoopTimeout,
              gun__owner,
              turret__owner,
              gun_sound__shotPath,
              sound_tags,
              gun_sound__blob)


def is_shooting(gun_sound__shotLoopTimeout : float)
  return gun_sound__shotLoopTimeout > 0.

[es(tag=sound, REQUIRE=gunSound, after=sound_begin_update_es, before=sound_end_update_es)]
def gun_sound_update(info : ParallelUpdateFrameDelayed;
                     var gun_sound__shotLoopTimeout : float&;
                     var gun_sound__deltaTime : float4&;
                     var gun_sound__event : SoundEvent&;
                     gun__overheat : float = 0.;
                     turret__owner = INVALID_ENTITY_ID)
  if !sound_banks_is_master_preset_loaded()
    return
  if is_valid_handle_value(gun_sound__event)
    set_var_optional(gun_sound__event, "heat", gun__overheat)
    if !is_shooting(gun_sound__shotLoopTimeout)
      abandon_shot_loop(gun_sound__event, turret__owner)
      //logerr("abandon gun_sound__event at {info.curTime} ---------------------------------")

  gun_sound__deltaTime.w = gun_sound__deltaTime.z
  gun_sound__deltaTime.z = gun_sound__deltaTime.y
  gun_sound__deltaTime.y = gun_sound__deltaTime.x
  gun_sound__deltaTime.x = info.dt
  gun_sound__shotLoopTimeout -= min(min(min(gun_sound__deltaTime.x, gun_sound__deltaTime.y), gun_sound__deltaTime.z), gun_sound__deltaTime.w)


def gun_sound_on_irq_impl(irq : string;
                          irq_type : uint;
                          animchar_bbox : bbox3f;
                          gun__owner : EntityId;
                          sound_tags : Object;
                          @shared_comp sound_irqs : Object;
                          sound_max_irq_dist = 40.;
                          gun_sound__blob : SoundOcclusionBlob&)
  let isWatched = is_watched_gun_sound(gun__owner)
  if isWatched || should_play(get_gun_sound_pos(animchar_bbox), sound_max_irq_dist)
    var handle = sound_player_common::play_path(irq, sound_irqs, sound_tags, isWatched, get_gun_sound_pos(animchar_bbox), false)
    if is_valid_handle_value(handle)
      if irq_type == sound_hash("matUnderFeet")
        set_var(handle, "mat", float(get_smid_from_gun_owner(gun__owner)))
      add_gun_sound_to_owner_sound_group(handle, get_gun_sound_pos(animchar_bbox), gun__owner)
      attach_to_blob(handle, gun_sound__blob)


[es(tag=sound, REQUIRE=gunSound)]
def gun_sound_on_irq(evt : CmdSoundIrq;
                     animchar_bbox : bbox3f;
                     gun__owner : EntityId;
                     sound_tags : Object;
                     @shared_comp sound_irqs : Object;
                     sound_max_irq_dist = 40.;
                     gun_sound__blob : SoundOcclusionBlob&)
  if sound_banks_is_master_preset_loaded()
    gun_sound_on_irq_impl(evt.irq, evt.irqType, animchar_bbox, gun__owner, sound_tags, sound_irqs, sound_max_irq_dist, gun_sound__blob)


def gun_irq_sim(a, b : float;
                irqs : Array;
                gun__owner : EntityId;
                animchar_bbox : bbox3f;
                sound_tags : Object;
                is_watched : bool;
                gun_sound__blob : SoundOcclusionBlob&)
  for it in irqs
    let obj = get_ecs_object(it)
    let relPos = obj?.relPos ?? .0
    if relPos >= a && relPos < b
      var handle = sound_player_common::play_path(*obj, sound_tags, is_watched, get_gun_sound_pos(animchar_bbox), false)
      if is_valid_handle_value(handle)
        if has(*obj, "matUnderFeet")
          set_var(handle, "mat", float(get_smid_from_gun_owner(gun__owner)))
        add_gun_sound_to_owner_sound_group(handle, get_gun_sound_pos(animchar_bbox), gun__owner)
        attach_to_blob(handle, gun_sound__blob)


[es(tag=sound)]
def gun_bolt_action_sound_update(info : ParallelUpdateFrameDelayed&;
                                 gun : Gun&;
                                 var gun_bolt_action_sound__time : float&;
                                 @shared_comp gun_bolt_action_sound__irqs : Array;

                                 sound_tags : Object;

                                 gun__owner : EntityId;
                                 animchar_bbox : bbox3f;
                                 sound_max_irq_dist = 40.;
                                 gun_sound__blob : SoundOcclusionBlob&)

  let cur = gun |> gun_lerpBoltActionTime(info.curTime)
  assume prev = gun_bolt_action_sound__time

  if prev == cur
    return

  if sound_banks_is_master_preset_loaded()

    let isWatched = is_watched_gun_sound(gun__owner)
    if isWatched || should_play(get_gun_sound_pos(animchar_bbox), sound_max_irq_dist)

      if prev < cur
        gun_irq_sim(prev, cur, gun_bolt_action_sound__irqs, gun__owner, animchar_bbox, sound_tags, isWatched, gun_sound__blob)
      else
        gun_irq_sim(prev, 2., gun_bolt_action_sound__irqs, gun__owner, animchar_bbox, sound_tags, isWatched, gun_sound__blob)
        if cur > 0.
          gun_irq_sim(0., cur, gun_bolt_action_sound__irqs, gun__owner, animchar_bbox, sound_tags, isWatched, gun_sound__blob)

  prev = cur



[es(tag=sound, REQUIRE=gunSound)]
def gun_sound_on_unloaded(evt : EventOnMasterSoundPresetLoaded;
                          var gun_sound__event : SoundEvent&;
                          var gun_sound__shotLoopTimeout : float&;
                          var gun_sound__deltaTime : float4&)
  if !evt.isLoaded
    release_immediate(gun_sound__event)
    gun_sound__shotLoopTimeout = 0.
    gun_sound__deltaTime = float4(1., 1., 1., 1.)


[es(tag=sound, after=(animchar_before_render_es, sound_begin_update_es), before=sound_end_update_es)]
def gun_owner_sound_event_group_update(info : ParallelUpdateFrameDelayed;
                                       var gun_owner_sound_event_group : SoundEventGroup&)
  if sound_banks_is_master_preset_loaded()
    update_sounds(gun_owner_sound_event_group)


[es(tag=sound, after=sound_begin_update_es, before=sound_end_update_es)]
def gun_sound_occlusion_update(info : ParallelUpdateFrameDelayed;
                               animchar_bbox : bbox3f;
                               gun__owner : EntityId;
                               var gun_sound__blob : SoundOcclusionBlob&)

  let pos = get_gun_sound_pos(animchar_bbox)
  let shouldPlay = !is_watched_gun_sound(gun__owner)

  if shouldPlay
    if is_valid_handle_value(gun_sound__blob)
      set_pos(gun_sound__blob, pos)
    else
      gun_sound__blob |> create_blob(pos, 0./*attach radius*/, 0.1/*occlusion radius*/)
  elif is_valid_handle_value(gun_sound__blob)
    gun_sound__blob |> delete_blob()


[es(tag=sound)]
def gun_owner_sound_event_group_on_unloaded(evt : EventOnMasterSoundPresetLoaded;
                                            var gun_owner_sound_event_group : SoundEventGroup&)
  if !evt.isLoaded
    release_all_sounds(gun_owner_sound_event_group)
