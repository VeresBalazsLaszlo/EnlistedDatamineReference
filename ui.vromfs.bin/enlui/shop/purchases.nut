import "%enlSqGlob/userInfo.nut" as userInfo
from "app" import get_circuit_conf
from "%ui/ui_library.nut" import *

let httpRequest = require("%ui/shop/httpRequest.nut")

let purchased = Watched({})

let { checkPurchasesUrl = "https://purch.gaijinent.com/check_purchase.php" } = get_circuit_conf()

async function refreshPurchased() {
  if (purchased.get().len() == 0 || !userInfo.get())
    return

  let data = await httpRequest.requestData(checkPurchasesUrl,
    httpRequest.createGuidsRequestParams(purchased.get().keys()))
  if (data == null)
    return

  let purchasedUpdate = {}
  foreach (guid, amount in data?.items ?? {})
    purchasedUpdate[guid] <- amount
  if (null != purchasedUpdate.findvalue(@(amount, guid) purchased.get()?[guid] != amount))
    purchased.mutate(@(v) v.__update(purchasedUpdate))
}

function addGuids(guids) {
  let update = {}
  foreach (guid in guids)
    if (guid not in purchased.get())
      update[guid] <- 0
  if (update.len() > 0) {
    purchased.mutate(@(v) v.__update(update))
    refreshPurchased()
  }
}

userInfo.subscribe(function(val) {
  if (val)
    refreshPurchased()
  else
    purchased.set({})
})

return {
  purchased
  addGuids
  refreshPurchased
}