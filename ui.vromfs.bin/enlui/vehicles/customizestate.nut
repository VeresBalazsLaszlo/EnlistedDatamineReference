import "%ui/components/colorize.nut" as colorize
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/vehDecorUtils.nut" import stringToDecal, decalToCompObject,
  readSkinFromTemplate, getVehSkinById, VEH_AGE_BASE, VEH_SCALE_BASE, VEH_ROTATION_BASE
from "%ui/currency/premium.nut" import hasPremium
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/featureFlags.nut" import hasVehicleCustomization
from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/meta/servProfile.nut" import vehDecorators, vehCamouflages
from "%ui/meta/clientApi.nut" import add_veh_decorators, apply_decorator_unique,
  buy_apply_veh_decorators, apply_camouflage
from "%ui/vehicles/decorViewer.nut" import setDecalSlot, setDecalMirrored, setDecalTwoSide, vehTargetEid, applyDecalsToVehicle, setDecorInfo, applyDecorToVehicle
from "%ui/soldiers/model/state.nut" import curArmyData
from "%ui/style/designConst.nut" import accentTitleTxtColor
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, findItemTemplate
from "%ui/showState.nut" import vehicleInVehiclesScene
from "%ui/vehicles/vehiclesListState.nut" import isCustomizeWndOpen
from "%ui/vehicles/vehDecorState.nut" import vehCustomizationCfg, vehCamouflageCfg
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix
from "%ui/ui_library.nut" import *

let vehCustSchemesCfg = mkComputedConfigGet("vehCustSchemes", {})

const OBJ_TEXSET = "animchar__objTexSet"

let customizationParams = Watched(null)
let lastOpenedGroupName = Watched("")

let selectedCamouflage = Watched(null)
let selectedDecorator = Watched(null)

let isPurchasing = Watched(false)
let notPurchased = Watched({})

let ageSlider = Watched(VEH_AGE_BASE)
let scaleSlider = Watched(VEH_SCALE_BASE)
let rotationSlider = Watched(VEH_ROTATION_BASE)
let showUniqueDetails = Watched(false)
let hasCampaigns = Watched(false)
let selectedCampaign = Watched(COMMON_CAMPAIGN)

let templateDb = ecs.g_entity_mgr.getTemplateDB()

let skinParamsToDetails = Computed(@()
  ",".join([
    ageSlider.get().tointeger(),
    scaleSlider.get().tointeger(),
    rotationSlider.get().tointeger()
  ]))

let viewVehCustSchemes = Computed(function() {
  if (!hasVehicleCustomization.get())
    return null

  let vehicle = vehicleInVehiclesScene.get()
  if (vehicle == null)
    return null

  let { itemsubtype = null } = vehicle
  let armyId = getLinkedArmyName(vehicle)
  let { vehDecal = null, vehDecorator = null, reqArmies = [] } = vehCustSchemesCfg.get()?[itemsubtype]

  if (vehDecal == null && vehDecorator == null)
    return null

  return reqArmies.len() > 0 && !reqArmies.contains(armyId)
    ? null
    : { vehDecal, vehDecorator }
})

let vehDecorBelongCfg = mkComputedConfigGet("vehDecorBelongCfg", {})
let vehDecorLimits = mkComputedConfigGet("vehDecorLimits", {})

let availVehDecorByTypeId = Computed(function() {
  let res = {}
  foreach (guid, vehDecorator in vehDecorators.get()) {
    let { cType, id } = vehDecorator
    if (cType not in res)
      res[cType] <- {}
    if (id not in res[cType])
      res[cType][id] <- {}

    res[cType][id][guid] <- vehDecorator
  }
  return res
})

let curOwnCamoList = Computed(function() {
  let { guid = null, basetpl = "" } = vehicleInVehiclesScene.get()
  if (guid == null)
    return null

  let config = vehCamouflageCfg.get()?[trimUpgradeSuffix(basetpl)] ?? {}
  return (vehCamouflages.get()?[guid].available ?? [])
    .filter(@(v) v in config)
})

let customizationSort = @(a, b) (a?.weight ?? 0) <=> (b?.weight ?? 0) || a.id <=> b.id

let forcedCustomizationExcludes = {
  objTexReplace = {}
  objTexSet = {}
  cfg = {}
  hasOwned = {}
}

