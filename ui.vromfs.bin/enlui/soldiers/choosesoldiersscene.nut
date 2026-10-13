import "%ui/components/textButton.style.nut" as defBtnStyle
import "%ui/control/gui_buttons.nut" as JB
import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
import "%darg/helpers/mkTextRow.nut" as mkTextRow
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%ui/soldiers/model/getPayItemsData.nut" as getPayItemsData
import "%ui/components/checkbox.nut" as checkbox
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/soldiers/components/squadHeader.nut" as squadHeader
import "%ui/components/mkSoldierCard.nut" as mkSoldierCard
import "%ui/components/valueWithBonus.nut" as mkValueWithBonus
import "%ui/components/mkHeader.nut" as mkHeader
import "%ui/soldiers/researchUpgradeMsgBox.nut" as gotoResearchUpgradeMsgBox
import "%ui/shop/soldiersPurchaseWnd.nut" as soldiersPurchaseWnd
import "%ui/soldiers/model/squadClassLimits.nut" as getClassLimitsComp
from "%ui/style/fontsStyle.nut" import fontBody, fontHeading2, fontSub
from "%ui/components/unseenSignal.nut" import blinkUnseenIcon
from "%ui/soldiers/model/state.nut" import curArmy, curArmyData, armoryByArmy
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierIdx
from "%ui/style/designConst.nut" import midPadding, blurBgColor, blurBgFillColor, smallPadding,
  defBgBtn, bigPadding, activeBgColor, defBgColor, slotBaseSize, listCtors, defTxtColor,
  attentionTxtColor, msgHighlightedTxtColor, negativeTxtColor, titleTxtColor, fadedTxtColor
from "%ui/soldiers/readyStatus.nut" import READY, TOO_MUCH_CLASS, NOT_FIT_CUR_SQUAD,
  NOT_READY_BY_EQUIP
from "%ui/components/defcomps.nut" import note, noteTextArea
from "%ui/components/textButton.nut" import FAPrimary, Regular
from "%ui/style/buttonsStyle.nut" import primaryFlatButtonStyle
from "%ui/shop/currencyComp.nut" import mkItemCurrency
from "%ui/shop/armyShopState.nut" import curArmyItemsPrefiltered
from "%ui/meta/profile.nut" import curCampItems
from "%ui/soldiers/model/reserve.nut" import hasCurArmyReserve
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/components/msgbox.nut" import showMsgbox, showMessageWithContent
from "%ui/soldiers/model/chooseSoldiersState.nut" import squadSoldiers, reserveSoldiers,
  reserveFilteredSoldiers, selectedSoldierGuid, soldiersStatuses, applySoldierManage,
  changeSoldierOrderByIdx, maxSquadSize, soldiersSquadParams, moveCurSoldier,
  soldierToReserveByIdx, curSoldierToReserve, curSoldierToSquad, getCanTakeSlots,
  soldiersSquad, curSquadSoldierIdx, closeChooseSoldiersWnd, isPurchaseWndOpened,
  updateSoldiersListAndSort, buyAndFillSoldiers, curReserveFilter, numHiddenSoldiers,
  reserveByFilterIds
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/soldiers/model/reserve.nut" import curArmyReserve, curArmyReserveCapacity
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/growth/growthState.nut" import curGrowthState, curGrowthConfig, curGrowthProgress,
  curGrowthTiers
from "%ui/currency/premium.nut" import hasPremium
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/soldiers/mkSoldierInfo.nut" import mkSoldierInfo, mkCustomButtons
from "%ui/soldiers/model/reserveFilterPkg.nut" import mkOpenFilterBtn
from "%ui/soldiers/model/unseenSoldiers.nut" import unseenSoldiers, markSoldierSeen
from "%ui/soldiers/model/selectItemState.nut" import curCanUnequipSoldiersList, massUnequipReserve
from "%sqstd/timers.nut" import debounce
from "%ui/meta/perks/perksExp.nut" import perkLevelsGrid
from "%ui/shop/soldiersPurchaseState.nut" import unseenSoldierShopItems, soldierShopItems,
  getSoldiersList
from "%ui/components/unseenComps.nut" import smallUnseenNoBlink
from "%ui/soldiers/soldierDismissBtn.nut" import bigDismissBtn, retireReturnCost, mkDismissWarning,
  mkApplyChangesWarning
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/preset/presetEquipUi.nut" import mkPresetEquipBlock
from "%ui/soldiers/model/squadInfoState.nut" import deselectSoldier
from "%ui/soldiers/model/config/soldierRetireConfig.nut" import retireReturn
from "%ui/helpers/metalink.nut" import getLinkedSquadGuid, getLinkedArmyName
from "%ui/meta/tutorial/meta_tutorial_button.nut" import mkPageButton
from "%ui/meta/tutorial/meta_tutorial_config.nut" import Tutorial
from "%ui/components/soldierClasses.nut" import soldierClasses, getClassCfg
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/soldiers/model/soldiersState.nut" import DEF_KIND
from "%ui/components/soldiersUiComps.nut" import kindIcon, className
from "%ui/shop/shopPkg.nut" import getCantBuyData
from "%ui/soldiers/model/cratesContent.nut" import getLoadedCrateContent, crateContentWatch
from "%ui/researches/researchesState.nut" import tableStructure, researchStatuses, RESEARCHED
from "%ui/researches/researchesFocus.nut" import focusResearch
from "%ui/ui_library.nut" import *
from "%ui/shop/armyCurrencyUi.nut" import currencySilverUi

let { nameColor, txtDisabledColor } = listCtors

let previewSoldiers = Watched([])
squadSoldiers.subscribe(@(v) previewSoldiers.set(clone v))

const NO_SOLDIER_SLOT_IDX = -1
const SOLDIERS_ON_PAGE = 12
const ADD_SLOT_EFFECT = "squad_size"

const autoFillPriority = [
  "engineer", "anti_tank", "radioman", "assault", "mgun", "medic", "sniper", "rifle"
]

let SELL_BTN_STYLE = {
  defBgColor = defBgBtn
}

