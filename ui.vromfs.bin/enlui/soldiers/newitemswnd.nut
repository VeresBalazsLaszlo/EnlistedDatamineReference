import "%ui/control/gui_buttons.nut" as JB
import "%ui/vehicles/allowedVehicles.nut" as allowedVehicles
import "%darg/helpers/mkTextRow.nut" as mkTextRow
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/soldiers/mkAnimatedItemsBlock.nut" as mkAnimatedItemsBlock
import "%ui/components/spinner.nut" as spinner
import "%ui/profile/profileScene.nut" as profileScene
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontSub
from "%ui/style/designConst.nut" import smallPadding, midPadding, bigPadding, warningColor,
  soldierLvlColor, activeTxtColor, defBgColor, defTxtColor
from "%ui/components/textButton.nut" import Regular, Primary
from "%ui/style/cursors.nut" import withTooltip
from "%ui/components/defcomps.nut" import txt
from "%ui/components/textButton.style.nut" import TextNormal, TextHover, textMargin
from "dagor.time" import get_time_msec
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/components/itemsInfo.nut" import getObjectName, getItemDesc
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/showState.nut" import curSelectedItem, changeCameraFov
from "%ui/components/soldiersUiComps.nut" import mkSoldierMedalIcon
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/components/itemTier.nut" import mkTierStars, mkItemTier
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, findItemTemplate
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/soldiers/model/newItemsToShow.nut" import needNewItemsWindow, newItemsToShow,
  markNewItemsSeen, justPurchasedItems, uniteSimilarItems, needBoosterWarning
from "%ui/soldiers/model/boosters.nut" import needBoosterCapWarning
from "%ui/unlocks/dailyRewardsState.nut" import specialUnlock
from "%ui/userstats/unlocksState.nut" import activeUnlocks
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/soldiers/model/state.nut" import curArmy, curUnlockedSquads, setCurSquadId
from "%ui/shop/shopState.nut" import getGoodManageObject
from "%ui/vehicles/vehiclesListState.nut" import goToSquad
from "%ui/soldiers/soldierDismissBtn.nut" import dismissBtn
from "%ui/soldiers/model/mkItemModifyData.nut" import mkItemUpgradeData
from "%ui/soldiers/components/modifyItemComp.nut" import openUpgradeItemMsg
from "%ui/soldiers/model/itemActions.nut" import isItemActionInProgress
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/mainMenu/sectionsState.nut" import setCurSection, curSection, Section
from "%ui/meta/servProfile.nut" import purchasesCount
from "string" import startswith
from "%ui/shop/armyShopState.nut" import needGoodManage, goodManageData, itemToShopItem
from "%ui/soldiers/components/perksPackage.nut" import mkPerksPointsBlock, hasStatsMaxed
from "%ui/eventPass/eventItemPkg.nut" import eventItemPreview
from "%ui/components/msgbox.nut" import showMessageWithContent
from "%ui/ui_library.nut" import *

const ADD_CAMERA_FOV_MIN = -20
const ADD_CAMERA_FOV_MAX = 5


const SHOW_ITEM_DELAY = 1.0 
const ANIM_TRIGGER = "reward_items_wnd_anim"
const ANIM_TEXT_TRIGGER = "reward_text_wnd_anim"
const ANIM_TITLE_TRIGGER = "reward_title_wnd_anim"

const STAR_DEF_DURATION = 0.2
const STAR_BLICK_DURATION = 0.4

const STAR_DEF_DELAY_INCREASE = 0.1
const STAR_NEXT_DELAY = 0.3

let waitingSpinner = spinner(hdpx(25))

let isAnimFinished = Watched(false)

let firstPurchases = mkOnlineSaveData("hasFirstPurchases", @() null)
let firstPurchasesStored = firstPurchases.watch

let curItem = Watched(null)
curItem.subscribe(function(v) {
  if (v != null)
    defer(function() {
      curSelectedItem.set(v)
      if (!isAnimFinished.get())
        anim_start(ANIM_TEXT_TRIGGER)
    })
  else
    curSelectedItem.set(null)
})
let soldierMaxStatsReceived = Computed(@() hasStatsMaxed(curItem.get()))
let needGoodManageBtn = Computed(@() curSection.get() != Section.MAIN && needGoodManage.get())


let isGoodWeapon = @(item) item?.ammotemplate != null
let isGoodSoldier = @(item) item?.itemtype  == "soldier"

