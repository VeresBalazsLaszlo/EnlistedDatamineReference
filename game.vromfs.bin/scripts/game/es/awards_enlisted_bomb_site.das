require ecs
require ecs.safe
require ecs.common
require enlisted.game.es.offender_cache_common
require enlisted.events_enlisted
require strings
require game.es.awards_common

[es(tag=server)]
def award_on_bomb_site_detonation(evt : EventAwardZoneCapturers;
                                  capzone__bombSitePlanterEid : EntityId;
                                  capzone__bombSitePlantParticipants : Object;
                                  capzone__bombSiteZonePresenceOnPlant : EidList;
                                  capzone__bombSiteParticipantsAwardAmount : float;
                                  capzone__bombSiteDefenseAwardAmount : float)

  assume participants = capzone__bombSitePlantParticipants
  let totalContribution = reduce(participants, 0.) <| $(a, b) => a + b ?? 0.

  if totalContribution <= 0.
    return
  let invTotalContribution = capzone__bombSiteParticipantsAwardAmount / totalContribution

  var awardedPlayers : table<uint>
  let planterInfo = get_offender_from_cache(capzone__bombSitePlanterEid)

  using() <| $(var awardList : Array)
    for it in participants
      let participantContribution = it.value ?? 0.
      let participantEid = EntityId(to_uint(it.key))
      let participantInfo = get_offender_from_cache(participantEid)
      if !is_valid_cache_soldier(participantInfo) || participantInfo.player == planterInfo.player
        continue
      awardedPlayers.insert(uint(participantInfo.player))
      awardList |> push_soldier_stat(participantInfo, "captures", participantContribution * invTotalContribution)

    var presenceByPlayer : table<uint; array<CachedSoldier>>
    for defenderEid in capzone__bombSiteZonePresenceOnPlant
      let defender = get_offender_from_cache(defenderEid)
      if !is_valid_cache_soldier(defender) || defender.player == planterInfo.player
        continue
      let defenderPlayerUid = uint(defender.player)
      if !key_exists(presenceByPlayer, defenderPlayerUid)
        presenceByPlayer[defenderPlayerUid] <- array<CachedSoldier>()
      presenceByPlayer[defenderPlayerUid] |> push(defender)
    for soldiers in values(presenceByPlayer)
      let soldiersCount = float(length(soldiers))
      let invPlayerSoldiersCount = soldiersCount > 0. ? (1.0 / soldiersCount) : 1.0
      for soldier in soldiers
        awardedPlayers.insert(uint(soldier.player))
        awardList |> push_soldier_stat(soldier, "captures", capzone__bombSiteDefenseAwardAmount * invPlayerSoldiersCount)

    broadcast_schemeless_event(typeinfo undecorated_typename(type<EventSquadMembersStats>)) <| $(var init : Object)
      set(init, "list", awardList)

  for playerId in keys(awardedPlayers)
    let playerEid = EntityId(playerId)
    sendEvent(playerEid, EventPlayerSquadHelpedToDestroyPoint())
    add_award(playerEid, "capture") <| $(award)
      set(award, "scoreId", "captures")
