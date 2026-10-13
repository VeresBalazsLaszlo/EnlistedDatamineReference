require ecs
require app
require DagorMath
require gameLibs.pufd_events.pufd_events
require sound_utils.modules.sound_player_common
require soundEvent
require soundSystem


[es(tag=sound)]
def zombie_radio_objective_sound(evt : ParallelUpdateFrameDelayed;
                                 objective_spawner__nextActivationAfterTime : float;
                                 objective_spawner__activationPeriod : float;
                                 objective_spawner__active : bool;
                                 transform : float3x4;

                                 zombie_radio_objective_sound__activePath : string;
                                 zombie_radio_objective_sound__completedPath : string;
                                 zombie_radio_objective_sound__failedPath : string;
                                 zombie_radio_objective_sound__hitCooldown : float;
                                 zombie_radio_objective_net_sound__isInProgress : bool;
                                 var zombie_radio_objective_sound__nextHitAfter : float&;
                                 var zombie_radio_objective_sound__prevActivationAfterTime : float&;
                                 var zombie_radio_objective_sound__activeEvent : SoundEvent&)

  assume curTime = evt.curTime
  assume event = zombie_radio_objective_sound__activeEvent

  if !sound_banks_is_master_preset_loaded()
    release_play_or(event)
    return

  let shouldPlay = objective_spawner__active && zombie_radio_objective_net_sound__isInProgress
  let playing = event.enabled
  let completed = playing && objective_spawner__active && !zombie_radio_objective_net_sound__isInProgress
  let failed = playing && !objective_spawner__active

  if event |> play_or_abandon(zombie_radio_objective_sound__activePath, transform[3], shouldPlay)
    set_var(event, "timer", cvt(objective_spawner__nextActivationAfterTime - curTime, 0., objective_spawner__activationPeriod, 100., 0.))

    if playing && objective_spawner__nextActivationAfterTime > zombie_radio_objective_sound__prevActivationAfterTime
      if curTime > zombie_radio_objective_sound__nextHitAfter
        zombie_radio_objective_sound__nextHitAfter = curTime + zombie_radio_objective_sound__hitCooldown
        set_var(event, "hit", 1.)

    if zombie_radio_objective_sound__nextHitAfter > 0. && curTime > zombie_radio_objective_sound__nextHitAfter
      zombie_radio_objective_sound__nextHitAfter = 0.
      set_var(event, "hit", 0.)

  if completed
    oneshot(zombie_radio_objective_sound__completedPath, transform[3])

  elif failed
    oneshot(zombie_radio_objective_sound__failedPath, transform[3])

  zombie_radio_objective_sound__prevActivationAfterTime = objective_spawner__nextActivationAfterTime
