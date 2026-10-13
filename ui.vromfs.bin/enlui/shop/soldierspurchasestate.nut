from "%ui/shop/armyShopState.nut" import curArmyShopItems, curUnseenAvailShopGuids
from "%ui/components/soldierClasses.nut" import getClassCfg, getKindCfg, soldierClasses
from "%ui/ui_library.nut" import *

const SOLDIER_GROUP = "soldier_silver_group"
const BATTLE_PASS_SOLDIER_GROUP = "soldier_battlepass_group"
let isSoldiersPurchasing = Watched(false)


let soldierShopItems = Computed(@() curArmyShopItems.get().filter(@(s)
  (s?.offerGroup == SOLDIER_GROUP || s?.offerGroup == BATTLE_PASS_SOLDIER_GROUP)))

let unseenSoldierShopItems = Computed(function() {
  let guids = {}
  foreach (shopItem in soldierShopItems.get())
    if (shopItem.guid in curUnseenAvailShopGuids.get())
      guids[shopItem.guid] <- true
  return guids
})

function extractKinds(crateContent) {
  let classesList = crateContent?.content.soldierClasses ?? {}
  if (classesList.len() == 0)
    return []

  let res = {}
  foreach (sClass in classesList) {
    let { kind } = getClassCfg(sClass)
    res[kind] <- true
  }
  return res.keys()
}

function getKindsList(itemsContent) {
  let kinds = {}
  foreach (content in itemsContent) {
    let sKindList = extractKinds(content)
    if (sKindList.len() != 1)
      continue

    let [ soldierKind ] = sKindList
    if (soldierKind not in kinds) {
      let sKindData = {
        soldierKind
        title = loc(getKindCfg(soldierKind).locId)
      }
      kinds[soldierKind] <- sKindData
    }
  }

  let res = kinds.values()
  res.sort(@(a, b) a.title <=> b.title)
  return res
}

function getSoldiersList(cratesContent, sShopItems) {
  let kindsToShow = getKindsList(cratesContent)
  let soldiersToShow = sShopItems.reduce(function(res, content) {
    let soldierSpec = cratesContent.findvalue(@(crate)
      crate.shopItemId == content.id)?.content.soldierClasses[0]
    let soldierKind = soldierClasses?[soldierSpec].kind ?? ""
    res.append(content.__merge({ soldierSpec, soldierKind }))
    return res
  }, [])
    .sort(@(a, b) (b?.limit == 1) <=> (a?.limit == 1)
      || (soldierClasses?[a.soldierSpec].rank ?? 0) <=> (soldierClasses?[b.soldierSpec].rank ?? 0))

  return { kindsToShow, soldiersToShow }
}


return {
  soldierShopItems
  unseenSoldierShopItems
  getSoldiersList
  isSoldiersPurchasing
}