let needShowFirstPurchaseBtn = Computed(function() {
  let item = curItem.get()
  let { weapon = true, soldier = true } = firstPurchasesStored.get()
  return needGoodManageBtn.get() &&
    ((isGoodWeapon(item) && !weapon) || (isGoodSoldier(item) && !soldier))
})


function updateFirstPurchases(purchases) {
  let joined = clone firstPurchasesStored.get() ?? {}
  purchases.each(@(val, key) joined[key] <- val || (joined?[key] ?? false))
  firstPurchases.setValue(joined)
}

function checkIsFirstPurchase() {
  if (firstPurchasesStored.get() != null)
    return

  local soldiersPurchased = 0
  local weaponsPurchased = 0
  let soldier = {}
  let weapon = {}

  foreach (shopItemsByArmy in itemToShopItem.get()) {
    shopItemsByArmy.each(function(shopItems, id) {
      shopItems.each(function(shopItem) {
        if (startswith(id, "soldier:"))
          soldier[shopItem] <- true
        else
          foreach (itemsByArmy in allItemTemplates.get()) {
            if (itemsByArmy?[id].ammotemplate != null) {
              weapon[shopItem] <- true
              break
            }
          }
      })
    })
  }

  foreach (key, val in purchasesCount.get()) {
    if (soldiersPurchased > 1 && weaponsPurchased > 1)
      break

    if (key in soldier)
      soldiersPurchased += val.amount
    if (key in weapon)
      weaponsPurchased += val.amount
  }

  updateFirstPurchases({
    soldier = soldiersPurchased > 1
    weapon = weaponsPurchased > 1
  })
}
newItemsToShow.subscribe(function(v) {
  let { allItems = [] } = v
  let { guid = null } = curItem.get()
  let item = guid == null ? allItems?[0] : allItems.findvalue(@(i) i.guid == guid)
  curItem.set(item)
  checkIsFirstPurchase()
})

local animEndTime = -1

function tryMarkSeen() {
  if (animEndTime > get_time_msec()) {
    anim_skip($"{ANIM_TRIGGER}_skip")
    anim_skip_delay(ANIM_TRIGGER)
    animEndTime = -1
    return
  }
  markNewItemsSeen()
  needGoodManage.set(false)
}

let textAnimations = @(trigger = null) [
  { trigger = trigger, prop = AnimProp.opacity,
    from = 0, to = 1, duration = 0.8, play = true, easing = InOutCubic }
  { trigger = trigger, prop = AnimProp.scale,
    from = [1.5, 2], to = [1, 1], duration = 0.3, play = true, easing = InOutCubic }
]

let title = @(titleText) {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  transform = true
  animations = textAnimations(ANIM_TITLE_TRIGGER)
  text = loc(titleText)
}.__update(fontHeading2)

let curItemDescription = @(item) {
  size = const [sw(50), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  margin = const [0, 0, hdpx(25), 0]
  text = getItemDesc(item)
  transform = true
  animations = textAnimations(ANIM_TEXT_TRIGGER)
}.__update(fontBody)

function soldierMedal(soldier) {
  if (soldier?.itemtype != "soldier")
    return null

  let medal = mkSoldierMedalIcon(soldier, hdpx(24))
  return medal == null ? null
    : withTooltip(medal, @() loc("hero/medal"))
}

function curItemName(item, armyInfoId) {
  let belongingObject = (armyInfoId ?? "") == "" ? null
    : {
        rendObj = ROBJ_TEXT
        text = loc($"{armyInfoId}/full")
        color = warningColor
      }.__update(fontBody)
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = [
      {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        valign = ALIGN_CENTER
        padding = [midPadding, 0]
        children = [
          {
            rendObj = ROBJ_TEXT
            size = SIZE_TO_CONTENT
            text = getObjectName(item)
          }.__update(fontHeading2)
          soldierMedal(item)
        ]
      }
      belongingObject
    ]
    transform = true
    animations = textAnimations(ANIM_TEXT_TRIGGER)
  }
}

let underline = {
  rendObj = ROBJ_SOLID
  size = const [pw(80), hdpx(1)]
  color = Color(100, 100, 100, 50)
}

