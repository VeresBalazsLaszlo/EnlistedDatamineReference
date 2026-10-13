import "%ui/control/gui_buttons.nut" as JB
import "%dngscripts/ecs.nut" as ecs
from "dagor.debug" import logerr
from "%ui/state/appState.nut" import isInBattleState
from "%ui/meta/servProfile.nut" import soldiersLook
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfileLookCfg
from "%ui/soldiers/model/config/outfitConfig.nut" import freeOutfitsForArmy, outfitShopTypes,
  equippedOutfitsForArmy, getCustomizeScheme, getSquadOutfit, isObjAvailableForCampaign,
  ownedOutfitsByArmy, outfitSchemes
from "%ui/soldiers/model/all_items_templates.nut" import findItemTemplate, allItemTemplates
from "%ui/scene/soldier_tools.nut" import appearanceToRender
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierInfo
from "%ui/meta/clientApi.nut" import change_outfit
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/soldiers/model/state.nut" import armySquadsById, curSquadSoldiersInfo
from "%ui/helpers/metalink.nut" import isLinkedTo, getFirstLinkByType, isObjLinkedToAnyOfObjects,
  getFirstLinkedObjectGuid
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/items/outfitBundles.nut" import outfitBundles, bundlesPresentation
from "%ui/meta/configs.nut" import mkComputedConfigGet
from "%ui/soldiers/model/config/soldierResideConfig.nut" import resideCustomization
from "%sqstd/timers.nut" import debounce
from "%ui/ui_library.nut" import *
from "%ui/components/itemTexReplace.nut" import getTexReplaceString, getTexSetString, getCamouflageString
from "%ui/components/itemAttachmentParams.nut" import getAttachmentParams

let rand = require("%sqstd/rand.nut")()
let DB = ecs.g_entity_mgr.getTemplateDB()

const blockedHeroSlots = { head = true } 
let ignoreIconSlots = freeze(["backpack", "hands", "face_equipment", "gloves", "front_belt_l",
  "front_belt_r"].totable()) 
let ignoreForMultiPurchase = @(slot) slot == "head"

let isCustomizationWndOpened = Watched(false)
let currentItemPart = mkWatched(persist, "currentItemPart", "")
let curCustomizationItem = mkWatched(persist, "curCustomizationItem", null)
let customizationToApply = mkWatched(persist, "customizationToApply", {})
let customizedSoldierInfo = Computed(@() isInBattleState.get() ? null : curSoldierInfo.get())
let soldiersDropCfg = mkComputedConfigGet("soldiers_drop")

let campaignOutfit = Computed(function() {
  let { armyId = null, squadId = null } = customizedSoldierInfo.get()
  if (armyId == null || squadId == null)
    return ""
  return getSquadOutfit(armyId, squadId, armySquadsById.get(), gameProfileLookCfg.get())
})

let customizeScheme = Computed(function() {
  let {
    armyId = null, squadId = null, gametemplate = null, heroTpl = null
  } = customizedSoldierInfo.get()
  if (armyId == null || squadId == null || gametemplate  == null)
    return {}

  let campaign = campaignOutfit.get()

  let scheme = getCustomizeScheme(squadsCfgById.get(), outfitSchemes.get(),
      armyId, squadId, campaign)
    .__merge(resideCustomization.get()?[gametemplate] ?? {})

  let { overrideCampaignSlots = {} } = soldiersDropCfg.get()?[heroTpl]
  foreach (slot, item in overrideCampaignSlots?[campaign] ?? {})
    scheme[slot] <- (clone scheme?[slot] ?? []).append(item)

  return scheme
})

function isSoldierLocked(soldier, dropConfigs) {
  let { heroTpl = null } = soldier
  let { isOutfitLocked = false } = dropConfigs?[heroTpl]
  return isOutfitLocked
}

function isSlotLocked(soldier, slotId, dropConfigs) {
  let { heroTpl = null } = soldier
  let { overrideSlots = {} } = dropConfigs?[heroTpl]
  return (slotId in overrideSlots) && (slotId in blockedHeroSlots)
}