let SELECT_ACTIVE_BTN_STYLE = {
  defBgColor = defBtnStyle.BgActive
  defBdColor = defBtnStyle.BgNormal
  defTxtColor = defBtnStyle.TextActive
}

let negativeSelectionFrame = freeze({
  rendObj = ROBJ_FRAME
  size = FLEX
  borderWidth = hdpxi(1)
  color = negativeTxtColor
})

let positiveSelectionFrame = freeze({
  rendObj = ROBJ_FRAME
  size = FLEX
  borderWidth = hdpxi(1)
  color = fadedTxtColor
})

let unseenIcon = blinkUnseenIcon(0.7, msgHighlightedTxtColor, "th-large")
let smallUnseenIcon = blinkUnseenIcon(0.7)
let smallUnseenNoBlinkCmp = smallUnseenNoBlink.__merge({ hplace = ALIGN_RIGHT, vplace = ALIGN_TOP })

let scrollbarParams = {
  size = FLEX_V
  skipDirPadNav = true
  barStyle = @(_has_scroll) {
    _width = fsh(1)
    _height = fsh(1)
    skipDirPadNav = true
  }
  knobStyle = {
    skipDirPadNav = true
    hoverChild = @(sf) {
      rendObj = ROBJ_BOX
      size = const [hdpx(8), FLEX]
      borderWidth = const [0, hdpx(1), 0, hdpx(1)]
      borderColor = Color(0, 0, 0, 0)
      fillColor = sf & S_ACTIVE ? Color(255,255,255)
        : sf & S_HOVER ? Color(110, 120, 140, 80)
        : Color(110, 120, 140, 160)
    }
  }
}

let unequipBtn = Regular(loc("removeAllEquipment/reserve"),
  @() showMsgbox({
    text = loc("removeAllEquipment/confirm")
    buttons = [
      {
        text = loc("Ok")
        action = @() massUnequipReserve(reserveSoldiers.get(), armoryByArmy.get())
        customStyle = { hotkeys = [[$"^J:X | Enter"]] }
      }
      {
        text = loc("Cancel")
        isCancel = true
        isCurrent = true
        customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
      }
    ]
  }),
  {
    hplace = ALIGN_RIGHT
    vplace = ALIGN_BOTTOM
  })

function reserveByKindAndRank() {
  let soldiersByKind = {}
  foreach (idx, soldier in reserveSoldiers.get()) {
    let { sKind, sClass } = soldier
    let { rank = 0 } = soldierClasses?[sClass]
    let byRank = soldiersByKind?[sKind] ?? {}
    let list = byRank?[rank] ?? []
    list.append(idx)
    byRank[rank] <- list
    soldiersByKind[sKind] <- byRank
  }
  return soldiersByKind
}

function addSoldiersOfClass(soldiersFromReserve, soldiersFromShop, classData, toAdd, reserve) {
  let { total = 0, used = 0, sKind } = classData
  let possibleToAdd = min(toAdd, total - used)
  if (possibleToAdd <= 0)
    return 0

  let reserveByKind = reserve?[sKind] ?? {}
  local added = 0
  for (local rank = 5; rank >= 0; rank--) {
    if (rank not in reserveByKind)
      continue
    let byRank = reserveByKind[rank]
    let num = min(byRank.len(), possibleToAdd - added)
    soldiersFromReserve.extend(byRank.slice(0, num))
    added += num
    if (added == possibleToAdd)
      break
  }

  if (added < possibleToAdd)
    soldiersFromShop[sKind] <- possibleToAdd - added
  return added
}

function getShopItemsByKind(priorities, soldiersToShow) {
  let result = {}
  foreach (shopItem in soldiersToShow) {
    let { soldierKind, curShopItemPrice, curItemCost } = shopItem
    let { price, currencyId = null } = curShopItemPrice
    if (!priorities.contains(soldierKind)
        || curItemCost.len() == 0
        || (currencyId != null && price > 0))
      continue

    let { soldierSpec, requirements = {}, guid } = shopItem
    let { rank = 0 } = soldierClasses?[soldierSpec]
    if (rank <= (result?[soldierKind].rank ?? -1)
      || null != getCantBuyData(curArmyData.get(), requirements,
          curGrowthState.get(), curGrowthConfig.get(), curGrowthProgress.get(),
          curGrowthTiers.get(), allItemTemplates.get()))
      continue

    result[soldierKind] <- { rank, guid, sClass = soldierSpec }
  }

  return result
}

function getCrateContent(shopItems) {
  let res = []
  foreach (shopItem in shopItems.get()) {
    let crateId = shopItem?.crates[0]
    res.append({
      shopItemId = shopItem.id
      content = getLoadedCrateContent(crateId, crateContentWatch.get())
    })
  }
  return res
}

function chooseForPurchase(priorities, buySoldiersTbl, amountToBuy) {
  if (amountToBuy == 0)
    return {}

  let crateContent = getCrateContent(soldierShopItems)
  let { soldiersToShow } = getSoldiersList(crateContent, soldierShopItems.get())
  let kindToShopItem = getShopItemsByKind(priorities, soldiersToShow)

  let purchaseTbl = {}
  foreach (kind in priorities) {
    if (kind not in buySoldiersTbl || kind not in kindToShopItem)
      continue
    let toBuy = min(amountToBuy, buySoldiersTbl[kind])
    let { guid, sClass } = kindToShopItem[kind]
    purchaseTbl[guid] <- { count = toBuy, sClass }
    amountToBuy -= toBuy
    if (amountToBuy <= 0)
      break
  }
  return purchaseTbl
}

