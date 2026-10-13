import "%dngscripts/ecs.nut" as ecs   
from "%ui/helpers/metalink.nut" import getLinkedArmyName, getLinkedSquadGuid
from "%ui/components/soldierPhoto.nut" import mkSoldierPhotoName
from "%ui/scene/soldier_tools.nut" import getWeapTemplates, mkEquipment, getItemAnimationBlacklist
from "%ui/helpers/animation_utils.nut" import getIdleAnimState
from "%ui/soldiers/model/state.nut" import getSoldierItem
from "%ui/soldiers/components/perksPackage.nut" import getSoldierClassPerksPoints
from "%ui/ui_library.nut" import *

function collectSoldierPhoto(soldier, soldiersOutfit, overrideOutfit = {}, isLarge = false) {
  if (soldier?.photo != null)
    return soldier

  let { guid = null, equipScheme = {}, gametemplate = null } = soldier
  let equipmentInfo = []
  let equipment = mkEquipment(soldier, equipScheme, soldiersOutfit, overrideOutfit)
  if (equipment != null) {
    foreach (slot, equip in equipment) {
      if (!equip || !equip.gametemplate)
        continue
      equipmentInfo.append({
        slot = slot
        tpl = equip.gametemplate
      })
    }
  }

  let weapTemplates = getWeapTemplates(guid, equipScheme)
  let soldierTemplate = gametemplate
    ? ecs.g_entity_mgr.getTemplateDB().getTemplateByName(gametemplate)
    : null
  let overridedIdleAnims = soldierTemplate?.getCompValNullable("animation__overridedIdleAnims")
  let overridedSlotsOrder = soldierTemplate?.getCompValNullable("animation__overridedSlotsOrder").getAll()

  let animation = getIdleAnimState({
    weapTemplates
    itemTemplates = getItemAnimationBlacklist(soldier, guid, equipScheme, soldiersOutfit)
    overridedIdleAnims
    overridedSlotsOrder
    seed = guid?.hash() ?? 0
  })

  return soldier.__merge({
    photo = mkSoldierPhotoName(gametemplate, equipmentInfo, animation, isLarge)
  })
}

function findSlotByIngameWeaponSlot(equipScheme, ingameWeaponSlot) {
  foreach (slot, equip in equipScheme)
    if (equip?.ingameWeaponSlot == ingameWeaponSlot)
      return slot
  return null
}

function collectSoldierDataImpl(
  soldier, perksDataV, curCampSquadsV, armiesV, classesCfgV, campItemsV, soldiersOutfit,
  soldiersPremiumItems, soldierSchemesV, maxTrainByClassV
) {
  let { guid = null, sClass = null, basetpl = null, tier = 1, equipScheme = {} } = soldier
  if (guid == null)
    return soldier
  let armyId = getLinkedArmyName(soldier)
  let perks = perksDataV?[guid]
  let { exp = 0 } = perks

  let { kind = sClass } = classesCfgV?[sClass] 
  let { country = null } = (soldierSchemesV?[armyId] ?? {})
    .findvalue(@(data) basetpl == data.gametemplate)

  local equipSlot = findSlotByIngameWeaponSlot(equipScheme, "primary")
  local primaryWeapon = getSoldierItem(guid, equipSlot, campItemsV)

  if (primaryWeapon == null) {
    equipSlot = findSlotByIngameWeaponSlot(equipScheme, "secondary")
    primaryWeapon = getSoldierItem(guid, equipSlot, campItemsV)
  }

  if (primaryWeapon == null) {
    equipSlot = findSlotByIngameWeaponSlot(equipScheme, "tertiary")
    primaryWeapon = getSoldierItem(guid, equipSlot, campItemsV)
  }

  return collectSoldierPhoto(soldier.__merge({
    primaryWeapon
    country = country ?? armiesV?[armyId].country
    level = tier
    maxLevel = max(tier, (maxTrainByClassV?[sClass] ?? 0) + 1)
    locPerkPoints = getSoldierClassPerksPoints(sClass)
    exp
    armyId
    squadId = curCampSquadsV?[getLinkedSquadGuid(soldier)].squadId
    sKind = kind
  }), soldiersOutfit, soldiersPremiumItems)
}

return {
  collectSoldierPhoto
  collectSoldierDataImpl
}