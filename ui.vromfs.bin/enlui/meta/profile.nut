from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/meta/curCampaign.nut" import curCampaignConfig
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "dagor.memtrace" import set_huge_alloc_threshold
from "%ui/ui_library.nut" import *

from "%ui/meta/servProfile.nut" import items, soldiers, squads, soldiersOutfit


let verify = @(list) list.filter(@(obj) obj?.hasVerified ?? true)

function updateObjects(objData, templates, overrides = null) {
  let all = {}
  let allByArmy = {}
  foreach (guid, obj in objData) {
    let armyId = getLinkedArmyName(obj)
    let tmpl = templates?[armyId][obj?.basetpl]
    let item = tmpl || overrides ? (tmpl ?? const {}).__merge(obj, overrides ?? const {}) : obj
    all[guid] <- item

    if (!armyId)
      continue

    if (armyId not in allByArmy)
      allByArmy[armyId] <- {}
    allByArmy[armyId][guid] <- item
  }
  return {
    all
    allByArmy
  }
}



let itemsCur = Computed(function() {
  let prevSize = set_huge_alloc_threshold(45 << 20)
  let result = updateObjects(items.get(), allItemTemplates.get())
  set_huge_alloc_threshold(prevSize)
  return result
})
let curCampItems = Computed(@() itemsCur.get().all)
let itemsByArmies = Computed(@() itemsCur.get().allByArmy)



let soldiersCur = Computed(@() updateObjects(verify(soldiers.get()), allItemTemplates.get()))
let curCampSoldiers = Computed(@() soldiersCur.get().all)
let soldiersByArmies = Computed(@() soldiersCur.get().allByArmy)



let outfitsByArmies = Computed(@() updateObjects(soldiersOutfit.get(),
  allItemTemplates.get(), const { isOutfitItem = true }).allByArmy)



let curCampSquads = Computed(@() verify(squads.get()))
let squadsByArmies = Computed(function() {
  let res = {}
  foreach (obj in curCampSquads.get()) {
    let armyId = getLinkedArmyName(obj)
    if (!armyId)
      continue

    local armyItems = res?[armyId]
    if (armyItems == null) {
      armyItems = {}
      res[armyId] <- armyItems
    }
    armyItems[obj.guid] <- obj
  }
  return res
})

let commonArmy = Computed(@() gameProfile.get()?.commonArmy)

let curArmiesList = Computed(@() (curCampaignConfig.get()?.armies ?? []).map(@(a) a.id))

let curArmiesListExt = Computed(function() {
  let armiesList = clone curArmiesList.get()
  let commonArmyId = commonArmy.get()
  if (commonArmyId != null)
    armiesList.append(commonArmyId)
  return armiesList
})

let campaignsByArmy = Computed(function() {
  let res = {}
  foreach (campaign in gameProfile.get()?.campaigns ?? {})
    foreach (army in campaign?.armies ?? [])
      res[army.id] <- campaign
  return res
})

let linkIgnore = { army = true, index = true }
function remapByLink(objList) {
  let res = {}
  foreach (obj in objList)
    foreach (to, linkType in obj.links)
      if (linkType not in linkIgnore) {
        if (to not in res)
          res[to] <- {}
        if (linkType not in res[to])
          res[to][linkType] <- []
        res[to][linkType].append(obj)
      }
  return res
}

let campItemsByLink = Computed(@() remapByLink(curCampItems.get()))

return {
  curArmiesList
  curArmiesListExt
  commonArmy
  itemsByArmies
  outfitsByArmies
  soldiersByArmies
  squadsByArmies
  curCampItems
  curCampSoldiers
  curCampSquads
  campItemsByLink
  campaignsByArmy
}
