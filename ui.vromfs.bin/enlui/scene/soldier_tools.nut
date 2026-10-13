import "%enlSqGlob/weapon_slots.nut" as weaponSlots
import "%dngscripts/ecs.nut" as ecs
from "dagor.debug" import logerr
from "dagor.math" import Point3
from "%ui/soldiers/model/state.nut" import getSoldierItem, getSoldierItemSlots, getModSlots, curSquadSoldiersInfo, armySquadsById, getSoldierByGuid
from "%ui/helpers/animation_utils.nut" import getIdleAnimState
from "%ui/helpers/metalink.nut" import getLinkedArmyName, isLinkedTo, getLinkedSquadGuid
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, findItemTemplate
from "%ui/meta/profile.nut" import campItemsByLink, curCampSoldiers, curCampItems
from "%ui/meta/servProfile.nut" import squads, soldiersLook, soldiersOutfit
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfileLookCfg
from "%ui/scene/soldier_overrides.nut" import soldierOverrides, isSoldierDisarmed, isSoldierSlotsSwap, getSoldierIdle, getSoldierHeadTemplate, getSoldierFace, faceGenOverrides, getSoldierFaceGen
from "%ui/soldiers/model/config/outfitConfig.nut" import getSquadOutfit, isObjAvailableForCampaign
from "%sqstd/frp.nut" import subscribeList
from "%ui/ui_library.nut" import *

let curGenFaces = require("%ui/faceGen/gen_faces.nut")

const weaponSlotNames = [ "primary", "secondary", "tertiary", "melee", "grenade", "special"]
const notShownOutsideSquad = [ "parachute", "radio" ]

let DB = ecs.g_entity_mgr.getTemplateDB()

let WEAP_SLOT_TYPES = { primary = true, secondary = true, side = true, tertiary = true,
  melee = true, grenade = true }

let EQUIPMENT_SLOT_TYPES = { radio = true }

let INVENTORY_SLOT_TYPES = { inventory = true, grenade = true, mine = true, flask_usable = true,
  binoculars_usable = true, inventory_hidden = true }

let soldierViewGen = Watched(0)
let soldierViewNext = @() soldierViewGen.modify(@(v) v + 1)
subscribeList(soldierViewNext, soldierOverrides, faceGenOverrides, curSquadSoldiersInfo)
let appearanceToRender = Watched(null)

let initSoldierQuery = ecs.SqQuery("initSoldierQuery", {
  comps_rw = [
    ["animchar__res", ecs.TYPE_STRING],
    ["guid", ecs.TYPE_STRING],
    ["guid_hash", ecs.TYPE_INT],
    ["human_weap__weapInfo", ecs.TYPE_ARRAY],
    ["animchar__scale", ecs.TYPE_FLOAT],
    ["animchar__depScale", ecs.TYPE_POINT3],
    ["animchar__transformScale", ecs.TYPE_POINT3],
    ["appearance__rndSeed", ecs.TYPE_INT]
  ]
})

function initFacegenParams(face_equip, animchar_disabled_params, init_comps) {
  let template = DB.getTemplateByName(face_equip.template)
  let animchar = template?.getCompValNullable("animchar__res")
  let { faceId = null } = face_equip
  if (animchar && faceId != null) {
    let params = getSoldierFaceGen(animchar, faceId) ?? curGenFaces?[animchar][faceId.tostring()]
    if (params != null) {
      init_comps["animcharParams"] <- params
      foreach (param in animchar_disabled_params)
        if (init_comps?["animcharParams"][param] != null)
          init_comps["animcharParams"].$rawdelete(param)
    } else
      log($"Soldier {animchar} have no {faceId} face gen params")
  }
}

function calcFaceGenDisableParams(equipment) {
  let animcharDisabledParams = []
  foreach (eq in equipment){
    if (!eq || !eq.template)
      continue
    let template = DB.getTemplateByName(eq.template)
    animcharDisabledParams.extend(template?.getCompValNullable("disabledFaceGenParams").getAll() ?? [])
  }
  return animcharDisabledParams
}

