import "%enlSqGlob/userInfo.nut" as userInfo
import "sony.store" as psnStore
import "auth.psn" as auth_psn
from "%dngscripts/platform.nut" import is_ps4
from "dng.sony" import get_auth_data_async
from "%ui/meta/clientApi.nut" import check_purchases
from "eventbus" import eventbus_subscribe, eventbus_subscribe_onehit
from "%ui/state/appState.nut" import isInBattleState
from "%ui/ui_library.nut" import *

let logPSN = with_prefix("[PSN STORE]")


let ENLISTED_SERVICE_LABEL = is_ps4 ? 0 : 1
const AUTH_DATA_SUB_ID = "sony.auth_data_store"

let updateCb = @(_status) check_purchases()
eventbus_subscribe("psn_update_purchases_on_store_return", updateCb)

function updatePurchases() {
  logPSN($"updatePurchases: is in battle: {isInBattleState.get()}, is logged in: {userInfo.get() != null}")
  if (userInfo.get() == null || isInBattleState.get())
    return

  eventbus_subscribe_onehit(AUTH_DATA_SUB_ID, function(auth_data) {
    if (!auth_data.error && userInfo.get() != null) {
      logPSN("Update purchases after request")
      auth_psn.login_psn(auth_data, "psn_update_purchases_on_store_return")
    }
  })

  get_auth_data_async(AUTH_DATA_SUB_ID)
}

eventbus_subscribe("psnStoreClosed", @(_) updatePurchases())

return {
  show_category = @(cat) psnStore.open_category(
    cat,
    ENLISTED_SERVICE_LABEL,
    "psnStoreClosed",
    {}
  )
  show_pack_by_id = @(id) psnStore.open_product(
    id,
    ENLISTED_SERVICE_LABEL,
    "psnStoreClosed",
    {}
  )
}