import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/mkHeader.nut" as mkHeader
import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
import "%ui/shop/buyShopItem.nut" as buyShopItem
import "%ui/currency/currenciesWidgetUi.nut" as currenciesWidgetUi
import "statsd" as statsd
import "%ui/components/colorize.nut" as colorize
import "%ui/currency/premiumWnd.nut" as premiumWnd
import "%ui/tutorial/squadTextTutorial.nut" as openSquadTextTutorial
import "%ui/components/fontIconButton.nut" as fontIconButton
import "%ui/shop/buySquadWindow.nut" as buySquadWindow
from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/components/textButton.nut" import Regular, soundActive, FAPrimary
from "%ui/style/designConst.nut" import bigPadding, smallPadding, defTxtColor, titleTxtColor,
  commonBtnHeight, attentionTxtColor, negativeTxtColor, blurBgColor, blurBgFillColor,
  selectedTxtColor, squadSlotHorSize, airSelectedBgColor, defBgColor, fadedTxtColor, opaqueBgColor,
  hoverBgColor, smallOffset, midPadding, accentTitleTxtColor
from "%ui/components/msgbox.nut" import showMsgbox, showMessageWithContent
from "%ui/components/defcomps.nut" import txt, noteTextArea
from "%ui/soldiers/unlockSquadScene.nut" import openUnlockSquadScene
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/soldiers/chooseSquadsSlots.nut" import mkHorizontalSlot, mkEmptyHorizontalSlot, curDropData
from "%ui/mpRoom/enlRoomState.nut" import isEventRoom
from "%ui/gameModes/eventModesState.nut" import isEventModesOpened
from "%ui/soldiers/model/unseenSquads.nut" import unseenSquads, markSeenSquads
from "%ui/components/unseenSignal.nut" import blinkUnseenIcon
from "%ui/shop/armyShopState.nut" import curArmyItemsPrefiltered
from "%ui/soldiers/model/chooseSquadsState.nut" import squadsArmy, selectedSquadId, chosenSquads,
  reserveSquads, displaySquads, slotsCount, applyAndClose, closeChooseSquadsWnd,
  changeSquadOrderByUnlockedIdx, squadsArmyLimits, moveIndex, changeList,
  curArmyLockedSquadsData, sendSquadActionToBQ, maxSquadsInBattle, premSquadSlots,
  previewSquads, sellableSquads, sellSquad, sellingSquadId, getCantTakeReason, showSquadOrderError
from "%ui/soldiers/model/squadsFavoriteState.nut" import favoriteSquads, addFavorite, removeFavorite
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/shop/armySlotDiscount.nut" import armySlotDiscount, armySlotItem
from "%ui/currency/premiumComp.nut" import premiumImage
from "%ui/soldiers/model/state.nut" import armoryByArmy, soldiersBySquad, curArmy
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/growth/growthState.nut" import curGrowthConfig, curTemplates
from "%ui/growth/growthPkg.nut" import mkGrowthItemCard
from "%ui/control/active_controls.nut" import isGamepad
from "%dngscripts/platform.nut" import is_pc
from "%ui/tutorial/unseenSquadTextTutorial.nut" import unseenSquadTutorials, markSeenSquadTutorial
from "%ui/tutorial/squadTextTutorialPresentation.nut" import tutorials
from "%ui/components/mkPromoWidget.nut" import promoWidget
from "%ui/shop/currencyComp.nut" import mkDiscountWidget, mkCurrencyImage
from "%ui/soldiers/model/squadInfoState.nut" import isSquadRented, buyRentedSquad
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/soldiers/components/squadsFilter.nut" import squadsFilterUi, getFilterSquads,
  getCountSquadTypes, updateSquadTypes
from "%ui/mainMenu/sectionsState.nut" import jumpToArmyGrowth
from "%ui/components/squadsUiComps.nut" import squadTypeIcon
from "%ui/quickMatchQueue.nut" import isChangesBlocked, showBlockedChangesMessage
from "%ui/shop/currencyPresentation.nut" import getCurrencyPresentation
from "%ui/soldiers/model/selectItemState.nut" import massUnequipArmyReserve
from "%ui/soldiers/armySquadTier.nut" import updateSquadsBR
from "%ui/quickMatch.nut" import joinQueue
from "%ui/gameModes/gameModeState.nut" import currentGameMode
from "%ui/meta/tutorial/meta_tutorial_button.nut" import mkPageButton
from "%ui/meta/tutorial/meta_tutorial_config.nut" import Tutorial
from "%ui/shop/shopItems.nut" import shopItems
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, equipSchemesByArmy
from "%ui/components/itemsInfo.nut" import itemNameFromTemplate
from "%sqstd/string.nut" import utf8ToLower
from "%ui/meta/profile.nut" import curArmiesList, campItemsByLink
from "%ui/ui_library.nut" import *

let { squadPlaceReasonData } = require("%ui/soldiers/model/chooseSquadsState.nut")
let premium = require("%ui/currency/premium.nut")
let { hasPremium } = premium
let premiumSquadsInBattle = premium.maxSquadsInBattle
let presetsBlock = require("%ui/soldiers/squadPresetsBlock.nut")

let textInput = require("%ui/components/textInput.nut")


const SILVER_ID = "enlisted_silver"

let premTxtStyle = { color = accentTitleTxtColor }.__update(fontSub)


let filter = Watched({})
let sentStatsdData = persist("sentStatsdData", @() {})

const commonBtnWidth = hdpxi(250)
const squadTypeIconSize = hdpxi(24)
const headerHeight = hdpx(40)

let playSoundItemPlace = @() sound_play("ui/inventory_item_place")
let unseenIcon = blinkUnseenIcon()

