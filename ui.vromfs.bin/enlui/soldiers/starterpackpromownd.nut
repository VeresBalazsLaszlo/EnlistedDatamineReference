import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/components/colorize.nut" as colorize
import "%ui/components/faComp.nut" as faComp
import "%ui/soldiers/components/viewItemScene.nut" as viewItemScene
from "%ui/style/fontsStyle.nut" import fontHeading1, fontHeading2, fontBody
from "%ui/style/designConst.nut" import midPadding, titleTxtColor, defTxtColor, maxContentWidth, accentTitleTxtColor, commonBtnHeight
from "%ui/shop/armyShopState.nut" import shopItemContentArrayCtor
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, primeFlagStyle
from "%ui/currency/premiumComp.nut" import premiumImage
from "%ui/currency/currenciesComp.nut" import mkCurrencyImg
from "%ui/components/soldierClasses.nut" import getClassCfg
from "%sqstd/string.nut" import utf8ToUpper
from "%sqstd/math.nut" import getRomanNumeral
from "%ui/components/soldiersUiComps.nut" import kindIcon, className
from "%ui/currency/currenciesList.nut" import enlistedGold
from "%ui/soldiers/components/itemTypesData.nut" import itemTypeIcon
from "%ui/components/itemsInfo.nut" import itemNameFromTemplate, iconByGameTemplate
from "%ui/helpers/gradients.nut" import mkColoredGradientY
from "%ui/state/safeArea.nut" import safeAreaVerPadding, safeAreaHorPadding
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, findItemTemplate
from "%ui/soldiers/model/items_list_lib.nut" import mkShopItem
from "%ui/soldiers/components/campaignPromoPkg.nut" import weapInfoBtn
from "%ui/navState.nut" import addScene, removeScene
from "%ui/components/textButton.nut" import Purchase
from "%ui/shop/buyShopItemExternal.nut" import openPurchaseLink, canPurchaseExternal
from "%ui/ui_library.nut" import *

const wndContentWidth = fsh(120)
const WND_UID = "STARTER_PACK_PROMO"
const ENLISTED_GOLD_BONUS = "300"
const iconSize = hdpxi(40)
const infoBlockPadding = fsh(3)
const smallBlockPadding = fsh(1)
let weaponBlockSize = [hdpx(330), hdpx(110)]


let starterPack = Watched(null)
let crateContent = shopItemContentArrayCtor(starterPack)


let blockHeaderStyle = freeze({ color = accentTitleTxtColor }.__update(fontHeading2))
let defTxtStyle = freeze({ color = titleTxtColor }.__update(fontBody))
let bottomGradient = mkColoredGradientY({colorTop=0x00000000, colorBottom=0xFF000000})

let mkTextArea = @(text, override = {}) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = FLEX_H
  text
}.__update(override)


let closeButton = closeBtnBase({
  onClick = @() starterPack.set(null),
  hplace = ALIGN_RIGHT,
  vplace = ALIGN_TOP
})

let wndHeader = mkHeaderFlag(
  {
    rendObj = ROBJ_TEXT
    hplace = ALIGN_LEFT
    padding = const [fsh(2), fsh(3)]
    text = utf8ToUpper(loc("shop/starter_pack"))
  }.__update(fontHeading1),
  primeFlagStyle
)


let headerWndBlock = {
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = midPadding
  children = [
    wndHeader
    @() {
      watch = starterPack
      rendObj = ROBJ_TEXT
      padding = midPadding
      text = loc(starterPack.get()?.nameLocId)
    }.__update(defTxtStyle)
  ]
}


let blockHeader = @(text) mkTextArea(text, blockHeaderStyle)


let currencyText = mkTextArea(loc("enlistedGold", {
  count = colorize(accentTitleTxtColor, ENLISTED_GOLD_BONUS)}), defTxtStyle)
let premiumText = @(days) days <= 0 ? null
  : mkTextArea(loc("premium/days", { days = colorize(accentTitleTxtColor, days)}), defTxtStyle)