let customizedSoldierLocked = Computed(@()
  isSoldierLocked(customizedSoldierInfo.get(), soldiersDropCfg.get()))

let resetSoldierRender = debounce(@() appearanceToRender.set(null), 0.1)

customizationToApply.subscribe(function(v) {
  if (customizedSoldierInfo.get() == null || v.len() <= 0) {
    resetSoldierRender()
    return
  }
  appearanceToRender.set(v)
})

function increment(table, template) {
  table[template] <- 1 + (table?[template] ?? 0)
  return table
}

function decrement(table, template) {
  let count = table?[template]
  if (count == null)
    return table

  if (count > 1)
    table[template] = count - 1
  else
    table.rawdelete(template)
  return table
}

let freeItemsBySquad = Computed(function() {
  let res = {}
  foreach (outfit in freeOutfitsForArmy.get())
    if (outfit.links.len() <= 1)
      increment(res, outfit.basetpl)
  return res
})

let freeItemsForSoldier = Computed(function() {
  let { guid = null } = customizedSoldierInfo.get()
  
  let result = clone freeItemsBySquad.get()
  let equippedItems = soldiersLook.get()?[guid].items ?? {}
  equippedItems.each(@(val) increment(result, val))

  let linkedItems = equippedOutfitsForArmy.get()
  linkedItems.each(function(outfit) {
    if (isLinkedTo(outfit, guid) && isLinkedTo(outfit, campaignOutfit.get()))
      increment(result, outfit.basetpl)
  })

  return result
})

let schemeItemsPrice = Computed(function() {
  let { armyId = null } = customizedSoldierInfo.get()
  let res = {}
  let ownedTemplates = ownedOutfitsByArmy.get().templates?[armyId] ?? {}
  let itemTypes = outfitShopTypes.get()
  let itemTemplatesVal = allItemTemplates.get()
  foreach (slotItems in customizeScheme.get()) {
    foreach (basetpl in slotItems) {
      let { itemsubtype = null } = findItemTemplate(itemTemplatesVal, armyId, basetpl)
      let curItemPrice = itemTypes?[itemsubtype]
      let isHidden = (curItemPrice ?? {}).findvalue(@(v) v?.isZeroHidden) != null
      let isOwned = basetpl in ownedTemplates
      if (curItemPrice != null && (!isHidden || isOwned))
        res[basetpl] <- curItemPrice
    }
  }
  return res
})

let itemsToBuy = Computed(@()
  customizationToApply.get().filter(@(item, slot)
    item != ""
      && item not in freeItemsForSoldier.get()
      && item in schemeItemsPrice.get()
      && (customizeScheme.get()?[slot] ?? []).contains(item)
  ))

let curSoldierItemsPrice = Computed(@()
  schemeItemsPrice.get()?.filter(@(_, key) key not in freeItemsForSoldier.get()))

let premiumItemsCount = Computed(function() {
  let res = {}
  let { guid = null} = customizedSoldierInfo.get()
  let linkedItems = freeOutfitsForArmy.get()
  foreach (item in linkedItems)
    if (item.links.len() == 1
      || (isLinkedTo(item, guid) && isObjAvailableForCampaign(item, campaignOutfit.get())))
        increment(res, item.basetpl)
  return res
})

let templatesCache = {}

function getIconAttachments(slotTemplates, isIgnore = false) {
  let iconAttachments = []
  foreach (slotId, tmpl in slotTemplates) {
    if (tmpl == "" || (isIgnore && slotId in ignoreIconSlots))
      continue

    let templ = DB.getTemplateByName(tmpl)
    if (templ == null) {
      if (DB.size() != 0)
        logerr($"Not found look template for /*{tmpl}*/ at /*{slotId}*/ slot")
      continue
    }

    let aParams = getAttachmentParams(tmpl)
    let objTexReplace = getTexReplaceString(aParams)
    let objTexSet = getTexSetString(aParams)
    let camouflage = getCamouflageString(aParams?.camouflage)

    iconAttachments.append({
      animchar = templ.getCompValNullable("animchar__res") ?? ""
      slot = slotId
      active = templ.getCompValNullable("isActivated") ?? ""
      objTexReplaceRules = "objTexReplaceRules{{0} r1{{1}}}".subst(objTexReplace, "")
      objTexSetRules = "objTexSetRules{{0}} ".subst(objTexSet)
      camouflage = camouflage ? "camouflage_override{{0}}".subst(camouflage) : ""
    })
  }
  return iconAttachments
}

