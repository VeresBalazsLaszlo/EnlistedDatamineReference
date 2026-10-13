require ecs


[es(tag=server, REQUIRE=zombie_mode_human, track=(human_inventory__entityUseStart, human_inventory__entityUseEnd))]
def inventory_use_revive_syringe_item(evt : Event;
                                      eid aka offender_eid : EntityId;
                                      human_inventory__targetToUse : EntityId;
                                      human_inventory__entityUseStart : float;
                                      human_inventory__entityUseEnd : float)
  if offender_eid == human_inventory__targetToUse
    return
  query(human_inventory__targetToUse) <| $ [es] (var human_inventory__reviveSyringeStart : float&;
                                                 var human_inventory__reviveSyringeEnd : float&;
                                                 var human_inventory__reviveSyringeOffender : EntityId&)
    human_inventory__reviveSyringeStart = human_inventory__entityUseStart
    human_inventory__reviveSyringeEnd = human_inventory__entityUseEnd
    human_inventory__reviveSyringeOffender = offender_eid
  if !human_inventory__targetToUse
    query() <| $ [es] (var human_inventory__reviveSyringeOffender : EntityId&;
                       var human_inventory__reviveSyringeStart : float&;
                       var human_inventory__reviveSyringeEnd : float&)
      if human_inventory__reviveSyringeOffender == offender_eid
        human_inventory__reviveSyringeStart = -1.f
        human_inventory__reviveSyringeEnd = -1.f
        human_inventory__reviveSyringeOffender = INVALID_ENTITY_ID
