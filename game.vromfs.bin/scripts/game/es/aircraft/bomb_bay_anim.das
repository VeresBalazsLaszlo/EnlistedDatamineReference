require ecs
require enlisted.events_enlisted
require DaWeapons
require PhysVars

[es(tag=gameClient, before=clear_gun_launch_events_es, after=after_guns_update_sync,
    REQUIRE=gun__isBombBayWeapon)]
def bomb_bay_detect_drop_es(info : ParallelUpdateFrameDelayed;
                            turret__owner : EntityId;
                            gun_launch_events : GunLaunchEvents)
  if length(gun_launch_events.launchEvents) == 0
    return
  query(turret__owner) <| $ [es] (var bomb_bay_anim__lastDropTime : float&)
    bomb_bay_anim__lastDropTime = info.curTime

[es(tag=render)]
def bomb_bay_anim_update_es(info : ParallelUpdateFrameDelayed;
                            bomb_bay_anim__closeDelay : float;
                            bomb_bay_anim__speed : float;
                            bomb_bay_anim__lastDropTime : float;
                            var bomb_bay_anim__varId : int&;
                            var bomb_bay_anim__openAmount : float&;
                            var phys_vars : PhysVars)
  if bomb_bay_anim__varId < 0
    bomb_bay_anim__varId = registerVar(phys_vars, "p_bombhatch", 0.0)

  let timeSinceLastDrop = info.curTime - bomb_bay_anim__lastDropTime
  let target = timeSinceLastDrop < bomb_bay_anim__closeDelay ? 1.0 : 0.0

  if bomb_bay_anim__openAmount < target
    bomb_bay_anim__openAmount = min(bomb_bay_anim__openAmount + bomb_bay_anim__speed * info.dt, target)
  elif bomb_bay_anim__openAmount > target
    bomb_bay_anim__openAmount = max(bomb_bay_anim__openAmount - bomb_bay_anim__speed * info.dt, target)

  setVar(phys_vars, bomb_bay_anim__varId, bomb_bay_anim__openAmount)
