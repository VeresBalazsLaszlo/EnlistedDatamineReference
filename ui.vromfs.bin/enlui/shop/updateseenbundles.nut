import "%ui/userstats/serverTime.nut" as serverTime
from "%ui/unlocks/unseenUnlocksState.nut" import hasNewbieUnlocksData
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/shop/unseenShopItems.nut" import markShopItemSeen
from "%ui/shop/armyShopState.nut" import curAvailableShopItems
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/ui_library.nut" import *

let markedAllBundlesSeenTime = mkOnlineSaveData("markedArmyBundlesSeenTime", @() {})

curAvailableShopItems.subscribe(function(items) {
  let armyId = curArmy.get()
  if (armyId == null)
    return

  if (!hasNewbieUnlocksData.get() && ((markedAllBundlesSeenTime.watch.get()?[armyId] ?? 0) == 0)) {
    
    
    let unseenGuids = items.filter(@(item)
      ((item?.shop_price ?? 0) > 0)
      || ((item?.curShopItemPrice.price ?? 0) > 0)
      || ((item?.curItemCost.len() ?? 0) > 0)
    ).map(@(item) item.guid)
    if (unseenGuids.len()) {
      let savedTime = markedAllBundlesSeenTime.watch.get()
      markedAllBundlesSeenTime.setValue(savedTime.__merge({[armyId] = serverTime.get()}))
      defer(@() markShopItemSeen(armyId, unseenGuids))
    }
  }
  else if (hasNewbieUnlocksData.get() && armyId) {
    let savedTime = markedAllBundlesSeenTime.watch.get()
    markedAllBundlesSeenTime.setValue(savedTime.__merge({[armyId] = serverTime.get()}))
  }
})

console_register_command(@() markedAllBundlesSeenTime.setValue({}), "meta.resetSeenBundlesTime")