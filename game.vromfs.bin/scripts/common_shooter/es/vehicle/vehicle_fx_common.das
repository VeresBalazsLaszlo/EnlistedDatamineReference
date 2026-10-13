module vehicle_fx_common shared

require ecs
require Gun
require Ballistics
require BallisticsProps


def should_spawn_barrel_fx(gun_eid : EntityId) : bool
  let BARREL_FX_MIN_CALIBER = 0.015
  var keep = false
  query(gun_eid) <| $ [es] (gun__shell_prop_ids : GunShellPropIds;
                            turret__groupName : string = "")
    if turret__groupName == "smoke"
      return
    if length(gun__shell_prop_ids) == 0
      return
    assume shellId = gun__shell_prop_ids[0]
    projectile_get_props(int(shellId.shellId)) <| $(props : ProjectileProps)
      if props.caliber > BARREL_FX_MIN_CALIBER
        keep = true
  return keep