function getHasArmor(gametemplate, slotTemplates) {
  if (gametemplate == "")
    return false

  let itemTemplate = DB.getTemplateByName(gametemplate)
  if (0 < (itemTemplate?.getCompValNullable("item__armorAmount") ?? 0.0))
    return true

  foreach (tpl in slotTemplates) {
    let attachTemplate = DB.getTemplateByName(tpl)
    if (0 < (attachTemplate?.getCompValNullable("item__armorAmount") ?? 0.0))
      return true
  }

  return false
}

function getIconDataFromTemplate(itemTemplates, armyId, lookItem, isIgnore = false) {
  local iconData = templatesCache?[lookItem]
  if (iconData)
    return iconData

  let { gametemplate = "", slotTemplates = {} } = findItemTemplate(itemTemplates, armyId, lookItem)
  iconData = {
    gametemplate
    iconAttachments = getIconAttachments(slotTemplates, isIgnore)
    hasArmor = getHasArmor(gametemplate, slotTemplates)
  }
  templatesCache[lookItem] <- iconData
  return iconData
}

let lookCustomizationParts = [
  {
    locId = "appearance/helmet"
    slotName = "helmet"
  },
  {
    locId = "appearance/head"
    slotName = "head"
  },
  {
    locId = "appearance/tunic"
    slotName = "tunic"
  },
  {
    locId = "appearance/gloves"
    slotName = "gloves"
  },
  {
    locId = "appearance/pants"
    slotName = "pants"
  }]

let availableCItem = Computed(function() {
  let res = []
  let { armyId = null, guid = null, isHero = false } = customizedSoldierInfo.get()
  if (armyId == null || guid == null)
    return res

  let curSoldierItems = (clone soldiersLook.get()?[guid].items) ?? {}
  foreach (item in equippedOutfitsForArmy.get())
    if (isLinkedTo(item, guid) && isObjAvailableForCampaign(item, campaignOutfit.get())) {
      let slot = item.links[guid]
      curSoldierItems[slot] <- item.basetpl
    }
  curSoldierItems.__update(customizationToApply.get())

  let blockedSlots = isHero ? blockedHeroSlots : {}
  let itemScheme = customizeScheme.get()
  let itemTemplatesVal = allItemTemplates.get()
  foreach (part in lookCustomizationParts) {
    let { slotName } = part
    if (itemScheme?[slotName] == null
        || itemScheme[slotName].len() == 1
        || slotName in blockedSlots)
      continue

    let item = curSoldierItems?[slotName]
    let iconData = getIconDataFromTemplate(itemTemplatesVal, armyId, item)
    res.append({ item }.__update(part, iconData))
  }
  return res
})

let oldSoldiersLook = Computed(function() {
  let res = {}
  let { armyId = null, guid = null } = customizedSoldierInfo.get()
  if (armyId == null || guid == null)
    return res

  let itemScheme = customizeScheme.get()
  let curSoldierItems = clone soldiersLook.get()?[guid].items
  foreach (item in equippedOutfitsForArmy.get())
    if (isLinkedTo(item, guid) && isObjAvailableForCampaign(item, campaignOutfit.get())) {
      let slot = item.links[guid]
      curSoldierItems[slot] <- item.basetpl
    }

  foreach (part in lookCustomizationParts) {
    let { slotName } = part
    if (itemScheme?[slotName] == null || itemScheme[slotName].len() == 1)
      continue

    res[slotName] <- curSoldierItems?[slotName] ?? ""
  }

  return res
})

oldSoldiersLook.subscribe(@(v) curCustomizationItem.set(v?[currentItemPart.get()]))

