require ecs
require ecs.safe
require ecs.common
require enlisted.events_enlisted
require game.es.weapon_refill_ammo_common
require game.es.inventory_common

[es(tag=server)]
def gun_initial_ammo_spawn_on_loot_gun(evt : EventOnWeapSlotItemPickup; eid : EntityId)
  query(evt.itemEid) <| $ [es] (gun__ammoHolders : Array;
                                gun__initialAmmoHoldersCount : IntList;
                                var gun__isInitialAmmoHoldersSpawned : bool&)
    if gun__isInitialAmmoHoldersSpawned
      return
    gun__isInitialAmmoHoldersSpawned = true

    let ammoHoldersLen = min(length(gun__ammoHolders), length(gun__initialAmmoHoldersCount))
    if ammoHoldersLen < 1
      return

    for ammoHolder, count in gun__ammoHolders, gun__initialAmmoHoldersCount
      let ammoTemplate = ammoHolder ?? ""
      if ammoTemplate == ""
        continue

      for _i in range(0, count)
        createEntity(ammoTemplate) <| $(var init : ComponentsInitializer)
          set(init, "item__ownerEid", eid)


[es(tag=server)]
def gun_initial_ammo_update_weap_info_on_loot_gun(evt : EventOnWeapSlotItemPickup;
                                                  var human_weap__weapInfo : Array&)
  query(evt.itemEid) <| $ [es] (gun__ammoHolders : Array;
                                gun__initialAmmoHoldersCount : IntList)
    let ammoHoldersLen = min(length(gun__ammoHolders), length(gun__initialAmmoHoldersCount))
    if ammoHoldersLen < 1
      return

    var weapInfo = getRW_ecs_object(human_weap__weapInfo[evt.slotId])
    if weapInfo == null
      return

    set(*weapInfo, "reserveAmmoTemplate", gun__ammoHolders[0])
    set(*weapInfo, "numReserveAmmo", gun__initialAmmoHoldersCount[0])

    if ammoHoldersLen < 2
      return

    using() <| $(var additional_ammo_templates : Array)
      using() <| $(var additional_ammo_nums : Array)
        for i in range(1, ammoHoldersLen)
          push(additional_ammo_templates, gun__ammoHolders[i])
          push(additional_ammo_nums, gun__initialAmmoHoldersCount[i])
        set(*weapInfo, "additionalReserveAmmoTemplates", additional_ammo_templates)
        set(*weapInfo, "additionalNumReserveAmmos", additional_ammo_nums)

[es(tag=server, on_appear)]
def gun_initial_ammo_with_special_ammo_pouch(evt : Event;
                                             gun__ammoHolders : Array;
                                             eid : EntityId;
                                             item__initialTeam : int;
                                             var item__specialFlag : bool&;
                                             gun__curAmmoHolderIndex : int;
                                             gun__ammo : int;
                                             gun__numReserveAmmo : int;
                                             gun__reserveAmmoTemplate : string;
                                             gun__additionalReserveAmmoTemplates : StringList;
                                             gun__additionalNumReserveAmmos : IntList;
                                             gun__owner : EntityId)
  query(gun__owner) <| $ [es] (soldier__sKind : string;
                               team : int;
                               var itemContainer : EidList&)
    if soldier__sKind != "partisan" || item__specialFlag || team == item__initialTeam
      return

    item__specialFlag = true
    var ammoHolders : array<string>
    for ammoHolder in gun__ammoHolders
      push(ammoHolders, ammoHolder ?? "")

    if gun__numReserveAmmo > 0
      let ammoHolderIdx = find_index(ammoHolders, gun__reserveAmmoTemplate)
      let ammoInGun = (ammoHolderIdx == gun__curAmmoHolderIndex) ? gun__ammo : 0

      refill_ammo_for_gun(gun__owner, eid,
                          ammoInGun,
                          gun__reserveAmmoTemplate,
                          gun__numReserveAmmo - 1,
                          itemContainer) <| $(itemTemplate)
        return is_ammo_for_gun(itemTemplate, gun__ammoHolders) && find_index(gun__additionalReserveAmmoTemplates, itemTemplate) < 0

    for ammoTemplateStr, ammoNum in gun__additionalReserveAmmoTemplates, gun__additionalNumReserveAmmos
      if ammoNum <= 0
        continue


      peek(ammoTemplateStr) <| $(ammoTemplate)
        let ammoHolderIdx = find_index(ammoHolders, string(ammoTemplateStr))
        let ammoInGun = (ammoHolderIdx == gun__curAmmoHolderIndex) ? gun__ammo : 0

        refill_ammo_for_gun(gun__owner, eid, ammoInGun, ammoTemplate, ammoNum, itemContainer) <| $(itemTemplate)
          return itemTemplate == ammoTemplate
