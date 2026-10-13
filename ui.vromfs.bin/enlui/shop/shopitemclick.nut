import "%ui/shop/buySquadWindow.nut" as buySquadWindow
import "%ui/shop/buyShopItem.nut" as buyShopItem
import "%ui/shop/viewShopItemsScene.nut" as viewShopItemsScene
import "%ui/shop/hasLootRestriction.nut" as checkLootRestriction
import "%ui/shop/shopItemCompositeWindow.nut" as shopItemCompositeWindow
from "%ui/soldiers/model/state.nut" import curArmyData
from "%ui/shop/shopState.nut" import getCantBuyDataOnClick
from "%ui/shop/armyShopState.nut" import shopItemContentCtor, purchaseIsPossible, needGoodManage
from "%ui/shop/shopPkg.nut" import shopItemLockedMsgBox, mkProductView
from "%ui/shop/shopPackage.nut" import mkShopMsgBoxView, mkCanUseShopItemInfo, mkUseForCamouflage
from "%ui/shop/shopItems.nut" import shopItemsBase
from "%sqstd/underscore.nut" import deep_clone
from "%ui/meta/servProfile.nut" import purchasesCount
from "%ui/ui_library.nut" import *

let activatePremiumBtn = require("%ui/shop/activatePremiumBtn.nut")



function addIncludesShopItems(shopItem) {
  if ((shopItem?.includes.len() ?? 0) == 0)
    return shopItem

  let res = deep_clone(shopItem)
  let allShopItems = shopItemsBase.get()
  let purchases = purchasesCount.get()
  local { squads = [], decorators = [], premiumDays = 0, announcements = [] } = res
  foreach (guid in (res?.includes ?? [])) {
    let includesShopItem = allShopItems?[guid]
    if ((purchases?[guid].amount ?? 0) > 0)
      continue

    foreach (squadData in (includesShopItem?.squads ?? []))
      squads.append(squadData)
    foreach (decoratorData in (includesShopItem?.decorators ?? []))
      decorators.append(decoratorData)

    premiumDays += (includesShopItem?.premiumDays ?? 0)
    foreach (announcement in (includesShopItem?.announcements ?? [])) {
      let idx = announcements.findindex(@(a) a.announcementId == announcement.announcementId)
      if (idx == null)
        announcements.append(announcement)
      else
        announcements[idx].count += announcement.count
    }
  }

  res.squads <- squads
  res.decorators <- decorators
  res.announcements <- announcements
  res.premiumDays <- premiumDays
  return res
}


function isShopItemComposite(shopItem) {
  let { squads = [], decorators = [] } = shopItem
  return squads.len() > 1 || (squads.len() > 0 && decorators.len() > 0)
}


function shopItemClick(shopItem) {
  let lockData = getCantBuyDataOnClick(shopItem)
  if (lockData != null)
    return shopItemLockedMsgBox(lockData)
  if (!purchaseIsPossible.get())
    return

  let { guid = "" } = curArmyData.get()
  let { curShopItemPrice = null, squads = [] } = shopItem

  let sItemFinal = addIncludesShopItems(shopItem)
  if (isShopItemComposite(sItemFinal)) {
    shopItemCompositeWindow(sItemFinal)
    return
  }

  let countWatched = Watched(1)
  let crateContent = shopItemContentCtor(shopItem)
  let hasItemContent = crateContent == null ? false
    : (crateContent.get()?.content.items.len() ?? 0) > 0

  let isBuyingWithGold = curShopItemPrice?.currencyId == "EnlistedGold"
  let squad = squads.findvalue(@(s) s.armyId == guid) ?? squads?[0]
  if (squad != null && isBuyingWithGold) {
    buySquadWindow({
      shopItem = shopItem
      armyId = squad.armyId
      squadId = squad.id
    })
    return
  }

  let description = hasItemContent
    ? mkCanUseShopItemInfo(crateContent)
    : mkUseForCamouflage(shopItem)

  let productView = mkShopMsgBoxView(shopItem, crateContent, countWatched)
  let itemView = mkProductView(shopItem, crateContent)
  function buyItemActionCb() {
    buyShopItem({
      shopItem = shopItem
      activatePremiumBtn
      productView = productView ?? itemView
      description
      viewBtnCb = hasItemContent ? @() viewShopItemsScene(shopItem) : null
      countWatched
      needCheckAndBuy = true
    })
    needGoodManage.set(true)
  }
  checkLootRestriction(buyItemActionCb, { itemView, description }, crateContent)
}

return {
  shopItemClick
  isShopItemComposite
}
