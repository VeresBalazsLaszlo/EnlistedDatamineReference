import "%gdkLib/impl/app.nut" as app
import "%gdkLib/impl/store.nut" as store
import "%enlSqGlob/userInfo.nut" as userInfo
from "%ui/gdk/login.nut" import xbox_login
from "%ui/meta/clientApi.nut" import check_purchases
from "%ui/state/appState.nut" import isInBattleState
from "%ui/ui_library.nut" import *
from "auth" import YU2_OK

let logXbox = with_prefix("[XBOX STORE]")


app.register_unconstrain_callback(function() {
  logXbox($"updatePurchases: is logged in: {userInfo.get() != null}, isInBattleState: {isInBattleState.get()}")
  if (userInfo.get() == null || isInBattleState.get())
    return

  xbox_login(function(status, _) {
    let isSuccess = status == YU2_OK
    logXbox($"Update purchases: is success: {isSuccess}, is logged in {userInfo.get() != null}")
    if (!isSuccess || userInfo.get() == null)
      return

    logXbox("Update purchases after request")
    check_purchases()
  })
})


function show_marketplace(productKind) {
  logXbox($"show_marketplace({productKind})")
  store.show_marketplace(productKind, function(success) {
    logXbox($"show_marketplace succeeded: {success}")
  })
}

function show_details(productId) {
  logXbox($"show_details({productId})")
  store.show_details(productId, function(success) {
    logXbox($"show_details succeeded: {success}")
  })
}

function show_purchase(productId) {
  logXbox($"show_purchase({productId})")
  store.show_purchase(productId, function(success) {
    logXbox($"show_purchase succeeded: {success}")
  })
}

return {
  PKNone = store.ProductKind.None
  PKConsumable = store.ProductKind.Consumable
  PKDurable = store.ProductKind.Durable
  PKGame = store.ProductKind.Game
  PKPass = store.ProductKind.Pass
  PKUnmanagedConsumable = store.ProductKind.UnmanagedConsumable

  show_marketplace
  show_details
  show_purchase
}