function accountFeatures() {
  return {
    size = FLEX
    flow = FLOW_VERTICAL
    gap = smallBlockPadding
    vplace = ALIGN_CENTER
    padding = const [0, infoBlockPadding]
    children = [
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = midPadding
        children = [
          mkCurrencyImg(enlistedGold, iconSize)
          premiumImage(iconSize)
        ]
      }
      @() {
        watch = starterPack
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = midPadding
        children = [
          currencyText
          premiumText(starterPack.get()?.premiumDays ?? 0)
        ]
      }
    ]
  }
}



let mkSClassRow = @(sClass, tier) @() {
  watch = sClassesCfg
  flow = FLOW_HORIZONTAL
  gap = midPadding
  valign = ALIGN_CENTER
  children = [
    kindIcon(sClassesCfg.get()?[sClass].kind ?? sClass, defTxtStyle.fontSize, defTxtStyle.color)
    className(sClass).__update(defTxtStyle)
    {
      rendObj = ROBJ_TEXT
      text = tier
    }.__update(defTxtStyle)
  ]
}


function mkSoldierInfo(crate) {
  if (crate == null)
    return null
  let { armyId = null, content = null } = crate
  let { soldierClasses = [] } = content
  if (soldierClasses.len() <= 0)
    return null
  let sClasses = soldierClasses.reduce(function(res, sClass) {
    let { locId = "" } = getClassCfg(sClass)
    if (locId != "")
      res.append({
        sClass = sClass
        sortLoc = loc(locId)
      })
    return res
  }, [])
    .sort(@(a, b) a.sortLoc <=> b.sortLoc)
    .map(@(s) s.sClass)
  let { soldierTierMin = 0, soldierTierMax = 0} = content
  let tiersText = soldierTierMin == soldierTierMax ? getRomanNumeral(soldierTierMin)
    : $"{getRomanNumeral(soldierTierMin)}-{getRomanNumeral(soldierTierMax)}"
  return {
    size = FLEX
    flow = FLOW_VERTICAL
    gap = smallBlockPadding
    padding = const [0, infoBlockPadding]
    children = soldierClasses.len() <= 0 ? null : [
      blockHeader(loc($"{armyId}/full"))
      {
        flow = FLOW_VERTICAL
        children = sClasses.map(@(sClass) mkSClassRow(sClass, tiersText))
      }
    ]
  }
}


let mkItemRow = @(item) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = midPadding
  valign = ALIGN_CENTER
  children = [
    itemTypeIcon(item?.itemtype, item?.itemsubtype)
    {
      rendObj = ROBJ_TEXT
      text = itemNameFromTemplate(item)
    }.__update(defTxtStyle)
  ]
}


let itemsInfo = @(crate) (crate == null || (crate?.content.items.len() ?? 0) == 0) ? null
  : function() {
  let { armyId = null, content = null } = crate
  let { items = {} } = content
  let itemTemplatesVal = allItemTemplates.get()
  let children = items.keys().reduce(function(res, val) {
      let item = findItemTemplate(itemTemplatesVal, armyId, val)
      if (item != null && item?.growthTier == null)
        res.append(mkItemRow(item))
      return res
    }, [])
  return {
    watch = allItemTemplates
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = smallBlockPadding
    padding = const [0, infoBlockPadding]
    children = [
      blockHeader(loc("starterPack/eachArmy"))
      {
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = midPadding
        children
      }
    ]
  }
}

let featuresGap = {
  size = const [hdpx(1), FLEX]
  rendObj = ROBJ_SOLID
  color = 0xCCFFFFFF
}

let featuresBlock = @() {
  watch = crateContent
  size = const [FLEX, hdpx(180)]
  flow = FLOW_HORIZONTAL
  gap = featuresGap
  children = [accountFeatures]
    .extend(crateContent.get().map(mkSoldierInfo))
    .append(itemsInfo(crateContent.get()?[0]))
}

let cratePlusSign = faComp("plus", {
  color = defTxtStyle.color
  fontSize = defTxtStyle.fontSize
})