let priceIconSize = [hdpxi(30), hdpxi(30)]
let priceIconSilver = mkCurrencyImage(getCurrencyPresentation(SILVER_ID)?.icon, priceIconSize)


function sendData(key) {
  let keyToCheck = isGamepad.get()
    ? $"squad_management_gamepad_{key}"
    : $"squad_management_{key}"

  if (keyToCheck in sentStatsdData)
    return

  sentStatsdData[keyToCheck] <- 1
  statsd.send_counter(keyToCheck, 1)
}

let curArmyUnseenSquads = Computed(@() unseenSquads.get()?[squadsArmy.get()])

let firstSlotToAnim = Watched(null)
let secondSlotToAnim = Watched(null)
let needMoveCursor = Watched(false)
let hoveredSquad = Watched(null)
let vehiclesFilterText = Watched("")

function moveSquad(direction) {
  let squadId = selectedSquadId.get()
  if (squadId == null)
    return

  let maxSlots = maxSquadsInBattle.get()
  foreach (watch in [chosenSquads, reserveSquads]) {
    let list = watch.get()
    let idx = list.findindex(@(s) s?.squadId == squadId)
    if (idx == null)
      continue

    let newIdx = idx + direction
    if (watch == chosenSquads) {
      let checkIdxFrom = direction > 0 ? idx : newIdx
      let checkIdxTo = direction > 0 ? newIdx : idx
      if ((checkIdxFrom < maxSlots) != (checkIdxTo < maxSlots)) {
        let checkSquad = list?[checkIdxFrom]
        if (checkSquad != null) {
          let reason = getCantTakeReason(checkSquad, list, checkIdxTo)
          if (reason != null)
            return showSquadOrderError(checkSquad.guid, checkSquad.squadId, reason)
        }
      }
    }

    if (newIdx in list) {
      watch.set(moveIndex(list, idx, newIdx))
      markSeenSquads(squadsArmy.get(), [squadId])
      needMoveCursor.set(hoveredSquad.get() != null)
      firstSlotToAnim.set(watch == reserveSquads ? newIdx + chosenSquads.get().len() : newIdx)
      secondSlotToAnim.set(watch == reserveSquads ? idx + chosenSquads.get().len() : idx)
    }
    break
  }
  firstSlotToAnim.set(null)
  secondSlotToAnim.set(null)
}

let moveParams = Computed(function(prev) {
  local watch = null
  local idx = null
  let selId = isGamepad.get()
    ? hoveredSquad.get() ?? selectedSquadId.get()
    : selectedSquadId.get()
  if (selId != null)
    foreach (w in [chosenSquads, reserveSquads]) {
      idx = w.get().findindex(@(s) s?.squadId == selId)
      if (idx != null) {
        watch = w
        break
      }
    }

  let newValues = {
    canUp = watch != null && idx > 0
    canDown = watch != null && idx < watch.get().len() - 1
    canTake = watch == reserveSquads
    canRemove = watch == chosenSquads
  }

  if (prev == FRP_INITIAL)
    return newValues

  foreach (k, v in newValues)
    if (prev[k] != v)
      return newValues 

  return prev 
})

let buttonClose = Regular(loc("Close"), applyAndClose,
  { key = "closeSquadsManage" 
    size = [FLEX, commonBtnHeight]
    hotkeys = [[$"^{JB.B} | Esc"]]
  })

