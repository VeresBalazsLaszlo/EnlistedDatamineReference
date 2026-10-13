import "utf8" as utf8
import "%ui/helpers/icon3dByGameTemplate.nut" as iconByGameTemplate
import "%dngscripts/ecs.nut" as ecs
from "dagor.localize" import doesLocTextExist
from "%sqstd/string.nut" import CASE_PAIR_LOWER, CASE_PAIR_UPPER
from "%sqstd/time.nut" import secondsToTime
from "math" import abs
from "%ui/components/mkSpecialItemIcon.nut" import SIGN_PREMIUM, SIGN_EVENT, SIGN_BP
from "%ui/ui_library.nut" import *
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/soldiers/soldierCustomizationState.nut" import getIconDataFromTemplate

const UPGRADE_TEMPLATE_SUFFIX = "_upgrade_"
const LOCID_ITEMS = "items/{0}"

let ITEM_DETAILS_BRIEF = [
  { key = "hitPowerTotal", precision = 0.1, range = [0, 26] }
  { key = "kineticArmorPowerMax", precision = 0.1, range = [0, 200] }
  { key = "rateOfFire", measure = "shots/min" }
  { key = "recoilAmountVert", isPositive = false }
  { key = "recoilAmountHor", isPositive = false }
  { key = "gun__adsSpeedMult", mult = 100, defVal = 1, range = [0, 130] }
  { key = "gun__firingModeNames" }
]

let ITEM_DETAILS_FULL = [
  { key = "caliber", measure = "mm", mult = 1000, precision = 0.01 }
  { key = "hitPowerTotal", precision = 0.1, range = [0, 26] }
  { key = "explodeHitPower", precision = 0.1 }
  { key = "hitpower", measure = "meters", precision = 0.1, baseKey = "hitPowerTotal" }
  { key = "cumulativeArmorPower", measure = "mm", precision = 0.1 }
  { key = "kineticArmorPower", measure = "meters", altMeasure = "mm", precision = 0.1 }
  { key = "speed", measure = "m/sec" }
  { key = "rateOfFire", measure = "shots/min" }
  { key = "gun__reloadTime", measure = "sec", precision = 0.1, isPositive = false }
  { key = "gun_spread__maxDeltaAngle", mult = 100, isPositive = false }
  { key = "recoilControlMult", measure = "percent" }
  { key = "recoilAmountVert", isPositive = false }
  { key = "recoilAmountHor", isPositive = false }
  { key = "bullets" }
  { key = "flamethrower__maxFlameLength", measure = "meters" }
  { key = "flamethrower__streamDamagePerSecond" }
  { key = "item__healAmount", precision = 0.1 }
  { key = "item__reviveAmount", precision = 0.1 }
  { key = "item__weight", measure = "grams", mult = 1000, altLimit = 1.0, altMeasure = "kg", precision = 0.1 }
  { key = "weap__sprintLerpFactor", measure = "percent", mult = 100 }
  { key = "cartridgeMass", measure = "grams", mult = 1000, altLimit = 1.0, altMeasure = "kg", precision = 0.1 }
  { key = "gun__firingModeNames" }
  { key = "splashDamage" }
]

let ARMOR_ORDER = ["front", "side", "back", "top", "bottom"]

let GENERAL_VEHICLE_DETAILS = [
  { key = "crew", measure = "persons" }
  { key = "armament" }
  { key = "maxSpeed", measure = "km/h", precision = 0.01 }
]

let SPEC_PLANE_DETAILS = [
  { key = "maxClimb", measure = "m/sec", precision = 0.01 }
  { key = "bestTurnTime", measure = "sec", precision = 0.01 }
]

let SPEC_TANK_DETAILS = [
  { key = "gun__reloadTime", measure = "sec", precision = 0.1 }
  { key = "turret__yawSpeed", measure = "deg/sec", precision = 0.1 }
  { key = "turret__pitchSpeed", measure = "deg/sec", precision = 0.1 }
  { key = "armor__body", measure = "mm" }
  { key = "armor__turret", measure = "mm" }
  { key = "engine__horsePowers", baseKey = "engine__maxRPM" }
  { key = "Mass__TakeOff", measure = "tonne", mult = 0.001, precision = 0.1 }
]

let VEHICLE_DETAILS = [].extend(GENERAL_VEHICLE_DETAILS, SPEC_PLANE_DETAILS, SPEC_TANK_DETAILS)

function getCampaignTitle(campId) {
  let locId = $"{campId}/full"
  return doesLocTextExist(locId) ? loc(locId) : campId
}