let casualStarAnim = @(delay = 0, starCount = 1) [
  {
    prop = AnimProp.opacity, from = 0, to = 0,
    duration = delay, play = true, easing = InOutCubic
  }
  {
    prop = AnimProp.opacity, from = 0, to = 1,
    duration = STAR_DEF_DURATION, delay = delay,
    play = true, easing = InOutCubic,
    onFinish = @() sound_play("ui/order_fulfiled_star")
  }
  {
    prop = AnimProp.color, from = soldierLvlColor, to = activeTxtColor,
    duration = STAR_BLICK_DURATION, delay = STAR_NEXT_DELAY * starCount,
    play = true, easing = Blink, onFinish = @() isAnimFinished.set(true)
  }
]

let advancedStarAnim = @(delay = 0, starCount = 1, idx = 1) [
  {
    prop = AnimProp.opacity, from = 0, to = 0,
    duration = delay, play = true, easing = InOutCubic
  }
  {
    prop = AnimProp.opacity, from = 0, to = 1,
    duration = STAR_DEF_DURATION, delay = delay,
    play = true, easing = InOutCubic,
    onFinish = @() sound_play("ui/order_fulfiled_star")
  }
  {
    prop = AnimProp.color, from = soldierLvlColor, to = activeTxtColor,
    duration = STAR_DEF_DURATION, delay = STAR_DEF_DELAY_INCREASE * starCount + delay,
    play = true, easing = Blink,
    onFinish = @() sound_play( idx == 1 ? "ui/order_fulfiled_top" : "")
  }
  {
    prop = AnimProp.scale, from =[1.0, 1.0], to = [1.4, 1.4],
    duration = STAR_DEF_DURATION, delay = STAR_DEF_DELAY_INCREASE * starCount + delay,
    play = true,  easing = InOutCubic, onFinish = function() {
      isAnimFinished.set(true)
    }
  }
]

function animatedStars(item){
  if (item?.itemtype != "soldier")
    return null
  local delay = 0.2
  let level = item?.level ?? 1
  let stars = array(level, 1)
  return @() {
    watch = isAnimFinished
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    padding = const [0 ,0, fsh(1) ,0]
    children = stars.map(@(star, idx) function(){
      delay += STAR_DEF_DELAY_INCREASE
      return mkTierStars(star, {
        fontSize = hdpx(45),
        transform = true
        animations = isAnimFinished.get() ? null
          : level <= 3 ? casualStarAnim(delay, level)
          : advancedStarAnim(delay, level, idx + 1)
        padding = midPadding
      })
    })
  }
}

let mkPerksPoints = @(soldier) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  valign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = mkPerksPointsBlock(soldier)
}

function newItemsWndContent() {
  let itemsToShow = newItemsToShow.get()
  if (itemsToShow == null)
    return null

  let { itemsGuids, outfitsGuids, soldiersGuids, boostersGuids, currencyGuids, allItems, header,
    armyByGuid } = itemsToShow
  justPurchasedItems.set(clone itemsGuids)

  let itemsCount = itemsGuids.len() + outfitsGuids.len() + boostersGuids.len() + currencyGuids.len()
  let soldiersCount = soldiersGuids.len()
  let subtitle = itemsCount > 1 ? "delivery/items"
    : itemsCount == 1 ? "delivery/item"
    : soldiersCount > 1 ? "delivery/soldiers"
    : "delivery/soldier"

  let curItemValue = curItem.get()
  let { guid = null, template = {} } = curItemValue
  let { expMul = 0.0 } = template
  let animBlock = mkAnimatedItemsBlock({ items = uniteSimilarItems(allItems) },
    curItemValue?.basetpl, 
    {
      width = sw(80)
      addChildren = []
      hasAnim = !isAnimFinished.get()
      baseAnimDelay = SHOW_ITEM_DELAY
      animTrigger = ANIM_TRIGGER
      hasItemTypeTitle = false
      onItemClick = @(item) curItem.set(item)
      onVisibleCb = function() {
        sound_play(soldierMaxStatsReceived.get()
          ? "ui/debriefing/new_equip_top"
          : "ui/debriefing/new_equip")
      }
      isDisarmed = true
      armyByGuid
    })

  animEndTime = get_time_msec() + 1000 * animBlock.totalTime
  let specialUnlockHeader =
    activeUnlocks.get()?[specialUnlock.get()].meta.congratulationLangId ?? ""

  return {
    watch = [newItemsToShow, curItem, specialUnlock]
    size = const [sw(80), fsh(86)]
    flow = FLOW_VERTICAL
    gap = smallPadding
    halign = ALIGN_CENTER
    children = [
      {
        size = FLEX
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        gap = midPadding
        children = [
          title(specialUnlockHeader != "" ? loc(specialUnlockHeader)
            : expMul < 0 ? loc("battlePenaltyTitle")
            : header
          )
          underline
          curItemName(curItemValue, armyByGuid?[guid])
          soldiersCount <= 0 || curItemValue?.itemtype != "soldier" ? null
            : {
                rendObj = ROBJ_SOLID
                color = defBgColor
                children = mkPerksPoints(curItemValue)
              }
          {
            size = FLEX
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            children = eventItemPreview(curItemValue)
          }
          curItemDescription(curItemValue)
        ]
      }
      animatedStars(curItemValue)
      underline
      title(subtitle)
      {
        margin = [bigPadding, 0]
        size = const [pw(100), SIZE_TO_CONTENT]
        children = makeVertScroll(animBlock.component,
          {
            halign = ALIGN_CENTER
            size = FLEX_H
            maxHeight = sh(25)
          }
        )
      }
    ]
  }
}