function reinitEquipment(eid, equipment) {
  let animcharDisabledParams = calcFaceGenDisableParams(equipment)
  let cur_human_equipment = ecs.obsolete_dbg_get_comp_val(eid, "human_equipment__slots")

  let filteredEquipment = {}
  foreach (slotId, slot in cur_human_equipment) {
    if (slot.item != null && slot.item != ecs.INVALID_ENTITY_ID) {
      let templateArray = ecs.g_entity_mgr.getEntityFutureTemplateName(slot.item)?.split("+") ?? []
      let oldTemplateBase = templateArray?[0] ?? slot.template
      if (oldTemplateBase && oldTemplateBase == equipment?[slotId].template
          && ecs.obsolete_dbg_get_comp_val(slot.item, "slot_attach__visible"))
        continue

      ecs.g_entity_mgr.destroyEntity(slot.item)
      slot.item = ecs.EntityId(ecs.INVALID_ENTITY_ID)
      slot.template = ""
    }
    filteredEquipment[slotId] <- equipment?[slotId]
  }

  foreach (slot, eq in filteredEquipment) {
    if (!eq || !eq.template)
      continue

    let comps = {
      ["animchar_attach__attachedTo"] = [eid, ecs.TYPE_EID],
    }
    if (slot == "face")
      initFacegenParams(eq, animcharDisabledParams, comps)
    if (eq.template!=""){
      cur_human_equipment[slot].item = ecs.g_entity_mgr.createEntity(eq.template, comps)
      cur_human_equipment[slot].template = eq.template
    }
  }
  ecs.obsolete_dbg_set_comp_val(eid, "human_equipment__slots", cur_human_equipment)
}

function setEquipment(eid, equipment) {
  let sl = ecs.obsolete_dbg_get_comp_val(eid, "human_equipment__slots")
  let equipSlots = sl.getAll()
  let animcharDisabledParams = calcFaceGenDisableParams(equipment)
  local updateEquipmentSlots = false
  foreach (slot, eq in equipment) {
    if (equipSlots[slot].item != null && equipSlots[slot].item != ecs.INVALID_ENTITY_ID)
      ecs.g_entity_mgr.destroyEntity(equipSlots[slot].item)

    if (!eq || !eq.template)
      continue

    let comps = {
      ["animchar_attach__attachedTo"] = [eid, ecs.TYPE_EID],
    }
    if (eq.template && eq.template!="") {
      if (sl?[slot] != null) {
        if (slot == "face")
          initFacegenParams(eq, animcharDisabledParams, comps)
        sl[slot].item = ecs.g_entity_mgr.createEntity(eq.template, comps)
        sl[slot].template = eq.template
        updateEquipmentSlots = true
      }
    }
  }
  if (updateEquipmentSlots)
    ecs.obsolete_dbg_set_comp_val(eid, "human_equipment__slots", sl)
}

let isWeaponSlot = @(slotType, scheme) slotType in INVENTORY_SLOT_TYPES
  || (scheme?[slotType].ingameWeaponSlot ?? "") in WEAP_SLOT_TYPES

function getWearInfos(soldierGuid, scheme) {
  let eInfos = []
  let itemSlots = getSoldierItemSlots(soldierGuid, campItemsByLink.get())
  foreach (itemInfo in itemSlots) {
    let { slotType, item } = itemInfo
    let { slotTemplates = {} } = item
    if (slotTemplates.len() <= 0 && isWeaponSlot(slotType, scheme))
      continue

    let itemGuid = itemInfo.item.guid
    let info = curCampItems.get()?[itemGuid]
    if (info?.slot != null)
      eInfos.append(info)
  }
  return eInfos
}

