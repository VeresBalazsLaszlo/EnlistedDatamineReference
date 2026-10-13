require ecs
require PhysVars

[es(on_appear)]
def init_selected_weapon_var(evt : Event;
                             var human_anim__selectedWeaponVarId : int&;
                             var human_anim__selectedStationaryGunVarId : int?;
                             var phys_vars : PhysVars)
  human_anim__selectedWeaponVarId = phys_vars |> registerVar("weapon_selected", 0.0)
  if human_anim__selectedStationaryGunVarId != null
    *human_anim__selectedStationaryGunVarId = phys_vars |> registerVar("stationary_gun", 0.0)