let isItemInScheme = @(scheme, slot, item) (scheme?[slot] ?? []).contains(item)
let customizedSoldierLook = Computed(@() oldSoldiersLook.get()
  .__merge(customizationToApply.get())
  .filter(@(item, slot)
    !ignoreForMultiPurchase(slot)
      && isItemInScheme(customizeScheme.get(), slot, item)
      && item in (schemeItemsPrice.get() ?? {})))

let itemsForSquad = Computed(function() {
  let { armyId = null } = customizedSoldierInfo.get()
  if (armyId == null || customizedSoldierLook.get().len() == 0)
    return {}

  let neededItems = {}
  let soldierGuids = {}
  let allowedLook = customizedSoldierLook.get().filter(@(item) !ignoreForMultiPurchase(item))
  let dropsCfg = soldiersDropCfg.get()
  foreach (soldier in curSquadSoldiersInfo.get()) {
    if (isSoldierLocked(soldier, dropsCfg))
      continue

    let sGuid = soldier.guid
    let { items = {} } = soldiersLook.get()?[sGuid]
    foreach (slotId, newItem in allowedLook) {
      if (items?[slotId] != newItem
          && isItemInScheme(customizeScheme.get(), slotId, newItem)
          && !isSlotLocked(soldier, slotId, dropsCfg))
        increment(neededItems, newItem)
    }
    soldierGuids[sGuid] <- true
  }

  foreach (outfit in equippedOutfitsForArmy.get())
    if (isLinkedTo(outfit, campaignOutfit.get())
        && isObjLinkedToAnyOfObjects(outfit, soldierGuids))
      decrement(neededItems, outfit.basetpl)

  return neededItems
})

let buyItemsSquad = Computed(function() {
  let res = {}
  let inventoryItems = freeItemsBySquad.get()
  foreach(item, count in itemsForSquad.get()) {
    let buyItems = count - (inventoryItems?[item] ?? 0)
    if (buyItems > 0)
      res[item] <- buyItems
  }
  return res
})

let createItemsPerSlotWatch = @() Computed(function() {
  let { guid = null } = customizedSoldierInfo.get()
  let items = soldiersLook.get()?[guid].items
  if (items == null)
    return []

  if (customizedSoldierLocked.get())
    return []

  let curItemPart = currentItemPart.get()
  if (curItemPart == "")
    return []

  if (isSlotLocked(customizedSoldierInfo.get(), curItemPart, soldiersDropCfg.get()))
    return []

  let defaultItem = items?[curItemPart] ?? ""
  local res = clone (customizeScheme.get()?[curItemPart] ?? [])
  let curPrice = curSoldierItemsPrice.get()
  let freeItems = freeItemsForSoldier.get()

  res = res
    .filter(function(val) {
      if (defaultItem == val) 
        return false
      if (val in freeItems)
        return true
      return val in curPrice
    })
    .sort(@(a,b) b in freeItems <=> a in freeItems
      || (curPrice?[a].len() ?? 0) > 0 <=> (curPrice?[b].len() ?? 0) > 0)

  if (res.len() > 0) 
    res.insert(0, defaultItem)

  return res
})

let itemsDisplayData = Computed(function() {
  let { armyId = null } = customizedSoldierInfo.get()
  let itemTemplatesVal = allItemTemplates.get()
  let result = customizeScheme.get().reduce(function(res, itemsBySlots, itemSlot) {
    itemsBySlots.each(function(itemId) {
      if (itemId == "")
        return
      let iconData = getIconDataFromTemplate(itemTemplatesVal, armyId, itemId)
      res[itemId] <- iconData.__update({ itemSlot, itemId })
    })
    return res
  }, {})
  return result
})


function closeCustomizationWnd() {
  currentItemPart.set("")
  curCustomizationItem.set(null)
  customizationToApply.set({})
  isCustomizationWndOpened.set(false)
}

function getAvailableItem(possibleItems, soldierGuid,
    slot, itemTpl = "", usedGuids = {}) {
  local alreadyEquipped = false
  local candidateItem = null
  
  
  foreach(item in possibleItems) {
    if (itemTpl != "" && item.basetpl != itemTpl)
      continue

    let sGuid = getFirstLinkByType(item, slot)
    if (sGuid == soldierGuid) {
      alreadyEquipped = true
      candidateItem = item
      break
    }
    if (candidateItem != null)
      continue
    if (sGuid == null && item.guid not in usedGuids) {
      candidateItem = item
    }
  }

  return { alreadyEquipped, itemGuid = candidateItem?.guid ?? "" }
}


