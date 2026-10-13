import "%ui/items/itemsMapping.nut" as itemsMapping
import "%ui/eventPass/eventPassButton.nut" as mkEventPassButton
import "%ui/shop/clickShopItem.nut" as clickShopItem
import "%ui/components/faComp.nut" as faComp
import "%ui/shop/buyShopItem.nut" as buyShopItem
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/style/designConst.nut" import smallPadding, midPadding, bigPadding, largePadding,
  unitSize, startBtnWidth, unseenColor, defTxtColor
from "%ui/gameModes/eventModeStyle.nut" import localGap
from "%ui/gameModes/eventModesState.nut" import selEvent, isEventModesOpened
from "%ui/eventPass/taskWidgetUi.nut" import eventTasksUi
from "%ui/state/eventState.nut" import createCratesListForItems
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/soldiers/model/itemActions.nut" import isItemActionInProgress
from "%ui/soldiers/model/cratesContent.nut" import crateContentWatch
from "%ui/components/textButton.nut" import Regular, Purchase
from "%ui/soldiers/model/state.nut" import curCampItemsCount, selectArmy
from "%ui/eventPass/eventPassWindowState.nut" import openEventPassWindow, getRewardIdx
from "%ui/eventPass/eventItemPkg.nut" import eventItemIcon
from "%ui/shop/shopState.nut" import setAutoGroup
from "%ui/mainMenu/sectionsState.nut" import setCurSection, Section
from "%ui/eventPass/bpUnlocksList.nut" import eventRewardsList
from "%ui/eventPass/eventTaskRewardsState.nut" import basicUnlock, purchaseStageProgress, unlockPrices, premiumStage0Unlock
from "%ui/eventPass/eventPassPkg.nut" import getUniqueRewards
from "%ui/battlepass/rewardsPkg.nut" import prepareRewards
from "%ui/userstats/unlocksState.nut" import unlockProgress, emptyProgress
from "%ui/unlocks/tasksWidgetUi.nut" import mkEventTask
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings
from "%ui/eventPass/eliteEventPass.nut" import hasEliteEventPass, canBuyEventPass, elitePassItem
from "%ui/components/mkBoosterMark.nut" import mkBoosterMark
from "%ui/ui_library.nut" import *

const SHOP_GROUP = "premium"

let marathonPassIconSize = const [hdpxi(120), hdpxi(160)]
const itemIconSize = hdpxi(22)

let itemsToCrates = Computed(function() {
  let eventParams = selEvent.get()?.queues.findvalue(@(v)
    (v?.extraParams.showConsumables.len() ?? 0) != 0)
  if (eventParams == null)
    return {}

  let itemsTbl = eventParams.extraParams.showConsumables.reduce(@(res, v) res.rawset(v, true), {})
  return createCratesListForItems(crateContentWatch.get(), itemsTbl)
})

let itemsToShopItems = Computed(function() {
  let res = {}
  if (itemsToCrates.get().len() == 0)
    return res

  let cratesToItems = {}
  foreach (itemTmpl, crateIds in itemsToCrates.get())
    foreach (crateId in crateIds)
      cratesToItems[crateId] <- itemTmpl

  foreach (shopItem in shopItems.get())
    foreach (crateId in shopItem?.crates ?? [])
      if (crateId in cratesToItems) {
        res[cratesToItems[crateId]] <- shopItem
        break
      }
  return res
})

let basicUnlockProgress = Computed(function() {
  let unlock = basicUnlock.get() ?? {}
  return unlock.__merge(unlockProgress.get()?[unlock?.name] ?? emptyProgress)
})

let mkTitle = @(text) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  text
}.__update(fontBody)

function openShopAndCloseWnd(army) {
  selectArmy(army)
  setCurSection(Section.SHOP)
  setAutoGroup(SHOP_GROUP)
  isEventModesOpened.set(false)
}

function rewardItemsToIds(itemMappingVal) {
  let res = {}
  foreach (idx, item in itemMappingVal) {
    let itemTemplate = item?.itemTemplate
    if (itemTemplate != null)
      res[itemTemplate] <- idx
  }
  return res
}

let btnWidth = (unitSize * 2.5).tointeger()
let eventItemCmp = @(icon, btn) {
  flow = FLOW_VERTICAL
  gap = smallPadding
  halign = ALIGN_CENTER
  children = [
    eventItemIcon(icon)
    btn
  ]
}