function getItemAnimationBlacklist(soldier, soldierGuid, scheme, soldiersLookVal) {
  let itemTemplates = []
  let armyId = getLinkedArmyName(soldier)
  foreach (slotType, _ in scheme) {
    let item = getSoldierItem(soldierGuid, slotType, campItemsByLink.get())
    let { gametemplate = "" } = item
    if (gametemplate != "") {
      let itemTemplate = DB.getTemplateByName(gametemplate)
      if (itemTemplate != null)
        itemTemplates.append(itemTemplate)
    }
  }
  let eInfos = getWearInfos(soldierGuid, scheme)
  foreach (eInfo in eInfos) {
    let itemTemplate = DB.getTemplateByName(eInfo.gametemplate)
    if (itemTemplate != null)
      itemTemplates.append(itemTemplate)
  }
  let soldierLook = soldiersLookVal?[soldierGuid]
  if (soldierLook != null) {
    let itemTemplatesVal = allItemTemplates.get()
    foreach (tmpl in soldierLook?.items ?? {}) {
      let eInfo = findItemTemplate(itemTemplatesVal, armyId, tmpl)
      if (eInfo != null && eInfo?.slot != null) {
        let itemTemplate = DB.getTemplateByName(eInfo.gametemplate)
        if (itemTemplate != null)
          itemTemplates.append(itemTemplate)
      }
    }
  }
  return itemTemplates
}

function getWeapTemplates(soldierGuid, scheme) {
  let weapTemplates = {primary="", secondary="", tertiary="", special=""}
  let slotOrder = ["primary", "secondary", "tertiary", "special"]
  foreach (slotType, slot in scheme) {
    if (weapTemplates?[slot?.ingameWeaponSlot] != "")
      continue
    let weapon = getSoldierItem(soldierGuid, slotType, campItemsByLink.get())
    if ("gametemplate" not in weapon)
      continue

    weapTemplates[slot.ingameWeaponSlot] = $"{weapon.gametemplate}+menu_gun"
  }

  foreach(slot in slotOrder) {
    let template = weapTemplates?[slot] ?? ""
    if (template == "")
      continue

    let newTemplate = "+".concat(template, "primary_menu_gun")
    weapTemplates[slot] = newTemplate
    break
  }

  return weapTemplates
}

function getTemplate(gametemplate) {
  let itemTemplate = DB.getTemplateByName(gametemplate)
  if (!itemTemplate)
    return null
  let recreateName = itemTemplate.getCompValNullable("item__recreateInEquipment") ?? "base_vis_item"
  return recreateName == "" ? gametemplate : $"{gametemplate}+{recreateName}"
}

