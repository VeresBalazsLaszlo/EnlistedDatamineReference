module weapon_refill_ammo_common

require ecs
require app
require ecs.common
require game.es.inventory_common
require DagorSystem


struct MagazinesCount
  current : int
  partial : int

def check_and_update_ressuply_ammo_spam_timers(requester : EntityId)
  var isOk = true
  query(requester) <| $ [es] (human__minRessuplyTime : float;
                              var human__lastRessuplyAt : float&)
    let curTime = get_sync_time()
    isOk = curTime - human__lastRessuplyAt > human__minRessuplyTime
    if isOk
      human__lastRessuplyAt = curTime
  return isOk

def check_and_update_ressuply_medkit_spam_timers(requester : EntityId)
  var isOk = true
  query(requester) <| $ [es] (human__minRessuplyTime : float;
                              var human__lastRessuplyMedkitAt : float&)
    let curTime = get_sync_time()
    isOk = curTime - human__lastRessuplyMedkitAt > human__minRessuplyTime
    if isOk
      human__lastRessuplyMedkitAt = curTime
  return isOk

def check_and_update_ressuply_grenade_spam_timers(requester : EntityId)
  var isOk = true
  query(requester) <| $ [es] (human__minRessuplyTime : float;
                              var human__lastRessuplyGrenadeAt : float&)
    let curTime = get_sync_time()
    isOk = curTime - human__lastRessuplyGrenadeAt > human__minRessuplyTime
    if isOk
      human__lastRessuplyGrenadeAt = curTime
  return isOk

def get_magazines_count(ammo_in_gun : int;
                        max_ammo_in_magazine : int;
                        item_container : EidList;
                        is_suitable_ammo_cb : block<(itemTemplate : string) : bool>)
  var magazines = MagazinesCount(
    current = (ammo_in_gun <= 0 ? 0 : 1),
    partial = 0
  )


  for itemEid in item_container
    query(itemEid) <| $ [es] (item__template : string; ammo_holder__ammoCount : int)
      if !invoke(is_suitable_ammo_cb, item__template)
        return
      magazines.current++
      if ammo_holder__ammoCount < max_ammo_in_magazine
        magazines.partial++

  return magazines


def is_ammo_for_gun(ammo_template; ammo_holders_templates)
  for ammo_holder_template in ammo_holders_templates
    let holder = get_string(ammo_holder_template, "")
    if holder != "" && ammo_template == holder
      return true
  return false


def refill_ammo(requester; count; ammoTemplate)
  for _i in range(0, count)
    push_item_in_cont(requester, ammoTemplate)
  return count > 0


def is_throwable_grenade(item_eid : EntityId)
  let grenadeType = get_string(item_eid, "item__grenadeType", "")
  return grenadeType != "" && grenadeType != "shell"


def count_grenades_in_inventory(requester : EntityId)
  var grenadesInContainer = 0
  query(requester) <| $ [es] (itemContainer : EidList)
    for itemEid in itemContainer
      if is_throwable_grenade(itemEid)
        ++grenadesInContainer
  return grenadesInContainer


def get_grenades_capacity(requester : EntityId)
  var capacity = 1
  query(requester) <| $ [es] (human__numGrenadesResupply : int)
    capacity = human__numGrenadesResupply
  return capacity


def try_to_refill_grenades(requester, grenadeTemplate, requiredGrenadeCount)
  if grenadeTemplate == ""
    return 0

  var grenadesAdded = 0
  let grenadesInContainer = count_grenades_in_inventory(requester)

  let grenadesToAdd = requiredGrenadeCount - grenadesInContainer
  if grenadesToAdd > 0
    grenadesAdded = grenadesToAdd
    refill_ammo(requester, grenadesToAdd, grenadeTemplate)

  return grenadesAdded


def resupply_gun(empty_magazines_count, partial_magazines_count : int;
                 requester : EntityId;
                 holder_ammo_count : int;
                 reserve_ammo_template : string | #;
                 var item_container : EidList&;
                 is_suitable_ammo_cb : block<(itemTemplate : string) : bool>)
  let magazinesCount = empty_magazines_count + partial_magazines_count
  if magazinesCount <= 0
    return false

  // remove partial magazines from inventory which will be replaced by full magazines after that
  var i = length(item_container) - 1
  var numPartialMagsToBeRemoved = partial_magazines_count

  while i >= 0
    if numPartialMagsToBeRemoved <= 0
      break
    query(item_container[i]) <| $ [es] (item__template : string; ammo_holder__ammoCount : int)
      if !invoke(is_suitable_ammo_cb, item__template) || ammo_holder__ammoCount >= holder_ammo_count
        return
      destroyEntity(item_container[i])
      item_container |> erase(i)
      --numPartialMagsToBeRemoved
    --i

  return refill_ammo(requester, magazinesCount, reserve_ammo_template)

def refill_ammo_for_gun(requester_eid : EntityId;
                        gun_eid : EntityId;
                        ammo_in_gun : int;
                        ammo_template : string | #;
                        num_reserve_ammo : int;
                        var item_container : EidList;
                        is_suitable_ammo_cb : block<(itemTemplate : string) : bool>)
  let ammoTplComp = ammo_template |> getTemplateByName
  if ammoTplComp == null
    logerr("Template /*{ammo_template}*/ not exist in entity /*{getEntityTemplateName(gun_eid)}*/")
    return false

  let holderAmmoCount = *ammoTplComp |> getTemplateComponent("ammo_holder__ammoCount") ?? 0
  if holderAmmoCount <= 0
    logerr("/*{requester_eid}*/ ammo_holder.ammoCount is less than or equal to 0 in template: /*{ammo_template}*/")
    return false

  let magazines = get_magazines_count(ammo_in_gun, holderAmmoCount, item_container, is_suitable_ammo_cb)
  let emptyMagazineCount = num_reserve_ammo - magazines.current

  return resupply_gun(emptyMagazineCount, magazines.partial, requester_eid, holderAmmoCount, ammo_template, item_container, is_suitable_ammo_cb)
