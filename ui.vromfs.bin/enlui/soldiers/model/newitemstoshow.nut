import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
from "%ui/meta/clientApi.nut" import mark_seen_objects
from "%ui/meta/perks/perksSchemesConfig.nut" import soldierSchemes
from "%ui/soldiers/model/items_list_lib.nut" import prepareItems, preferenceSort
from "%ui/soldiers/model/state.nut" import curArmy, armies
from "%ui/meta/profile.nut" import itemsByArmies, soldiersByArmies, commonArmy,
  outfitsByArmies, campItemsByLink, curCampSquads
from "%ui/soldiers/model/soldierPerks.nut" import perksData
from "%ui/meta/servProfile.nut" import soldiersLook, decorators, notifiers, vehDecorators
from "%ui/soldiers/model/config/soldierTrainingConfig.nut" import maxTrainByClass
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/soldiers/model/collectSoldierData.nut" import collectSoldierDataImpl
from "%ui/vehicles/vehDecorState.nut" import vehCamouflageCfg
from "%ui/soldiers/model/boosters.nut" import allBoosters, curExpBonus, needBoosterCapWarning
from "%ui/profile/decoratorState.nut" import decoratorsCfgByType
from "%ui/components/wndManager.nut" import registerWnd, Wnd, WndEvents
from "%ui/components/wndPermissionFlags.nut" import canShowNewItems, autoClose
from "%ui/ui_library.nut" import *
from "%sqstd/rand.nut" import shuffle
from "%ui/currency/currencies.nut" import currenciesById
from "%ui/items/itemsPresentation.nut" import rewardsPresentation


enum NotifyStatus {
  NONE = "NONE"
  NEW = "NEW"
}


let justPurchasedItems = mkWatched(persist, "justPurchasedItems", [])


function getUnseenObjects(armyObjects, allNotifiers) {
  let res = {}
  foreach (guid, notifier in allNotifiers) {
    if (notifier.status != NotifyStatus.NEW)
      continue

    foreach (armyId, objects in armyObjects) {
      let object = objects?[guid]
      if (object == null)
        continue

      if (armyId not in res)
        res[armyId] <- {}

      res[armyId][guid] <- object
      break
    }
  }

  return res
}

let newItems = Computed(@() getUnseenObjects(itemsByArmies.get(), notifiers.get()))
let newSoldiers = Computed(@() getUnseenObjects(soldiersByArmies.get(), notifiers.get()))
let newOutfits = Computed(@() getUnseenObjects(outfitsByArmies.get(), notifiers.get()))

let newCurrency = Computed(function() {
  let res = {}
  foreach (guid, notifier in notifiers.get()) {
    if (notifier.status != NotifyStatus.NEW)
      continue

    let { amount = 0, id = "" } = notifier?.notify.currency
    if (amount <= 0)
      continue

    let currencyCfg = rewardsPresentation?[id]
    if (currencyCfg == null)
      continue

    res[guid] <- currencyCfg.__merge({
      guid
      currencyId = id
      count = amount
    })
  }
  return res
})

let newBoosters = Computed(function() {
  let commonArmyId = commonArmy.get()
  let allNotifiers = notifiers.get()
  let filterFunc = @(boosterObj) boosterObj.booster.guid in allNotifiers
  let res = {}
  foreach (guid, boosterObj in allBoosters.get())
    if (filterFunc(boosterObj))
      res[guid] <- {
        links = { [commonArmyId] = "army" }
        guid = boosterObj.booster.guid
        basetpl = boosterObj.booster.boosterId
        gametemplate = boosterObj.template.expMul < 0 ? "penalty_template" : "booster_template"
        itemtype = "booster"
      }.__update(boosterObj)
  return res
})

newBoosters.subscribe(function(v) {
  if (null != v.findvalue(@(b) b.booster.activeTs > 0))
    needBoosterCapWarning.set(true)
})

let needBoosterWarning = registerWnd({
  dataWatch = Computed(function() {
      let { maxBoostersBonus = 0 } = gameProfile.get()
      let boostersBonus = curExpBonus(allBoosters.get())
      return needBoosterCapWarning.get()
        && maxBoostersBonus > 0
        && newBoosters.get().findvalue(@(b) b.booster.activeTs == 0
          && b.template.expMul + boostersBonus > maxBoostersBonus) != null
    })
  showWatch = canShowNewItems
  closeWatch = autoClose
  name = Wnd.BOOSTER_CAP
  order = [Wnd.ITEMS]
  handlers = { [WndEvents.SUPPRESS] = @() needBoosterCapWarning.set(false) }
})

let boosterSort = @(a, b) a.booster.expireTs <=> b.booster.expireTs
  || (b?.template.expMul ?? 0) <=> (a?.template.expMul ?? 0)

