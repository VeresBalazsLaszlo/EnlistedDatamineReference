import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/faComp.nut" as faComp
import "%darg/helpers/mkTextRow.nut" as mkTextRow
import "%ui/soldiers/mkItemWithMods.nut" as mkItemWithMods
import "%ui/soldiers/model/getPayItemsData.nut" as getPayItemsData
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
from "%ui/style/fontsStyle.nut" import fontSub, fontBody, fontHeading2
from "%ui/style/designConst.nut" import bigPadding, defTxtColor, smallPadding
from "%sqstd/math.nut" import ceil
from "%ui/components/msgbox.nut" import showMsgbox, showMessageWithContent
from "%ui/components/textButton.style.nut" import TextNormal, TextHover, TextDisabled, textMargin
from "%ui/components/defcomps.nut" import txt
from "%ui/meta/profile.nut" import curCampItems
from "%ui/soldiers/model/itemActions.nut" import upgradeItem, disposeItem
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, findItemTemplate
from "%ui/soldiers/components/itemDetailsPkg.nut" import diffUpgrades, mkUpgradesStatsComp
from "%ui/soldiers/model/unseenUpgrades.nut" import markUpgradesUsed
from "%ui/shop/currencyComp.nut" import mkItemCurrency, mkCurrencyImage
from "%ui/style/buttonsStyle.nut" import primaryFlatButtonStyle
from "%ui/shop/mkCounter.nut" import mkCounter
from "%ui/items/itemModify.nut" import mkGuidsCountTbl
from "%ui/style/colors.nut" import HighlightFailure
from "%ui/shop/currencyPresentation.nut" import getCurrencyPresentation
from "%ui/components/itemTier.nut" import mkTextStars
from "%ui/ui_library.nut" import *

let { tagStars } = require("%ui/components/itemTier.nut")

let itemSize = [hdpx(315), hdpx(90)]

let mkFaComp = @(text) faComp(text, {
  size = [SIZE_TO_CONTENT, itemSize[1]]
  valign = ALIGN_CENTER
  fontSize = hdpx(30)
  color = defTxtColor
})

let arrowComp = mkFaComp("arrow-circle-right")

let buttonTextColor = @(sf, isEnabled = true) !isEnabled ? TextDisabled
  : sf & S_HOVER ? TextHover
  : TextNormal

let orderedPrices = @(priceOptions) (clone priceOptions)
  .sort(@(a, b) (getCurrencyPresentation(a.orderTpl)?.order ?? 0)
    <=> (getCurrencyPresentation(b.orderTpl)?.order ?? 0))

function orderViews(priceOptions) {
  return orderedPrices(priceOptions).map(@(option) mkItemCurrency({
    currencyTpl = option.orderTpl,
    count = option.ordersInStock,
    textStyle = { color = TextNormal }.__update(fontBody)
  }))
}

function mkUpgradeItemInfo(currentItem, upgradedItem, upgradesList,
  priceOptions, countWatched) {
  let itemMaxCount = max(currentItem.count, currentItem?.guids.len() ?? 0)
  let { upgradeIdx = 0 } = currentItem
  return @() {
    watch = countWatched
    size = const [sw(90), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = bigPadding
    halign = ALIGN_CENTER
    children = [
      {
        size = FLEX_H
        valign = ALIGN_CENTER
        children = [
          txt(loc("upgradeItemMsgHeader")).__update({
            hplace = ALIGN_CENTER
          }.__update(fontBody))
          {
            flow = FLOW_HORIZONTAL
            hplace = ALIGN_RIGHT
            valign = ALIGN_CENTER
            gap = fsh(2)
            children = orderViews(priceOptions)
          }
        ]
      }
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = 5 * bigPadding
        halign = ALIGN_CENTER
        padding = 5 * bigPadding
        children = [
          mkItemWithMods({
            item = currentItem.__merge({ count = countWatched.get() })
            itemSize
            isInteractive = false
          })
          arrowComp
          {
            flow = FLOW_VERTICAL
            gap = bigPadding
            children = [
              mkItemWithMods({
                item = upgradedItem.__merge({ count = countWatched.get() })
                itemSize
                isInteractive = false
              })
              upgradesList.len() <= 0 ? null : mkUpgradesStatsComp(upgradesList)
            ]
          }
        ]
      }
      currentItem.itemtype == "vehicle" || itemMaxCount <= 1 ? null : {
        size = FLEX_H
        gap = bigPadding
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        children = [
          {
            rendObj = ROBJ_TEXTAREA
            size = FLEX_H
            halign = ALIGN_CENTER
            behavior = Behaviors.TextArea
            text = loc("weapon/upgradesCount", {
              tier = mkTextStars(upgradeIdx)
              count = countWatched.get()
              maxCount = itemMaxCount
            })
            color = defTxtColor
            tagsTable = tagStars
          }.__update(fontBody)
          mkCounter(itemMaxCount, countWatched, 1, true)
        ]
      }
    ]
  }
}