let forcedCustomization = Computed(function() {
  let { id = "" } = selectedCamouflage.get()
  let { gametemplate = "" } = vehicleInVehiclesScene.get()
  let camouflageData = getVehSkinById(gametemplate, id)
  local {
    objTexReplace = null, objTexSet = null, animchar__objTexReplace = null,
    animchar__objTexSet = null
  } = camouflageData

  let res = {}

  if (animchar__objTexSet != null)
    res.animchar__objTexSet <- animchar__objTexSet

  if (animchar__objTexReplace != null || objTexReplace != null) {
    camouflageData.filter(@(_, k) k not in forcedCustomizationExcludes).each(@(v, k) res[k] <- v)
    if (objTexReplace != null)
      res.animchar__objTexReplace <- objTexReplace
    if (objTexSet != null)
      res.animchar__objTexSet <- objTexSet
  }

  return res
})

let hasNoBelongToHidden = @(belongData)
  belongData.findvalue(@(belong) belong.len() > 0) != null

let hasBelongByArmy = @(armyBelong, armyId)
  armyBelong.len() == 0 || (armyBelong?[armyId] ?? false)

let hasBelongByCountry = @(countryBelong, countryId)
  countryBelong.len() == 0 || (countryBelong?[countryId] ?? false)

let hasBelongByType = @(vehTypeBelong, vehType)
  vehTypeBelong.len() == 0 || (vehTypeBelong?[vehType] ?? false)

function getDecorBelongText(belongId) {
  let belongCfg = vehDecorBelongCfg.get()?[belongId] ?? {}
  let armyBelong = (belongCfg?.byArmy ?? {}).keys()
  let countryBelong = (belongCfg?.byCountry ?? {}).keys()
  let vehTypeBelong = (belongCfg?.byVehType ?? {}).keys()
  let belongData = {
    armyies = ", ".join(armyBelong
      .map(@(v) colorize(accentTitleTxtColor, loc($"{v}/full"))))
    countries = ", ".join(countryBelong
      .map(@(v) colorize(accentTitleTxtColor, loc($"country/{v}"))))
    vehTypes = ", ".join(vehTypeBelong
      .map(@(v) colorize(accentTitleTxtColor, loc($"vehType/{v}"))))
  }

  let res = "\n".join(belongData.map(function(txt, key) {
    let keyText = loc($"decorator/belong/{key}")
    return txt == "" ? null : $"{keyText}: {txt}"
  }).values().filter(@(v) v != null))
  return res == "" ? ""
    : "{0}\n{1}".subst(loc("decorator/conditions"), res)
}

let curDecorCfgByType = Computed(function() {
  let vehicle = vehicleInVehiclesScene.get()
  if (vehicle == null)
    return null

  let armyId = getLinkedArmyName(vehicle)
  let { basetpl = null, itemsubtype = null } = vehicle
  let template = findItemTemplate(allItemTemplates.get(), armyId, basetpl)
  let { guid = "" } = curArmyData.get()
  let { country = "" } = template
  let belongCfg = vehDecorBelongCfg.get()
  let res = vehCustomizationCfg.get().map(@(decData)
    decData.filter(function(decor) {
      let { belongId = "" } = decor
      if (belongId == "")
        return true

      let belongData = belongCfg?[belongId] ?? {}
      return hasNoBelongToHidden(belongData)
        && hasBelongByArmy(belongData?.byArmy ?? {}, guid)
        && hasBelongByCountry(belongData?.byCountry ?? {}, country)
        && hasBelongByType(belongData?.byVehType ?? {}, itemsubtype)
    }))
  return res
})

let viewVehDecorByType = Computed(function() {
  let { guid = "" } = vehicleInVehiclesScene.get()
  let decoratorsCfg = vehCustomizationCfg.get()
  return availVehDecorByTypeId.get()
    .map(function(cTypeData) {
      let res = {}
      foreach (idData in cTypeData)
        foreach (dGuid, decorator in idData)
          if (decorator.vehGuid == guid) {
            let cfg = decoratorsCfg?[decorator.cType][decorator.id]
            res[dGuid] <- decorator.__merge({ cfg })
          }
      return res
    })
})

let vehCamouflageObj = Computed(function() {
  let { guid = null } = vehicleInVehiclesScene.get()
  if (guid == null)
    return
  return vehCamouflages.get()?[guid]
})

let viewVehCamouflage = Computed(@()
  vehCamouflageObj.get()?.active[hasCampaigns.get() ? selectedCampaign.get() : COMMON_CAMPAIGN])