function getIndices(sClassLimits, amountToAdd, squad) {
  if (amountToAdd <= 0 || squad == null)
    return null

  let armyId = getLinkedArmyName(squad)
  let { squadId } = squad
  let { newClass = "" } = squadsCfgById.get()?[armyId][squadId]
  let { kind } = getClassCfg(newClass)

  let limits = {}
  foreach (classInfo in sClassLimits.get())
    limits[classInfo.sKind] <- classInfo

  let addSoldiersIndices = []
  let buySoldiersTbl = {}
  local toAdd = amountToAdd
  let reserve = reserveByKindAndRank()
  let priorities = (kind == DEF_KIND
      ? autoFillPriority
      : autoFillPriority.filter(@(v) v != kind).insert(0, kind))
    .filter(@(v) v in limits)

  foreach (sKind in priorities) {
    let classInfo = limits[sKind]
    toAdd -= addSoldiersOfClass(addSoldiersIndices, buySoldiersTbl, classInfo, toAdd, reserve)
    if (toAdd <= 0)
      break
  }
  return {
    addSoldiersIndices
    buySoldiersTbl = chooseForPurchase(priorities, buySoldiersTbl, toAdd)
  }
}

function fillSoldiers(addSoldiersIndices) {
  let reserveSoldiersVal = reserveSoldiers.get()
  let removeGuids = {}
  squadSoldiers.mutate(function(list) {
    foreach (idx in addSoldiersIndices) {
      let soldier = reserveSoldiersVal[idx]
      let { sKind, guid } = soldier

      local insertTo = list.findindex(@(v) v == null || v?.sKind == sKind) ?? 0
      if (list[insertTo]?.sKind == sKind && insertTo + 1 < list.len())
        insertTo++

      if (list[insertTo] == null)
        list[insertTo] = soldier
      else {
        list.insert(insertTo, soldier)
        for (local i = 0; i < list.len(); i++)
          if (list[i] == null) {
            list.remove(i)
            break
          }
      }
      removeGuids[guid] <- true
    }
  })
  reserveSoldiers.set(reserveSoldiersVal.filter(@(v) v.guid not in removeGuids))
}

function mkPurchaseBtn(currencyTpl, count, action, isEnabled, needShortcut) {
  let { TextNormal, TextHover, textMargin } = defBtnStyle
  let customStyle = primaryFlatButtonStyle
    .__merge( needShortcut ? { hotkeys = [[$"^J:Y | Enter"]] } : {})

  return {
    text = @(_textField, params, handler, group, sf)
      textButtonTextCtor({
        children = {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_CENTER
          margin = textMargin
          children = mkTextRow(loc("btn/buyCurrency"),
            @(text) {
              rendObj = ROBJ_TEXT
              color = sf & S_HOVER ? TextHover : TextNormal
              text
            }.__update(fontBody),
            {
              ["{currency}"] = mkItemCurrency( 
                {
                  currencyTpl
                  count
                  textStyle = {
                    color = sf & S_HOVER ? TextHover : TextNormal
                  }.__update(fontBody)
                })
            })
        }
      }, params, handler, group, sf)
    action
    customStyle
    isEnabled
  }
}

function showNotEnoughMoney(currencyTpl, count) {
  let currencyWithStyle = {
    currencyTpl
    count
    textStyle = { color = defTxtColor }.__update(fontBody)
  }
  showMessageWithContent({
    content = {
      size = const [sw(90), fsh(32)]
      children = [
        {
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          size = FLEX
          children = {
            flow = FLOW_HORIZONTAL
            children = mkTextRow(loc("shop/notEnoughCurrency"),
              @(txt) {
                rendObj = ROBJ_TEXT
                text = txt
                color = attentionTxtColor
              }.__update(fontBody),
              {
                ["{priceDiff}"] = mkItemCurrency(currencyWithStyle) 
              })
          }
        }
        {
          hplace = ALIGN_RIGHT
          vplace = ALIGN_TOP
          valign = ALIGN_CENTER
          children = currencySilverUi
        }
      ]
    }
  })
}

function mkPurchaseBtns(buySoldiersTbl, addSoldiersIndices) {
  let squad = soldiersSquad.get()
  local totalCost = {}
  let shopItemsVal = curArmyItemsPrefiltered.get()
  let buyItems = {}
  foreach (shopItemGuid, buyData in buySoldiersTbl) {
    let { count } = buyData
    let { itemCost = {} } = shopItemsVal?[shopItemGuid]
    foreach (currency, cost in itemCost)
      totalCost[currency] <- cost * count + (totalCost?[currency] ?? 0)
    buyItems[shopItemGuid] <- count
  }

  let buttons = []
  foreach (currency, count in totalCost) {
    let payItems = getPayItemsData({ [currency] = count }, curCampItems.get())
    let currencyTpl = currency
    let payCount = count
    let action = payItems == null
      ? @() showNotEnoughMoney(currencyTpl, payCount)
      : function() {
          fillSoldiers(addSoldiersIndices)
          let soldiersGuids = squadSoldiers.get().filter(@(s) s != null).map(@(s) s.guid)
          let reserveGuids = reserveSoldiers.get().map(@(s) s.guid)
          buyAndFillSoldiers(squad.guid, soldiersGuids, reserveGuids, buyItems, payItems)
        }
    buttons.append(
      mkPurchaseBtn(currencyTpl, payCount, action, payItems != null, buttons.len() == 0))
  }
  return buttons
}

function purchasePreview(sClass, count, params = {}) {
  let { kind } = getClassCfg(sClass)
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    gap = midPadding
    children = [
      kindIcon(kind, hdpxi(24))
      count > 1
        ? {
            rendObj = ROBJ_TEXT
            text = loc("common/amountShort", { count })
          }.__update(fontSub)
        : null
      className(sClass)
    ]
  }.__update(params)
}

function showSoldiersToBuy(buySoldiersTbl) {
  let children = []
  foreach (buyData in buySoldiersTbl) {
    let { sClass, count } = buyData
    children.append(purchasePreview(sClass, count))
  }
  return {
    flow = FLOW_VERTICAL
    gap = midPadding
    children
  }
}

