import "%ui/currency/currenciesWidgetUi.nut" as currenciesWidgetUi
import "%ui/dropdownmenu/dropDownMainMenu.nut" as dropDownMainMenu
import "%ui/profile/profileButton.nut" as profileButton
import "%ui/premium/premiumButtonUi.nut" as premiumWidgetUi
from "%ui/shop/armyCurrencyUi.nut" import freeExpWithExchangeUi
from "%ui/style/designConst.nut" import largePadding, bigPadding, midPadding, sidePadding
from "%ui/ui_library.nut" import *
from "%ui/shop/armyCurrencyUi.nut" import currencyUi, currencySilverUi

let currenciesPanel = {
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  gap = midPadding
  children = [
    {
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        currenciesWidgetUi
        currencySilverUi
      ]
    },
    {
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        currencyUi
        freeExpWithExchangeUi
      ]
    }
  ]
}

let profileInfoBlock = freeze({
  flow = FLOW_HORIZONTAL
  gap = sidePadding
  margin = const [bigPadding, 0, 0, 0]
  hplace = ALIGN_RIGHT
  halign = ALIGN_RIGHT
  children = [
    currenciesPanel
    {
      flow = FLOW_HORIZONTAL
      gap = largePadding
      valign = ALIGN_BOTTOM
      children = [
        profileButton
        premiumWidgetUi
        dropDownMainMenu
      ]
    }
  ]
})

return profileInfoBlock
