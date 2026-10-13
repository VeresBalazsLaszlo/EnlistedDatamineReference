require ecs
require enlisted.events_enlisted
require game.es.capzones_common
require game.utils.team
require game.events_game
require DagorMath

def on_capzone_captured(zone_eid : EntityId; cap_team : int)
  query(zone_eid) <| $ [es(REQUIRE_NOT=capzone__noTeamScore)] (capzone__isSectorCaptured : bool;
                                                               capzone__checkAllZonesInGroup : bool;
                                                               capzone__mustBeCapturedByTeam : int;
                                                               capzone__winOnCapture : bool const?;
                                                               groupName aka captured_groupName : string)
    if (capzone__isSectorCaptured ||
        !capzone__checkAllZonesInGroup ||
         cap_team != capzone__mustBeCapturedByTeam ||
        !all_capzones_in_group_captured_by_team(cap_team, groupName))
      return

    // Disable all capzones in group, to avoid sending event second time
    query() <| $ [es] (groupName : string; capzone__mustBeCapturedByTeam : int; var active : bool&; var capzone__isSectorCaptured : bool&)
      if groupName == captured_groupName && capzone__mustBeCapturedByTeam == cap_team
        capzone__isSectorCaptured = true
        active = false

    if capzone__winOnCapture != null && *capzone__winOnCapture
      var win = true
      find_query() <| $ [es] (capzone__isSectorCaptured : bool; capzone__winOnCapture aka other_capzone__winOnCapture : bool)
        if other_capzone__winOnCapture && !capzone__isSectorCaptured
          win = false
        return !win
      if win
        broadcastEvent(EventTeamWon(team = cap_team))
    else
      broadcastEvent(EventSectorCaptured(zone = zone_eid, team = cap_team))

[es(tag=server)]
def capzone_check_all_zones_in_group(evt : EventZoneCaptured)
  on_capzone_captured(evt.zone, evt.team)

[es(tag=server)]
def capzone_check_all_zones_in_group_delayed(evt : EventZoneIsAboutToBeCaptured)
  on_capzone_captured(evt.zone, evt.team)

[es(tag=server, track=active)]
def reset_sector_capture_status_on_reactivation(evt : Event;
                                                active : bool;
                                                var capzone__isSectorCaptured : bool&)
  if active
    capzone__isSectorCaptured = false