let uniqueDetails = Computed(function() {
  let { gametemplate = "" } = vehicleInVehiclesScene.get()
  if (gametemplate == "")
    return {}

  let tpl = templateDb.getTemplateByName(gametemplate)
  let res = tpl?.getCompValNullable(OBJ_TEXSET)?.getAll() ?? {}
  return res
})

let uniqueDetailsAvailable = Computed(@() uniqueDetails.get().len() > 0
  
    && ((selectedCamouflage.get() != null && OBJ_TEXSET not in selectedCamouflage.get())
      || (viewVehCamouflage.get() != null
          && viewVehCamouflage.get()?.skinId != "" && OBJ_TEXSET not in viewVehCamouflage.get()))
)

let curVehCustomization = Computed(function() {
  let { gametemplate = "" } = vehicleInVehiclesScene.get()
  if (gametemplate == "")
    return {}

  let skin = viewVehCamouflage.get()
  local res = readSkinFromTemplate(gametemplate, skin)
  if (!isCustomizeWndOpen.get())
    return res

  let selected = forcedCustomization.get()
  if (selected.len() > 0)
    res = clone selected

  if (uniqueDetailsAvailable.get() && showUniqueDetails.get())
    res.animchar__objTexSet <- clone uniqueDetails.get()

  
  return res
})

let curCamouflageId = Computed(@()
  selectedCamouflage.get()?.id ?? viewVehCamouflage.get()?.skinId ?? "")

function startUsingDecor(slot, cfg) {
  setDecalSlot(slot)
  setDecorInfo(cfg.id, cfg.cType)
  selectedDecorator.set(cfg)
}

function mirrorDecal(isMirrored) {
  setDecalMirrored(isMirrored)
}

function twoSideDecal(isTwoSided, isMirrored) {
  setDecalTwoSide(isTwoSided, isMirrored)
}

function buyApplyDecorators(decorators, camouflage, vehGuid, cost, cb = null) {
  if (isPurchasing.get())
    return

  isPurchasing.set(true)
  buy_apply_veh_decorators(decorators, camouflage, vehGuid, cost, function(res) {
    isPurchasing.set(false)
    cb?(res)
  })
}

function applyDecorator(guid, vehGuid, cType, details, slot, hasUnique, cb = null) {
  if (isPurchasing.get())
    return

  isPurchasing.set(true)
  apply_decorator_unique(guid, vehGuid, cType, details, slot, hasUnique, function(res) {
    isPurchasing.set(false)
    cb?(res)
  })
}

function applySkinData(skinId, vehGuid, isCommon, campaign) {
  if (isPurchasing.get()
    || vehGuid == null
    || (skinId != "" && !curOwnCamoList.get().contains(skinId)))
    return

  isPurchasing.set(true)

  apply_camouflage(vehGuid, skinId,
    skinParamsToDetails.get(),
    showUniqueDetails.get(),
    isCommon,
    campaign,
    function(res) {
      isPurchasing.set(false)
      if (res?.error == null)
        selectedCamouflage.set(null)
    })
}

function applyCamouflage(skinId, vehGuid) {
  applySkinData(skinId, vehGuid,
    !hasCampaigns.get(),
    hasCampaigns.get() ? selectedCampaign.get() : COMMON_CAMPAIGN)
}

let closeDecoratorsList = @() customizationParams.set(null)

let viewVehDecorData = keepref(Computed(function() {
  let vehicleGuid = vehicleInVehiclesScene.get()?.guid ?? ""
  let targetEid = vehTargetEid.get() ?? ecs.INVALID_ENTITY_ID
  if (vehicleGuid == "" || targetEid == ecs.INVALID_ENTITY_ID)
    return null

  let decorVehicleGametemplate = vehicleInVehiclesScene.get()?.gametemplate ?? ""
  let currentTargetVehicleTemplate = ecs.g_entity_mgr.getEntityTemplateName(targetEid)
  if (currentTargetVehicleTemplate != null && decorVehicleGametemplate != "" && !(currentTargetVehicleTemplate?.contains(decorVehicleGametemplate) ?? false))
    return null

  let hasPrem = hasPremium.get()
  let { slotsNum = 0, premSlotsNum = 0 } = viewVehCustSchemes.get()?.vehDecorator ?? {}
  let availableSlots = hasPrem ? slotsNum + premSlotsNum : slotsNum
  if (availableSlots <= 0)
    return null

  let decorArray = []
  let busySlots = {}
  foreach(decor in notPurchased.get()?.vehDecorator ?? []) {
    let { details, cType, id, slotIdx } = decor
    let decorData = stringToDecal(details, cType, id, slotIdx)
    if (decorData != null) {
      decorArray.append(decorData)
      busySlots[slotIdx] <- true
    }
  }
  foreach (decorById in availVehDecorByTypeId.get()?.vehDecorator ?? {})
    foreach (decor in decorById) {
      let { vehGuid, slotIdx, id, details, cType } = decor
      if (vehGuid != vehicleGuid || slotIdx >= availableSlots)
        continue

      let decorData = stringToDecal(details, cType, id, slotIdx)
      if (decorData != null && slotIdx not in busySlots)
        decorArray.append(decorData)
    }

  return { targetEid, decorArray }
}))