let buttonMassUnequip = Regular(loc("removeAllEquipment/reserve"),
  @() showMsgbox({
    text = loc("removeAllEquipment/confirmSquads")
    buttons = [
      {
        text = loc("Ok")
        action = @() massUnequipArmyReserve(reserveSquads.get(),
          soldiersBySquad.get(), armoryByArmy.get(),
          
          @(_) updateSquadsBR(reserveSquads.get(), true))
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
    minWidth = commonBtnWidth
    size = [SIZE_TO_CONTENT, commonBtnHeight]
    hplace = ALIGN_RIGHT
  })

let emptySquadToBuy = @(children) {
  rendObj = ROBJ_BOX
  size = squadSlotHorSize
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  fillColor = Color(0,0,0,0)
  borderColor = fadedTxtColor
  borderWidth = hdpx(1)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = children
}

let buySquadBtn = @(sf) {
  size = SIZE_TO_CONTENT
  halign = ALIGN_RIGHT
  margin = const [0, hdpx(26)]
  children = {
    color = sf & S_HOVER ? titleTxtColor : defTxtColor
    rendObj = ROBJ_IMAGE
    size = hdpx(30)
    image = Picture("ui/skin#icons/plus.svg:{0}:{0}".subst(hdpxi(30)))
  }
}

let squadsCountHint = @() {
  watch = squadsArmyLimits
  size = FLEX_H
  flow = FLOW_VERTICAL
  children = [
    noteTextArea(loc("squads/maximumInBattleHint"))
      .__update({color = titleTxtColor, maxWidth = hdpx(440)}, fontSub)
    noteTextArea(loc("squads/maxSquadsToTakeHint",
      { maxSquads =  colorize(titleTxtColor, squadsArmyLimits.get().maxSquadsInBattle),
        infantry  =  colorize(titleTxtColor, squadsArmyLimits.get().maxInfantrySquads),
        bike      =  colorize(titleTxtColor, squadsArmyLimits.get().maxBikeSquads),
        vehicle   =  colorize(titleTxtColor, squadsArmyLimits.get().maxVehicleSquads),
        transport =  colorize(titleTxtColor, squadsArmyLimits.get().maxTransportSquads) }))
  ]
}

let mkText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text
}.__update(fontSub, override)

let mkTextArea = @(text, override = {}) {
  size = FLEX_H
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  color = titleTxtColor
  text
}.__update(fontSub, override)

let squadsManagementHint = mkTextArea(loc("squads/movingSquadsHint"), {
  margin = [bigPadding, 0]
})

function manageBlock() {
  let { canUp, canDown, canTake, canRemove } = moveParams.get()
  return {
    watch = [moveParams, isChangesBlocked]
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      FAPrimary("arrow-up", function() {
          if (hoveredSquad.get() != null)
            selectedSquadId.set(hoveredSquad.get())
          moveSquad(-1)
          sendData("arrow-up")
          sendData( "any_button")
        },
        {
          key = "manageSquadsBtnUp" 
          isEnabled = canUp && !isChangesBlocked.get()
          hotkeys = [["^J:Y", {description = loc("Move Up")}]]
        }),
      FAPrimary("arrow-down", function() {
          if (hoveredSquad.get() != null)
            selectedSquadId.set(hoveredSquad.get())
          moveSquad(1)
          sendData("arrow-down")
          sendData( "any_button")
        },
        {
          key = "manageSquadsBtnDown" 
          isEnabled = canDown && !isChangesBlocked.get()
          hotkeys = [["^J:X", {description = loc("Move Down")}]]
        }),
      canTake ? FAPrimary("arrow-left", function() {
            if (hoveredSquad.get() != null)
              selectedSquadId.set(hoveredSquad.get())
            changeList()
            sendData("arrow-left")
            sendData( "any_button")
          },
          {
            key = "manageSquadsBtnLeft" 
            isEnabled = canTake && !isChangesBlocked.get()
            hotkeys = [["^J:LB", {description = loc("TakeToBattle")}]]
          })
        : canRemove ? FAPrimary("arrow-right", function() {
            if (hoveredSquad.get() != null)
              selectedSquadId.set(hoveredSquad.get())
            changeList()
            sendData("arrow-right")
            sendData( "any_button")
          },
          {
            key = "manageSquadsBtnRight" 
            isEnabled = canRemove && !isChangesBlocked.get()
            hotkeys = [["^J:RB", {description = loc("MoveToReserve")}]]
          })
        : null
    ]
  }
}

let squadUnseenMark = @(squadId) @() {
  watch = curArmyUnseenSquads
  hplace = ALIGN_RIGHT
  children = (curArmyUnseenSquads.get()?[squadId] ?? false) ? unseenIcon : null
}

let emptySlotNumberStyle = {
  fillColor = Color(0,0,0,0)
  borderColor = fadedTxtColor
  borderWidth = hdpx(1)
}


let squadNumber = @(idx, isForPrem, style = {}) {
  rendObj = ROBJ_BOX
  size = const [hdpx(32), FLEX]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  padding = [0, smallPadding]
  margin = [0, midPadding,0,0]
  fillColor = defBgColor
  borderWidth = 0
  borderColor = isForPrem ? attentionTxtColor : 0
  children = mkText(idx + 1, isForPrem ? premTxtStyle : {})
}.__merge(style)

let mkBuySquadSlot = @(num, shopItem, discount)
  watchElemState(@(sf) {
    flow = FLOW_HORIZONTAL
    margin = [0, 0, bigPadding, 0]
    behavior = Behaviors.Button
    onClick = @() buyShopItem({ shopItem })
    children = [
      squadNumber(num, false, emptySlotNumberStyle)
      emptySquadToBuy([
        {
          size = FLEX
          valign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          margin = const [0, hdpx(20)]
          gap = hdpx(20)
          children = [
            mkTextArea(loc("squad/openNewSlot"), {
              color = sf & S_HOVER ? titleTxtColor : fadedTxtColor
            })
            mkDiscountWidget(discount, { hplace = ALIGN_LEFT, vplace = ALIGN_CENTER, pos = null })
          ]
        }
        buySquadBtn(sf)
      ])
    ]
  })

function onDropCbForHorSlot(idxFrom, idxTo) {
  if (isChangesBlocked.get()) {
    showBlockedChangesMessage()
    return
  }
  changeSquadOrderByUnlockedIdx(idxFrom, idxTo)
  sendData("drag_and_drop")
  foreach (cSquad in chosenSquads.get()) {
    let { squadType = null } = cSquad
    if (squadType in unseenSquadTutorials.get()) {
      openSquadTextTutorial(squadType)
      markSeenSquadTutorial(squadType)
      break
    }
  }
  playSoundItemPlace()
}

function squadHorSlot(squad, idx, fixedSlotsCount, maxSquadsLen = 0, premSlotsLen = 0) {
  let group = ElemGroup()
  let stateFlags = Watched(0)
  let { squadId = null } = squad
  let sellCost = Computed(@() sellableSquads.get()?[squadId] ?? 0)

  function onInfoCb() {
    let armyId = squadsArmy.get()
    if (isSquadRented(squad))
      buyRentedSquad.set({ armyId, squadId })
    else
      openUnlockSquadScene(armyId, squadsCfgById.get()?[armyId][squadId])
    selectedSquadId.set(null)
  }

  let onClick = @() selectedSquadId.set(squadId)
  let isSelected = Computed(@() selectedSquadId.get() == squadId)
  let isFavorite = Computed(@() squadId in favoriteSquads.get())

  function onFavoriteCb() {
    if (isFavorite.get())
      removeFavorite(squadId)
    else
      addFavorite(squadId)
  }

  function onHover(on) {
    hoveredSquad.set(on ? squadId : null)
    hoverHoldAction("unseenSquad", squadId,
      @(id) markSeenSquads(squadsArmy.get(), [id])
    )(on)
  }

  let thisSlotNeedMoveCursor = Computed(@()
    hoveredSquad.get() == squadId ? needMoveCursor.get() : false)

  return function() {
    let sellCostVal = sellCost.get()
    let onSellCb = isSquadRented(squad) || sellCostVal <= 0 ? null
      : function() {
          let sellHeader = loc("squad/sellHeader", {
            squadName = colorize(attentionTxtColor, loc(squad.titleLocId))
          })

          showMessageWithContent({
            content = {
              size = const [sw(60), SIZE_TO_CONTENT]
              flow = FLOW_VERTICAL
              gap = bigPadding
              margin = const [hdpxi(50),0,0,0]
              hplace = ALIGN_CENTER
              halign = ALIGN_CENTER
              children = [
                mkTextArea(sellHeader, { halign = ALIGN_CENTER }.__update(fontBody))
                mkText(loc("squad/sellAttention"), {
                  color = negativeTxtColor
                }.__update(fontBody))
                {
                  size = FLEX_H
                  flow = FLOW_HORIZONTAL
                  gap = bigPadding
                  margin = hdpxi(50)
                  halign = ALIGN_CENTER
                  valign = ALIGN_CENTER
                  children = [
                    mkText(loc("squad/sellSilverInfo"), fontBody)
                    {
                      flow = FLOW_HORIZONTAL
                      valign = ALIGN_CENTER
                      gap = smallPadding
                      children = [
                        priceIconSilver
                        mkText(sellCostVal, fontBody)
                      ]
                    }
                  ]
                }
                mkTextArea(loc("squad/sellInfo"), {
                  size = const [hdpxi(640), SIZE_TO_CONTENT]
                  color = defTxtColor
                })
              ]
            }
            buttons = Computed(@() [
              { text = loc("Cancel"), isCancel = true }
              {
                text = loc("squad/sellBtn")
                action = @() sellSquad(squadsArmy.get(), squad.guid, sellCostVal)
                isCurrent = true
                customStyle = { enabledDelay = 5, isEnabled = !sellingSquadId.get() }
              }
            ])
          })
        }

    return {
      watch = [
        thisSlotNeedMoveCursor, firstSlotToAnim, secondSlotToAnim, chosenSquads,
        unseenSquadTutorials, sellCost
      ]
      children = mkHorizontalSlot(
        squad.__merge({
          idx
          onDropCb = onDropCbForHorSlot
          onInfoCb
          onSellCb
          onFavoriteCb
          onClick
          isSelected
          isLocked = maxSquadsLen > 0 && idx >= maxSquadsLen + premSlotsLen
          override = { onHover }
          group
          stateFlags
          fixedSlots = fixedSlotsCount
          needMoveCursor = thisSlotNeedMoveCursor.get()
          firstSlotToAnim = firstSlotToAnim.get()
          secondSlotToAnim = secondSlotToAnim.get()
          addChildren = [squadUnseenMark(squad.squadId)]
          needSquadTutorial = squad.squadType in tutorials
          isFavorite
        }))
    }
  }
}

function onDropCbForEmptySlot(idxFrom, idxTo) {
  if (isChangesBlocked.get()) {
    showBlockedChangesMessage()
    return
  }
  changeSquadOrderByUnlockedIdx(idxFrom, idxTo)
  sendData("drag_and_drop")
  playSoundItemPlace()
}

function emptyHorSquadSlot(idx, fixedSlotsCount, isReserveEmpty, maxSquadsLen) {
  let onClick = idx < maxSquadsLen ? null
    : @() showMsgbox({
        text = loc("msg/cantTakeNotPremSquad")
        buttons = [{ text = loc("Ok"), isCancel = true }]
          .extend(squadPlaceReasonData?.squadPrem.buttons ?? [])
      })
  return mkEmptyHorizontalSlot({
    idx
    onClick
    onDropCb = onDropCbForEmptySlot
    fixedSlots = fixedSlotsCount
    hasBlink = !isReserveEmpty
    isPrem = idx >= maxSquadsLen
  })
}

let mkSquadSlot = @(
  squad, idx, fixedSlotsCount, isReserve, isReserveEmpty = true, maxSquadsLen = 0, premSlotsLen = 0
) {
  flow = FLOW_HORIZONTAL
  children = [
    isReserve ? null : squadNumber(idx, idx >= maxSquadsLen)
    squad != null
      ? squadHorSlot(squad, idx, fixedSlotsCount, maxSquadsLen, premSlotsLen)
      : emptyHorSquadSlot(idx, fixedSlotsCount, isReserveEmpty, maxSquadsLen)
  ]
}

const iconSize = hdpxi(30)
let premiumIcon = premiumImage(iconSize)

let mkPrimeSlotTxt = @(icon, locId) {
  flow = FLOW_HORIZONTAL
  size = FLEX_H
  gap = bigPadding
  valign = ALIGN_CENTER
  margin = const [0, hdpx(20)]
  children = [
    icon
    mkText(loc(locId), { color = fadedTxtColor })
  ]
}

let slotToBuy = @(num, icon, locId) {
  flow = FLOW_HORIZONTAL
  children = [
    squadNumber(num, false, emptySlotNumberStyle)
    emptySquadToBuy(mkPrimeSlotTxt(icon, locId))
  ]
}

let mkPrimeSlots = @(num, count, icon, locId) {
  flow = FLOW_VERTICAL
  gap = midPadding
  children = array(count).map(@(_, idx) slotToBuy(num + idx, icon, locId))
}

let mkBuyPremBtn = @(onClick)
  watchElemState(@(sf) {
    rendObj = ROBJ_BOX
    behavior = Behaviors.Button
    onClick
    size = hdpx(48)
    fillColor = sf & S_HOVER ? hoverBgColor : opaqueBgColor
    borderWidth = hdpx(1)
    borderRadius = hdpx(48)
    borderColor = sf & S_HOVER ? selectedTxtColor : fadedTxtColor
    pos = [squadSlotHorSize[0] - midPadding * 2, 0]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    sound = soundActive
    children = {
      keepAspect = KEEP_ASPECT_FIT
      rendObj = ROBJ_IMAGE
      size = hdpx(30)
      image = Picture("ui/skin#icons/plus.svg:{0}:{0}".subst(hdpxi(30)))
      color = sf & S_HOVER ? selectedTxtColor : titleTxtColor
    }
  })

function extendSlots() {
  let squadNum = chosenSquads.get().len()
  let shopItem = armySlotItem.get()
  let discount = armySlotDiscount.get()
  let sPremNum = shopItem == null ? squadNum : squadNum + 1

  let children = []
  if (previewSquads.get() == null) {
    if (shopItem != null)
      children.append(mkBuySquadSlot(squadNum, shopItem, discount))
    if (!hasPremium.get() && premiumSquadsInBattle.get() > 0)
      children.append({
        gap = midPadding
        valign = ALIGN_CENTER
        children = [
          mkPrimeSlots(sPremNum, premiumSquadsInBattle.get(), premiumIcon, "squad/plusPremiunSquadSlot")
          mkBuyPremBtn(premiumWnd)
        ]
      })
  }

  return {
    watch = [
      hasPremium, premiumSquadsInBattle, chosenSquads, previewSquads,
      armySlotItem, armySlotDiscount
    ]
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    children
  }
}

let scrollHandlerLeftPanel = ScrollHandler()

let panelBg = {
  size = FLEX_V
  flow = FLOW_VERTICAL
  padding = bigPadding
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
}

let mkSquadTypeInfo = @(squadType, current, total) {
  valign = ALIGN_CENTER
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    squadTypeIcon(squadType, squadTypeIconSize, { color = defTxtColor })
    txt($"{current}/{total}")
  ]
}

