require ecs
require game.utils.team
require enlisted.events_enlisted
require app
require DngNet

[es(tag=server, no_order)]
def session_timer(info : UpdateStageInfoAct;
                  eid : EntityId;
                  session_timer__time_end : float)
  if info.curTime < session_timer__time_end || session_timer__time_end < 0.
    return
  setOptional(eid, "session_timer__time_end", -1.)

  var leadersCount = 0
  var maxRoundScore = -1.
  var bestTeamId = TEAM_UNASSIGNED
  query() <| $ [es] (team__score : float; team__id : int)
    if team__score > maxRoundScore
      maxRoundScore = team__score
      bestTeamId = team__id
      leadersCount = 1
    elif team__score == maxRoundScore
      leadersCount += 1

  if leadersCount > 1
    bestTeamId = TEAM_UNASSIGNED
  broadcastEvent(EventTeamWon(team = bestTeamId))

[es(tag=server)]
def session_timer_start(evt : EventFirstPlayerConnected;
                        eid : EntityId;
                        var session_timer__time_end : float&)
  session_timer__time_end += get_sync_time()
  send_net_event(eid, SessionTimerEnd(time = session_timer__time_end))