let viewVehDecalData = keepref(Computed(function() {
  let vehicleGuid = vehicleInVehiclesScene.get()?.guid ?? ""
  let targetEid = vehTargetEid.get() ?? -1
  if (vehicleGuid == "" || targetEid < 0)
    return null

  let hasPrem = hasPremium.get()
  let { slotsNum = 0, premSlotsNum = 0 } = viewVehCustSchemes.get()?.vehDecal ?? {}
  let avaiSlots = hasPrem ? slotsNum + premSlotsNum : slotsNum
  if (avaiSlots <= 0)
    return null

  let decalCompArray = ecs.CompArray()
  foreach (decalsById in availVehDecorByTypeId.get()?.vehDecal ?? {})
    foreach (decal in decalsById) {
      let { vehGuid, slotIdx, id, details, cType } = decal
      if (vehGuid != vehicleGuid || slotIdx >= avaiSlots)
        continue

      let decalData = stringToDecal(details, cType, id, slotIdx)
      if (decalData != null)
        decalCompArray.append(decalToCompObject(decalData))
    }
  foreach(decal in notPurchased.get()?.vehDecal ?? []) {
    let { details, cType, id, slotIdx } = decal
    let decalData = stringToDecal(details, cType, id, slotIdx)
    if (decalData != null)
      decalCompArray.append(decalToCompObject(decalData))
  }

  return { targetEid, decalCompArray }
}))

let viewVehCustLimits = Computed(function() {
  let viewVehGuid = vehicleInVehiclesScene.get()?.guid
  if (viewVehGuid == null)
    return null

  let cfg = vehCustomizationCfg.get()
  let res = {}
  foreach (vehDecorator in vehDecorators.get()) {
    let { cType, id, vehGuid, slotIdx } = vehDecorator
    if (vehGuid != viewVehGuid)
      continue

    let groupId = cfg?[cType][id].subType ?? ""
    if (groupId != "")
      res[cType] <- (res?[cType] ?? {}).__update({ [slotIdx] = groupId })
  }
  return res
})

function updateViewVehDecals(_ = null) {
  let decals = viewVehDecalData.get()
  if (decals != null)
    applyDecalsToVehicle(decals)
}

function updateViewVehDecor(_ = null) {
  let decors = viewVehDecorData.get()
  if (decors != null)
    applyDecorToVehicle(decors)
}

viewVehDecalData.subscribe(updateViewVehDecals)
viewVehDecorData.subscribe(updateViewVehDecor)
notPurchased.subscribe(function(_ = null) {
  updateViewVehDecals()
  updateViewVehDecor()
})

function stopUsingDecal() {
  selectedDecorator.set(null)
  setDecalSlot(-1)
  setDecorInfo("", "")
  updateViewVehDecals()
}

console_register_command(@(id) add_veh_decorators(id), "meta.addVehCustomizator")

return {
  closeDecoratorsList
  customizationParams
  lastOpenedGroupName
  selectedCamouflage
  vehCamouflageObj
  uniqueDetailsAvailable
  showUniqueDetails
  hasCampaigns
  selectedCampaign

  selectedDecorator
  startUsingDecor
  isPurchasing
  notPurchased
  mirrorDecal
  twoSideDecal
  stopUsingDecal

  curVehCustomization
  vehDecorLimits
  customizationSort
  viewVehCustSchemes
  viewVehCustLimits
  viewVehCamouflage
  curCamouflageId

  availVehDecorByTypeId
  curOwnCamoList
  curDecorCfgByType
  getDecorBelongText
  viewVehDecorByType
  applyDecorator
  applyCamouflage
  applySkinData
  buyApplyDecorators

  ageSlider
  scaleSlider
  rotationSlider
  skinParamsToDetails
}