function saveOutfit(needCloseWnd = true, calleeCb = null) {
  let { guid = null } = customizedSoldierInfo.get()
  let applyItems = customizationToApply.get()
  let oldLook = oldSoldiersLook.get()
  if ( guid == null
      || applyItems.findindex(@(item, slot) item != oldLook?[slot]) == null) {
    if (needCloseWnd)
      closeCustomizationWnd()
    customizationToApply.set({})
    return true
  }

  if (itemsToBuy.get().len() > 0) {
    let self = calleeCb ?? callee()
    showMsgbox({
      text = needCloseWnd ? loc("msg/leaveAppearanceConfirm") : loc("msg/cancelOutfitChanges")
      buttons = [
        { text = needCloseWnd ? loc("Yes") : loc("Ok"),
          action = function() {
            customizationToApply.set({})
            self()
          },
          isCurrent = true }
        { text = loc("Cancel"), isCancel = true, customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] } }
      ]
    })
    return false
  }

  let prem = {}
  let premList = freeOutfitsForArmy.get() ?? []
  foreach (slot, outfitTmpl in applyItems) {
    if (outfitTmpl == "")
      prem[slot] <- ""
    else {
      let { itemGuid, alreadyEquipped } = getAvailableItem(premList, guid, slot, outfitTmpl)
      if (!alreadyEquipped)
        prem[slot] <- itemGuid
    }
  }

  change_outfit(guid, {}, prem, campaignOutfit.get())
  if (needCloseWnd)
    closeCustomizationWnd()
  return true
}

function blockOnClick(slotName) {
  currentItemPart.set(slotName)
  isCustomizationWndOpened.set(true)
}

function itemBlockOnClick(item) {
  if (item == "") {
    curCustomizationItem.set("")
    customizationToApply.mutate(@(v) v[currentItemPart.get()] <- "")
    return
  }
  curCustomizationItem.set(item)
  customizationToApply.mutate(@(v) v[currentItemPart.get()] <- item)
}

function collectItemsBySoldierGuids(soldiersVal,
    configsVal, equippedOutfitsForArmyVal, campaignOutfitVal) {
  
  let outfitItemGuids = {}
  let soldierGuids = {}
  foreach (soldier in soldiersVal) {
    if (isSoldierLocked(soldier, configsVal))
      continue
    soldierGuids[soldier.guid] <- true
  }

  if (soldierGuids.len() == 0)
    return outfitItemGuids

  foreach (outfit in equippedOutfitsForArmyVal)
    if (isLinkedTo(outfit, campaignOutfitVal)) {
      let soldierGuid = getFirstLinkedObjectGuid(outfit, soldierGuids)
      if (soldierGuid == "")
        continue
      let soldierOutfit = outfitItemGuids?[soldierGuid] ?? {}
      let slot = outfit.links[soldierGuid]
      soldierOutfit[slot] <- outfit.basetpl
      outfitItemGuids[soldierGuid] <- soldierOutfit
    }
  return outfitItemGuids
}

let mkOutfitRequestData = @(items, filterByTpl = null)
  items.reduce(function(res, slots, guid) {
    let filteredItems = filterByTpl == null ? slots : slots.filter(@(v) v in filterByTpl)
    res[guid] <- { premium = filteredItems.map(@(_) "") }
    return res
  }, {})