let buttonCancel = {
  text = loc("Cancel")
  isCancel = true
  customStyle = { hotkeys = [[$"^{JB.B} | Esc" ]] }
}

function mkUpgradeItemButtons(guids, priceOptions, count) {
  let hotkeysList = [ [["^J:X"]], [["^J:Y"]] ]
  let buttons = [buttonCancel]
  foreach (idx, order in orderedPrices(priceOptions)) {
    let { orderTpl, orderReq } = order
    let ordersGuids = getPayItemsData({ [orderTpl] = orderReq * count },
      curCampItems.get())
    let isEnabledOrders = (ordersGuids?.len() ?? 0) > 0
    buttons.append({
      text = @(_textField, params, handler, group, sf)
        textButtonTextCtor({
          children = {
            flow = FLOW_HORIZONTAL
            valign = ALIGN_CENTER
            margin = textMargin
            children = mkTextRow(loc("btn/upgrade/useOrders"),
              @(t) txt(t).__update({
                color = buttonTextColor(sf, isEnabledOrders)
              }, fontBody),
              {
                ["{orders}"] = mkItemCurrency({ 
                  currencyTpl = orderTpl
                  count = orderReq * count
                  textStyle = {
                    color = buttonTextColor(sf, isEnabledOrders)
                  }.__update(fontBody)
                })
              })
          }
        }, params, handler, group, sf)
      action = @() upgradeItem(mkGuidsCountTbl(guids, count), ordersGuids, @(_) markUpgradesUsed())
      customStyle = {
        isEnabled = isEnabledOrders
        hotkeys = hotkeysList?[idx]
      }.__update(primaryFlatButtonStyle)
    })
  }
  return buttons
}

let notEnoughMsg = @(currencyData) showMsgbox({
  children = {
    flow = FLOW_VERTICAL
    size = const [sw(70), SIZE_TO_CONTENT]
    gap = hdpx(15)
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc("notEnoughOrders")
      }.__update(fontHeading2)
      {
        flow = FLOW_HORIZONTAL
        children = [
          {
            rendObj = ROBJ_TEXT
            text = loc("needMoreOrders")
          }.__update(fontHeading2)
          {
            flow = FLOW_HORIZONTAL
            gap = {
              rendObj = ROBJ_TEXT
              text = loc("mainmenu/or")
              vplace = ALIGN_BOTTOM
              padding = bigPadding
            }.__update(fontSub)
            children = currencyData.map(@(curr) {
              flow = FLOW_HORIZONTAL
              gap = smallPadding
              children = [
                {
                  rendObj = ROBJ_TEXT
                  text = curr.orderReq - curr.ordersInStock
                  color = HighlightFailure
                }.__update(fontHeading2)
                mkCurrencyImage(getCurrencyPresentation(curr.orderTpl)?.icon)
              ]
            })
          }
        ]
      }
      {
        rendObj = ROBJ_TEXTAREA
        size = FLEX_H
        behavior = Behaviors.TextArea
        text = loc("dontHaveEnoughOrders")
      }.__update(fontHeading2)
    ]
  }
})

