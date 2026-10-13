require ecs
require soundEvent
require soundSystem
require math.base
require strings
require game.utils.team
require sound_utils.modules.sound_player_common


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, after=sound_begin_update_es, before=sound_end_update_es)]
def rallypoint_sound_update(evt : Event;
                            var rallypoint_sound__event : SoundEvent&;
                            rallypoint_sound__friendlyPath : string;
                            rallypoint_sound__enemyPath : string;
                            rallypoint_sound__range : float;
                            rallypoint_sound__enable : bool;
                            rallypoint_sound__isFriendly : bool;
                            transform : float3x4)

  let path = rallypoint_sound__isFriendly ? rallypoint_sound__friendlyPath : rallypoint_sound__enemyPath
  let enable = rallypoint_sound__enable && !empty(path) && sound_banks_is_master_preset_loaded()
  let shouldPlay = enable && (rallypoint_sound__event.enabled ? (distance_sq(get_listener_pos(), transform[3]) < square(rallypoint_sound__range)) :
                                                                (distance_sq(get_listener_pos(), transform[3]) < square(rallypoint_sound__range * 0.9)))

  play_or_release(rallypoint_sound__event, path, transform[3], shouldPlay)


[es(tag=sound, on_appear, on_event=EventHeroChanged)]
def rallypoint_sound_setup(evt : Event;
                           team aka rallypoint_team : int;
                           var rallypoint_sound__event : SoundEvent&;
                           var rallypoint_sound__isFriendly : bool&)
  let isFriendly = is_teams_friendly(rallypoint_team, get_local_player_team())
  if rallypoint_sound__isFriendly != isFriendly
    rallypoint_sound__isFriendly = isFriendly
    rallypoint_sound__event.enabled = false
    release(rallypoint_sound__event)
