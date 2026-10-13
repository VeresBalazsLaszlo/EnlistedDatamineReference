import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/closeBtn.nut" as closeBtnBase
from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/style/designConst.nut" import midPadding, maxContentWidth, commonBtnHeight,
  titleTxtColor, blurBgColor, blurBgFillColor, bigPadding
from "%ui/components/textButton.nut" import Regular, Primary
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/soldiers/soldierCustomizationState.nut" import campaignOutfit, isCustomizationWndOpened,
  closeCustomizationWnd, getIconDataFromTemplate, collectItemsBySoldierGuids, mkOutfitRequestData,
  oldSoldiersLook, customizationToApply
from "%ui/soldiers/soldierCustomizationPkg.nut" import itemBlock
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierInfo
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/soldiers/model/state.nut" import curSquadSoldiersInfo
from "%ui/meta/configs.nut" import serverConfigs
from "%ui/soldiers/model/config/outfitConfig.nut" import equippedOutfitsForArmy
from "%ui/meta/clientApi.nut" import change_outfit_squad
from "%ui/ui_library.nut" import *


const UNEQUIP_WND_UID = "UNEQUIP_WND_UID"

const verticalGap = midPadding * 2
const wndWidth = min(sw(40), maxContentWidth) - hdpx(75) * 2


let isUnequipWndOpened = Watched(false)
let itemsInUnequipWnd = Watched({})

let closeUnequipWnd = @() isUnequipWndOpened.set(false)

itemsInUnequipWnd.subscribe(function(v) {
  if (v.len() == 0)
    closeUnequipWnd()
})

let squadCustomizationItems = Computed(function() {
  if (!isCustomizationWndOpened.get())
    return {}

  return collectItemsBySoldierGuids(curSquadSoldiersInfo.get(),
    serverConfigs.get(), equippedOutfitsForArmy.get(), campaignOutfit.get())
})

function removeItem(basetpl) {
  itemsInUnequipWnd.mutate(@(v) v.$rawdelete(basetpl))
  if (itemsInUnequipWnd.get().len() == 0)
    closeUnequipWnd()
}

function openUnequipWnd() {
  itemsInUnequipWnd.set(squadCustomizationItems.get().reduce(
    function(res, itemsInSlots) {
      foreach (basetpl in itemsInSlots)
        res[basetpl] <- (res?[basetpl] ?? 0) + 1
      return res
    }, {}))
  isUnequipWndOpened.set(true)
}

let wndHeader = {
  size = FLEX_H
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("appearance/headerUnequip")
      color = titleTxtColor
      hplace = ALIGN_CENTER
    }.__update(fontHeading2)
    {
      children = closeBtnBase({ onClick = closeUnequipWnd })
      hplace = ALIGN_RIGHT
    }
  ]
}

const wrapParams = {
  width = wndWidth
  halign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  vGap = verticalGap
  hGap = verticalGap
}

function wndContent() {
  let watch = [curSoldierInfo, itemsInUnequipWnd, allItemTemplates]
  let { guid = null, armyId = null } = curSoldierInfo.get()
  if (guid == null || armyId == null)
    return { watch }

  let itemsToShow = itemsInUnequipWnd.get()
  let prices = {} 
  let itemTemplatesVal = allItemTemplates.get()
  return {
    watch
    size = const [wndWidth, SIZE_TO_CONTENT]
    padding = const [verticalGap, 0]
    gap = verticalGap
    flow = FLOW_VERTICAL
    children = [
      wrap(itemsToShow.keys().map(function(itemId) {
        let itemData = getIconDataFromTemplate(itemTemplatesVal, armyId, itemId).__merge({ itemSlot = "", itemId })
        return itemBlock(guid, itemData, prices, itemsToShow, removeItem)
      }), wrapParams)
    ]
  }
}

function unequipOutfit() {
  let requestData = mkOutfitRequestData(squadCustomizationItems.get(), itemsInUnequipWnd.get())
  change_outfit_squad(requestData, campaignOutfit.get())
  closeCustomizationWnd()
  closeUnequipWnd()
}

function applyBtnBlock() {
  let btnsBlock = []
  if (itemsInUnequipWnd.get().len() > 0)
    btnsBlock.append(Primary(loc("equip/quickUnequip"), unequipOutfit, { hotkeys = [["^J:Y"]] }))

  btnsBlock.append(Regular(loc("Cancel"), closeUnequipWnd, { hotkeys = [[$"^{JB.B} | Esc"]] }))
  return {
    watch = itemsInUnequipWnd
    size = const [FLEX, hdpx(100)]
    valign = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    halign = ALIGN_CENTER
    gap = bigPadding
    children = btnsBlock
  }
}

isUnequipWndOpened.subscribe(function(val) {
  if (!val) {
    removeModalWindow(UNEQUIP_WND_UID)
    return
  }

  addModalWindow({
    key = UNEQUIP_WND_UID
    rendObj = ROBJ_WORLD_BLUR_PANEL
    size = FLEX
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    onClick = @() null
    children = {
      rendObj = ROBJ_WORLD_BLUR_PANEL
      size = FLEX_H
      color = blurBgColor
      fillColor = blurBgFillColor
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      children = {
        size = FLEX_H
        maxWidth = maxContentWidth
        padding = hdpx(75)
        flow = FLOW_VERTICAL
        halign = ALIGN_CENTER
        gap = verticalGap
        children = [
          wndHeader
          wndContent
          applyBtnBlock
        ]
      }
    }
  })
})

let hasChanges = Computed(function() {
  let oldLook = oldSoldiersLook.get()
  return customizationToApply.get()
    .findindex(@(item, slot) item != oldLook?[slot]) != null
})

function unequip() {
  if (hasChanges.get())
    customizationToApply.set({})
  openUnequipWnd()
}

let unequipCustomizationBtn = @() squadCustomizationItems.get().len() == 0 && !hasChanges.get()
  ? { watch = [hasChanges, squadCustomizationItems] }
  : {
      watch = [hasChanges, squadCustomizationItems]
      size = [FLEX, commonBtnHeight]
      children = Regular(loc("appearance/unequipBtn"),
        unequip,
        {
          size = [FLEX, commonBtnHeight]
          hotkeys = [["^J:X"]]
        })
    }

return unequipCustomizationBtn
