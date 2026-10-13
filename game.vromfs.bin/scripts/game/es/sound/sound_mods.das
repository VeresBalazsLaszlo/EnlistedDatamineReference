require ecs
require ecs.common


def add_sound_mod(eid : EntityId; var sound_mods : EidList&)
  if sound_mods |> find_index(eid) == -1
    sound_mods |> push(eid)

def remove_sound_mod(eid : EntityId; var sound_mods : EidList&)
  let idx = sound_mods |> find_index(eid)
  if idx >= 0
    sound_mods |> erase(idx)


[es(tag=sound, on_appear, REQUIRE=sound_mod_tags)]
def sound_mods_effect_appear(evt : Event;
                             eid : EntityId;
                             game_effect__attachedTo : EntityId)
  query(game_effect__attachedTo) <| $ [es] (var sound_mods : EidList&)
    add_sound_mod(eid, sound_mods)


[es(tag=sound, on_disappear, REQUIRE=sound_mod_tags)]
def sound_mods_effect_disappear(evt : Event;
                                eid : EntityId;
                                game_effect__attachedTo : EntityId)
  query(game_effect__attachedTo) <| $ [es] (var sound_mods : EidList&)
    remove_sound_mod(eid, sound_mods)


/*
[es(tag=sound)]
def sound_mods_equipment_equipped(evt : EventOnEquipmentEquipped;
                                  var sound_mods : EidList&)
  query(evt.equipmentEid) <| $ [es(REQUIRE=sound_mod_tags)] ()
    add_sound_mod(evt.equipmentEid, sound_mods)


[es(tag=sound)]
def sound_mods_equipment_unequipped(evt : EventOnEquipmentUnequipped;
                                    var sound_mods : EidList&)
  query(evt.equipmentEid) <| $ [es(REQUIRE=sound_mod_tags)] ()
    remove_sound_mod(evt.equipmentEid, sound_mods)
*/


[es(tag=sound, on_appear, REQUIRE=sound_mod_tags)]
def sound_mod_tags_appear(evt : Event;
                          eid : EntityId;
                          animchar_attach__attachedTo : EntityId)

  query(animchar_attach__attachedTo) <| $ [es] (var sound_mods : EidList&)
    add_sound_mod(eid, sound_mods)



[es(tag=sound, on_disappear, REQUIRE=sound_mod_tags)]
def sound_mod_tags_disappear(evt : Event;
                             eid : EntityId;
                             animchar_attach__attachedTo : EntityId)

  query(animchar_attach__attachedTo) <| $ [es] (var sound_mods : EidList&)
    remove_sound_mod(eid, sound_mods)



[es(tag=sound, on_appear, before=sound_tags_apply)]
def sound_mods_appear(evt : Event;
                      eid aka eid_sound_mods : EntityId;
                      var sound_mods : EidList&)

  query() <| $ [es(REQUIRE=sound_mod_tags)] (eid : EntityId;
                                             animchar_attach__attachedTo : EntityId)
    if eid_sound_mods == animchar_attach__attachedTo
      add_sound_mod(eid, sound_mods)

  query() <| $ [es(REQUIRE=sound_mod_tags)] (eid : EntityId;
                                             game_effect__attachedTo : EntityId)
    if eid_sound_mods == game_effect__attachedTo
      add_sound_mod(eid, sound_mods)

