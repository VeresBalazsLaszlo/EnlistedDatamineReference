import "%ui/helpers/icon3dByGameTemplate.nut" as icon3dByGameTemplate
import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/style/designConst.nut" import soldierWndWidth, midPadding, smallPadding, listCtors,
  slotBaseSize
from "%ui/style/cursors.nut" import setTooltip
from "%ui/meta/servProfile.nut" import soldiersLook
from "%ui/soldiers/soldierCustomizationState.nut" import currentItemPart, oldSoldiersLook,
  itemBlockOnClick, blockOnClick, customizationToApply
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierInfo
from "%ui/shop/currencyComp.nut" import mkItemCurrency
from "%ui/currency/currenciesComp.nut" import mkCurrency
from "%ui/currency/currenciesList.nut" import enlistedGold
from "%ui/scene/soldier_tools.nut" import appearanceToRender
from "%ui/ui_library.nut" import *

let listBgColor = listCtors.bgColor
let listTxtColor = listCtors.txtColor

const blockHeight = hdpx(124)
let blockWidth = (soldierWndWidth - midPadding * 3) / 2
const currencyIconSize = hdpxi(30)
const armorIconSize = hdpxi(22)


let itemParams = {
  width = blockWidth / 2
  hplace = ALIGN_LEFT
  height = blockHeight - hdpx(10)
}

let selectItemBlockWidth = slotBaseSize[0] - midPadding * 2
const purchaseItemBlockWidth = blockHeight

let selectingItemParams = {
  width = selectItemBlockWidth / 2
  height = blockHeight
  hplace = ALIGN_LEFT
}

let purchasingItemParams = {
  width = purchaseItemBlockWidth
  height = blockHeight
}

let mkPriceInteractive = @(currencyId, count, group, isSelected) watchElemState(@(sf){
  group
  children = currencyId == "EnlistedGold"
    ? mkCurrency({
        currency = enlistedGold
        price = count
        iconSize = currencyIconSize
        txtStyle = { color = listTxtColor(sf, isSelected) }
      })
    : mkItemCurrency({
        currencyTpl = currencyId
        count
        textStyle = { color = listTxtColor(sf, isSelected), fontSize = fontBody.fontSize }
      })
})

let priceBlock = @(itemPrice, params = {}) function(){
  let priceList = []
  let { isSelected = false, group = null } = params
  foreach (key, val in itemPrice) {
    if (key == "EnlistedGold")
      priceList.insert(0, mkPriceInteractive(key, val.price, group, isSelected))
    else
      priceList.append(mkPriceInteractive(key, val.price, group, isSelected))
  }
  return priceList.len() <= 0 ? null
    : {
        flow = FLOW_HORIZONTAL
        gap = hdpx(20)
        children = priceList
        vplace = ALIGN_BOTTOM
        valign = ALIGN_CENTER
      }
}

let armorIcon = @(hasArmor, color) !hasArmor ? null : {
    rendObj = ROBJ_IMAGE
    size = const [armorIconSize, armorIconSize]
    image = Picture("ui/skin#shield_icon.svg:{0}:{0}".subst(armorIconSize))
    keepAspect = true
    color
  }

let mkTooltip = @(hasArmor) !hasArmor ? null
  : @(on) setTooltip(on ? loc("appearance/extraArmor") : null)

function mkCustomizationSlot(itemToShow, itemsPrices) {
  let { slotName, iconAttachments, item, locId, gametemplate, hasArmor } = itemToShow
  let group = ElemGroup()
  let itemPrice = itemsPrices?[item] ?? {}
  let onHover = mkTooltip(hasArmor)
  let icon = icon3dByGameTemplate(gametemplate, itemParams.__merge({
    genOverride = { iconAttachments }
    shading = "same"
  }))

  return watchElemState(function(sf) {
    let { armyId = null, guid = null } = curSoldierInfo.get()
    let isSelected = slotName == currentItemPart.get()
    let color = listTxtColor(sf, isSelected)
    return armyId == null || guid == null ? null : {
      watch = [currentItemPart, curSoldierInfo]
      rendObj = ROBJ_SOLID
      size = [blockWidth, blockHeight]
      margin = [0, midPadding]
      onClick = @() blockOnClick(slotName)
      onHover
      halign = ALIGN_RIGHT
      behavior = Behaviors.Button
      color = listBgColor(sf, isSelected)
      group
      children = [
        {
          flow = FLOW_HORIZONTAL
          gap = smallPadding
          margin = smallPadding
          children = [
            {
              rendObj = ROBJ_TEXT
              color
              text = loc(locId)
            }
            armorIcon(hasArmor, color)
          ]
        }
        icon
        currentItemPart.get() == ""
          ? null
          : priceBlock(itemPrice, {
              vplace = ALIGN_BOTTOM
              padding = [smallPadding, 0]
              group
              isSelected
            })
      ]}
  })
}

function mkPrice(currencyId, count, style){
  if (currencyId == "EnlistedGold")
    return mkCurrency({
      currency = enlistedGold
      price = count
      iconSize = currencyIconSize
    }.__update({ txtStyle = style }))

  return mkItemCurrency({
    currencyTpl = currencyId
    count
    textStyle = style.__update({ fontSize = fontBody.fontSize })
  })
}

