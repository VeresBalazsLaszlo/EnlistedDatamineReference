import "%ui/shop/buyShopItem.nut" as buyShopItem
import "%ui/shop/buySquadWindow.nut" as buySquadWindow
from "%ui/style/colors.nut" import BtnBdNormal, borderColor
from "%ui/style/designConst.nut" import unitSize
from "%ui/shop/armyShopState.nut" import curArmyShopItems, shopItemContentCtor
from "%ui/shop/shopPkg.nut" import mkShopItemView, mkShopItemPriceLine, mkClassCanUseCenter,
  cardSquadPreviewSize
from "%ui/ui_library.nut" import *

const CARD_MAX_WIDTH = fsh(80)
let shopItemHeight = 6.0 * unitSize

let hoverBox = @(sf, maxWidth) {
  size = FLEX
  maxWidth
  rendObj = ROBJ_BOX
  borderWidth = sf & S_HOVER ? hdpx(4) : hdpx(1)
  borderColor = borderColor(sf, false)
}


let mkProductView = @(shopItem, crateContent = null) {
  rendObj = ROBJ_SOLID
  size = cardSquadPreviewSize
  padding = hdpx(1)
  color = BtnBdNormal
  clipChildren = true
  children = mkShopItemView({
    shopItem
    crateContent
  })
}

function onSquadBuy(shopItem) {
  let crateContent = shopItemContentCtor(shopItem)
  let { price = 0 } = shopItem?.curShopItemPrice
  if (price > 0) {
    let squad = shopItem?.squads[0]
    buySquadWindow({
      shopItem
      armyId = squad?.armyId
      squadId = squad?.id
    })
  } else {
    let productView = mkProductView(shopItem, crateContent)
    let description = mkClassCanUseCenter(crateContent)
    buyShopItem({
      shopItem
      productView
      description
    })
  }
}

let mkBuyButton = @(shopItem) watchElemState(@(sf) {
  size = [FLEX, shopItemHeight]
  behavior = Behaviors.Button
  onClick = @() onSquadBuy(shopItem)
  children = [
    {
      size = FLEX
      flow = FLOW_VERTICAL
      children = [
        mkShopItemView({ shopItem })
        mkShopItemPriceLine(shopItem)
      ]
    }
    hoverBox(sf, CARD_MAX_WIDTH)
  ]
})

let mkSquadBuyPromo = @(squadId, override = {}) function() {
  let res = { watch = curArmyShopItems }
  let shopItems = curArmyShopItems.get().filter(@(sItem)
    (sItem?.squads ?? []).findindex(@(squad) squad.id == squadId) != null)
  if (shopItems.len() == 0)
    return res

  return res.__update({
    size = const [fsh(50), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = fsh(1.5)
    children = shopItems.map(mkBuyButton)
  }, override)
}

return mkSquadBuyPromo