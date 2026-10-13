require ecs
require ecs.common
require DagorMath
require PhysVars
require enlisted.events_enlisted

[es(tag=gameClient, on_appear, REQUIRE=resolvedTurret)]
def turret_recoil_init_es(evt : Event;
                          turret__owner : EntityId;
                          turret__id : int;
                          var turret_recoil__kickTime : float&;
                          var turret_recoil__returnTime : float&)
  query(turret__owner) <| $ [es] (@shared_comp turret_control__turretInfo : Array)
    if turret__id < length(turret_control__turretInfo)
      let turretObj = get_ecs_object(turret_control__turretInfo, turret__id)
      if turretObj == null
        return
      turret_recoil__kickTime   = get_float(*turretObj, "gunRecoilKickTime")   ?? 0.1f
      turret_recoil__returnTime = get_float(*turretObj, "gunRecoilReturnTime") ?? 0.4f

[es(tag=gameClient, REQUIRE_NOT=deadEntity)]
def turret_recoil_move_barrel_es(info : ParallelUpdateFrameDelayed; turret_control__gunEids : EidList; var phys_vars : PhysVars)
  for turretEid in turret_control__gunEids
    query(turretEid) <| $ [es(REQUIRE=(resolvedTurret, gun))] (turret__gunRecoilVarId : int;
                                                               turret_recoil__startTime : float;
                                                               turret_recoil__kickTime : float = 0.1;
                                                               turret_recoil__returnTime : float = 0.4)
      if turret__gunRecoilVarId < 0
        return
      let t = info.curTime - turret_recoil__startTime
      let recoil = (t <= turret_recoil__kickTime) ? -1.f : cvt(t, turret_recoil__kickTime, turret_recoil__kickTime + turret_recoil__returnTime, -1.f, 0.f)
      setVar(phys_vars, turret__gunRecoilVarId, recoil)
