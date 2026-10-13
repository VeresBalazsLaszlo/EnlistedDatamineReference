require ecs
require gameLibs.pufd_events.pufd_events
require %gameLibs.anim.motionMatching.das.mm_events

[es(tag=render, before=before_net_phys_sync)]
def motion_matching_start_search_job(info : ParallelUpdateFrameDelayed)
  broadcastEventImmediate(MotionMatchingStartSearchJob(dt = info.dt))