let obtainedItemCmp = faComp("check", {
  fontSize = hdpx(20)
  color = unseenColor
  padding = midPadding
})

let ownedItemsCount = @(icon, locId, count) {
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_IMAGE
      keepAspect = KEEP_ASPECT_FIT
      size = const [itemIconSize, itemIconSize]
      image = Picture("{0}:{1}:{2}".subst(icon, itemIconSize, itemIconSize))
    }
    {
      rendObj = ROBJ_TEXT
      text = loc(locId)
    }.__update(fontSub)
    {
      rendObj = ROBJ_TEXT
      text = loc("common/amountShort", { count })
    }.__update(fontSub)
  ]
}

function addShopItem(itemCmpList, ownedItems, curCampItemsCountVal, itemMappingVal,
    isItemActionInProgressVal, shopItem, rewardsTbl, itemTmpl) {
  let rewardId = rewardsTbl?[itemTmpl]
  if (rewardId == null)
    return

  let { eventImage = null, cardImage = null, isMultiple = false, icon = ""
  } = itemMappingVal[rewardId]
  let bigIcon = eventImage ?? cardImage
  let count = curCampItemsCountVal?[itemTmpl] ?? 0
  let armyId = shopItem?.armies.findvalue(@(_) true)
  let onClickCb = armyId == null
    ? @() clickShopItem(shopItem)
    : @() openShopAndCloseWnd(armyId)

  let btn = !isMultiple && count > 0
    ? obtainedItemCmp
    : Regular(loc("eventPass/buy"), onClickCb, {
        isEnabled = !isItemActionInProgressVal
        btnWidth
      })
  itemCmpList.append(eventItemCmp(bigIcon, btn))

  if (count > 0) {
    let { nameLocId = "" } = shopItem
    ownedItems.append(ownedItemsCount(icon, nameLocId, count))
  }
}

function addRewardItem(itemCmpList, curCampItemsCountVal, itemMappingVal,
    itemsToCratesVal, rewardsTbl, itemTmpl) {
  let rewardId = rewardsTbl?[itemTmpl]
  if (rewardId == null)
    return

  let { eventImage = null, cardImage = null, isMultiple = false } = itemMappingVal[rewardId]
  let icon = eventImage ?? cardImage
  function onClick() {
    let crateIds = itemsToCratesVal?[itemTmpl] ?? []
    local idx = null
    foreach (crateId in crateIds) {
      idx = getRewardIdx(crateId)
      if (idx != null)
        break
    }
    openEventPassWindow(idx)
  }

  let count = curCampItemsCountVal?[itemTmpl] ?? 0
  let btn = !isMultiple && count > 0
    ? obtainedItemCmp
    : Regular(loc("eventPass/get"), onClick, { btnWidth })
  itemCmpList.append(eventItemCmp(icon, btn))
}

let mkEventConsumables = @(itemBlockWidth) function() {
  let watch = [isItemActionInProgress, curCampItemsCount, selEvent, itemsMapping,
    itemsToCrates, itemsToShopItems]
  let eventParams = selEvent.get()?.queues.findvalue(@(v)
    (v?.extraParams.showConsumables.len() ?? 0) != 0)
  if (eventParams == null)
    return { watch }

  let obtainable = []
  let ownedItems = []
  let rewardsByTemplate = rewardItemsToIds(itemsMapping.get())
  foreach (itemTmpl in eventParams.extraParams.showConsumables) {
    let shopItem = itemsToShopItems.get()?[itemTmpl]
    if (shopItem != null)
      addShopItem(obtainable, ownedItems, curCampItemsCount.get(), itemsMapping.get(),
        isItemActionInProgress.get(), shopItem, rewardsByTemplate, itemTmpl)
    else
      addRewardItem(obtainable, curCampItemsCount.get(), itemsMapping.get(),
        itemsToCrates.get(), rewardsByTemplate, itemTmpl)
  }

  let children = [
    mkTitle(loc("events/consumables"))
    {
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      halign = ALIGN_CENTER
      children = wrap(obtainable, {
        width = itemBlockWidth
        vGap = largePadding
        hGap = midPadding
      })
    }
  ]

  if (ownedItems.len() > 0)
    children.append(
      mkTitle(loc("inventory/myItems")),
      {
        flow = FLOW_VERTICAL
        gap = smallPadding
        children = ownedItems
      })

  return {
    watch
    flow = FLOW_VERTICAL
    gap = localGap
    children
  }
}

