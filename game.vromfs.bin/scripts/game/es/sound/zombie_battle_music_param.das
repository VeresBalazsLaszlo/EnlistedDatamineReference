require ecs
require app
require soundEvent
require gameLibs.pufd_events.pufd_events
require common_shooter.events_common_shooter
require math.base


[es(tag=sound, after=sound_begin_update_es, before=sound_end_update_es)]
def zombie_battle_music_param_update(evt : ParallelUpdateFrameDelayed;
                                     sound_preset__isLoaded : bool;
                                     zombie_battle_music_param__name : string;
                                     var zombie_battle_music_param__active : bool&)
  if sound_preset__isLoaded
    var active = false
    query() <| $ [es] (zombie_battle_music_trigger__dropAtTime : float)
      active ||= evt.curTime < zombie_battle_music_trigger__dropAtTime

    if zombie_battle_music_param__active != active
      zombie_battle_music_param__active = active
      set_var_global(zombie_battle_music_param__name, active ? 1. : 0.)
  else
    zombie_battle_music_param__active = false


[es(tag=sound)]
def zombie_near_battle_music_trigger(evt : ParallelUpdateFrameDelayed;
                                     zombie_near_battle_music_trigger__range : float;
                                     zombie_near_battle_music_trigger__updateInterval : float;
                                     zombie_near_battle_music_trigger__duration : float;
                                     var zombie_near_battle_music_trigger__updateAfter : float&;
                                     var zombie_battle_music_trigger__dropAtTime : float&)

  if evt.curTime <= zombie_near_battle_music_trigger__updateAfter
    return

  zombie_near_battle_music_trigger__updateAfter = evt.curTime + zombie_near_battle_music_trigger__updateInterval

  query() <| $ [es(REQUIRE=hero)] (transform aka human_transform : float3x4)

    find_query() <| $ [es(REQUIRE=zombie, REQUIRE_NOT=hero)] (transform aka zombie_transform : float3x4;
                                                              zombie_aggro_net_sound_state__isAggressive : bool;
                                                              isAlive = true)
      if isAlive && zombie_aggro_net_sound_state__isAggressive && length_sq(zombie_transform[3] - human_transform[3]) < square(zombie_near_battle_music_trigger__range)
        zombie_battle_music_trigger__dropAtTime = max(zombie_battle_music_trigger__dropAtTime, evt.curTime + zombie_near_battle_music_trigger__duration)
        return true
      return false


[es(tag=sound)]
def zombie_attack_battle_music_trigger(evt : EventOnEntityHit;
                                       zombie_attack_battle_music_trigger__duration : float;
                                       var zombie_battle_music_trigger__dropAtTime : float&)

  if evt.victim != evt.offender && (has(evt.victim, "hero") || has(evt.offender, "hero")) && (has(evt.victim, "zombie") || has(evt.offender, "zombie"))
    zombie_battle_music_trigger__dropAtTime = max(zombie_battle_music_trigger__dropAtTime, get_sync_time() + zombie_attack_battle_music_trigger__duration)