function mkEquipment(soldier, scheme, soldiersLookVal, premiumItems, customizationOvr = null) {
  if (DB.size() == 0)
    return {}

  let { guid } = soldier
  let soldiersDefaultLook = soldiersLookVal?[guid]
  if (soldiersDefaultLook == null)
    return {}

  let armyId = getLinkedArmyName(soldier)
  let squadGuid = getLinkedSquadGuid(soldier)
  let faceOverride = getSoldierFace(guid)
  let itemTemplatesVal = allItemTemplates.get()

  
  local slotTmpls = {}
  foreach (slotType, templ in soldiersDefaultLook.items) {
    let itemTemplate = findItemTemplate(itemTemplatesVal, armyId, templ)
    if (itemTemplate != null)
      slotTmpls[slotType] <- itemTemplate
  }

  
  
  let overrideSlotsList = []
  let itemSlots = getSoldierItemSlots(guid, campItemsByLink.get())
  foreach (itemSlot in itemSlots) {
    let { slotType } = itemSlot
    if (slotType in INVENTORY_SLOT_TYPES)
      continue
    if (squadGuid == null && notShownOutsideSquad.contains(slotType))
      continue
    let slot = scheme?[slotType]
    if (slot == null || (slot?.ingameWeaponSlot in WEAP_SLOT_TYPES))
      continue
    let itemTemplate = findItemTemplate(itemTemplatesVal, armyId, itemSlot.item.basetpl)
    if (itemTemplate != null) {
      slotTmpls[slotType] <- itemTemplate
      let equipSlot = itemTemplate?.slot
      if (equipSlot != null && equipSlot != slotType && equipSlot in slotTmpls)
        overrideSlotsList.append(equipSlot)
    }
  }

  
  foreach (item in premiumItems) {
    let slotType = item.links[guid]
    let itemTemplate = findItemTemplate(itemTemplatesVal, armyId, item.basetpl)
    if (itemTemplate != null)
      slotTmpls[slotType] <- itemTemplate
  }
  foreach (slotType, templ in customizationOvr ?? {}) {
    if (templ == "") {
      slotTmpls[slotType] <- null
      continue
    }
    let itemTemplate = findItemTemplate(itemTemplatesVal, armyId, templ)
    if (itemTemplate != null)
      slotTmpls[slotType] <- itemTemplate
  }

  
  foreach (removeSlot in overrideSlotsList)
    slotTmpls.$rawdelete(removeSlot)

  local equipment = {}
  foreach (slotType, itemTemplate in slotTmpls) {
    let itemSlot = itemTemplate?.slot ?? slotType
    if (itemTemplate == null) {
      equipment[itemSlot] <- null
      continue
    }
    let { gametemplate } = itemTemplate
    let template = getTemplate(gametemplate)
    let data = { gametemplate, template }
    if (slotType == "head")
      data.faceId <- faceOverride ?? soldiersDefaultLook.faceId
    equipment[itemSlot] <- data
  }
  foreach (itemTemplate in slotTmpls)
    foreach (slotType, gametemplate in itemTemplate?.slotTemplates ?? {}) {
      let template = getTemplate(gametemplate)
      equipment[slotType] <- { gametemplate, template }
    }

  
  foreach (itemSlot in itemSlots) {
    let { slotType } = itemSlot
    if (slotType in INVENTORY_SLOT_TYPES)
      continue

    let slot = scheme?[slotType]
    if (slotType not in WEAP_SLOT_TYPES
        && (slot?.ingameWeaponSlot not in WEAP_SLOT_TYPES)
        && (slotType not in EQUIPMENT_SLOT_TYPES))
      continue

    let itemTemplate = findItemTemplate(itemTemplatesVal, armyId, itemSlot.item.basetpl)
    foreach (slotId, gametemplate in itemTemplate?.slotTemplates ?? {}) {
      let template = getTemplate(gametemplate)
      equipment[slotId] <- { gametemplate, template }
    }
  }

  if ((equipment?.head ?? "") != "" || (equipment?.skined_helmet ?? "") != "")
    equipment.hair <- null
  equipment = equipment.filter(@(v) v != "" && v != null)
  return equipment
}

function getSoldierWeaponOffsetByAnimation(selectedPose, itemTemplates) {
  local animationWeaponOffset = Point3(0.0, 0.0, 0.0)
  foreach (itemTemplate in itemTemplates) {
    let itemAnimationWeaponOffset = itemTemplate.getCompValNullable("animationWeaponOffset")
    if (itemAnimationWeaponOffset == null)
      continue

    local foundPose = false
    local defaultOffset = Point3(0.0, 0.0, 0.0)
    foreach (anim, offset in itemAnimationWeaponOffset) {
      if (anim == selectedPose || anim == "all_states") {
        foundPose = true
        animationWeaponOffset += offset
      }
      if (anim == "no_state_found")
        defaultOffset = offset
    }
    if (!foundPose)
      animationWeaponOffset += defaultOffset
  }
  return animationWeaponOffset
}

