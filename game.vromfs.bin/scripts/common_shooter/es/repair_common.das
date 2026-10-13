module repair_common shared

require ecs
require dm
require DngDm
require game.utils.team

def is_maintenance_allowed(operator_team : int; target_team : int)
  return target_team == TEAM_UNASSIGNED || operator_team == TEAM_UNASSIGNED || is_teams_friendly(operator_team, target_team)

def repair_vehicle(recovery_ratio : float;
                   var meta_parts_state : MetaPartsState&;
                   var damage_model : DamageModel&;
                   var fire_protection : FireProtection&)
  var repairRequired = false
  for partId in range(get_damage_part_props_count(damage_model.dmData))
    assume part = get_damage_part_props_for_modification(damage_model.dmData, partId)
    assume fire_protection_part = fire_protection[partId]
    var hp = uint16(0)
    part.relHpFixed = rel_hp_float_to_fixed_ceil(rel_hp_fixed_to_float(part.relHpFixed) + float(recovery_ratio))
    part.state = (DamagePartState.DP_STATE_DAMAGED)
    if uint(part.relHpFixed) > uint(HP_DAMAGED_STATE_TRESHOLD_FIXED)
      part.state = (DamagePartState.DP_STATE_NORMAL)
    if fire_protection_part.maxHp > 0.f
      hp = rel_hp_float_to_fixed_ceil(rel_hp_fixed_to_float(fire_protection_part.hpFixed) + float(recovery_ratio))
    fire_protection_part.hpFixed = hp
    repairRequired = uint(part.relHpFixed) < uint(MAX_REL_HP_FIXED)
  for part in meta_parts_state.state
    part |> metapart_reset()
    part |> metapart_setHp(rel_hp_float_to_fixed_ceil(rel_hp_fixed_to_float(part.hp) + recovery_ratio))
    repairRequired = uint(rel_hp_fixed_to_float(part.hp)) < uint(MAX_REL_HP_FIXED)
  return repairRequired

def repair_vehicle_part(recover_health : float;
                        damage_model_part_id : int;
                        var dm_parts__damagedByTeammate : BoolList&;
                        var damage_model : DamageModel&;
                        var fire_protection : FireProtection&)
  assume part = get_damage_part_props_for_modification(damage_model.dmData, damage_model_part_id)
  assume fire_protection_part = fire_protection[damage_model_part_id]

  var hp = uint16(0)
  part.relHpFixed = rel_hp_float_to_fixed_ceil(rel_hp_fixed_to_float(part.relHpFixed) + recover_health)
  part.state = DamagePartState.DP_STATE_DAMAGED

  if uint(part.relHpFixed) > uint(HP_DAMAGED_STATE_TRESHOLD_FIXED)
    part.state = DamagePartState.DP_STATE_NORMAL
    dm_parts__damagedByTeammate[damage_model_part_id] = false
  if fire_protection_part.maxHp > 0.f
    hp = rel_hp_float_to_fixed_ceil(rel_hp_fixed_to_float(fire_protection_part.hpFixed) + recover_health)

  fire_protection_part.hpFixed = hp