let mkPremSlotsInfo = @(premSlots) premSlots.len() == 0 ? null
  : {
      flow = FLOW_HORIZONTAL
      gap = bigPadding
              valign = ALIGN_CENTER
      children = [
        txt({ text = loc("+") }).__update({ color = accentTitleTxtColor }, fontBody)
      ].extend(premSlots.keys().map(@(squadType) {
        valign = ALIGN_CENTER
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = [
          squadTypeIcon(squadType, squadTypeIconSize, { color = accentTitleTxtColor })
          txt({ text = $"{premSlots[squadType]}" }).__update(premTxtStyle)
        ]
      }))
    }

function mkLeftHeader() {
  let squadGroups = Computed(function() {
    let maxInBattle = maxSquadsInBattle.get()
    let squads = displaySquads.get()
    let mainSlots = {}
    let premSlots = {}
    foreach (idx, squad in squads) {
      if (squad == null)
        continue

      let { vehicleType = "" } = squad
      let storage = idx < maxInBattle ? mainSlots : premSlots
      if (vehicleType == "bike" || vehicleType == "jeep")
        storage.bike <- (storage?.bike ?? 0) + 1
      else if (vehicleType == "truck")
        storage.truck <- (storage?.truck ?? 0) + 1
      else if (vehicleType != "")
        storage.tank <- (storage?.tank ?? 0) + 1
      else
        storage.rifle <- (storage?.rifle ?? 0) + 1
    }
    let curSquads = mainSlots.reduce(@(res, val) res + val, 0)
      + premSlots.reduce(@(res, val) res + val, 0)

    return { mainSlots, premSlots, curSquads, maxSquads = squads.len() }
  })

  return function() {
    let { mainSlots, premSlots, curSquads, maxSquads } = squadGroups.get()
    let { maxInfantrySquads, maxBikeSquads, maxVehicleSquads,
      maxTransportSquads } = squadsArmyLimits.get()

    return {
      watch = [squadsArmyLimits, squadGroups]
      size = const [FLEX, headerHeight]
      flow = FLOW_HORIZONTAL
      gap = { size = FLEX }
      children = [
        txt({ text = loc("squads/maxSquads", { curSquads, maxSquads }) })
          .__update(curSquads < maxSquads ? {} : premTxtStyle)
        {
          valign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          children = [
            {
              flow = FLOW_HORIZONTAL
              gap = bigPadding
              valign = ALIGN_CENTER
              children = [
                mkSquadTypeInfo("rifle", mainSlots?.rifle ?? 0, maxInfantrySquads)
                mkSquadTypeInfo("bike", mainSlots?.bike ?? 0, maxBikeSquads)
                mkSquadTypeInfo("truck", mainSlots?.truck ?? 0, maxTransportSquads)
                mkSquadTypeInfo("tank", mainSlots?.tank ?? 0, maxVehicleSquads)
              ]
            }
            mkPremSlotsInfo(premSlots)
          ]
        }
      ]
    }
  }
}


