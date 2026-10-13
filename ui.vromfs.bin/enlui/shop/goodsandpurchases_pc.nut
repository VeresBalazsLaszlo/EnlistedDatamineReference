import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/shop/httpRequest.nut" import requestData, createGuidsRequestParams
from "%ui/networkedUrls.nut" import getShopApiUrl
from "%ui/ui_library.nut" import *

let purchases = require("%ui/shop/purchases.nut")

const SHOP_API_URL = "https://api.gaijinent.com/item_info.php"

let goodsInfo = mkWatched(persist, "goodsInfo", {}) 

let isGoodsRequested = Watched(false)
let marketIds = Watched([])

async function requestGoodsInfo() {
  if (!userInfo.get())
    return

  let guids = marketIds.get().filter(@(guid) guid not in goodsInfo.get())
  if (guids.len() == 0)
    return

  let shopApiUrl = getShopApiUrl() ?? SHOP_API_URL
  if (shopApiUrl == "") {
    
    log("Empty shop API URL skipping goods request")
    return
  }

  log($"Requesting shop API for goods {shopApiUrl}")
  goodsInfo.mutate(function(v) {
    foreach (guid in guids)
      v[guid] <- null
  })

  isGoodsRequested.set(true)
  let data = await requestData(shopApiUrl, createGuidsRequestParams(guids))
  isGoodsRequested.set(false)
  let list = data?.items
  if (typeof list != "table" || !list.len())
    return
  goodsInfo.mutate(@(value) value.__update(list))
}

userInfo.subscribe(@(_) requestGoodsInfo())
marketIds.subscribe(function(guids) {
  purchases.addGuids(guids)
  requestGoodsInfo()
})

return purchases.__merge({
  goodsInfo
  marketIds
  isGoodsRequested
})