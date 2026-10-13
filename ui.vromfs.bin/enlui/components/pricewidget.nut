from "%ui/shop/currencyPresentation.nut" import ticketGroups
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/currency/currencies.nut" import currenciesById
from "%ui/style/cursors.nut" import setTooltip
from "%ui/shop/currencyComp.nut" import mkCurrencyCardsTooltip
from "%ui/shop/numberUtils.nut" import abbreviateAmount
from "%ui/ui_library.nut" import *
from "types" import Integer

function priceWidget(price, currencyId) {
  let currency = currenciesById.get()?[currencyId]

  let tooltip = price instanceof Integer && (currencyId in ticketGroups)
    ? mkCurrencyCardsTooltip(currencyId,
        [{
          amount = price
          icon = ticketGroups[currencyId].icon
        }]
      )
    : null

  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onHover = tooltip
      ? @(on) setTooltip(on ? tooltip : null)
      : null
    children = [
      currency == null ? null : {
        size = hdpx(30)
        rendObj = ROBJ_IMAGE
        image = Picture(currency.image(hdpx(30)))
      }
      {
        rendObj = ROBJ_TEXT
        text = currency
          ? abbreviateAmount(price)
          : loc($"priceText/{currencyId}", { price }, $"{price}{currencyId}")
      }.__update(fontBody)
    ]
  }
}

return {
  priceWidget
}
