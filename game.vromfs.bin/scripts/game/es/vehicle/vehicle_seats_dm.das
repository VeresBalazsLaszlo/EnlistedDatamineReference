require ecs
require dm
require DngDm

// dont disable collisions for soldier dm nodes in menu as they are needed for xray
[es(on_appear, after=(vehicle_seats_hide_owner_init_es, crew_receive_damage_from_dm_part_es), REQUIRE_NOT=menuVehicle)]
def disable_vehicle_node_traces_for_non_hidden_crew(evt : Event;
                                                    vehicle_seats_hide_owner : BoolList;
                                                    vehicle_seats_receive_damage_from_dm_part : IntList;
                                                    var damage_model : DamageModel&)
  for partId, hidden in vehicle_seats_receive_damage_from_dm_part, vehicle_seats_hide_owner
    set_collision_node_exclude(damage_model.dmData, partId, !hidden)

[es(on_appear, track=(isInVehicle, isInVehicleHidden))]
def disable_human_dm_for_hidden_crew(evt : Event;
                                     isInVehicle : bool;
                                     isInVehicleHidden : bool;
                                     var damage_model : DamageModel&)
  let hidden = isInVehicle && isInVehicleHidden
  for id in range(get_damage_part_props_count(damage_model.dmData))
    set_enabled <| get_damage_part_props_for_modification(damage_model.dmData, id) <| !hidden