let leftButtonBlock = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  children = [
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      children = [
        is_pc ? squadsManagementHint : null
        squadsCountHint
      ]
    }
    {
      flow = FLOW_VERTICAL
      gap = smallPadding
      halign = ALIGN_RIGHT
      children = [
        manageBlock
        Regular(loc("squads/presets"), presetsBlock.open, {
          key = "openPresetsBlock"
          size = [SIZE_TO_CONTENT, commonBtnHeight]
          minWidth = commonBtnWidth
        })
        buttonClose
      ]
    }
  ]
}


function leftPanel() {
  let noReserve = reserveSquads.get().len() == 0
  let squads = displaySquads.get()
  return panelBg.__merge({
    watch = [displaySquads, reserveSquads, maxSquadsInBattle, premSquadSlots]
    children = [
      mkLeftHeader()
      makeVertScroll({
        flow = FLOW_VERTICAL
        gap = midPadding
        children = squads.map(@(squad, idx) mkSquadSlot(
          squad, idx, squads.len(), false, noReserve, maxSquadsInBattle.get(), premSquadSlots.get()
        )).append(extendSlots)
      }, {
        size = FLEX_V
        styling = thinStyle
        scrollHandler = scrollHandlerLeftPanel
      })
      leftButtonBlock
    ]
  })
}


