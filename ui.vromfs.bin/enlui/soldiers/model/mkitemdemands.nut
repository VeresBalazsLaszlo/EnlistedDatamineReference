from "%ui/soldiers/model/state.nut" import curArmyData, curArmy
from "%ui/shop/shopPkg.nut" import getCantBuyData
from "%ui/growth/growthState.nut" import curGrowthState, curGrowthConfig, curGrowthProgress, curGrowthTiers
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/shop/armyShopState.nut" import getShopItems, curArmyItemsPrefiltered, itemToShopItem
from "%ui/ui_library.nut" import *

let shopDemand = {
  order = 500
  lockTxt = loc("itemDemandsHeader/canObtainInShop_yes")
  canObtainInShop = true
}


function mkItemListDemands(items) {
  if (typeof items != "array")
    items = [items]
  return Computed(function() {
    return items.map(function(item) {
      if (item?.isShopItem) {
        let shopItems = getShopItems(item?.basetpl, curArmy.get(), itemToShopItem.get(),
          allItemTemplates.get(), curArmyItemsPrefiltered.get())
        let shopItem = shopItems?[0]
        let demands = getCantBuyData(curArmyData.get(),
          shopItem?.requirements,
          curGrowthState.get(),
          curGrowthConfig.get(),
          curGrowthProgress.get(),
          curGrowthTiers.get(),
          allItemTemplates.get())
        return {
          item
          demands = demands ?? shopDemand
        }
      }

      return { item }
    })
  })
}

function mkItemDemands(item) {
  let demands = mkItemListDemands(item)
  return Computed(@() demands.get()?[0].demands)
}

return {
  mkItemDemands
  mkItemListDemands
}