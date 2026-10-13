require ecs
require dm
require DngDm

[es(on_appear)]
def crew_hp_after_hit_es(evt : Event;
                         var crew_hp_after_hit : IntList&;
                         vehicle_seats_receive_damage_from_dm_part : IntList;
                         damage_model : DamageModel)
  resize(crew_hp_after_hit, length(vehicle_seats_receive_damage_from_dm_part))
  for seatNo in iter_range(vehicle_seats_receive_damage_from_dm_part)
    let partId = vehicle_seats_receive_damage_from_dm_part[seatNo]
    crew_hp_after_hit[seatNo] = partId > -1 ? int(get_damage_part_props(damage_model.dmData, partId).relHpFixed) : 0
