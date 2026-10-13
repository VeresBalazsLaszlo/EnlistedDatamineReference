require ecs
require ecs.safe
require game.utils.team
require math
require math.base
require DngDm
require enlisted.events_enlisted
require common_shooter.events_common_shooter
require common_shooter.es.hit_result_common
require human_net_speech.modules.human_net_speech_request_common


def is_headshot(dm_parts__type : StringList&; coll_node_id : int)
  return coll_node_id >= 0 && coll_node_id < length(dm_parts__type) && string(dm_parts__type[coll_node_id]) == "head"


def was_killed(evt : EventOnEntityHit)
  return (evt.hitResult == int(HitResult.HIT_RES_KILLED))


def is_concussed(eid : EntityId)
  var isConcussed = false
  query(eid) <| $ [es] (concussion__isActive : bool)
    isConcussed = concussion__isActive
  return isConcussed


[es(tag=server)]
def human_hit_net_speech(evt : EventOnEntityHit;
                         eid : EntityId;
                         transform : float3x4;
                         isAlive : bool;
                         team : int;
                         human_net_speech__isFarKillThreshold = 100.)
  if evt.victim == evt.offender || !isAlive
    return

  if evt.victim != eid && evt.offender != eid
    return

  if evt.hitResult == int(HitResult.HIT_RES_NONE)
    return

  assume dd = evt
  if dd.damageType != int(DamageType.DM_PROJECTILE) && dd.damageType != int(DamageType.DM_EXPLOSION) && dd.damageType != int(DamageType.DM_MELEE) && dd.damageType != int(DamageType.DM_BACKSTAB)
    return

  let thisTeam = team
  var isFriendly = false
  query(evt.victim != eid ? evt.victim : evt.offender) <| $ [es] (team aka other_team : int)
    isFriendly = is_teams_friendly(thisTeam, other_team)
  if isFriendly
    return

  if evt.victim == eid
    if !was_killed(evt) && (dd.damageType == int(DamageType.DM_PROJECTILE) || dd.damageType == int(DamageType.DM_EXPLOSION))
      request_net_speech(evt.victim, "wounded")

  elif evt.offender == eid
    query(evt.victim) <| $ [es] (dm_parts__type : StringList&)
      if was_killed(evt) && !is_concussed(evt.victim)
        if dd.damageType == int(DamageType.DM_EXPLOSION)
          request_net_speech(evt.offender, "enemyKillExplode")
        elif is_headshot(dm_parts__type, dd.collNodeId)
          request_net_speech(evt.offender, "enemyHeadshot")
        elif length_sq(dd.hitPos - transform[3]) > square(human_net_speech__isFarKillThreshold)
          request_net_speech(evt.offender, "enemyKillFar")
        elif (dd.damageType == int(DamageType.DM_MELEE))
          request_net_speech(evt.offender, "enemyKillMelee")
        else
          request_net_speech(evt.offender, "enemyKill")
      else
        request_net_speech(evt.offender, "enemyHit")


[es(tag=server, REQUIRE=projectile__stopped)]
def human_hit_friendly_human_net_speech(evt : EventProjectileIntersectEntityWithHp)

  query(evt.offender) <| $ [es(REQUIRE_NOT=deadEntity)] (transform aka offender_transform : float3x4;
                                                         team aka offender_team : int;
                                                         human_net_speech__friendlyFireDistThreshold = 20.)
    query(evt.victim) <| $ [es(REQUIRE=human_net_phys)] (team aka victim_team : int = int(TEAM_UNASSIGNED))
      if is_teams_friendly(offender_team, victim_team)
        var eidToSpeak = INVALID_ENTITY_ID
        var closestDistSq = square(human_net_speech__friendlyFireDistThreshold)
        query() <| $ [es(REQUIRE=human_net_phys)] (eid : EntityId; team : int; transform : float3x4)
          if eid != evt.victim && eid != evt.offender && is_teams_friendly(team, offender_team)
            let distSq = length_sq(transform[3] - offender_transform[3])
            if distSq < closestDistSq
              eidToSpeak = eid
              closestDistSq = distSq
        if !!eidToSpeak
          request_net_speech(eidToSpeak, "friendlyFireHit")