function getArmaments(guns) {
  guns = (guns ?? []).filter(@(gun) (gun?["gun__maxAmmo"] ?? 0) > 0)
  if (guns.len() == 0)
    return null

  let reducedGuns = []
  foreach (gun in guns) {
    let gunId = gun?["gun__blk"]
    let prevGun = reducedGuns.findvalue(@(g) g?["gun__blk"] == gunId)
    if (prevGun == null) {
      reducedGuns.append({ count = 1 }.__update(gun))
    } else {
      ++prevGun.count
      prevGun["gun__maxAmmo"] <- (prevGun?["gun__maxAmmo"] ?? 0) + (gun?["gun__maxAmmo"] ?? 0)
    }
  }
  reducedGuns.sort(@(a, b) a.count <=> b.count
    || a["gun__maxAmmo"] <=> b["gun__maxAmmo"])
  return reducedGuns
}

let itemNameCache = {}

function getItemLocIdByTemplate(template) {
  if (template == null || typeof template != "string")
    return null

  if (template in itemNameCache)
    return itemNameCache[template]

  let gametemplate = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(template)
  let name = gametemplate != null ? gametemplate.getCompValNullable("item__name") : null
  if (name != null)
    itemNameCache[template] <- name
  return name
}

function trimUpgradeSuffix(tmpl) {
  if (typeof tmpl != "string")
    return tmpl
  let tmplEnd = tmpl.indexof(UPGRADE_TEMPLATE_SUFFIX)
  return tmplEnd != null ? tmpl.slice(0, tmplEnd) : tmpl
}

let itemDescByType = {
  function booster(item) { 
    let { battles = 0, expMul = 0.0, lifeTime = 0 } = item?.template
    let percent = abs(expMul * 100).tointeger()
    let boosterType = (expMul < 0) ? "penalty" : "booster"

    local descLimit = ""
    if (lifeTime > 0) {
      local { days = 0, hours = 0 } = secondsToTime(lifeTime)
      let limit = days == 7 ? loc($"items/booster/limit/week")
        : days > 0 ? loc($"items/booster/limit/days", { lifetime = days })
        : loc($"items/booster/limit/hours", { lifetime = hours })
      descLimit = loc("items/booster/desc/lifetime", { lifetime = limit })
    }

    let descExp = battles > 0
      ? loc($"items/{boosterType}/desc/battles", { percent, battles, limit = descLimit })
      : loc($"items/{boosterType}/desc/exp", { percent, limit = descLimit })

    return descExp
  }
}

function itemNameFromGametemplate(gametemplate) {
  let locId = getItemLocIdByTemplate(gametemplate)
  return locId != null ? loc(locId) : null
}

function itemNameFromItemtype(item) {
  let { itemtype = "" } = item
  let locId = LOCID_ITEMS.subst(itemtype)
  return doesLocTextExist(locId) ? loc(locId) : null
}

function itemNameFromTemplate(item) {
  let { gametemplate = "" } = item
  return itemNameFromGametemplate(gametemplate) ?? itemNameFromItemtype(item)
}

function boosterName(item) {
  let { expMul = 0.0 } = item?.template
  let percent = abs(expMul * 100).tointeger()
  let boosterType = expMul < 0 ? "penalty" : "booster"
  return loc($"items/{boosterType}/name", { percent })
}

function itemNameFromItem(item) {
  let { basetpl = "" } = item
  local locId = LOCID_ITEMS.subst(basetpl)
  if (doesLocTextExist(locId))
    return loc(locId)

  locId = LOCID_ITEMS.subst(trimUpgradeSuffix(basetpl))
  return doesLocTextExist(locId) ? loc(locId) : itemNameFromTemplate(item)
}

function getItemSubtitle(item) {
  let { basetpl = null } = item
  let tmpl = trimUpgradeSuffix(basetpl ?? item)
  return loc($"items/{tmpl}/subtitle", "")
}

let signLocalization = {
  [SIGN_PREMIUM] = loc("campaign/premSquadWeapon"),
  [SIGN_EVENT] = loc("campaign/eventSquadWeapon"),
  [SIGN_BP] = loc("campaign/bpSquadWeapon"),
}

let getItemOrigin = @(item)
  signLocalization?[item?.sign] ?? loc("campaign/promoSquadWeapon")


function getItemDesc(item) {
  let { gametemplate = null, itemtype = "unknown", basetpl = null } = item
  let res = itemDescByType?[itemtype](item)
  if (res != null)
    return res

  let tmpl = $"{trimUpgradeSuffix(basetpl ?? item)}"
  let locItemId = $"items/{tmpl}/desc"
  if (doesLocTextExist(locItemId))
    return loc(locItemId)

  let locTypeId = $"items/{itemtype}/desc"
  if (doesLocTextExist(locTypeId))
    return loc(locTypeId)

  
  let itemNameId = getItemLocIdByTemplate(gametemplate)
  let locBlkId = $"{itemNameId}/desc"
  if (doesLocTextExist(locBlkId))
    return loc(locBlkId)

  return ""
}

