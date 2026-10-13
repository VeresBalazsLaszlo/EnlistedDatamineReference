from "%ui/currency/currencies.nut" import currenciesList
from "app" import get_circuit_conf
from "%ui/shop/shopUrls.nut" import getShopCategoryUrl
from "%ui/ui_library.nut" import *

let shopCategoryUrl = get_circuit_conf()?.shopCategoryUrl
  ?? "https://store.gaijin.net/catalog.php?category={category}" 


let enlistedGold = freeze({
  id = "EnlistedGold"
  image = @(size) "ui/skin#currency/enlisted_gold.svg:{0}:{0}".subst(size.tointeger())
  locId = "currency/code/EnlistedGold"
  purchaseUrl = getShopCategoryUrl("EnlistedGold")
  qrDesc = "currency/code/qr/EnlistedGoldConsoles"
  qrConsoleUrl = "{0}&partner=QRLogin&partner_val=q37edt1l".subst(
    shopCategoryUrl.subst({ category = "EnlistedGoldConsoles" }))
})

currenciesList.set([enlistedGold])

return {
  enlistedGold
}