let newItemsToShow = Computed(function() {
  let commonArmyId = commonArmy.get()
  let curArmyId = curArmy.get()

  let armyByGuid = {}
  let itemsObjects = {}
  foreach (armyId, armyItems in newItems.get()) {
    if (armyId != curArmyId && armyId != commonArmyId)
      foreach (guid, _ in armyItems)
        armyByGuid[guid] <- armyId

    itemsObjects.__update(armyItems)
  }
  let joinedItems = prepareItems(itemsObjects.keys(), itemsObjects, false)

  let perksDataVal = perksData.get()
  let curCampSquadsVal = curCampSquads.get()
  let armiesVal = armies.get()
  let sClassesCfgVal = sClassesCfg.get()
  let campItemsByLinkVal = campItemsByLink.get()
  let soldiersLookVal = soldiersLook.get()
  let soldierSchemesVal = soldierSchemes.get()
  let maxTrainByClassVal = maxTrainByClass.get()

  local soldiersObjects = {}
  foreach (armyId, armySoldiers in newSoldiers.get()) {
    if (armyId != curArmyId && armyId != commonArmyId)
      foreach (guid, _ in armySoldiers)
        armyByGuid[guid] <- armyId
    soldiersObjects.__update(armySoldiers)
  }
  soldiersObjects = soldiersObjects.map(@(soldier) collectSoldierDataImpl(
    soldier, perksDataVal, curCampSquadsVal, armiesVal,
    sClassesCfgVal, campItemsByLinkVal, soldiersLookVal,
    {} ,
    soldierSchemesVal, maxTrainByClassVal))

  let outfitsObjects = {}
  foreach (armyId, armyItems in newOutfits.get()) {
    if (armyId != curArmyId && armyId != commonArmyId)
      foreach (guid, _ in armyItems)
        armyByGuid[guid] <- armyId
    outfitsObjects.__update(armyItems)
  }
  let joinedOutfits = prepareItems(outfitsObjects.keys(), outfitsObjects, false)

  let allItems = [].extend(
    joinedItems.sort(preferenceSort),
    joinedOutfits,
    soldiersObjects.values().sort(preferenceSort),
    newBoosters.get().values().sort(boosterSort),
    newCurrency.get().values())

  return allItems.len() > 0
    ? {
        header = loc("battleRewardTitle")
        allItems
        itemsGuids = itemsObjects.keys()
        outfitsGuids = outfitsObjects.keys()
        soldiersGuids = soldiersObjects.keys()
        boostersGuids = newBoosters.get().keys()
        currencyGuids = newCurrency.get().keys()
        armyByGuid
      }
    : null
})


function uniteSimilarItems(items) {
  let res = []
  foreach (item in items) {
    if (item?.itemtype == "soldier") {
      res.append(item)
      continue
    }

    let unitedItem = "basetpl" in item ? res.findvalue(@(i) i?.basetpl == item.basetpl)
      : "currencyId" in item ? res.findvalue(@(i) i?.currencyId == item.currencyId)
      : null
    if (unitedItem == null)
      res.append(clone item)
    else
      unitedItem.count <- (unitedItem?.count ?? 1) + (item?.count ?? 1)
  }
  return res
}


let isMarkSeenInProgress = Watched(false) 
function markNewItemsSeen() {
  if (isMarkSeenInProgress.get() || newItemsToShow.get() == null)
    return

  let { itemsGuids, soldiersGuids, outfitsGuids, boostersGuids, currencyGuids
    } = newItemsToShow.get()
  isMarkSeenInProgress.set(true)

  let guids = [].extend(itemsGuids, soldiersGuids, outfitsGuids, boostersGuids, currencyGuids)
  mark_seen_objects(guids, @(_) isMarkSeenInProgress.set(false))
}

let needNewItemsWindow = registerWnd({
  dataWatch = Computed(@() newItemsToShow.get() != null && !isMarkSeenInProgress.get())
  showWatch = canShowNewItems
  closeWatch = autoClose
  name = Wnd.ITEMS,
  order = [Wnd.ROULETTE, Wnd.DAILY]
  handlers = { [WndEvents.SUPPRESS] = markNewItemsSeen }
})

let unseenReward = Computed(function() {
  let receivedItems = []
  let allVehDecors = vehDecorators.get()
  let allDecorators = decorators.get()
  let camouflageCfg = vehCamouflageCfg.get()
  let currenciesCfg = currenciesById.get()
  let { portrait = {}, nickFrame = {} } = decoratorsCfgByType.get()
  let curCampSquadsVal = curCampSquads.get()
  foreach (guid, notifier in notifiers.get()) {
    if (notifier.status != NotifyStatus.NEW)
      continue

    let vehDecor = allVehDecors?[guid]
    if (vehDecor) {
      receivedItems.append(vehDecor.__merge({ basetpl = vehDecor.id }))
      continue
    }

    let decor = allDecorators?[guid]
    if (decor) {
      let cfg = portrait?[guid] ?? nickFrame?[guid]
      if (cfg != null)
        receivedItems.append(decor.__merge({ basetpl = guid }, cfg))
      continue
    }

    let camoCfg = camouflageCfg.findvalue(@(cfg) guid in cfg)
    if (camoCfg) {
      receivedItems.append(camoCfg[guid].__merge({ basetpl = guid }))
      continue
    }

    let currency = currenciesCfg?[notifier?.notify.currency.id]
    if (currency) {
      receivedItems.append(currency.__merge(notifier))
      continue
    }

    let squad = curCampSquadsVal?[guid]
    if (squad) {
      receivedItems.append({ squadId = squad.squadId })
      continue
    }
  }

  let { allItems = [] } = newItemsToShow.get()
  receivedItems.extend(allItems.filter(@(item) "basetpl" in item))
  return shuffle(receivedItems)
})


return {
  needNewItemsWindow
  newItemsToShow
  needBoosterWarning
  uniteSimilarItems
  markNewItemsSeen
  justPurchasedItems
  unseenReward
  NotifyStatus
}