function vehicleSquadBtn() {
  let watch = [curItem, curArmy, allowedVehicles]
  let isVehicle = curItem.get()?.itemtype == "vehicle"
  if (!isVehicle)
    return { watch }
  let { basetpl } = curItem.get()
  let squadsWithVehicle = (allowedVehicles.get()?[curArmy.get()] ?? {})
    .reduce(function(result, squadsV, squadId) {
      if (basetpl in squadsV)
        result.append(squadId)
      return result
    }, [])
  if (squadsWithVehicle.len() == 0)
    return { watch }

  local receivedSquad = null
  foreach(item in squadsWithVehicle) {
    receivedSquad = curUnlockedSquads.get().findvalue(@(squad) squad.squadId == item)?.squadId
    if (receivedSquad)
      break
  }

  if (receivedSquad == null)
    return { watch }

  let btnAction = @() goToSquad(receivedSquad)

  return {
    watch
    children = Regular(loc("GoToSquad"), function() {
      tryMarkSeen()
      btnAction()
    }, { hotkeys = [[ "^J:Y" ]] })
  }
}

function soldierDismissBtn() {
  let watch = [newItemsToShow, curItem]
  if (newItemsToShow.get() == null || curItem.get()?.itemtype != "soldier")
    return { watch }

  let { soldiersGuids = [] } = newItemsToShow.get()
  if (soldiersGuids.len() <= 0)
    return { watch }

  if (soldiersGuids.len() == 1)
    return {
      watch
      children = dismissBtn(curItem.get(), tryMarkSeen)
    }

  let nextSoldierGuid = newItemsToShow.get().soldiersGuids.findvalue(@(v) v != curItem.get().guid)
  let nextItemToShow = newItemsToShow.get().allItems.findvalue(@(v) v?.guid == nextSoldierGuid)
  return {
    watch
    children = dismissBtn(curItem.get(), @() curItem.set(nextItemToShow))
  }
}

function upgradeItemBtn() {
  let watch = [curItem, isItemActionInProgress, newItemsToShow, allItemTemplates]
  let justUpgradedItem = clone curItem.get()
  if (justUpgradedItem == null)
    return { watch }

  
  let { basetpl = "" } = justUpgradedItem
  let { allItems = [] } = newItemsToShow.get()
  justUpgradedItem.guids <- allItems
    .filter(@(item) (item?.guid ?? "") != "" && item?.basetpl == basetpl)
    .map(@(item) item.guid)

  let upgradeDataWatch = mkItemUpgradeData(justUpgradedItem)
  let upgradeData = upgradeDataWatch.get()
  let { isResearchRequired = false, hasEnoughOrders = false, isUpgradable = false,
    upgradeitem = "" } = upgradeData

  if (isResearchRequired || !(isUpgradable && hasEnoughOrders))
    return { watch }

  if (isItemActionInProgress.get())
    return {
      watch
      children = waitingSpinner
    }

  let armyId = getLinkedArmyName(justUpgradedItem)
  local nextUpgrade = findItemTemplate(allItemTemplates.get(), armyId, upgradeitem)
  nextUpgrade = justUpgradedItem.__merge(nextUpgrade)

  return {
    watch
    children = Regular(@(_textField, params, handler, group, sf)
      textButtonTextCtor({
        children = {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          margin = textMargin
          children = mkTextRow(loc("btn/upgrade/nextTier"),
            @(t) txt(t).__update({
              color = sf & S_HOVER ? TextHover : TextNormal
            }, fontBody),
            {
              ["{stars}"] = mkItemTier(nextUpgrade) 
            })
        }
      }, params, handler, group, sf),
      function() {
        tryMarkSeen()
        openUpgradeItemMsg(justUpgradedItem, upgradeData)
      }, {
        hotkeys = [["^J:X"]]
      })
  }
}