let labelText = @(sf, needHighlight) mkText(loc("squad/dropToReserve"), {
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  color = (sf & S_ACTIVE) && needHighlight ? selectedTxtColor : defTxtColor
})


function onDropCbForReserveContainer(data) {
  if (isChangesBlocked.get()) {
    showBlockedChangesMessage()
    return
  }
  if (data.squadIdx > chosenSquads.get().len() - 1)
    return

  let { guid, squadId } = chosenSquads.get()[data.squadIdx]
  sendSquadActionToBQ("move_to_reserve", guid, squadId)
  sendData("drag_and_drop")
  reserveSquads.mutate(@(v) v.insert(0, chosenSquads.get()[data.squadIdx]))
  chosenSquads.mutate(@(v) v[data.squadIdx] = null)
  playSoundItemPlace()
}

function dropToReserveContainer() {
  function dropContainer(sf) {
    let highligtToDrop = curDropData.get()?.squadIdx != null
      && curDropData.get().squadIdx <= chosenSquads.get().len() - 1
    return {
      watch = [curDropData, chosenSquads]
      key = "dropToReserveSquad" 
      rendObj = ROBJ_BOX
      fillColor = (sf & S_ACTIVE) && highligtToDrop ? airSelectedBgColor : defBgColor
      size = squadSlotHorSize
      borderWidth = highligtToDrop ? hdpx(1) : 0
      transform = true
      behavior = Behaviors.DragAndDrop
      onDrop = onDropCbForReserveContainer
      children = labelText(sf, highligtToDrop)
    }
  }
  return watchElemState(dropContainer)
}


let scrollHandlerRightPanel = ScrollHandler()


function growthSquadMsgbox(growthData) {
  let okBtn = { text = loc("Ok"), isCancel = true }
  let { growthId, lockTxt = "" } = growthData
  let { itemTemplate = null, armyId = null } = curGrowthConfig.get()?[growthId].reward
  let item = curTemplates.get()?[itemTemplate]

  if (item == null) {
    log($"Undefined growth item for {growthId}")
    return
  }

  showMessageWithContent({
    content = {
      flow = FLOW_VERTICAL
      size = FLEX_H
      halign = ALIGN_CENTER
      gap = bigPadding
      children = [
        {
          size = FLEX_H
          halign = ALIGN_CENTER
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          children = [
            {
              rendObj = ROBJ_TEXT
              text = loc("growth/requiredHeader")
            }.__update(fontSub)
            {
              rendObj = ROBJ_TEXT
              text = lockTxt
              color = titleTxtColor
            }.__update(fontBody)
          ]
        }
        mkGrowthItemCard({ item, itemTemplate, armyId })
      ]
    }
    buttons = Computed(@() isEventRoom.get() || isEventModesOpened.get()
      ? [okBtn]
      : [okBtn, {
          text = loc("GoToGrowth")
          action = function() {
            jumpToArmyGrowth(growthId)
            closeChooseSquadsWnd()
          }
          isCurrent = true
        }])
  })
}

let vehiclesFilter = {
  size = FLEX
  valign = ALIGN_CENTER
  children = [
    textInput(vehiclesFilterText, { placeholder = loc("squads/filter/search_veh") })
    @() {
      watch = vehiclesFilterText
      hplace = ALIGN_RIGHT
      children = vehiclesFilterText.get() == "" ? null : fontIconButton("close", {
        onClick = @() vehiclesFilterText.set("")
        margin = const [0, fsh(0.5)]
      })
    }
  ]
}

function mkHeadRightPanel() {
  let squadTypesCount = Computed(@()
    updateSquadTypes(getCountSquadTypes(reserveSquads.get(), favoriteSquads.get()),
      curArmyLockedSquadsData.get(), 0))
  return {
    size = const [FLEX, headerHeight]
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = bigPadding
    margin = [0, 0, bigPadding, 0]
    children = [
      txt(loc("squads/reserveSquads", "Reserve squads"))
      vehiclesFilter
      squadsFilterUi({
        watchFilter = filter,
        squadTypesCount,
        offset = [-hdpxi(8), hdpxi(20)]
      })
    ]
  }
}


let mkSlotFaBtnParams = @(hintLocId) {
  btnHeight = squadSlotHorSize[1]
  hint = mkText(loc(hintLocId))
}

let mkPrefilteredSquads = @(itemNames) Computed(function() {
  let byVehicles = {}
  let byNames = {}
  let vnames = itemNames.get().vehicleNames
  foreach (armyId in curArmiesList.get()) {
    let vehicles = {}
    byVehicles[armyId] <- vehicles
    let squadConfigs = squadsCfgById.get()[armyId]
    let names = {}
    byNames[armyId] <- names
    foreach (squadConfig in squadConfigs) {
      let { id, vehicleType, isFake = false, allowedVehicles = [] } = squadConfig
      if (isFake)
        continue

      let { nameLocId = null, titleLocId = null } = getSquadPresentation(id, armyId)

      if (nameLocId != null) {
        let name = utf8ToLower(loc(nameLocId))
        if (names?[name] == null)
          names[name] <- {}
        names[name][id] <- true
      }

      if (titleLocId != null) {
        let title = utf8ToLower(loc(titleLocId))
        if (names?[title] == null)
          names[title] <- {}
        names[title][id] <- true
      }

      if (vehicleType == "")
        continue

      foreach (vehicleId in allowedVehicles) {
        let vehicleName = vnames?[vehicleId]
        if (vehicleName != null) {
          let squads = vehicles?[vehicleName] ?? {}
          squads[id] <- true
          vehicles[vehicleName] <- squads
        }
      }
    }
  }

  return { byVehicles, byNames }
})

