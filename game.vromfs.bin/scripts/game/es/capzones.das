require ecs
require game.events_game
require app
require enlisted.events_enlisted
require game.es.capzones_common

[es(tag=server)]
def capzone_start_capture_es(evt : EventZoneStartCapture)
  query(evt.eid) <| $ [es] (capzone__capTimeTeam1 : float;
                            capzone__capTimeTeam2 : float;
                            var capzone__capTime : float&)
    if evt.team == 1
      capzone__capTime = capzone__capTimeTeam1
    elif evt.team == 2
      capzone__capTime = capzone__capTimeTeam2


[es(tag=server)]
def capzone_start_decapture_es(evt : EventZoneStartDecapture)
  query(evt.eid) <| $ [es] (capzone__decapTimeTeam1 : float;
                            capzone__decapTimeTeam2 : float;
                            var capzone__decapTime : float&)
    if evt.team == 1
      capzone__decapTime = capzone__decapTimeTeam1
    elif evt.team == 2
      capzone__decapTime = capzone__decapTimeTeam2


[es(tag=server)]
def capzone_lock_after_activate_es(evt : EventEntityActivate;
                                   active : bool;
                                   capzone__unlockAfterTime : float;
                                   capzone__lockAfterActivate : bool;
                                   var capzone__locked : bool&;
                                   var capzone__endLockTime : float&)
  if capzone__lockAfterActivate && !active && evt.activate
    capzone__endLockTime = get_sync_time() + capzone__unlockAfterTime
    query() <| $ [es] (firstPlayerSpawnTime : float)
      if firstPlayerSpawnTime < 0. // disable timer till first spawn
        capzone__endLockTime = -1.
    capzone__locked = true

[es(tag=server)]
def capzone_set_lock_time_after_first_spawn(evt : EventFirstPlayerSpawned;
                                            active : bool;
                                            capzone__unlockAfterTime : float;
                                            capzone__locked : bool;
                                            var capzone__endLockTime : float&)
  if capzone__locked && active
    capzone__endLockTime = get_sync_time() + capzone__unlockAfterTime

def lock_capzone_on_capture(eid : EntityId)
  query(eid) <| $ [es] (capzone__unlockAfterTime : float;
                        capzone__lockAfterCap : bool;
                        var capzone__locked : bool&;
                        var capzone__endLockTime : float&)
    if capzone__lockAfterCap && !capzone__locked
      capzone__endLockTime = get_sync_time() + capzone__unlockAfterTime
      capzone__locked = true

[es(tag=server)]
def capzone_lock_after_capture_es(evt : EventZoneCaptured)
  lock_capzone_on_capture(evt.zone)

[es(tag=server)]
def capzone_lock_after_about_capture_es(evt : EventZoneIsAboutToBeCaptured)
  lock_capzone_on_capture(evt.zone)

[es(tag=server, no_order)]
def capzone_update_lock_es(evt : UpdateStageInfoAct;
                           eid : EntityId;
                           capzone__endLockTime : float;
                           var capzone__locked : bool&)
  if capzone__locked && capzone__endLockTime >= 0. && capzone__endLockTime < evt.curTime
    capzone__locked = false
    sendEvent(eid, EventZoneUnlock())

[es(tag=server, track=active, REQUIRE=capzone)]
def last_activated_group_set(evt : Event; groupName : string; active : bool)
  if active
    find_query() <| $ [es] (var activator__lastActivatedGroup : das_string&)
      activator__lastActivatedGroup := groupName
      return true

[es(tag=server, track=active, REQUIRE=capzone__bidirectionalAssault)]
def bidirectional_assault_capzone_state_reset_on_activate(evt : Event;
                                                          active : bool;
                                                          groupName : string;
                                                          var capzone__progress : float&;
                                                          var capzone__alwaysHide : bool&;
                                                          var capzone__alwaysShow : bool&;
                                                          capzone__onlyTeamCanCapture aka active_capzone__onlyTeamCanCapture : int;
                                                          var capzone__owningTeam : int&)
  if active
    capzone__owningTeam = -1
    capzone__progress = 0.0
    capzone__alwaysHide = false
    capzone__alwaysShow = true
    query() <| $ [es] (var capzone__alwaysHide : bool&;
                       var capzone__alwaysShow : bool&;
                       capzone__activateAfterCap : string;
                       capzone__onlyTeamCanCapture : int)
      if groupName == capzone__activateAfterCap && active_capzone__onlyTeamCanCapture != capzone__onlyTeamCanCapture
        capzone__alwaysHide = true
        capzone__alwaysShow = false