let curOutfitBundles = Computed(function() {
  let { armyId = null, squadId = null } = customizedSoldierInfo.get()
  if (armyId == null )
    return []

  let squadConfig = squadsCfgById.get()
  let outfitSchemesVal = outfitSchemes.get()

  return (outfitBundles.get()?[armyId] ?? {})
    .filter(function(v) {
      let { campaigns = [], isHidden = false } = v
      if (isHidden)
        return false

      foreach (campaign in campaigns) {
        let scheme = getCustomizeScheme(squadConfig, outfitSchemesVal, armyId, squadId, campaign)
        foreach (suit in v?.suits ?? []) {
          if (null != suit.findvalue(@(item, slot) !isItemInScheme(scheme, slot, item)))
            return false
        }
      }
      return true
    })
    .map(@(bundle, id)
      {
        id
        bundle
        presentation = bundlesPresentation?[id]
      })
    .values()
})


console_register_command(function() {
  let { armyId = null, squadId = null } = customizedSoldierInfo.get()

  let squadConfig = squadsCfgById.get()
  let outfitSchemesVal = outfitSchemes.get()

  foreach (id, bundle in outfitBundles.get()?[armyId] ?? {}) {
    let { suits = [] } = bundle
    if (suits.len() == 0)
      log($"{id}: empty suits")

    let { campaigns = [] } = bundle
    let errorSlots = {}
    foreach (campaign in campaigns) {
      let scheme = getCustomizeScheme(squadConfig, outfitSchemesVal, armyId, squadId, campaign)
      foreach (suit in suits)
        foreach (slot, item in suit) {
          if (!isItemInScheme(scheme, slot, item)) {
            if (campaign not in errorSlots)
              errorSlots[campaign] <- {}
            errorSlots[campaign][item] <- slot
          }
        }
    }

    foreach (campaign, errors in errorSlots) {
      log($"{id}: {campaign} invalid for {squadId}")
      foreach (item, slot in errors)
        log($"\t{item}: {slot}")
    }
  }
  log("Validate complete.")
}, "outfit.validateBundles")

console_register_command(function() {
  if (customizedSoldierInfo.get() == null) {
    console_print("Please select soldier for customization")
    return
  }

  let { guid, armyId } = customizedSoldierInfo.get()
  let premList = freeOutfitsForArmy.get() ?? []
  let outfitTypes = outfitShopTypes.get()
  let free = {}
  let prem = {}
  let itemTemplatesVal = allItemTemplates.get()
  foreach (slotId, list in customizeScheme.get()) {
    let freeAvail = []
    let premAvail = []
    foreach (outfitTmpl in list) {
      if (outfitTmpl == "")
        freeAvail.append(outfitTmpl)
      else {
        let prems = premList
          .filter(@(outfit) outfit.basetpl == outfitTmpl)
          .map(@(outfit) outfit.guid)
        if (prems.len() > 0)
          premAvail.extend(prems)
        else {
          let { itemsubtype = "" } = findItemTemplate(itemTemplatesVal, armyId, outfitTmpl)
          if (itemsubtype not in outfitTypes)
            freeAvail.append(outfitTmpl)
        }
      }
    }
    if (freeAvail.len() > 0)
      free[slotId] <- freeAvail[rand.rint(0, freeAvail.len() - 1)]
    if (premAvail.len() > 0)
      prem[slotId] <- premAvail[rand.rint(0, premAvail.len() - 1)]
  }
  change_outfit(guid, free, prem, campaignOutfit.get(), console_print)
}, "outfit.applyRandom")

return {
  ignoreForMultiPurchase
  isSoldierLocked
  isSlotLocked
  soldiersDropCfg
  customizedSoldierLocked
  isCustomizationWndOpened
  closeCustomizationWnd
  availableCItem
  currentItemPart
  createItemsPerSlotWatch
  curCustomizationItem
  blockOnClick
  itemBlockOnClick

  saveOutfit
  getAvailableItem

  customizedSoldierInfo
  customizationToApply
  oldSoldiersLook
  customizedSoldierLook
  itemsForSquad
  buyItemsSquad
  itemsDisplayData
  toDisplayData = @(displayData, itemsList)
    itemsList.map(@(itemId) displayData?[itemId])
  getIconDataFromTemplate

  itemsToBuy
  customizeScheme
  campaignOutfit
  freeItemsForSoldier
  premiumItemsCount
  schemeItemsPrice
  curSoldierItemsPrice

  curOutfitBundles

  collectItemsBySoldierGuids
  mkOutfitRequestData
}