function getNameComparable(template) {
  let itemname = itemNameFromTemplate(template)
  return itemname != null ? utf8ToLower(itemname) : null
}

let mkWeaponTypes = @() Computed(function() {
  let armyId = curArmy.get()
  let schemes = equipSchemesByArmy.get()?[armyId]
  if (schemes == null)
    return []

  let result = {}
  foreach (scheme in schemes) {
    foreach (slot in scheme) {
      let { itemTypes = null } = slot
      if (itemTypes) {
        itemTypes.each(@(itemType) result[itemType] <- true )
      }
    }
  }

  return result
})

let mkItemNames = @(weaponTypes) Computed(function() {
  let vehicleNames = {}
  let weaponNames = {}
  let templates = allItemTemplates.get()[curArmy.get()]
  foreach (id, template in templates) {
    let { itemtype } = template
    if (itemtype == "vehicle") {
      let name = getNameComparable(template)
      if (name != null)
        vehicleNames[id] <- name
    }
    else if (itemtype in weaponTypes.get()) {
      let name = getNameComparable(template)
      if (name != null)
        weaponNames[id] <- name
    }
  }

  return {
    vehicleNames
    weaponNames
  }
})

let mkReserveSquadsByWeapon = @(itemNames) Computed(function() {
  let squadsByWeapon = {}
  let campItemsByLinkVal = campItemsByLink.get()
  let soldiersBySquadVal = soldiersBySquad.get()
  let { weaponNames } = itemNames.get()

  foreach (squad in reserveSquads.get()) {
    let { squadId, guid } = squad
    let soldiers = soldiersBySquadVal?[guid] ?? []
    foreach (soldier in soldiers) {
      let items = campItemsByLinkVal?[soldier.guid] ?? []
      foreach (slot in items) {
        foreach (item in slot) {
          let { basetpl } = item
          let weaponName = weaponNames?[basetpl]
          if (weaponName) {
            let weaponSquads = squadsByWeapon?[weaponName] ?? {}
            weaponSquads[squadId] <- true
            squadsByWeapon[weaponName] <- weaponSquads
          }
        }
      }
    }
  }

  return squadsByWeapon
})

let mkFilteredLockedSquads = @(prefilteredSquads, filterText, locked) Computed(function() {
  let lockedV = locked.get()
  let filterTextVal = filterText.get()
  if (filterTextVal == "")
    return lockedV

  let armyId = curArmy.get()
  let squads = {}
  let prefiltered = prefilteredSquads.get()
  foreach (vehicleName, squadIds in prefiltered.byVehicles[armyId]) {
    if (vehicleName.contains(filterTextVal))
      squads.__update(squadIds)
  }
  foreach (squadName, squadIds in prefiltered.byNames[armyId]) {
    if (squadName.contains(filterTextVal))
      squads.__update(squadIds)
  }

  return lockedV.filter(@(squad) squad.squadId in squads)
})

let mkFilteredReserveSquads = @(prefilteredSquads, filterText, reserve, reserveSquadsByWeapon)
  Computed(function() {
    let reserveV = reserve.get()
    let filterTextV = filterText.get()
    if (filterTextV == "")
      return reserveV

    let armyId = curArmy.get()
    let squads = {}
    let prefiltered = prefilteredSquads.get()
    foreach (squadName, squadIds in prefiltered.byNames[armyId]) {
      if (squadName.contains(filterTextV))
        squads.__update(squadIds)
    }

    foreach (weaponName, squadIds in reserveSquadsByWeapon.get()) {
      if (weaponName.contains(filterTextV))
        squads.__update(squadIds)
    }

    foreach (vehicleName, squadIds in prefiltered.byVehicles[armyId]) {
      if (vehicleName.contains(filterTextV))
        squads.__update(squadIds)
    }

    return reserveV.filter(function(squad) {
      let { squadId } = squad
      return squadId in squads
    })
  })