function openUpgradeItemMsg(currentItem, upgradeData) {
  let {
    guids, armyId, upgradeitem, priceOptions, hasEnoughOrders
  } = upgradeData
  if (guids.len() == 0 && (currentItem?.guid ?? "") == "") {
    showMsgbox(loc("noFreeItemToUpgrade"))
    return
  }

  if (!hasEnoughOrders) {
    notEnoughMsg(priceOptions)
    return
  }

  let countWatched = Watched(1)
  let buttonsWatched = Computed(@() mkUpgradeItemButtons(guids, priceOptions, countWatched.get()))

  local upgradedItem = findItemTemplate(allItemTemplates.get(), armyId, upgradeitem)
  if (upgradedItem == null) 
    return

  upgradedItem = {
    guid = currentItem.guid
    basetpl = upgradeitem
    links = currentItem.links
    upgradeIdx = 0
    upgradeitem = ""
    count = 1
  }.__update(upgradedItem)

  let upgradesList = diffUpgrades(currentItem)

  showMessageWithContent({
    content = mkUpgradeItemInfo(currentItem, upgradedItem, upgradesList,
      priceOptions, countWatched)
    buttons = buttonsWatched
  })
}

function openDisposeItemMsg(currentItem, disposeData) {
  let {
    armyId, itemBaseTpl, orderTpl, orderCount, isDestructible, isRecyclable, isDisposable,
    guids, batchSize = 1
  } = disposeData
  if (guids == null) {
    showMsgbox(loc("unlinkBeforeDispose"))
    return
  }

  if (isDisposable && guids.len() < batchSize) {
    showMsgbox(loc("tip/notEnoughItemsDispose", { batchSize, count = orderCount.tointeger() }))
    return
  }

  let countWatched = Watched(batchSize)
  let action = @() disposeItem(mkGuidsCountTbl(guids, countWatched.get()))
  let buttons = [
    buttonCancel
    isRecyclable
      ? {
          text = loc("btn/recycle")
          isCurrent = true
          action
          customStyle = {
            hotkeys = [[ "^J:Y | Enter | Space" ]]
          }
        }
      : {
          text = @(_textField, params, handler, group, sf)
            textButtonTextCtor({
              children = @(){
                flow = FLOW_HORIZONTAL
                valign = ALIGN_CENTER
                margin = textMargin
                watch = countWatched
                children = mkTextRow(loc("btn/acquire"),
                  @(text) {
                    rendObj = ROBJ_TEXT
                    text
                    color = buttonTextColor(sf)
                  }.__update(fontBody),
                  {
                    ["{orders}"] = mkItemCurrency({ 
                      currencyTpl = orderTpl
                      count = ceil(orderCount * (countWatched.get() / batchSize))
                      textStyle = {
                        color = buttonTextColor(sf)
                      }.__update(fontBody)
                    })
                  }
                )
              }
            }, params, handler, group, sf)
          isCurrent = true
          action
          customStyle = {
            isEnabled = true
            hotkeys = [[ "^J:Y | Enter | Space" ]]
          }.__update(primaryFlatButtonStyle)
        }
  ]

  local children = mkItemWithMods({
    item = currentItem.__merge({ count = 1 })
    itemSize
    isInteractive = false
  })
  if (!isDestructible) {
    
    local downgradedItem = findItemTemplate(allItemTemplates.get(), armyId, itemBaseTpl)
    downgradedItem = {
      guid = currentItem.guid
      basetpl = itemBaseTpl
      links = currentItem.links
      upgradeIdx = 0
      upgradeitem = ""
      count = 1
    }.__update(downgradedItem)
    let upgradesList = diffUpgrades(currentItem, 0)
    children = [
      children
      arrowComp
      {
        flow = FLOW_VERTICAL
        gap = bigPadding
        children = [
          mkItemWithMods({
            item = downgradedItem
            itemSize
            isInteractive = false
          })
          upgradesList.len() <= 0 ? null : mkUpgradesStatsComp(upgradesList)
        ]
      }
    ]
  }

  let guidsCount = guids.len()
  let content = {
    size = const [hdpx(90), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc(isRecyclable ? "recycleItemMsgHeader"
          : isDestructible ? "disposeItemMsgHeader"
          : "downgradeItemMsgHeader")
        hplace = ALIGN_CENTER
        margin = const [0, 0, fsh(5), 0]
      }.__update(fontBody)
      {
        flow = FLOW_HORIZONTAL
        gap = 5 * bigPadding
        valign = ALIGN_TOP
        padding = 5 * bigPadding
        children
      }
      !isDestructible || guidsCount <= 1 ? null
        : mkCounter(guidsCount, countWatched, batchSize, true, { hotkeys = [[$"^J:X"]] })
    ]
  }

  showMessageWithContent({
    content
    buttons
  })
}

return {
  openUpgradeItemMsg
  openDisposeItemMsg
}
