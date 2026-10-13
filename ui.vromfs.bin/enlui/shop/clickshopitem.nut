import "%ui/shop/buySquadWindow.nut" as buySquadWindow
import "%ui/shop/buyShopItem.nut" as buyShopItem
import "%ui/shop/viewShopItemsScene.nut" as viewShopItemsScene
import "%ui/shop/hasLootRestriction.nut" as checkLootRestriction
from "%ui/shop/armyShopState.nut" import shopItemContentCtor, curArmyShopFolder, purchaseIsPossible, setCurArmyShopPath
from "%ui/shop/shopPackage.nut" import mkShopMsgBoxView, mkCanUseShopItemInfo
from "%ui/shop/shopPkg.nut" import shopItemLockedMsgBox, mkProductView
from "%ui/shop/shopState.nut" import getCantBuyDataOnClick
from "%ui/soldiers/model/state.nut" import curArmyData
from "%ui/ui_library.nut" import *

let activatePremiumBtn = require("%ui/shop/activatePremiumBtn.nut")


function clickShopItem(shopItem, isNotSuitable = false) {
  let { guid = "" } = curArmyData.get()
  let { squads = [] } = shopItem
  let squad = squads.findvalue(@(s) s.armyId == guid) ?? squads?[0]
  let isBuyingWithGold = shopItem?.curShopItemPrice.currencyId == "EnlistedGold"
  let countWatched = Watched(1)
  let crateContent = shopItemContentCtor(shopItem)
  let isMinimalView = shopItem?.image == null
  let hasItemContent = crateContent == null || isMinimalView ? false
    : (crateContent.get()?.content.items.len() ?? 0) > 0

  let lockData = getCantBuyDataOnClick(shopItem)

  if ((shopItem?.offerContainer ?? "") != "")
    setCurArmyShopPath((clone curArmyShopFolder.get().path).append(shopItem))
  else if (lockData != null)
    shopItemLockedMsgBox(lockData)
  else if (purchaseIsPossible.get()) {
    let description = hasItemContent ? mkCanUseShopItemInfo(crateContent) : null
    if (squad != null && isBuyingWithGold)
      buySquadWindow({
        shopItem
        armyId = squad.armyId
        squadId = squad.id
      })
    else {
      let productView = isMinimalView ? null : mkShopMsgBoxView(shopItem, crateContent, countWatched)
      let buyItemAction = @() buyShopItem({
        shopItem
        activatePremiumBtn
        productView
        description
        viewBtnCb = hasItemContent ? @() viewShopItemsScene(shopItem) : null
        countWatched
        isNotSuitable
      })
      checkLootRestriction(buyItemAction,
        {
          itemView = mkProductView(shopItem, crateContent)
          description
        },
        crateContent)
    }
  }
}

return clickShopItem