function autoFill(sClassLimits, amountToAdd, squad) {
  let { addSoldiersIndices = [], buySoldiersTbl = {} } = getIndices(sClassLimits, amountToAdd, squad)
  if (buySoldiersTbl.len() == 0) {
    fillSoldiers(addSoldiersIndices)
    return
  }

  if (!hasCurArmyReserve.get()) {
    showMsgbox({
      text = loc("shop/freePlaceForReserve")
      buttons = [{ text = loc("Close"), isCurrent = true, action = @() null }]
    })
    return
  }

  let buttons = [{
    text = loc("soldiers/fillFromReserve")
    action = @() fillSoldiers(addSoldiersIndices)
    isCurrent = true
    customStyle = { hotkeys = [[$"^J:X | Enter"]] }
  }]
  buttons.extend(mkPurchaseBtns(buySoldiersTbl, addSoldiersIndices))
  buttons.append({
    text = loc("Cancel")
    isCancel = true
    customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
  })

  showMessageWithContent({
    content = {
      size = const [sw(90), fsh(32)]
      children = [
        {
          size = FLEX
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          flow = FLOW_VERTICAL
          gap = hdpxi(10)
          children = [
            {
              rendObj = ROBJ_TEXT
              text = loc("soldiers/fillNotFound")
            }.__update(fontHeading2)
            showSoldiersToBuy(buySoldiersTbl)
            {
              rendObj = ROBJ_TEXT
              text = loc("soldiers/selectFillAction")
            }.__update(fontBody)
          ]
        }
        {
          hplace = ALIGN_RIGHT
          vplace = ALIGN_TOP
          children = currencySilverUi
        }
      ]
    }
    buttons
  })
}

function setPreviewSoldiers(sClassLimits, amountToAdd, squad) {
  let { addSoldiersIndices = [], buySoldiersTbl = {} } = getIndices(sClassLimits, amountToAdd, squad)
  let preview = clone squadSoldiers.get()
  let empties = []
  foreach (idx, soldierInSlot in preview)
    if (soldierInSlot == null)
      empties.append(idx)

  if (amountToAdd != empties.len())
    return

  foreach (idx in addSoldiersIndices) {
    let soldier = reserveSoldiers.get()[idx]
    preview[empties.remove(0)] = soldier
  }

  foreach (buyData in buySoldiersTbl) {
    let { sClass, count } = buyData
    for (local j = 0; j < count; j++)
      preview[empties.remove(0)] = { sClass }
  }
  previewSoldiers.set(preview)
}

function mkAutoFillButton(soldiersList, sClassLimits) {
  let amountToAdd = Computed(@() maxSquadSize.get() - soldiersList.get().len())

  return function() {
    let squad = soldiersSquad.get()
    return {
      watch = [amountToAdd, soldiersSquad]
      size = FLEX_H
      children = Regular(loc("soldiers/autoFill"),
        @() autoFill(sClassLimits, amountToAdd.get(), squad),
        {
          isEnabled = (amountToAdd.get() > 0 && squad != null)
          hotkeys = [["^J:LS"]]
          size = FLEX_H
          onHover = @(on) on
            ? setPreviewSoldiers(sClassLimits, amountToAdd.get(), squad)
            : previewSoldiers.set(clone squadSoldiers.get())
        })
    }
  }
}

let emptyResult = {
  size = FLEX_H
  rendObj = ROBJ_TEXT
  text = loc("squad/emptyFilter")
  margin = [smallPadding, 0]
  color = titleTxtColor
}.__update(fontSub)

