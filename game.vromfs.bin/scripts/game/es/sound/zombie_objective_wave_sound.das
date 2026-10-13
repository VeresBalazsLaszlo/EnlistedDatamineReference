require ecs
require soundEvent


def make_wave_id(next_wave_at_time : float; cur_wave_id : int)
  return next_wave_at_time >= 0. ? cur_wave_id : -1


[es(tag=sound, track=(objective_spawner__curWaveId, zombie_arena__zombieNextWaveAtTime))]
def zombie_objective_wave_sound(evt : Event;
                                zombie_arena__zombieNextWaveAtTime : float;
                                objective_spawner__curWaveId : int;
                                zombie_arena_objective_wave_sound__path : string;
                                var zombie_arena_objective_wave_sound__waveId : int&)

  let waveId = make_wave_id(zombie_arena__zombieNextWaveAtTime, objective_spawner__curWaveId)
  if zombie_arena_objective_wave_sound__waveId != waveId
    zombie_arena_objective_wave_sound__waveId = waveId
    oneshot(zombie_arena_objective_wave_sound__path)
