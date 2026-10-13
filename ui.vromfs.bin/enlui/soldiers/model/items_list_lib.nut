from "%ui/soldiers/model/state.nut" import getSoldierItemSlots
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/meta/profile.nut" import campItemsByLink
from "%ui/ui_library.nut" import *

let equalIgnore = { ctime = true, guid = true, guids = true, count = true, links = true, linkedItems = true }
function countParamsToCompare(item) {
  local res = item.len()
  foreach (key, _ in equalIgnore)
    if (key in item)
      res--
  return res
}

function getLinkedItemsData(guid) {
  let res = {}
  foreach (data in getSoldierItemSlots(guid, campItemsByLink.get())) {
    let tpl = data.item?.basetpl
    if (!(data.slotType in res))
      res[data.slotType] <- {}
    res[data.slotType][data.slotId ?? -1] <- tpl
  }
  return res
}

function mergeItems(item1, item2) {
  if (countParamsToCompare(item1) != countParamsToCompare(item2))
    return null
  foreach (key, val in item1)
    if (!equalIgnore?[key]
        && (!(key in item2) || !isEqual(val, item2[key])))
      return null

  local linkedItems = null
  if (item1?.equipScheme) {
    linkedItems = item1?.linkedItems ?? getLinkedItemsData(item1.guid)
    if (!isEqual(linkedItems, getLinkedItemsData(item2.guid)))
      return null
  }

  let guids = "guids" in item1 ? item1.guids : [item1?.guid]
  guids.append(item2?.guid)
  return item1.__merge({
    count = (item1?.count ?? 1) + (item2?.count ?? 1)
    guids = guids
    linkedItems = linkedItems
  })
}

let itemWeights = freeze([

  "vehicle",


  "explosion_pack",
  "grenade",
  "impact_grenade",
  "incendiary_grenade",
  "molotov",
  "lunge_mine",
  "tnt_block_exploder",
  "smoke_grenade",
  "antipersonnel_mine",
  "antitank_mine",


  "flamethrower",
  "mortar",


  "launcher",
  "grenade_launcher",
  "infantry_launcher",
  "antitank_rifle",


  "mgun",
  "assault_rifle",
  "semiauto",
  "carbine_tanker",
  "assault_semi",
  "submgun",
  "carbine_pistol",


  "rifle_grenade_launcher",
  "rifle_at_grenade_launcher",
  "shotgun",
  "boltaction_noscope",
  "carbine",
  "semiauto_sniper",
  "boltaction",


  "sideweapon",
  "flaregun",


  "flask_usable",
  "binoculars_usable",
  "backpack",
  "small_backpack",
  "big_ammo_pouch",
  "small_ammo_pouch",
  "big_grenade_pouch",
  "small_grenade_pouch",
  "radio",
  "melee",
  "bayonet",
  "scope",
  "medic_medkits",
  "medkits",
  "repair_kit",


  "soldier",


  "booster",


  "ticket",
].reduce(@(res, itemtype, idx, list) res.$rawset(itemtype, list.len() - idx), {}))

function prepareItems(items, objByGuid = {}, needMergeByTpl = true) {
  items = items
    .map(function(item) {
      if (typeof item == "string")
        return objByGuid?[item]
      if ("guid" in item)
        return objByGuid?[item.guid]
      return item
    })
    .filter(@(v) v != null)
    .sort(@(a, b) (a?.basetpl ?? "") <=> (b?.basetpl ?? ""))

  if (!needMergeByTpl)
    return items

  let res = []
  foreach (item in items) {
    local isMerged = false
    let tpl = item?.basetpl
    for(local i = res.len() - 1; i >= 0; i--) {
      let tgtItem = res[i]
      if (tgtItem?.basetpl != tpl)
        break
      let merged = mergeItems(tgtItem, item)
      if (!merged)
        continue
      res[i] = merged
      isMerged = true
      break
    }
    if (!isMerged)
      res.append(item)
  }

  return res
}

let mkShopItem = @(templateId, template, armyId)
  template.__merge({ guid = "", basetpl = templateId, isShopItem = true, links = { [armyId] = "army"} })

function addShopItems(
  items, armyId, templateFilter = @(_templateId, _template) true, vehByOwner = {}
) {
  let usedTemplates = {}
  foreach (item in items)
    if ("basetpl" in item)
      usedTemplates[item.basetpl] <- true

  foreach (templateId, template in (allItemTemplates.get()?[armyId] ?? {}))
    if (templateId not in usedTemplates
        && (!(template?.isZeroHidden ?? false) || templateId in vehByOwner)
        && templateFilter(templateId, template))
      items.append(mkShopItem(templateId, template, armyId))
}

let itemsSort = @(item1, item2) (item1?.guid != null) <=> (item2?.guid != null)
  || (itemWeights?[item1?.itemtype] ?? 0) <=> (itemWeights?[item2?.itemtype] ?? 0)
  || (item1?.growthTier ?? 0) <=> (item2?.growthTier ?? 0)
  || (item1?.itemsubtype ?? "") <=> (item2?.itemsubtype ?? "")
  || (item1?.gametemplate ?? "") <=> (item2?.gametemplate ?? "")
  || (item1?.upgradeIdx ?? 0) <=> (item2?.upgradeIdx ?? 0)

let preferenceSort = @(a, b) (itemWeights?[b?.itemtype] ?? 0) <=> (itemWeights?[a?.itemtype] ?? 0)
  || (a?.basetpl ?? "") <=> (b?.basetpl ?? "")

function findItemByGuid(items, guid) {
  foreach (it in items)
    if ("guids" in it ? it.guids.contains(guid) : it?.guid == guid)
      return it
  return null
}

return {
  itemWeights
  prepareItems
  mkShopItem
  addShopItems
  itemsSort
  preferenceSort
  findItemByGuid
}