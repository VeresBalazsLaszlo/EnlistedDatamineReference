require app
require ecs
require danetlibs.wounds.wounds_events
require common_shooter.events_common_shooter
require game.events_game


[es(tag=render, REQUIRE=(human__breakable_bones, attaches_list))]
def reset_bones_damage_on_healing_es(evt : CmdRestoreEntityHp;
                                     eid : EntityId;
                                     isAlive : bool;
                                     isDowned : bool = false)
  if !isAlive || isDowned || evt.restoreHp <= 0.f
    return
  sendEvent(eid, CmdResetTornWoundBoneDamage(eid = eid))


[es(tag=render, REQUIRE=(human__breakable_bones, attaches_list))]
def reset_bones_damage_on_downed_death_es(evt : EventEntityDied;
                                          eid : EntityId;
                                          hitpoints__downedEndTime : float)
  if hitpoints__downedEndTime < 0.f || get_sync_time() < hitpoints__downedEndTime
    return
  sendEvent(eid, CmdResetTornWoundBoneDamage(eid = eid))


[es(tag=render, REQUIRE=zombie)]
def on_zombie_death_event_send_es(evt : EventEntityDied;
                                  eid : EntityId)
  sendEvent(eid, EventOnDeathTornWoundApply(collNodeId = evt.collNodeId))