function createSoldier(
  guid, transform, soldiersLookVal, premiumItems = [], callback = null, extraTemplates = [],
  isDisarmed = false, isSiting = false, customizationOvr = null, poseIndex = null,
  reInitEid = ecs.INVALID_ENTITY_ID
) {
  let soldier = curCampSoldiers.get()?[guid]
  if (soldier == null)
    return ecs.INVALID_ENTITY_ID

  local scheme = soldier?.equipScheme ?? {}
  if (isSoldierDisarmed(guid) || isDisarmed)
    scheme = {}
  else if (isSoldierSlotsSwap(guid)) {
    let primaryKey = "primary" in scheme
      ? "primary"
      : scheme.findindex(@(val) val?.ingameWeaponSlot == "primary")
    let primary = scheme?[primaryKey]

    let secondaryKey = "secondary" in scheme
      ? "secondary"
      : scheme.findindex(@(val) val?.ingameWeaponSlot == "secondary")
    let secondary = scheme?[secondaryKey]

    if (primary && secondary)
      scheme = scheme.__merge({ [primaryKey] = secondary, [secondaryKey] = primary })
  }

  let soldierItems = getSoldierItemSlots(guid, campItemsByLink.get())
  let weapTemplates = getWeapTemplates(guid, scheme)

  let armyId = getLinkedArmyName(soldier)
  let squadGuid = getLinkedSquadGuid(soldier)
  let { squadId = "" } = squads.get()?[squadGuid]
  let outfit = getSquadOutfit(armyId, squadId, armySquadsById.get(), gameProfileLookCfg.get())
  let soldiersPremItems = premiumItems.filter(@(item)
    isLinkedTo(item, guid) && isObjAvailableForCampaign(item, outfit))

  let equipment = mkEquipment(soldier, scheme, soldiersLookVal,
    soldiersPremItems, customizationOvr)

  let weapInfo = []
  weapInfo.resize(weaponSlots.EWS_NUM)

  let overrideHead = getSoldierHeadTemplate(guid)
  if (overrideHead) {
    let template = getTemplate(overrideHead)
    equipment.face <- (equipment?.face ?? {}).__update({
      gametemplate = overrideHead
      template
    })
  }

  for (local slotNo = 0; slotNo < weaponSlots.EWS_NUM; ++slotNo) {
    let weapon = {}
    weapInfo[slotNo] = weapon
    let slotName = weaponSlotNames[slotNo]
    let slots = getModSlots(
      curCampItems.get()?[soldierItems.findvalue(@(item) item.slotType == slotName)?.item.guid])
    foreach (slot in slots) {
      let slotTemplateId = curCampItems.get()?[slot.equipped].gametemplate
      let slotTemplate = slotTemplateId ? DB.getTemplateByName(slotTemplateId) : null
      if (!slotTemplate)
        continue
      if ("gunMods" not in weapon)
        weapon.gunMods <- {}
      weapon.gunMods[slot.slotType] <- slotTemplate.getCompVal("gunAttachable__slotTag")
    }
  }

  let { gametemplate = null } = soldier
  if (gametemplate == null)
    return ecs.INVALID_ENTITY_ID

  let soldierTemplate = DB.getTemplateByName(gametemplate)
  let overridedIdleAnims = soldierTemplate?.getCompValNullable("animation__overridedIdleAnims")
  let overridedSlotsOrder = soldierTemplate?.getCompValNullable("animation__overridedSlotsOrder").getAll()
  let itemTemplates = equipment.map(@(eq) DB.getTemplateByName(eq.gametemplate)).filter(@(t) t != null).values()
  let guid_hash = guid.hash()
  let animation = getSoldierIdle(guid) ?? getIdleAnimState({
    weapTemplates
    itemTemplates
    overridedIdleAnims
    overridedSlotsOrder
    seed = poseIndex ?? guid_hash
    isSiting
  })
  let weaponOffset = getSoldierWeaponOffsetByAnimation(animation, itemTemplates)
  let bodyHeight = soldier?.bodyScale.height ?? 1.0
  let bodyWidth = soldier?.bodyScale.width ?? 1.0
  let result_template = "+".join(["customizable_menu_animchar","human_weap", "human_gun_offset_global_vars"].extend(extraTemplates))

  let animcharRes = soldierTemplate?.getCompValNullable("animchar__res")
  let collRes = soldierTemplate?.getCompValNullable("collres__res")

  if (reInitEid != ecs.INVALID_ENTITY_ID) {
    local canBeRecreated = false
    initSoldierQuery.perform(reInitEid, function(_eid, comp){
      if (animcharRes != comp.animchar__res){
        return
      }
      canBeRecreated = true
      comp.guid = guid
      comp.guid_hash = guid_hash
      comp.human_weap__weapInfo = weapInfo
      comp.animchar__scale = bodyHeight
      comp.animchar__depScale = Point3(bodyWidth, bodyHeight, bodyWidth)
      comp.animchar__transformScale = Point3(bodyWidth, 1.0, bodyWidth)
    })
    if (canBeRecreated){
      callback?(reInitEid)
      reinitEquipment(reInitEid, equipment)
      return reInitEid
    }
    else {
      ecs.g_entity_mgr.destroyEntity(reInitEid)
    }
  }
  return ecs.g_entity_mgr.createEntity(result_template, {
      ["animchar__res"] = animcharRes,
      ["collres__res"] = collRes,
      ["transform"] = transform,
      ["guid"] = guid,
      ["guid_hash"] = guid_hash,
      ["animchar__animStateNames"] = [{ lower = animation, upper = animation }, ecs.TYPE_OBJECT],
      ["human_weap__weapTemplates"] = [weapTemplates, ecs.TYPE_OBJECT],
      ["human_weap__weapInfo"] = [weapInfo, ecs.TYPE_ARRAY],
      ["animchar__scale"] = bodyHeight,
      ["animchar__depScale"] = Point3(bodyWidth, bodyHeight, bodyWidth),
      ["animchar__transformScale"] = Point3(bodyWidth, 1.0, bodyWidth),
      ["gun_offset__fromSoldier"] = [weaponOffset, ecs.TYPE_POINT3]
    },
    function(newEid) {
      callback?(newEid)
      setEquipment(newEid, equipment)
    }
  )
}

