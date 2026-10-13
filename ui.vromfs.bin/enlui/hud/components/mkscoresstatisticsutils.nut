from "%enlSqGlob/missionType.nut" import MissionType

let sortStatistics = @(a, b) a.isDeserter <=> b.isDeserter
  || (a.player?.scoreIndex ?? 0) <=> (b.player?.scoreIndex ?? 0)
  || a.player.disconnected <=> b.player.disconnected
  || (b.player?.score ?? 0) <=> (a.player?.score ?? 0)
  || (a.player?.lastUpdate ?? 0) <=> (b.player?.lastUpdate ?? 0)
  || (b.player?["scoring_player__kills"] ?? 0) <=> (a.player?["scoring_player__kills"] ?? 0) 
  || a.eid <=> b.eid

let sortStatisticsZombieMod = @(a, b)
  a.player.disconnected <=> b.player.disconnected
  || (b.player?.scoring_player__zombieTotalScore ?? 0) <=> (a.player?.scoring_player__zombieTotalScore ?? 0) 
  || (a.player?.lastUpdate ?? 0) <=> (b.player?.lastUpdate ?? 0)
  || a.eid <=> b.eid

let sortStatisticsGunGameMode = @(a, b)
  a.player.disconnected <=> b.player.disconnected
  || (b.player?["scoring_player__kills"] ?? 0) <=> (a.player?["scoring_player__kills"] ?? 0)
  || a.eid <=> b.eid

function sortPlayers(players, missionType) {
  let sorter = missionType == MissionType.ZOMBIE_MODE ? sortStatisticsZombieMod
    : missionType == MissionType.GUN_GAME ? sortStatisticsGunGameMode
    : sortStatistics
  players.sort(sorter)
}

function getPlayerPlace(debriefingData) {
  let { missionType, players, myTeam, localPlayerEid } = debriefingData
  let soldiers = []
  foreach (soldier in players) {
    if (soldier.team != myTeam)
      continue

    soldiers.append({
      player = soldier
      eid = soldier.eid
      isDeserter = soldier.isDeserter
    })
  }
  sortPlayers(soldiers, missionType)

  foreach (i, soldier in soldiers) {
    if (soldier.eid == localPlayerEid)
      return i + 1
  }

  return 0
}

return {
  getPlayerPlace
  sortPlayers
}
