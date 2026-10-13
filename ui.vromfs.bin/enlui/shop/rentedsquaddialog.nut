import "%ui/shop/clickShopItem.nut" as clickShopItem
from "%ui/shop/armyShopState.nut" import findSquadShopItem
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/soldiers/model/squadInfoState.nut" import buyRentedSquad
from "%ui/ui_library.nut" import *

function checkReqMsgbox(rentedSquadData = null) {
  let { armyId = null, squadId = null, hasMsgBox = false } = rentedSquadData
  if (armyId == null || squadId == null)
    return

  let shopItem = findSquadShopItem(armyId, squadId)
  if (shopItem == null) {
    showMsgbox(loc("msg/rentedSquadLimits"))
    return
  }

  if (hasMsgBox)
    showMsgbox({
      text = loc("msg/rentedSquadBuy")
      buttons = [
        { text = loc("btn/buy"), isCurrent = true, action = @() clickShopItem(shopItem) }
        { text = loc("OK"), isCancel = true }
      ]
    })
  else
    clickShopItem(shopItem)
}

buyRentedSquad.subscribe(checkReqMsgbox)
