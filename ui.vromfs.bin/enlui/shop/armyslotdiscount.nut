from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/currency/bonuses.nut" import bonusesList
from "%ui/shop/armyShopState.nut" import isAvailableByLimit
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/meta/servProfile.nut" import purchasesCount
from "%ui/ui_library.nut" import *

let hasSquadsEffects = @(armyEffects) (armyEffects?.maxSquadsInBattle ?? 0) > 0
  || (armyEffects?.maxInfantrySquads ?? 0) > 0
  || (armyEffects?.maxBikeSquads ?? 0) > 0
  || (armyEffects?.maxVehicleSquads ?? 0) > 0
  || (armyEffects?.maxTransportSquads ?? 0) > 0

let sellingBonusData = Computed(function() {
  let bonusId = bonusesList.get().findindex(@(bonus)
    bonus.armies.contains(curArmy.get()) && hasSquadsEffects(bonus.armyEffects))
  if (bonusId == null)
    return null

  let res = shopItems.get().findvalue(@(shopItem)
    (shopItem?.bonusId ?? "") == bonusId)
  return isAvailableByLimit(res, purchasesCount.get()) ? res : null
})

let armySlotItem = Computed(@() shopItems.get()?[sellingBonusData.get()?.guid])

let armySlotDiscount = Computed(@() armySlotItem.get()?.discountInPercent ?? 0)

return {
  hasSquadsEffects
  armySlotDiscount
  armySlotItem
}