function validateSoldierOutfit() {
  let errors = []
  let itemTemplatesVal = allItemTemplates.get()
  foreach (look in soldiersLook.get()) {
    let guid = look.guid
    let soldier = getSoldierByGuid(guid)
    if (soldier == null) {
      errors.append("Empty soldier info. Skip.")
      continue
    }

    let armyId = getLinkedArmyName(soldier)
    if (armyId == null) {
      errors.append($"Guid {guid}, armyId {armyId} passed. Skip.")
      continue
    }

    foreach (tmpl in look.items) {
      let eInfo = findItemTemplate(itemTemplatesVal, armyId, tmpl)
      if (eInfo != null && eInfo?.slot != null) {
        let itemTemplate = DB.getTemplateByName(eInfo.gametemplate)
        if (itemTemplate == null)
          errors.append($"Cannot load template {tmpl} for {guid} / {armyId}")
      }
      else
        errors.append($"Not found template {tmpl} for {guid} / {armyId}")
    }
  }

  foreach (item in soldiersOutfit.get()) {
    let armyId = getLinkedArmyName(item)
    let eInfo = findItemTemplate(itemTemplatesVal, armyId, item.basetpl)
    if (eInfo != null && eInfo?.slot != null) {
      let itemTemplate = DB.getTemplateByName(eInfo.gametemplate)
      if (itemTemplate == null)
        errors.append($"Cannot load template {item.basetpl} for {armyId}")
    }
    else
      errors.append($"Not found template {item.basetpl} for {armyId}")
  }

  foreach(err in errors)
    logerr(err)

  if (errors.len() > 0)
    logerr($"Got /*{errors.len()}*/ errors. List is above.")
  else
    console_print($"Outfits info from {soldiersLook.get().len() + soldiersOutfit.get().len()} blocks are fine")
}

console_register_command(@() validateSoldierOutfit(), "meta.validateAllSoldierOutfit")

return {
  soldierViewGen
  mkEquipment
  getWeapTemplates
  getItemAnimationBlacklist
  createSoldier = kwarg(createSoldier)
  appearanceToRender
  validateSoldierOutfit
}