function filterWarning() {
  let watch = vehiclesFilterText

  return (vehiclesFilterText.get() == "")
    ? { watch }
    : {
        watch
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = const [FLEX, SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        color = attentionTxtColor
        text = loc("squads/filter/result")
      }.__update(fontSub)
}

function rightPanel(filteredReserveSquads, filteredLockedSquads) {
  let squadsBackIndex = Computed(function() {
    let indices = {}
    foreach (idx, squad in reserveSquads.get())
      indices[squad.guid] <-idx
    return indices
  })

  let panelHeader = mkHeadRightPanel()

  return function() {
    let sCount = slotsCount.get()
    let children = []
    let reserve = filteredReserveSquads.get()
    let squadsBackIndexVal = squadsBackIndex.get()
    let reserveChildren = reserve
      .map(@(squad) mkSquadSlot(squad, (squadsBackIndexVal?[squad.guid] ?? 0) + sCount, sCount, true))
    updateSquadsBR(reserve)

    if (reserveChildren.len() >= 0)
      children
        .append(chosenSquads.get().findvalue(@(squad) squad != null)
          ? dropToReserveContainer()
          : null)
        .extend(reserveChildren)

    let lockedChildren = filteredLockedSquads.get()
      .map(function(squad) {
        let { squadId, growthData, isPremium = false } = squad
        let { growthId = null, shopItemGuid = null } = growthData
        function onInfo() {
          let armyId = squadsArmy.get()
          openUnlockSquadScene(armyId, squadsCfgById.get()?[armyId][squadId])
        }

        let unlockObj = {
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          children = [
            shopItemGuid != null ? null : FAPrimary("info", onInfo, mkSlotFaBtnParams("btn/view"))
            growthId == null ? null : FAPrimary("arrow-right", function() {
              jumpToArmyGrowth(growthId)
              closeChooseSquadsWnd()
            }, mkSlotFaBtnParams("GoToGrowth"))
          ]
        }

        let obtainAction = isPremium && shopItemGuid != null
          ? @() buySquadWindow({
                  shopItem = shopItems.get()[shopItemGuid]
                  armyId = squadsArmy.get()
                  squadId
                })
          : growthData != null ? @() growthSquadMsgbox(growthData)
          : onInfo
        return mkHorizontalSlot(squad.__merge({
          guid = ""
          isLocked = true
          idx = -1
          onClick = obtainAction
          unlockObj
        }))
      })

    if (lockedChildren.len() > 0) {
      children
        .append(txt(loc("squads/lockedSquads", "Locked squads")))
        .extend(lockedChildren)
    }

    return panelBg.__merge({
      watch = [squadsBackIndex, slotsCount, filteredReserveSquads, filter, filteredLockedSquads, chosenSquads]
      children = [
        panelHeader
        {
          size = FLEX_V
          margin = [0, 0, smallOffset, 0]
          xmbNode = XmbContainer({
            canFocus = false
            scrollSpeed = 5.0
            isViewport = true
          })
          children = makeVertScroll({
            flow = FLOW_VERTICAL
            gap = midPadding
            children = children.append(filterWarning)
          },
          {
            size = FLEX_V
            styling = thinStyle
            scrollHandler = scrollHandlerRightPanel
          })
        }
        {
          size = FLEX_H
          margin = midPadding
          children = [
            promoWidget("squads_manage")
            buttonMassUnequip
          ]
        }
      ]
    })
  }
}

function mkRightPanel() {
  let weaponTypes = mkWeaponTypes()
  let itemNames = mkItemNames(weaponTypes)
  let reserveSquadsByWeapon = mkReserveSquadsByWeapon(itemNames)
  let prefilteredSquads = mkPrefilteredSquads(itemNames)
  let filterText = Computed(@() utf8ToLower(vehiclesFilterText.get().strip()))

  let curArmySquads = Computed(@() squadsCfgById.get()?[curArmy.get()])
  let reserve = Computed(@()
    getFilterSquads(reserveSquads.get(), filter.get(), curArmySquads.get(), favoriteSquads.get()))

  let shopSquads = Computed(function() {
    let result = {}
    foreach (item in curArmyItemsPrefiltered.get())
      foreach (squadInfo in item?.squads ?? []) {
        let { id } = squadInfo
        result[id] <- true
      }
    return result
  })

  let lockedSquads = Computed(function() {
    let shopSquadsV = shopSquads.get()
    return curArmyLockedSquadsData.get()
      .filter(@(s) s.growthData != null || s.squadId in shopSquadsV)
  })

  let locked = Computed(@() getFilterSquads(lockedSquads.get(),
    filter.get() , curArmySquads.get()))

  let filteredReserveSquads = mkFilteredReserveSquads(prefilteredSquads, filterText, reserve,
    reserveSquadsByWeapon)
  let filteredLockedSquads = mkFilteredLockedSquads(prefilteredSquads, filterText, locked)

  return rightPanel(filteredReserveSquads, filteredLockedSquads)
}

let mkAllSquadsList = @() {
  size = FLEX
  flow = FLOW_HORIZONTAL
  gap = bigPadding
  children = [
    leftPanel
    mkRightPanel()
  ]
}

let neededSquad = Computed(@() hoveredSquad.get() ?? selectedSquadId.get())

let needSquadInfoHotkeys = Computed(@() neededSquad.get() != null)

function squadInfoHotkeyHelper() {
  return {
    watch = needSquadInfoHotkeys
    hotkeys = needSquadInfoHotkeys.get()
      ? [["^J:Start", {
          description = loc("squads/squadInfo"),
          action = function() {
            let armyId = squadsArmy.get()
            openUnlockSquadScene(armyId, squadsCfgById.get()?[armyId][neededSquad.get()])
          }
        }]]
      : null
  }
}

function chooseSquadsScene() {
  let armyId = squadsArmy.get()
  let watch = [squadsArmy, safeAreaBorders]
  if (armyId == null)
    return { watch }

  return {
    watch
    size = const [sw(100), sh(100)]
    flow = FLOW_VERTICAL
    padding = safeAreaBorders.get()
    onDetach = @() markSeenSquads(armyId, (curArmyUnseenSquads.get() ?? {}).keys())
    children = [
      squadInfoHotkeyHelper
      mkHeader({
        armyId
        textLocId = "squads/manageTitle"
        addAfterText = mkPageButton(Tutorial.SQUADS).__update({padding = [0, bigPadding]})
        addToRight = currenciesWidgetUi
      })
      mkAllSquadsList()
    ]
  }
}

let isOpened = keepref(Computed(@() squadsArmy.get() != null))
let open = @() sceneWithCameraAdd(chooseSquadsScene, "soldiers")
if (isOpened.get())
  open()

isOpened.subscribe(function(v) {
  if (v == true)
    open()
  else
    sceneWithCameraRemove(chooseSquadsScene)
})

console_register_command(function() {
  massUnequipArmyReserve(reserveSquads.get(), soldiersBySquad.get(), armoryByArmy.get(), null)
}, "test.undressSquads")

console_register_command(function() {
  applyAndClose()
  joinQueue(currentGameMode.get())
}, "debug.closeSquadsAndJoin")