function markFirstPurchases() {
  updateFirstPurchases({
    soldier = curItem.get()?.itemtype == "soldier"
    weapon = curItem.get()?.ammotemplate != null
  })
}

function goToManagement() {
  let item = curItem.get()
  if (isGoodSoldier(item)) {
    let { squadId = null } = getGoodManageObject({ soldier = item })
    if (squadId != null) {
      setCurSquadId(squadId)
      goodManageData.set({ squadId })
    }
  }
  else if (isGoodWeapon(item)) {
    let {
      squadId = null, soldierIdx = null, manageSlotType = null
    } = getGoodManageObject({ weapon = item })
    if (squadId != null && soldierIdx != null && manageSlotType != null) {
      setCurSquadId(squadId)
      goodManageData.set({ soldierIdx, manageSlotType})
    }
  }

  markFirstPurchases()
  tryMarkSeen()
  setCurSection(Section.MAIN)
}

let toManagementBtn = Primary(loc("btn/goToManagement"), goToManagement,
  { hotkeys = [["^J:X"]] })

let closeBtn = Regular(loc("Close"), tryMarkSeen,
  { hotkeys = [[$"^{JB.B} | Esc | Space | Enter"]] })

function newItemsWnd() {
  let buttonsBlock = []
  if (needShowFirstPurchaseBtn.get() || needGoodManageBtn.get())
    buttonsBlock.append(toManagementBtn)
  if (!needShowFirstPurchaseBtn.get())
    buttonsBlock.append(closeBtn)

  return {
    watch = [safeAreaBorders, isAnimFinished, needShowFirstPurchaseBtn,
      needGoodManageBtn]
    key = $"newItemsWindow"
    size = FLEX
    padding = safeAreaBorders.get()
    halign = ALIGN_CENTER
    behavior = [DngBhv.MenuCameraControl, Behaviors.TrackMouse]
    flow = FLOW_VERTICAL
    onMouseWheel = function(mouseEvent) {
      changeCameraFov(mouseEvent.button * 5, ADD_CAMERA_FOV_MIN, ADD_CAMERA_FOV_MAX)
    }
    children = [
      {
        margin = [midPadding * 4, 0, 0, 0]
        hplace = ALIGN_RIGHT
        size = const [FLEX, fsh(2)]
        children = !needShowFirstPurchaseBtn.get()
          ? closeBtnBase({ onClick = tryMarkSeen })
          : null
      }
      newItemsWndContent
      {
        size = FLEX_H
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = buttonsBlock.append(soldierDismissBtn, vehicleSquadBtn, upgradeItemBtn)
      }
    ]
  }
}

function playOpenSceneSound() {
  let openSceneSound = (newItemsToShow.get()?.itemsGuids.len() ?? 0) > 0 ? "ui/weaponry_delivery"
    : soldierMaxStatsReceived.get() ? "ui/troops_reinforcement_top"
    : "ui/troops_reinforcement"

  sound_play(openSceneSound)
}

function boosterWarning() {
  needBoosterCapWarning.set(false)
  showMessageWithContent({
    content = {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = loc("booster/maxExpReached")
      color = defTxtColor
    }.__update(fontSub)
    buttons = [
      { text = loc("Ok"), isCurrent = true, isCancel = true }
      { text = loc("profile/boostersTab"), action = @() profileScene("boosters") }
    ]
  })
}

function close() {
  sceneWithCameraRemove(newItemsWnd)
  curItem.set(null)
  isAnimFinished.set(false)
}

function open() {
  playOpenSceneSound()
  curItem.set(newItemsToShow.get()?.allItems[0])
  anim_start(ANIM_TITLE_TRIGGER)
  sceneWithCameraAdd(newItemsWnd, "new_items")
}

if (needNewItemsWindow.get() || specialUnlock.get() != null)
  open()

needNewItemsWindow.subscribe(@(v) v ? open() : close())
needBoosterWarning.subscribe(@(v) v ? boosterWarning() : null)
