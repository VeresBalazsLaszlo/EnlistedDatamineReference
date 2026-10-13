require ecs
require gameLibs.pufd_events.pufd_events


[es(tag=server, after=zombie_mode_objective_finalizer)]
def zombie_radio_objective_net_sound__is_in_progress(info : ParallelUpdateFrameDelayed;
                                                     objective_spawner__nextActivationAfterTime : float;
                                                     var zombie_radio_objective_net_sound__isInProgress : bool&)
  zombie_radio_objective_net_sound__isInProgress = info.curTime < objective_spawner__nextActivationAfterTime + 1.
