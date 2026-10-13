from "%ui/currency/purchaseMsgBox.nut" import setOpenShopFunctions
from "%ui/shop/armyShopState.nut" import buyCurrency
from "%ui/currency/currencies.nut" import currenciesList
from "%ui/ui_library.nut" import *

function initActions() {
  let actions = {}
  foreach (currency in currenciesList.get()) {
    let c = currency
    let { id, purchaseUrl = "" } = c
    if (purchaseUrl != "")
      actions[id] <- @() buyCurrency(c)
  }
  setOpenShopFunctions(actions)
}

initActions()
currenciesList.subscribe(@(_) initActions())