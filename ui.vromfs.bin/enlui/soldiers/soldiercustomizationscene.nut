import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/components/mkHeader.nut" as mkHeader
import "%ui/currency/currenciesWidgetUi.nut" as currenciesWidgetUi
import "%ui/components/mkNameBlock.nut" as mkNameBlock
import "%ui/soldiers/mkCallnameBlock.nut" as mkCallnameBlock
import "%ui/soldiers/mkSoldierResideBlock.nut" as mkResideBlock
import "%ui/soldiers/components/unequipCustomizationWnd.nut" as unequipWndOpenBtn
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import horGap, emptyGap, largePadding, slotBaseSize, bigPadding,
  midPadding, soldierWndWidth, maxContentWidth, blurBgColor, blurBgFillColor
from "%ui/soldiers/model/state.nut" import curArmyData, curCampItemsCount, curSquad, armySquadsById
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfileLookCfg
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/soldiers/soldierCustomizationState.nut" import isCustomizationWndOpened, availableCItem,
  createItemsPerSlotWatch, saveOutfit, premiumItemsCount, curSoldierItemsPrice,
  itemsDisplayData, toDisplayData, customizedSoldierLocked
from "%ui/soldiers/squadOutfitPreview.nut" import mkOutfitBundles
from "%ui/meta/curCampaign.nut" import outfitCampaignsByArmies
from "%ui/soldiers/soldierCustomizationPkg.nut" import itemBlock, mkCustomizationSlot
from "%ui/mainMenu/mkMenuScene.nut" import mkMenuScene
from "%ui/components/textButton.nut" import Regular
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierInfo
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/components/mkCampaignSelector.nut" import mkOutfitsListButton
from "%ui/soldiers/model/config/outfitConfig.nut" import getSquadOutfit
from "%ui/meta/clientApi.nut" import set_squad_outfit_preset
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/soldiers/components/soldierCustomizationBuyWnd.nut" import multiApplyBtn, purchaseBtn,
  customizationCurrency
from "%ui/meta/tutorial/meta_tutorial_button.nut" import mkPageButton
from "%ui/meta/tutorial/meta_tutorial_config.nut" import Tutorial
from "%ui/ui_library.nut" import *

let closeButton = closeBtnBase({ onClick = @() saveOutfit() })

let chooseItemWrapParams = {
  width = slotBaseSize[0]
  vGap = midPadding
  hGap = midPadding
  halign = ALIGN_CENTER
}

function mkChooseItemBlock() {
  let itemsPerSlotWatch = createItemsPerSlotWatch()
  return function() {
    if (itemsPerSlotWatch.get().len() == 0)
      return { watch = itemsPerSlotWatch }

    let { guid } = curSoldierInfo.get()
    let prices = curSoldierItemsPrice.get()
    let itemsCount = premiumItemsCount.get()
    return {
      watch = [curSoldierInfo, itemsDisplayData, itemsPerSlotWatch,
        premiumItemsCount, curSoldierItemsPrice]
      size = [slotBaseSize[0], FLEX]
      rendObj = ROBJ_WORLD_BLUR_PANEL
      flow = FLOW_VERTICAL
      padding = [midPadding, 0]
      color = blurBgColor
      fillColor = blurBgFillColor
      stopMouse = true
      xmbNode = XmbContainer({
        canFocus = true
        scrollSpeed = 5.0
        isViewport = true
      })
      children = makeVertScroll(
        wrap(toDisplayData(itemsDisplayData.get(), itemsPerSlotWatch.get())
            .map(@(itemData) itemBlock(guid, itemData, prices, itemsCount)),
          chooseItemWrapParams),
        { size = FLEX_V, styling = thinStyle })
    }
  }
}

let lookWrapParams = {
  width = soldierWndWidth
  vGap = midPadding
}

let attachmentsHint = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = FLEX_H
  text = loc("appearance/attachments_override")
  halign = ALIGN_LEFT
}.__update(fontSub)

function mkLookCustomizationBlock() {
  let campaignOutfit = Computed(function() {
    let squadInfo = curSquad.get()
    let { squadId = null } = squadInfo
    if (squadId == null)
      return ""

    let armyId = getLinkedArmyName(squadInfo)
    return getSquadOutfit(armyId, squadId, armySquadsById.get(), gameProfileLookCfg.get())
  })

  let outfitList = Computed(function() {
    let squadInfo = curSquad.get()
    let armyId = getLinkedArmyName(squadInfo)
    return outfitCampaignsByArmies.get()?[armyId] ?? {}
  })

  return function() {
    let { guid } = curSquad.get()
    return {
      watch = [curSquad, availableCItem, curSoldierItemsPrice,
        customizedSoldierLocked]
      rendObj = ROBJ_WORLD_BLUR_PANEL
      color = blurBgColor
      fillColor = blurBgFillColor
      size = FLEX
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      padding = midPadding
      gap = midPadding
      children = [
        mkOutfitsListButton(
          outfitList,
          @(calleeCb) saveOutfit(false, calleeCb),
          campaignOutfit,
          @(campaignId) set_squad_outfit_preset(guid, campaignId))
        wrap(availableCItem.get().map(@(item)
          mkCustomizationSlot(item, curSoldierItemsPrice.get())),
          lookWrapParams)
        attachmentsHint
        !customizedSoldierLocked.get() ? multiApplyBtn : null
        unequipWndOpenBtn
      ]
    }
  }
}

let mkLeftCustomizationBlock = @() {
  size = [soldierWndWidth, FLEX]
  flow = FLOW_VERTICAL
  gap = midPadding
  children = [
    mkNameBlock(curSoldierInfo)
    mkLookCustomizationBlock()
    mkResideBlock(curSoldierInfo)
    mkCallnameBlock(curSoldierInfo)
  ]
}

let mkRightBlock = {
  size = FLEX
  halign = ALIGN_RIGHT
  children = [
    mkOutfitBundles
    {
      vplace = ALIGN_BOTTOM
      children = purchaseBtn
    }
  ]
}

let mkCentralBlock = @() {
  size = FLEX
  flow = FLOW_HORIZONTAL
  gap = midPadding
  children = [
    mkLeftCustomizationBlock()
    mkChooseItemBlock()
    mkRightBlock
  ]
}

let topBar = @() {
  watch = [curArmyData, curCampItemsCount]
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  margin = [largePadding, 0, 0, 0]
  gap = midPadding
  size = FLEX
  maxWidth = maxContentWidth
  children = [
    Regular(loc("BackBtn"), @() saveOutfit(), { margin = 0, hotkeys = [[$"^{JB.B}"]] })
    mkHeader({
      armyId = curArmyData.get()?.guid
      textLocId = loc("appearance/choose")
      addAfterText = mkPageButton(Tutorial.OUTFIT).__update({padding = [0, bigPadding]})
      addToRight = {
        size = FLEX_V
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        children = [
          currenciesWidgetUi
          horGap
          customizationCurrency
          emptyGap
        ]
      }
      closeButton
    })
  ]
}

let soldierCustomizationScene = {
  size = FLEX
  halign = ALIGN_CENTER
  key = "soldierCustomization"
  behavior = DngBhv.MenuCameraControl
  onDetach = @() isCustomizationWndOpened.set(false)
  children = mkMenuScene(topBar, mkCentralBlock(), { size = FLEX_H })
}


isCustomizationWndOpened.subscribe(function(flag) {
  if (flag)
    sceneWithCameraAdd(soldierCustomizationScene, "soldiers")
  else
    sceneWithCameraRemove(soldierCustomizationScene)
})
