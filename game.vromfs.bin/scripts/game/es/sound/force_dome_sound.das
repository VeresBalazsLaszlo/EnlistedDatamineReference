require ecs
require soundEvent
require soundSystem
require math.base
require DagorMath
require enlisted.events_enlisted
require sound_utils.modules.sound_player_common


[es(tag=sound, after=sound_begin_update_es, before=sound_end_update_es)]
def force_dome_sound_update(info : ParallelUpdateFrameDelayed;
                            sound_preset__isLoaded : bool;
                            force_dome_sound__path : string;
                            force_dome_sound__enterPath : string;
                            force_dome_sound__hearingRange : float;
                            var force_dome_sound__isInside : bool&;
                            var force_dome_sound__event : SoundEvent&)
  if !sound_preset__isLoaded
    release_play_or(force_dome_sound__event)
    force_dome_sound__isInside = false
    return

  var depth = 1.
  var isInside = false
  ecs::query() <| $ [es] (force_dome__radius : float; force_dome__position : float3)
    let dist = length(get_listener_pos() - force_dome__position)
    depth = min(depth, cvt(dist, force_dome__radius - force_dome_sound__hearingRange, force_dome__radius, 0., 1.))
    isInside ||= dist < force_dome__radius

  set_var_global("foolMoonDomeDepth", depth) // TODO: replace "depth" with force_dome_sound__depth, move this set_var_global to another es

  if !force_dome_sound__event.enabled
    force_dome_sound__event.enabled = true
    force_dome_sound__event |> play(force_dome_sound__path)
  elif force_dome_sound__isInside != isInside
    oneshot(force_dome_sound__enterPath, get_listener_pos())
  force_dome_sound__isInside = isInside
  set_pos(force_dome_sound__event, get_listener_pos())