function chooseSoldiersScene() {
  let reserveAvailableSize = Computed(@() reserveFilteredSoldiers.get().findindex(@(s)
      (soldiersStatuses.get()?[s.guid] ?? NOT_FIT_CUR_SQUAD) & NOT_FIT_CUR_SQUAD)
    ?? reserveFilteredSoldiers.get().len())

  let curDropData = Watched(null)
  let curDropTgtIdx = Watched(NO_SOLDIER_SLOT_IDX)
  let curDropTgtIdxDebounced = Watched(NO_SOLDIER_SLOT_IDX)
  curDropData.subscribe(@(_) curDropTgtIdx.set(NO_SOLDIER_SLOT_IDX))
  curDropTgtIdx.subscribe(debounce(@(_) curDropTgtIdxDebounced.set(curDropTgtIdx.get()), 0.01))

  let moveParams = Computed(function() {
    local watch = null
    local idx = null
    let guid = selectedSoldierGuid.get()
    if (guid != null)
      foreach (w in [squadSoldiers, reserveFilteredSoldiers]) {
        idx = w.get().findindex(@(s) s?.guid == guid)
        if (idx != null) {
          watch = w
          break
        }
      }

    let listSize = watch == squadSoldiers ? watch.get().len()
      : watch == reserveFilteredSoldiers ? reserveAvailableSize.get()
      : 0
    let isAvailable = watch != null && idx < listSize
    return {
      canUp = isAvailable && idx > 0
      canDown = isAvailable && idx < listSize - 1
      canRemove = watch == squadSoldiers
      canTake = watch == reserveFilteredSoldiers
      takeAvailable = isAvailable && soldiersStatuses.get()?[guid] == READY
        && squadSoldiers.get().findindex(@(s) s == null) != null
    }
  })

  let soldierToTake = Computed(function() {
    let dropIdx = curDropData.get()?.soldierIdx
    if (dropIdx != null)
      return reserveFilteredSoldiers.get()?[dropIdx - maxSquadSize.get()]
    let selGuid = selectedSoldierGuid.get()
    return selGuid == null ? null : reserveFilteredSoldiers.get().findvalue(@(s) s?.guid == selGuid)
  })

  let slotsHighlight = Computed(function() {
    let soldier = soldierToTake.get()
    return soldier == null ? [] : getCanTakeSlots(soldier, squadSoldiers.get())
  })

  let commonLimit = Computed(@() curArmyReserveCapacity.get()
    - (hasPremium.get() ? (gameProfile.get()?.premiumBonuses.soldiersReserve ?? 0) : 0))
  let premiumLimit = Computed(@() hasPremium.get() ? curArmyReserveCapacity.get() : null)

  function reserveCountBlock() {
    let watch = [reserveFilteredSoldiers, numHiddenSoldiers]
    let reserveCount = reserveFilteredSoldiers.get().len()
    let hiddenCount = numHiddenSoldiers.get()
    if (reserveCount <= 0 && hiddenCount <= 0)
      return { watch }

    return {
      watch
      valign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      children = [
        {
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = [
            note(loc("squad/reserveAmount", { count = reserveCount }))
            mkValueWithBonus(commonLimit, premiumLimit)
          ]
        }
        hiddenCount > 0 ? note(loc("squad/hiddenAmount", { count = hiddenCount })) : null
      ]
    }
  }

  let buttonOk = Regular(loc("Close"), @() applySoldierManage(closeChooseSoldiersWnd),
    { hplace = ALIGN_RIGHT, hotkeys = [[$"^{JB.B} | Esc"]] })

  let getMoveDirSameList = @(idx, dropIdx, targetIdx)
    dropIdx < idx && targetIdx >= idx ? -1
      : dropIdx > idx && targetIdx <= idx ? 1
      : 0

  let mkMoveDirComputed = @(idx, fixedSlotsWatch) Computed(function() {
    let dropIdx = curDropData.get()?.soldierIdx ?? -1
    let targetIdx = curDropTgtIdxDebounced.get()
    if (targetIdx < 0 || dropIdx < 0 || dropIdx == idx)
      return 0
    let fixedSlots = fixedSlotsWatch.get()
    if (idx < fixedSlots)
      return dropIdx < fixedSlots && targetIdx < fixedSlots ? getMoveDirSameList(idx, dropIdx, targetIdx) : 0
    return dropIdx >= fixedSlots && targetIdx >= fixedSlots ? getMoveDirSameList(idx, dropIdx, targetIdx)
      : dropIdx < fixedSlots && targetIdx >= fixedSlots && targetIdx <= idx ? 1
      : 0
  })

  let soldierDragAnim = @(moveDir, idx, stateFlags, content, chContent)
    content.__merge({
      behavior = Behaviors.DragAndDrop
      canDrop = @(data) data?.dragid == "soldier"
      dropData = "dropData" in content ? content.dropData : { soldierIdx = idx, dragid = "soldier" }
      onDragMode = @(on, data) curDropData.set(on ? data : null)
      onElemState = function(sf) {
        stateFlags.set(sf)
        if (!curDropData.get() || curDropData.get().soldierIdx == idx)
          return
        if (sf & S_ACTIVE)
          curDropTgtIdx.set(idx)
        else if (curDropTgtIdx.get() == idx)
          curDropTgtIdx.set(NO_SOLDIER_SLOT_IDX)
      }
      transform = true
      children = curDropData.get() ? chContent.__merge({
        transform = true
        transitions = [{ prop = AnimProp.translate, duration = 0.3, easing = OutQuad }]
        behavior = Behaviors.RtPropUpdate
        rtAlwaysUpdate = true
        update = @() {
          transform = { translate = [0, moveDir.get() * (slotBaseSize[1] + smallPadding)] }
        }
      }) : chContent
    })

  let highlightBorder = {
    size = FLEX
    rendObj = ROBJ_FRAME
    borderWidth = hdpx(1)
    borderColor = 0xFFFFFFFF
  }

  function mkEmptySlot(soldier, idx, tgtHighlight, hasBlink, isInReserve = false) {
    let group = ElemGroup()
    let onDrop = @(data) changeSoldierOrderByIdx(data?.soldierIdx, idx)
    let isDropTarget = Computed(@() curDropTgtIdx.get() == idx
      && (curDropData.get()?.soldierIdx ?? -1) >= maxSquadSize.get())
    let needHighlight = Computed(@() tgtHighlight.get()?[idx] ?? false)
    let stateFlags = Watched(0)
    let moveDir = mkMoveDirComputed(idx, maxSquadSize)
    let { sClass = null } = soldier

    return function() {
      let content = {
        watch = [stateFlags, isDropTarget, needHighlight]
        group = group
        key = $"emptySlot_{idx}"
        onDrop
        dropData = null
        onClick = @() selectedSoldierGuid.set(null)
      }

      let chContent = {
        size = slotBaseSize
        children = sClass != null && !isInReserve
          ? [
              purchasePreview(sClass, 1, { size = slotBaseSize })
              positiveSelectionFrame
            ]
          : {
              key = $"empty_slot_{idx}{hasBlink}"
              size = FLEX
              rendObj = ROBJ_SOLID
              color = isDropTarget.get() ? activeBgColor : defBgColor
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              children = [
              {
                rendObj = ROBJ_TEXT
                text = loc("squad/soldierFreeSlot")
                color = hasBlink
                  ? nameColor(0, isDropTarget.get())
                  : txtDisabledColor(0, isDropTarget.get())
                animations = hasBlink
                  ? [{
                      prop = AnimProp.opacity, from = 0.4, to = 1, duration = 1,
                      play = true, loop = true, easing = Blink
                    }]
                  : null
              }.__update(fontSub)
              needHighlight.get() ? highlightBorder : null
            ]
          }
      }

      return soldierDragAnim(moveDir, idx, stateFlags, content, chContent)
    }
  }

  let unseenMark = @(soldierGuid) @() {
    watch = unseenSoldiers
    children = (unseenSoldiers.get()?[soldierGuid] ?? false) ? smallUnseenIcon : null
  }

  let isMarkingForSale = Watched(false)
  let soldierCheckedState = Watched({})
  let selectedSoldiersNum = Computed(function() {
    let checkedState = soldierCheckedState.get()
    local total = 0
    foreach (soldier in reserveSoldiers.get()) {
      if (checkedState?[soldier.guid] ?? false)
        total++
    }
    return total
  })
  let hoveredSoldierGuid = Watched(null)

  function selectHoveredSoldierForSale() {
    let guid = hoveredSoldierGuid.get()
    if (guid == null)
      return

    soldierCheckedState.mutate(@(v) v[guid] <- !(v?[guid] ?? false))
  }

  function mkSoldierSlot(soldier, idx, tgtHighlight, addObjects,
      hasGroupSelection = false, isInReserve = false) {
    let { guid } = soldier
    let isSelectedWatch = Computed(@() selectedSoldierGuid.get() == guid)
    let isDropTarget = Computed(@() idx < maxSquadSize.get() && curDropTgtIdx.get() == idx
      && (curDropData.get()?.soldierIdx ?? -1) >= maxSquadSize.get())
    let needHighlight = Computed(@() tgtHighlight.get()?[idx] ?? false)
    let moveDir = mkMoveDirComputed(idx, maxSquadSize)

    let soldierStatus = Computed(@() soldiersStatuses.get()?[guid] ?? READY)
    let onDrop = @(data) changeSoldierOrderByIdx(data?.soldierIdx, idx)
    let stateFlags = Watched(0)
    let group = ElemGroup()

    let hasSelectionUI = Computed(@() hasGroupSelection && isMarkingForSale.get())
    let hasCheckbox = Computed(@() hasSelectionUI.get() && !isGamepad.get())
    let isPreview = !isInReserve
      && squadSoldiers.get().findvalue(@(s) s?.guid == guid) == null

    return function() {
      let sf = stateFlags.get()
      let status = soldierStatus.get()
      let isSelected = isSelectedWatch.get()
      let watch = [stateFlags, soldierStatus, isSelectedWatch, isDropTarget, needHighlight,
        isMarkingForSale, isGamepad]
      let soldierWatch = Computed(@() soldierCheckedState.get()?[guid] ?? false)
      local isGroupSelected = false
      if (hasSelectionUI.get()) {
        watch.append(soldierWatch)
        isGroupSelected = soldierWatch.get()
      }
      let border = isPreview ? positiveSelectionFrame
        : !hasSelectionUI.get() ? null
        : isGroupSelected ? negativeSelectionFrame
        : positiveSelectionFrame

      let content = {
        watch
        xmbNode = XmbNode()
        group = group
        key = $"slot{guid}{idx}"
        onDrop = onDrop
        sound = {
          hover = "ui/enlist/button_highlight"
          click = "ui/enlist/button_click"
          active = "ui/enlist/button_action"
        }
        onClick = @() selectedSoldierGuid.set(guid == selectedSoldierGuid.get() ? null : guid)
        onHover = function(on) {
          if (hasSelectionUI.get() && isGamepad.get()) {
            if (on)
              hoveredSoldierGuid.set(guid)
            else
              hoveredSoldierGuid.set(null)
          }
          hoverHoldAction("markSeenSoldier",
            { armyId = curArmy.get(), guid },
            @(v) markSoldierSeen(v.armyId, v.guid))(on)
        }
      }

      let chContent = {
        flow = FLOW_HORIZONTAL
        gap = midPadding
        valign = ALIGN_CENTER
        children = [
          @() {
            watch = perkLevelsGrid
            children = [
              mkSoldierCard({
                soldierInfo = soldier
                expToLevel = perkLevelsGrid.get()?.expToLevel
                size = slotBaseSize
                group = group
                sf = sf
                isGroupSelected
                isSelected = isSelected || isDropTarget.get()
                isFaded = status != READY
                isClassRestricted = status & TOO_MUCH_CLASS
                hasAlertStyle = status & NOT_FIT_CUR_SQUAD
                hasWeaponWarning = !!(status & NOT_READY_BY_EQUIP)
                addChild = @(...) addObjects
              })
              border
              needHighlight.get() ? highlightBorder : null
            ]
          }
          hasCheckbox.get() && soldierWatch != null
            ? checkbox(soldierWatch, { text = null, margin = [0, midPadding, 0, 0] },
                {
                  override = { gap = null, margin = null }
                  setValue = @(val) soldierCheckedState.mutate(@(v) v[guid] <- val)
                })
            : null
        ]
      }

      return hasSelectionUI.get() || (status & NOT_FIT_CUR_SQUAD)
        ? content.__update({
            behavior = Behaviors.Button
            onElemState = @(s) stateFlags.set(s)
            transform = true
            children = chContent
          })
        : soldierDragAnim(moveDir, idx, stateFlags, content, chContent)
    }
  }

  let mkSoldiersList = kwarg(@(soldiers, hasUnseen = false, idxOffset = Watched(0),
    tgtHighlight = Watched([]), slotsBlinkWatch = Watched(false), isInReserve = false,
    hasGroupSelection = false
  ) function() {
    return {
      watch = [soldiers, idxOffset, tgtHighlight, slotsBlinkWatch,
        curCanUnequipSoldiersList]
      flow = FLOW_VERTICAL
      gap = smallPadding
      behavior = Behaviors.Button
      onClick = @() selectedSoldierGuid.set(null)
      children = soldiers.get().map(function(s, idx) {
        let addObjects = hasUnseen ? [unseenMark(s?.guid)] : []
        if (isInReserve && s?.guid in curCanUnequipSoldiersList.get())
          addObjects.append(unseenIcon)
        return s?.guid == null
          ? mkEmptySlot(s, idx + idxOffset.get(),
              tgtHighlight, slotsBlinkWatch.get(), isInReserve)
          : mkSoldierSlot(s, idx + idxOffset.get(),
              tgtHighlight, addObjects, hasGroupSelection, isInReserve)
      })
    }
  })

  let labelUnableToAdd = @(listWatch) function() {
    let watch = listWatch
    if (listWatch.get().len() == 0)
      return { watch }

    return {
      watch
      rendObj = ROBJ_TEXT
      size = FLEX_H
      margin = [smallPadding, 0]
      text = loc("squad/unableAddSoldier")
      color = titleTxtColor
    }.__update(fontSub)
  }

  let bg = {
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = blurBgColor
    fillColor = blurBgFillColor
    padding = midPadding
    flow = FLOW_VERTICAL
  }

  function manageBlock() {
    let { canUp, canDown, canTake, canRemove, takeAvailable } = moveParams.get()
    let hasMoveButtons = !isPurchaseWndOpened.get() && !isMarkingForSale.get()
    let needShowUpButton = canUp && hasMoveButtons
    let needShowDownButton = canDown && hasMoveButtons
    let haveHovered = hoveredSoldierGuid.get() != null
    let canSelect = isMarkingForSale.get() && haveHovered

    let buttons = isMarkingForSale.get()
    ? [
        FAPrimary("check-square", selectHoveredSoldierForSale, {
          key = $"selectForSale_{canSelect}"
          isEnabled = haveHovered
          hotkeys = [["^J:X", { description = loc("soldiers/mark") }]]
        })
      ]
    : [
        FAPrimary("arrow-up", @() moveCurSoldier(-1), {
          key = $"moveUp_{canUp}"
          isEnabled = needShowUpButton
          hotkeys = needShowUpButton ? [["^J:Y", { description = loc("Move Up") }]]
            : null
        }),
        FAPrimary("arrow-down", @() moveCurSoldier(1), {
          key = $"moveDown_{canDown}"
          isEnabled = needShowDownButton
          hotkeys = needShowDownButton ? [["^J:X", { description = loc("Move Down") }]]
            : null
        }),
        canTake
          ? FAPrimary("arrow-left", curSoldierToSquad, {
                key = $"moveToSquad_{takeAvailable}"
                hotkeys = [["^J:LB", { description = loc("TakeToBattle") }]]
                isEnabled = takeAvailable
              })
          : FAPrimary("arrow-right", curSoldierToReserve, {
              key = $"moveToReserve_{canRemove}"
              isEnabled = canRemove
              hotkeys = canRemove ? [["^J:RB", { description = loc("MoveToReserve") }]] : null
            })
      ]

    return {
      watch = [moveParams, isPurchaseWndOpened, isMarkingForSale, hoveredSoldierGuid]
      size = FLEX_H
      valign = ALIGN_CENTER
      halign = ALIGN_RIGHT
      flow = FLOW_HORIZONTAL
      gap = midPadding
      children = buttons.append({ size = FLEX }, buttonOk)
    }
  }

  let soldiersManageHint = @() {
    watch = [isGamepad, squadSoldiers]
    size = FLEX
    gap = midPadding
    valign = ALIGN_BOTTOM
    children = isGamepad.get() ? null : {
      size = [FLEX, squadSoldiers.get().len() > 7 ? FLEX : SIZE_TO_CONTENT]
      text = "{0} {1}".subst(loc("soldier/manageHeader"), loc("soldier/maxSoldiers"))
      rendObj = ROBJ_TEXTAREA
      behavior = [Behaviors.TextArea, Behaviors.Marquee]
      orientation = O_VERTICAL
      delay = 1
    }
  }


  let hasEmptySlotsBlink = Computed(function() {
    return reserveFilteredSoldiers.get().slice(0, reserveAvailableSize.get())
      .findindex(@(s) unseenSoldiers.get()?[s.guid] ?? false) != null
  })

  let soldiersList = Computed(@() squadSoldiers.get().filter(@(s) s != null))

  let sClassLimits = getClassLimitsComp(soldiersSquad, soldiersSquadParams,
    soldiersList, soldiersStatuses)

  let researchToAddSlot = Computed(function() {
    local res = null
    let statuses = researchStatuses.get()
    let army_id = curArmy.get()
    foreach (page_id, pageData in (tableStructure.get()?.pages ?? []))
      foreach (research_id, research in (pageData?.tables ?? {})) {
        let { line = 0, tier = 0, effect = null } = research
        if (ADD_SLOT_EFFECT in effect
          && statuses?[research_id] != RESEARCHED
          && (res == null || line < res.line || (line == res.line && tier < res.tier))
        )
          res = { army_id, page_id, research_id, line, tier }
      }
    return res
  })

  function addSlotButtonUi() {
    let watch = researchToAddSlot
    if (researchToAddSlot.get() == null)
      return { watch }

    return {
      watch
      size = FLEX_H
      children = Regular(loc("soldiers/unlockMoreSlot"),
        @() applySoldierManage(function() {
          closeChooseSoldiersWnd()
          focusResearch(researchToAddSlot.get())
        }),
        { size = FLEX_H }
      )
    }
  }


  let squadList = bg.__merge({
    size = const [SIZE_TO_CONTENT, FLEX]
    gap = midPadding
    children = [
      squadHeader({
        curSquad = soldiersSquad
        curSquadParams = soldiersSquadParams
        soldiersList
        soldiersStatuses
        vehicleCapacity = Watched(0)
      })
      mkSoldiersList({
        soldiers = previewSoldiers
        hasUnseen = false
        idxOffset = Watched(0)
        tgtHighlight = slotsHighlight
        slotsBlinkWatch = hasEmptySlotsBlink
      })
      mkAutoFillButton(soldiersList, sClassLimits)
      addSlotButtonUi
      soldiersManageHint
      manageBlock
    ]
  })

  function sellSelected() {
    let checkedState = soldierCheckedState.get()
    let guids = []
    local totalCost = 0
    local heroCount = 0
    
    foreach (soldier in reserveSoldiers.get()) {
      if (!(checkedState?[soldier.guid] ?? false))
        continue

      if (getLinkedSquadGuid(soldier) != null) {
        mkApplyChangesWarning()
        return
      }

      let { guid, sClass, tier, isHero } = soldier
      let cost = retireReturnCost(reserveSoldiers.get(), retireReturn.get(),
        curArmyReserveCapacity.get(), curArmyReserve.get(), guid, sClass, tier)
      if (cost == null)
        return

      if (isHero)
        ++heroCount
      totalCost += cost

      guids.append(guid)
    }

    if (guids.len() == 0)
      return

    
    
    mkDismissWarning(curArmy.get(), guids, heroCount, totalCost, @() soldierCheckedState.set({}))
  }

  let mkMarkBtn = @(isActive) Regular(loc("btn/selectSoldiers"),
    @() isMarkingForSale.set(!isMarkingForSale.get()),
    {
      hotkeys = [["^J:Y"]]
      size = FLEX_H
      style = isActive ? SELECT_ACTIVE_BTN_STYLE : SELL_BTN_STYLE
    })

  let mkSellBtn = @(isEnabled) Regular(loc("btn/massSellSoldiers"),
    sellSelected,
    {
      isEnabled
      size = FLEX_H
    })

  let mkMoreSoldiersBlock = @(withText = true) function() {
    let fgChild = unseenSoldierShopItems.get().len() == 0 ? null
      : smallUnseenNoBlinkCmp

    return {
      size = FLEX_H
      watch = unseenSoldierShopItems
      flow = FLOW_VERTICAL
      hplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      gap = midPadding
      children = [
        withText ? noteTextArea({
          text = loc("squad/getMoreSoldiers")
        }).__update(fontSub, {halign = ALIGN_CENTER}) : null
        Regular(loc("soldiers/purchaseSoldier"), @() isPurchaseWndOpened.set(true),
          {
            size = FLEX_H
            hotkeys = [["^J:Start"]]
          }.__update({ fgChild })
        )
      ]
    }
  }

  local wasPurchOpened = false
  isPurchaseWndOpened.subscribe(function(v) {
    if (!v && wasPurchOpened) {
      updateSoldiersListAndSort()
      wasPurchOpened = true
    }
    else
      wasPurchOpened = true
  })

  let availList = Computed(@() reserveFilteredSoldiers.get().slice(0, reserveAvailableSize.get()))
  let blockedList = Computed(@() reserveFilteredSoldiers.get().slice(reserveAvailableSize.get()))
  function reserveList() {
    let reserveCount = reserveFilteredSoldiers.get().len()
    let hiddenCount = numHiddenSoldiers.get()
    let total = reserveCount + hiddenCount
    if (total == 0)
      return bg.__merge({
        watch = [reserveFilteredSoldiers, numHiddenSoldiers]
        size = slotBaseSize
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        behavior = Behaviors.Button 
        children = mkMoreSoldiersBlock()
      })

    foreach (soldier in reserveFilteredSoldiers.get()) {
      if (isMarkingForSale.get() && soldier.guid not in soldierCheckedState.get())
        soldierCheckedState.mutate(@(v) v[soldier.guid] <- false) 
    }

    return bg.__merge({
      watch = [reserveFilteredSoldiers, hasCurArmyReserve, isMarkingForSale, numHiddenSoldiers]
      size = FLEX_V
      gap = midPadding
      children = [
        {
          size = FLEX_H
          children = [
            reserveCountBlock
            {
              vplace = ALIGN_TOP
              hplace = ALIGN_RIGHT
              children = mkOpenFilterBtn(curReserveFilter, reserveByFilterIds)
            }
          ]
        }
        reserveCount == 0 ? emptyResult : null
        makeVertScroll({
          xmbNode = XmbContainer({
            canFocus = false
            scrollSpeed = 5.0
          })
          flow = FLOW_VERTICAL
          children = [
            mkSoldiersList({
              soldiers = availList
              hasUnseen = true
              idxOffset = maxSquadSize
              isInReserve = true
              hasGroupSelection = true
            })
            labelUnableToAdd(blockedList)
            mkSoldiersList({
              soldiers = blockedList
              hasUnseen = false
              idxOffset = Computed(@() maxSquadSize.get() + reserveAvailableSize.get())
              isInReserve = true
              hasGroupSelection = true
            })
          ]
        }, scrollbarParams)
        hasCurArmyReserve.get() ? mkMoreSoldiersBlock(total < SOLDIERS_ON_PAGE) : null
        @() {
          watch = [isMarkingForSale, selectedSoldiersNum]
          flow = FLOW_HORIZONTAL
          gap = midPadding
          size = FLEX_H
          children = [
            mkMarkBtn(isMarkingForSale.get())
            mkSellBtn(isMarkingForSale.get() && selectedSoldiersNum.get() > 0)
          ]
        }
      ]
    })
  }

  let selectedSoldier = Computed(function() {
    let guid = selectedSoldierGuid.get()
    return squadSoldiers.get().findvalue(@(s) s?.guid == guid)
      ?? reserveFilteredSoldiers.get().findvalue(@(s) s?.guid == guid)
  })

  let soldiersContent = {
    size = FLEX
    flow = FLOW_HORIZONTAL
    gap = midPadding
    children = [
      squadList
      {
        size = FLEX
        flow = FLOW_HORIZONTAL
        gap = midPadding
        behavior = Behaviors.DragAndDrop
        onDrop = @(data) soldierToReserveByIdx(data?.soldierIdx)
        canDrop = @(data) data?.soldierIdx != null && data.soldierIdx < maxSquadSize.get()
        skipDirPadNav = true
        children = [
          reserveList
          mkSoldierInfo({
            soldierInfoWatch = selectedSoldier
            mkDismissBtn = bigDismissBtn
            onResearchClickCb = gotoResearchUpgradeMsgBox
            buttons = mkCustomButtons(selectedSoldier)
          })
          mkPresetEquipBlock(selectedSoldier)
        ]
      }
      unequipBtn
    ]
  }

  return {
    size = const [sw(100), sh(100)]
    behavior = DngBhv.MenuCameraControl
    children = [
      @() {
        watch = [curArmy, safeAreaBorders]
        size = FLEX
        flow = FLOW_VERTICAL
        padding = safeAreaBorders.get()
        children = [
          mkHeader({
            armyId = curArmy.get()
            textLocId = "soldier/manageTitle"
            addAfterText = mkPageButton(Tutorial.MEMBERS).__update({padding = [0, bigPadding]})
            closeButton = closeBtnBase({
              onClick = @() applySoldierManage(closeChooseSoldiersWnd)
            })
          })
          {
            size = FLEX
            flow = FLOW_VERTICAL
            children = soldiersContent
          }
        ]
      }
      @() {
        watch = isPurchaseWndOpened
        size = FLEX
        children = isPurchaseWndOpened.get() ? soldiersPurchaseWnd() : null
       }
    ]
  }
}

let isOpened = keepref(Computed(@() soldiersSquad.get() != null))

function open() {
  curSquadSoldierIdx.set(curSoldierIdx.get())
  deselectSoldier()
  sceneWithCameraAdd(chooseSoldiersScene, "soldiers_quarters")
}

if (isOpened.get())
  open()

isOpened.subscribe(function(v) {
  if (v == true)
    open()
  else
    sceneWithCameraRemove(chooseSoldiersScene)
})
