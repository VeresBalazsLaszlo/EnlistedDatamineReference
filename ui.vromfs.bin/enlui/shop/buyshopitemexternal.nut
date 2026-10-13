import "%ui/shop/checkPurchases.nut" as checkPurchases
from "%ui/consoleStore/consoleStore.nut" import openBundle, openBundles
from "%enlSqGlob/appInfo.nut" import isProductionCircuit
from "%ui/shop/shopUrls.nut" import getShopUrl, getUrlByGuid
from "%ui/shop/armyShopState.nut" import openPurchaseUrl, HAS_PC_STORE

function buyByGuid(guid) {
  let url = getUrlByGuid(guid) ?? getShopUrl()
  if (url == null)
    return false

  openPurchaseUrl(url)
  return true
}

let buyItemByGuid = !HAS_PC_STORE ? function(_) {
      openBundles()
      checkPurchases()
      return true
    }
  : buyByGuid

function buyItemByStoreId(storeId) {
  if (HAS_PC_STORE)
    buyByGuid(storeId)
  else
    openBundle(storeId)
  checkPurchases()
}

function canPurchaseExternal(shopItem) {
  let { devStoreId = null, storeId = null, purchaseGuid = null } = shopItem
  return null != (devStoreId ?? storeId ?? purchaseGuid)
}

function openPurchaseLink(shopItem) {
  
  if (!isProductionCircuit.get()) {
    let { devStoreId = "" } = shopItem
    if (devStoreId != "") {
      buyItemByStoreId(devStoreId)
      return true
    }
  }

  let { storeId = "" } = shopItem
  if (storeId != "") {
    buyItemByStoreId(storeId)
    return true
  }

  
  let { purchaseGuid = "" } = shopItem
  if (purchaseGuid != "")
    if (buyItemByGuid(purchaseGuid)) {
      return true
    }

  return false
}

return {
  canPurchaseExternal
  openPurchaseLink
}