let eventPassWdiget = {
  flow = FLOW_VERTICAL
  gap = smallPadding
  children = [
    Regular(loc("eventPass/viewRewards"), @(_) openEventPassWindow(),
      { size = FLEX_H, margin = [smallPadding, 0] })
    mkEventPassButton
    eventTasksUi
  ]
}

function dailyTaskBlock() {
  let watch = [basicUnlockProgress, purchaseStageProgress,
    basicUnlock, unlockPrices, unlockProgress]

  if (basicUnlock.get() == null)
    return { watch }

  let mainTask = basicUnlockProgress.get()
  let dailyTask = purchaseStageProgress.get()
  return {
    watch
    flow = FLOW_VERTICAL
    size = [startBtnWidth, SIZE_TO_CONTENT]
    gap = midPadding
    children = [
      {
        vplace = ALIGN_BOTTOM
        size = FLEX_H
        children = mkEventTask(mainTask,
          unlockPrices.get()?[mainTask.name], 1,
          unlockProgress.get(), true)
      }
      dailyTask == null ? null : {
        vplace = ALIGN_BOTTOM
        size = FLEX_H
        children = mkEventTask(dailyTask,
          unlockPrices.get()?[dailyTask.name], 1,
          unlockProgress.get(), true)
      }
    ]
  }
}

let plusObj = faComp("plus", {
  padding = midPadding
  fontSize = hdpx(13)
  color = defTxtColor
})

function marathonPassBuyBlock() {
  let { premPassItemIcons = null, rewardsDesc = "", rewardsOwned = ""} = bpEventSettings.get()
  let icons = premPassItemIcons ?? []
  let rewards = prepareRewards(
    getUniqueRewards(premiumStage0Unlock.get()).items, itemsMapping.get())

  let rewardsList = []
  foreach (rewardInfo in rewards) {
    let { reward } = rewardInfo
    if (reward?.name != null)
      rewardsList.append({
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          plusObj
          {
            rendObj = ROBJ_TEXT
            text = reward.name
            color = defTxtColor
          }.__update(fontSub)
        ]
      })
  }

  let purchaseBtn = !canBuyEventPass.get() ? null
    : hasEliteEventPass.get() ? Regular(loc("eventPass/obtained"), null, { isEnabled = false })
    : Purchase(loc("bp/buy"),
        @() buyShopItem({ shopItem = elitePassItem.get() }),
        { hotkeys = [["^J:Y", { description = { skip = true }}]] })

  return {
    watch = [bpEventSettings, hasEliteEventPass,
      itemsMapping, premiumStage0Unlock, canBuyEventPass]
    flow = FLOW_VERTICAL
    gap = midPadding
    size = FLEX_H
    halign = ALIGN_CENTER
    children = [
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        size = FLEX_H
        halign = ALIGN_CENTER
        children = icons.map(@(icon) {
          rendObj = ROBJ_IMAGE
          size = marathonPassIconSize
          image = Picture(icon)
        })
      }
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = FLEX_H
        halign = ALIGN_CENTER
        text = hasEliteEventPass.get() ? loc(rewardsOwned) : loc(rewardsDesc)
        color = defTxtColor
      }.__update(fontSub)
    ].extend(canBuyEventPass.get() ? rewardsList : [])
    .append(purchaseBtn)
  }
}

let eventWithStages = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  children = [
    {
      size = FLEX_H
      flow = FLOW_HORIZONTAL
      children = [
        dailyTaskBlock
        marathonPassBuyBlock
      ]
    }
    mkTitle(loc("events/participationReward"))
    eventRewardsList
  ]
}

function activeBonusMark() {
  let { premPassTokenMult = null } = bpEventSettings.get()
  return {
    watch = [hasEliteEventPass, bpEventSettings]
    hplace = ALIGN_RIGHT
    pos = [hdpx(20), bigPadding]
    children = !hasEliteEventPass.get() || premPassTokenMult == null
      ? null
      : mkBoosterMark(premPassTokenMult - 1.0, 0, "", { onClick = null })
  }
}

console_register_command(@(item) console_print(itemsToShopItems.get()?[item]), "event.shopItem")

return {
  eventPassWdiget
  mkEventConsumables
  eventWithStages
  activeBonusMark
}