let removeBtn = @(item, removeAction) watchElemState(@(sf){
  size = FLEX_H
  behavior = Behaviors.Button
  padding = smallPadding
  valign = ALIGN_CENTER
  onClick = @() removeAction(item)
  rendObj =  ROBJ_SOLID
  color = listBgColor(sf)
  children = [
    faComp("close", {
      fontSize = hdpx(12)
      color = listTxtColor(sf)
    })
    {
      rendObj = ROBJ_TEXT
      hplace = ALIGN_RIGHT
      color = listTxtColor(sf)
      text = loc("appearance/deselect")
    }
  ]
})

let defaultItemTitle = @(sf, isSelected){
  rendObj = ROBJ_TEXT
  text = loc("appearance/default_item")
  hplace = ALIGN_RIGHT
  color = listTxtColor(sf, isSelected)
}

let emptySlotTitle = @(sf, isSelected){
  rendObj = ROBJ_TEXT
  text = loc("appearance/empty_slot")
  hplace = ALIGN_RIGHT
  color = listTxtColor(sf, isSelected)
}

let amountText = @(count, sf = 0, isSelected = false) {
  padding = [smallPadding, 2 * smallPadding]
  rendObj = ROBJ_TEXT
  color = listTxtColor(sf, isSelected)
  text = loc("common/amountShort", { count })
}.__update(fontSub)

function selectingItemBlock(item, premiumItemsCount, itemPrice, soldierGuid, isSelected) {
  let { gametemplate = null, iconAttachments = [], hasArmor = false, itemId = "" } = item
  let group = ElemGroup()
  let isDefaultItem = soldiersLook.get()[soldierGuid].items.hasvalue(itemId)
  let isEmptySlot = gametemplate == null
  let rightTopInfo = @(sf, isSel) isEmptySlot
    ? emptySlotTitle(sf, isSel)
    : isDefaultItem
      ? defaultItemTitle(sf, isSel)
      : (premiumItemsCount?[itemId] ?? 0) > 1
        ? amountText(premiumItemsCount[itemId], sf, isSel)
        : null

  let setArmorTooltip = mkTooltip(hasArmor)

  return watchElemState(@(sf){
    watch = soldiersLook
    size = [selectItemBlockWidth, blockHeight]
    rendObj = ROBJ_SOLID
    padding = midPadding
    xmbNode = XmbNode()
    behavior = Behaviors.Button
    sound = {
      hover = "ui/enlist/button_highlight"
      click = "ui/enlist/button_click"
      active = "ui/enlist/button_action"
    }
    halign = ALIGN_RIGHT
    color = listBgColor(sf, isSelected)
    transitions = [
      { prop=AnimProp.color, duration = 0.2 }
    ]
    onClick = @() itemBlockOnClick(itemId)
    group
    onHover = function(hovered) {
      setArmorTooltip?(hovered)

      let currentSlot = currentItemPart.get()
      local res = (clone appearanceToRender.get()) ?? {}
      let itemToShow = hovered
        ? itemId
        : customizationToApply.get()?[currentSlot]

      if (itemToShow == null || itemToShow == oldSoldiersLook.get()?[currentSlot]) {
        if (currentSlot in res) {
          
          
          res.$rawdelete(currentSlot)
        }
      }
      else
        res[currentSlot] <- itemToShow

      appearanceToRender.set(res)
    }

    children = [
      icon3dByGameTemplate(gametemplate, selectingItemParams.__merge({
        genOverride = { iconAttachments }
        shading = "same"
      }))
      {
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = [
          rightTopInfo(sf, isSelected)
          armorIcon(hasArmor, listTxtColor(sf, isSelected))
        ]
      }
      priceBlock(itemPrice, {
        vplace = ALIGN_BOTTOM
        isSelected
        group
      })
    ]
  })
}

function purchasingItemBlock(itemData, premiumItemsCount, itemPrice, removeAction) {
  let { gametemplate = null, iconAttachments = [], itemId = "" } = itemData
  let count = premiumItemsCount?[itemId] ?? 0
  let icon = icon3dByGameTemplate(gametemplate, purchasingItemParams.__merge({
    genOverride = { iconAttachments }
    shading = "same"
  }))
  return watchElemState(@(sf) {
    flow = FLOW_VERTICAL
    gap = smallPadding
    halign = ALIGN_CENTER
    children = [
      {
        size = const [blockHeight, blockHeight]
        rendObj = ROBJ_SOLID
        color = listBgColor(sf)
        padding = smallPadding
        children = [
          count <= 1 ? null : amountText(count, sf)
          icon
        ]
      }
      priceBlock(itemPrice)
      removeBtn(itemId, removeAction)
    ]
  })
}


function itemBlock(soldierGuid, itemData, itemsPrices, premiumItemsCount, removeAction = null) {
  let { itemSlot = "", itemId = "" } = itemData
  let itemPrice = itemsPrices?[itemId] ?? {}

  let isSelected = Computed(function() {
    let curItemIdCheck = customizationToApply.get()?[itemSlot] ?? oldSoldiersLook.get()?[itemSlot]
    return removeAction == null && curItemIdCheck == itemId
  })

  return @() {
    watch = isSelected
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      removeAction == null
        ? selectingItemBlock(itemData, premiumItemsCount, itemPrice, soldierGuid, isSelected.get())
        : purchasingItemBlock(itemData, premiumItemsCount, itemPrice, removeAction)
    ]
  }
}


return {
  itemBlock
  mkCustomizationSlot
  mkPrice
  amountText
  armorIcon
}