let mkCrateWeapon = @(crate) function() {
  let { armyId = null, content = {} } = crate
  let { items = {} } = content
  let itemTemplatesVal = allItemTemplates.get()
  let weapons = items.keys().reduce(function(res, val) {
    let item = findItemTemplate(itemTemplatesVal, armyId, val)
    if (item?.growthTier != null)
      res.append(item.__merge({ itemId = val }))
    return res
  }, [])
  return {
    watch = allItemTemplates
    size = [weaponBlockSize[0], SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = {
      padding = midPadding
      vplace = ALIGN_CENTER
      children = cratePlusSign
    }
    children = weapons.map(function(w) {
      let itemToView = mkShopItem(w.itemId, w, armyId)
      let icon = iconByGameTemplate(w.gametemplate, {
        width = weaponBlockSize[0]/1.5
        height = weaponBlockSize[1]
      })
      return {
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = midPadding
        halign = ALIGN_CENTER
        children = [
          watchElemState(@(sf){
            rendObj = ROBJ_BOX
            size = weaponBlockSize
            behavior = Behaviors.Button
            onClick = function() {
              viewItemScene(itemToView)
            }
            borderWidth = hdpx(1)
            halign = ALIGN_CENTER
            valign = ALIGN_CENTER
            fillColor = sf & S_HOVER ? 0x00333333 : 0xFF000000
            borderColor = sf & S_HOVER ? titleTxtColor : defTxtColor
            children = [
              icon
              weapInfoBtn(sf)
            ]
          })
          {
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            size = FLEX_H
            text = itemNameFromTemplate(w)
            halign = ALIGN_CENTER
          }.__update(defTxtStyle)
        ]
      }
    })
  }
}

let weaponsPlusSign = faComp("plus", {
  color = accentTitleTxtColor
  fontSize = fontHeading1.fontSize
  pos = [0, weaponBlockSize[1]/2 - fontHeading1.fontSize / 2]
  padding = const [0, smallBlockPadding]
})

function weaponsBlock() {
  let hasNoItem = crateContent.get().findvalue(@(v) (v?.content.items.len() ?? 0) > 0) == null
  return {
    watch = crateContent
    flow = FLOW_HORIZONTAL
    gap = weaponsPlusSign
    children = hasNoItem ? null : crateContent.get().map(mkCrateWeapon)
  }
}

let purchaseButton = @() {
  watch = starterPack
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  children = Purchase(loc("starterPack/purchase"), @() openPurchaseLink(starterPack.get()), {
    style = { size = [SIZE_TO_CONTENT, commonBtnHeight] }
    isEnabled = canPurchaseExternal(starterPack.get())
  })
}


let bottomWndBlock = {
  size = const [wndContentWidth, fsh(60)]
  vplace = ALIGN_BOTTOM
  children = [
    {
      size = FLEX
      flow = FLOW_VERTICAL
      gap = fsh(6)
      children = [
        headerWndBlock
        featuresBlock
        weaponsBlock
      ]
    }
    purchaseButton
  ]
}


let wndContent = {
  size = FLEX
  halign = ALIGN_CENTER
  maxWidth = maxContentWidth
  children = [
    @() {
      watch = starterPack
      rendObj = ROBJ_IMAGE
      size = const [wndContentWidth, FLEX]
      image = Picture(starterPack.get()?.image ?? "ui/gameImage/premium_bg.avif")
      imageValign = ALIGN_TOP
      keepAspect = true
    }
    {
      size = const [wndContentWidth, fsh(80)]
      rendObj = ROBJ_IMAGE
      image = bottomGradient
      vplace = ALIGN_BOTTOM
    }
    @() {
      watch = [safeAreaVerPadding, safeAreaHorPadding]
      size = FLEX
      padding = [max(safeAreaVerPadding.get(), fsh(2)), max(safeAreaHorPadding.get(), fsh(2))]
      margin = const [0, 0, hdpx(40), 0]
      vplace = ALIGN_BOTTOM
      halign = ALIGN_CENTER
      children = [
        bottomWndBlock
        closeButton
      ]
    }
  ]
}


let scene = {
  size = FLEX
  key = WND_UID
  rendObj = ROBJ_SOLID
  color = 0xFF000000
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  onClick = @() null
  children = wndContent
}


starterPack.subscribe(@(v) v != null ? addScene(scene) : removeScene(scene))


return starterPack