function getItemTypeName(item) {
  let { itemtype = "" } = item
  let locId = $"itemtype/{itemtype}"
  return doesLocTextExist(locId) ? loc(locId) : ""
}

function iconByItem(item, params, armyId = null, isIgnore = false) {
  let { basetpl = null } = item
  local attachmentParams = params
  if (basetpl != null && armyId != null) {
    
    let { iconAttachments } = getIconDataFromTemplate(allItemTemplates.get(), armyId, basetpl, isIgnore)
    attachmentParams = attachmentParams.__merge({
      genOverride = { iconAttachments }
      shading = "same" })
  }
  return iconByGameTemplate(item?.gametemplate, attachmentParams)
}

let localizeSoldierName = memoize(function(soldier) {
  let { name = "", surname = "" } = soldier
  return {
    name = name == "" ? "" : loc(name)
    surname = surname == "" ? "" : loc(surname)
  }
})

let getObjectName = memoize(function(obj) {
  let { name, surname } = localizeSoldierName(obj)
  return surname == "" ? itemNameFromItem(obj) : $"{name} {surname}"
})

let soldierNameSlicer = memoize(function(soldier = null, useCallname = true) {
  let { name, surname } = localizeSoldierName(soldier)
  let { callname = "" } = soldier
  if (callname != "" && useCallname)
    return callname
  if (surname == "")
    return name
  let first = utf8(name).slice(0, 1)
  return (!CASE_PAIR_UPPER.contains(first) && !CASE_PAIR_LOWER.contains(first))
    ? $"{name} {surname}"
    : $"{first}. {surname}"
})


function getErrorSlots(slotsItems, equipScheme) {
  let errorSlots = {}
  let equipped = {}
  let slotTypeToGroup = {}
  foreach (slotType, slot in equipScheme) {
    let { atLeastOne = "" } = slot
    if (atLeastOne != "") {
      equipped[atLeastOne] <- false
      slotTypeToGroup[slotType] <- atLeastOne
    }
  }
  foreach (slotData in slotsItems) {
    let { item, slotType } = slotData
    if (item == null)
      continue

    let group = slotTypeToGroup?[slotType]
    if (group in equipped)
      equipped[group] = true

    local { basetpl, itemtype = null } = item
    basetpl = trimUpgradeSuffix(basetpl)
    let { items = [], itemTypes = [] } = equipScheme?[slotType]
    if ((itemTypes.len() != 0 || items.len() != 0)
        && !itemTypes.contains(itemtype)
        && !items.contains(basetpl))
      errorSlots[slotType] <- true
  }
  foreach (slotType, group in slotTypeToGroup)
    if (!equipped[group])
      errorSlots[slotType] <- true
  return errorSlots
}

let templateLevel = @(tmpl, level) level < 1 ? tmpl : $"{tmpl}_upgrade_{level}"

console_register_command(function() {
  foreach (armyId, templates in allItemTemplates.get()) {
    foreach (tmplId, template in templates) {
      let tmplLocId = $"items/{tmplId}"
      if (!doesLocTextExist(tmplLocId))
        continue

      let { gametemplate = "" } = template
      if (gametemplate == "")
        continue

      let itemNameId = getItemLocIdByTemplate(gametemplate)
      if (itemNameId && tmplLocId != itemNameId)
        log($"{armyId}/{tmplId} has gametemplate {gametemplate} with different localization {itemNameId}")
    }
  }
}, "loc.checkGameTemplates")

return freeze({
  getItemDetails = @(isFull) isFull ? ITEM_DETAILS_FULL : ITEM_DETAILS_BRIEF
  PLANE_DETAILS = [].extend(GENERAL_VEHICLE_DETAILS, SPEC_PLANE_DETAILS)
  TANK_DETAILS = [].extend(GENERAL_VEHICLE_DETAILS, SPEC_TANK_DETAILS)
  ARMOR_ORDER
  VEHICLE_DETAILS
  getCampaignTitle
  getArmaments
  trimUpgradeSuffix
  iconByGameTemplate
  iconByItem
  getItemSubtitle
  getItemDesc
  getItemOrigin
  getItemTypeName
  localizeSoldierName
  getObjectName
  soldierNameSlicer
  getErrorSlots
  templateLevel
  itemNameFromTemplate
  itemNameFromItem
  itemNameFromGametemplate
  boosterName
})
