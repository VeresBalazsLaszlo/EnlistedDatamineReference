require DagorMath
require DaWeapons
require ecs
require enlisted.events_enlisted

[es(tag=server, before=clear_gun_launch_events_es, after=after_guns_update_sync)]
def gun_overheat_es(info : ParallelUpdateFrameDelayed;
                    gun_launch_events : GunLaunchEvents;
                    gun__overheatReduce : float;
                    gun__overheatReduceOnOverheat : float;
                    gun__overheatPerShot : float;
                    var gun__isOverheat : bool&;
                    var gun__overheat : float&)
  if !gun__isOverheat
    // cooling is applied every tick, otherwise shots-to-overheat depends on tickrate
    gun__overheat = max(gun__overheat - gun__overheatReduce * info.dt, 0.f)
    for _ in range(length(gun_launch_events.launchEvents))
      gun__overheat = min(gun__overheat + gun__overheatPerShot, 1.f)
    if gun__overheat >= 1.f
      gun__isOverheat = true
  else
    gun__overheat = max(gun__overheat - gun__overheatReduceOnOverheat * info.dt, 0.f)
    if gun__overheat == 0.f
      gun__isOverheat = false
