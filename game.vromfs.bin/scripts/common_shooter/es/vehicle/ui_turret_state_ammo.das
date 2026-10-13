require ecs
require ecs.common
require strings
require enlisted.events_enlisted

[es(tag=ui, REQUIRE=vehicleWithWatched, no_order)]
def ui_update_wathed_vehicle_turret_ammo(info : ParallelUpdateFrameDelayed;
                                         turret_control__gunEids : EidList;
                                         ui_turrets_state__updateInterval : float = 0.1;
                                         disableVehicleResupply : Tag const?;
                                         fortification_repair__costPercent : float const?;
                                         var ui_turrets_state__ammo : Object&;
                                         var ui_turrets_state__nextUpdateTime : float&)
  if info.curTime < ui_turrets_state__nextUpdateTime
    return
  ui_turrets_state__nextUpdateTime = info.curTime + ui_turrets_state__updateInterval
  var groupAmmo : table<string; int>
  var reloadAmmo : table<string; int>
  var firstLoadedGunInGroup : table<string; EntityId>
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (gun__ammo : int;
                             gun__totalAmmo : int;
                             turret__numAmmoFirstStage : int = -1;
                             turret__groupName : string = "";
                             gun__ammo_by_shell : IntList const?)
      if !empty(turret__groupName)
        groupAmmo.insert(turret__groupName, (groupAmmo?[turret__groupName] ?? 0) + gun__ammo)
        reloadAmmo.insert(turret__groupName, (reloadAmmo?[turret__groupName] ?? 0) + gun__totalAmmo)
        if gun__ammo > 0 && !key_exists(firstLoadedGunInGroup, turret__groupName)
          firstLoadedGunInGroup.insert(turret__groupName, gunEid)
      ui_turrets_state__ammo |> push_to_object("{gunEid}") <| $(var ammo : Object)
        ammo |> set("curAmmo", gun__ammo)
        ammo |> set("totalAmmo", gun__totalAmmo)
        if turret__numAmmoFirstStage >= 0
          ammo |> set("firstStageAmmo", turret__numAmmoFirstStage)
        ammo |> set("canBeResuppliedOnPoint", disableVehicleResupply == null)
        ammo |> set("canBeResuppliedByEngineer", fortification_repair__costPercent != null)
        if gun__ammo_by_shell != null
          ammo |> set("ammoByBullet", *gun__ammo_by_shell)
    for groupKey, groupValue in keys(groupAmmo), values(groupAmmo)
      ui_turrets_state__ammo |> push_to_object(groupKey) <| $(var ammo : Object)
        ammo |> set("groupAmmo", groupValue)
        ammo |> set("reloadAmmo", reloadAmmo.get_value(groupKey))
        if key_exists(firstLoadedGunInGroup, groupKey)
          ammo |> set("firstLoadedGunInGroup", firstLoadedGunInGroup.get_value(groupKey))
