from "%ui/currency/currencies.nut" import currenciesBalance, currenciesSorted
from "%ui/shop/armyShopState.nut" import buyCurrency
from "%ui/style/designConst.nut" import defTxtColor, activeTxtColor, gap
from "%ui/currency/currenciesComp.nut" import mkCurrency, mkCurrencyTooltip
from "%ui/style/cursors.nut" import setTooltip
from "%dngscripts/platform.nut" import is_pc
from "%ui/ui_library.nut" import *

function currencyBalance(currency) {
  let stateFlags = Watched(0)
  return @() {
    watch = [currenciesBalance, stateFlags]
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags.set(sf)
    disableInput = is_pc && (currency?.purchaseUrl ?? "") == ""
    onClick = @() buyCurrency(currency)
    onHover = @(on) setTooltip(on ? mkCurrencyTooltip(currency) : null)

    children = mkCurrency({
      currency
      price = currenciesBalance.get()?[currency.id]
      txtStyle = { color = stateFlags.get() & S_HOVER ? activeTxtColor : defTxtColor }
      iconSize = hdpxi(30)
    })
  }
}

function currenciesWidget() {
  let visibleCurrencies = currenciesSorted.get().filter(@(currency) currency?.visible.get() ?? true)
  return {
    key = "currenciesWidget"
    watch = currenciesSorted
    flow = FLOW_HORIZONTAL
    gap = gap
    children = visibleCurrencies.map(currencyBalance)
  }
}

return currenciesWidget
