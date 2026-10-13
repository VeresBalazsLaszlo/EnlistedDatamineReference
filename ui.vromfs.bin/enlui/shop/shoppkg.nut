import "%ui/vehicles/allowedVehicles.nut" as allowedVehicles
import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/components/faComp.nut" as faComp
import "%ui/components/textButtonTextCtor.nut" as textButtonTextCtor
import "%ui/components/spinner.nut" as spinner
import "%ui/soldiers/model/equipClassSchemes.nut" as getEquipClasses
from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/shop/mkShopItemPrice.nut" import mkShopItemPrice
from "%ui/soldiers/components/itemTypesData.nut" import itemTypeIcon
from "%ui/components/soldierClasses.nut" import getClassCfg, getKindCfg, soldierKindsList
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix, itemNameFromTemplate
from "%ui/mainMenu/sectionsState.nut" import jumpToArmyGrowth, jumpToArmyGrowthTier
from "%ui/style/designConst.nut" import defBgColor, midPadding, smallPadding, defTxtColor,
  idleBgColor, mkTimerIcon, darkTxtColor, attentionTxtColor, negativeTxtColor
from "%ui/components/soldiersUiComps.nut" import kindIcon
from "%ui/components/textButton.style.nut" import TextNormal, textMargin
from "%ui/components/squadsUiComps.nut" import mkSquadIcon, mkRentInfo
from "%ui/soldiers/model/state.nut" import armySquadsById, lockedArmySquadsById
from "%ui/shop/currencyComp.nut" import mkDiscountWidget
from "%ui/helpers/time.nut" import secondsToHoursLoc
from "%ui/shop/mkCounter.nut" import mkCounter
from "%ui/shop/armyShopState.nut" import shopItemContentCtor, isContentSoldier
from "%ui/soldiers/model/reserve.nut" import curArmyReserve, curArmyReserveCapacity
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, getTierInterval,
  findItemTemplate
from "%ui/components/mkHeaderFlag.nut" import mkRightHeaderFlag, primeFlagStyle
from "%ui/components/mkSpecialItemIcon.nut" import bpIcon
from "%sqstd/math.nut" import getRomanNumeral
from "%ui/growth/growthState.nut" import GrowthStatus
from "%ui/ui_library.nut" import *

const DISCOUNT_WARN_TIME = 600

let cardPreviewSize = const [fsh(45), fsh(30)]
let cardSquadPreviewSize = const [fsh(60), fsh(30)]
let timerSize = fontSub.fontSize
let alertTxtStyle = const { color = attentionTxtColor }.__merge(fontSub)

let mkPurchaseSpinner = @(shopItem, purchasingItem) @() {
  watch = purchasingItem
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = purchasingItem.get() == shopItem ? spinner(hdpx(40), 0.7) : null
}

let mkShopItemImg = @(img, override = {}) (img ?? "").len()  == 0 ? null
  : {
      rendObj = ROBJ_IMAGE
      size = FLEX
      keepAspect = KEEP_ASPECT_FILL
      image = Picture(img)
    }.__update(override)

let mkShopItemVideo = @(uri) {
  size = FLEX
  keepAspect = KEEP_ASPECT_FILL
  rendObj = ROBJ_MOVIE
  movie = uri
  behavior = Behaviors.Movie
}

function mkShopItemPriceLine(shopItem, personalOffer = null, isNarrow = false, showInStock = true) {
  let children = mkShopItemPrice(shopItem, personalOffer, isNarrow, showInStock)
  return !children ? null : {
    rendObj = ROBJ_SOLID
    size = FLEX_H
    color = Color(40,40,40,255)
    valign = ALIGN_CENTER
    children
  }
}

let itemHighlight = @(trigger){
  size = FLEX
  rendObj = ROBJ_BOX
  borderWidth = hdpx(8)
  borderColor = 0xFFFFFF
  opacity = 0
  transform = true
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 1, trigger, easing = Blink }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 1, delay = 1, trigger, easing = Blink }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 1, delay = 2, trigger, easing = Blink }
  ]
}

const infoBtnSize = hdpxi(30)
const hoveredInfoBtnSize = hdpxi(33)

let mkInfoBtn = @(onClick) watchElemState(function(sf) {
  let size = sf & S_HOVER ? hoveredInfoBtnSize : infoBtnSize
  return {
    hplace = ALIGN_LEFT
    margin = fsh(1)
    behavior = Behaviors.Button
    onClick
    children = {
      rendObj = ROBJ_IMAGE
      size = array(2, size)
      image = Picture($"ui/skin#info/info_icon.svg:{size}:{size}")
    }
  }
})

let mkViewCrateBtn = @(crateContentWatch, onCrateViewCb)
  crateContentWatch == null || onCrateViewCb == null ? null
    : @() {
        watch = crateContentWatch
        hplace = ALIGN_LEFT
        children = (crateContentWatch.get()?.content.items.len() ?? 0) == 0 ? null
          : mkInfoBtn(onCrateViewCb)
      }

function extractItems(crateContent) {
  let { items = {} } = crateContent?.get().content
  let res = {}
  foreach (tmpl, _ in items)
    res[trimUpgradeSuffix(tmpl)] <- true
  return res.keys()
}

function extractClasses(crateContent) {
  let { soldierClasses = [] } = crateContent?.get().content
  let res = {}
  foreach (sClass in soldierClasses)
    res[getClassCfg(sClass).kind] <- true
  return res.keys()
}

let mkForVehicleSquad = @(squad, isUnlocked) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_CENTER
  gap = midPadding
  valign = ALIGN_CENTER
  children = [
    mkSquadIcon(squad?.icon, { size = hdpx(80), margin = smallPadding })
    {
      size = FLEX_H
      valign = ALIGN_CENTER
      halign = ALIGN_LEFT
      flow = FLOW_VERTICAL
      gap = midPadding
      children = [
        {
          rendObj = ROBJ_TEXTAREA
          size = FLEX_H
          behavior = Behaviors.TextArea
          color = defTxtColor
          text = loc(squad?.manageLocId ?? "")
        }.__update(fontBody)
        isUnlocked ? null
          : {
              rendObj = ROBJ_TEXT
              color = negativeTxtColor
              text = loc("shop/no_squad")
            }
      ]
    }
  ]
}

function mkSquadUsageKind(squadId, armyId) {
  local squad = armySquadsById.get()?[armyId][squadId]
  let isUnlocked = squad != null
  if (!isUnlocked)
    squad = lockedArmySquadsById.get()?[armyId][squadId]
      ?? getSquadPresentation(squadId, armyId)

  return !squad ? null : {
    rendObj = ROBJ_SOLID
    size = FLEX_H
    padding = midPadding
    color = defBgColor
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = mkForVehicleSquad(squad, isUnlocked)
  }
}


function mkClassCanUse(basetpl, armyId, templates) {
  let { itemtype = null, isFixed = false } = templates?[basetpl]
  if (isFixed)
    return {
      rendObj = ROBJ_TEXTAREA
      size = FLEX_H
      behavior = Behaviors.TextArea
      text = loc("shop/fixedItem")
    }

  if (itemtype == "vehicle") {
    let vehicleSquadIds = (allowedVehicles.get()?[armyId] ?? {})
      .filter(@(squad) squad?[basetpl]).keys()
    let squadsCount = vehicleSquadIds.len()
    return squadsCount == 0 ? null : {
      size = FLEX_H
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      gap = smallPadding
      children = [
        {
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          halign = ALIGN_CENTER
          size = FLEX_H
          text = loc("shop/squadsCanUse", { squadsCount })
        }.__update(fontBody)
      ].extend(vehicleSquadIds.map(@(squadId) mkSquadUsageKind(squadId, armyId)))
    }
  }

  let kindsList = getEquipClasses(armyId, basetpl, itemtype)
    .reduce(function(tbl, sClass) {
      let { kind, isPremium = false, isEvent = false } = getClassCfg(sClass)
      if (!isPremium && !isEvent)
        tbl[kind] <- true
      return tbl
    }, {})
    .keys()
  let count = kindsList.len()
  if (count == 0)
    return null

  let tShopCanUse = count == soldierKindsList.len()
    ? loc("shop/allCanUse")
    : loc("shop/someCanUse",
        { classes = ", ".join(kindsList.map(@(sKind) loc(getKindCfg(sKind).locId))) })
  return {
    rendObj = ROBJ_TEXTAREA
    size = FLEX_H
    behavior = Behaviors.TextArea
    text = tShopCanUse
  }
}

let mkClassCanUseCenter = @(crateContent) function() {
  let watch = [allItemTemplates, crateContent]
  let itemsList = extractItems(crateContent) ?? []
  if (itemsList.len() != 1)
    return { watch }

  let { armyId = null } = crateContent.get()
  let templates = allItemTemplates.get()?[armyId]
  let basetpl = itemsList[0]
  let classesCmp = mkClassCanUse(basetpl, armyId, templates)
  if (classesCmp == null)
    return { watch }

  return classesCmp.__update({
    watch
    halign = ALIGN_CENTER
  })
}

let mkShopItemInfoTier = @(minTier, maxTier, override = {})
  maxTier <= 0 || maxTier <= minTier ? null
    : {
        rendObj = ROBJ_TEXTAREA
        size = FLEX_H
        behavior = Behaviors.TextArea
        text = loc("shop/upgradeLevel", { maxUpgrade = maxTier, minUpgrade = minTier })
      }.__update(fontSub, override)

let mkShopItemInfoBlock = @(crateContent) function() {
  let watch = [allItemTemplates, crateContent]
  let itemsList = extractItems(crateContent) ?? []
  if (itemsList.len() != 1)
    return { watch }

  let { armyId = null } = crateContent.get()
  let templates = allItemTemplates.get()?[armyId]
  let basetpl = itemsList[0]
  let { minTier, maxTier } = getTierInterval(crateContent?.get().content.items, templates)
  return {
    watch
    size = FLEX_H
    flow = FLOW_VERTICAL
    hplace = ALIGN_CENTER
    padding = [smallPadding, 0]
    margin = midPadding
    children = [
      mkShopItemInfoTier(minTier, maxTier)
      mkClassCanUse(basetpl, armyId, templates)
    ]
  }
}

let mkTitle = @(text, minAmount, maxAmount, isBundle) {
  flow = FLOW_HORIZONTAL
  size = FLEX_H
  valign = ALIGN_CENTER
  gap = smallPadding
  children = [
    {
      rendObj = ROBJ_TEXTAREA
      size = FLEX_H
      behavior = Behaviors.TextArea
      text
    }.__update(fontBody)
    minAmount <= 1 || isBundle ? null : {
      rendObj = ROBJ_TEXT
      text = loc("common/amountShort", {
        count = minAmount == maxAmount ? minAmount : $"{minAmount}-{maxAmount}"
      })
    }.__update(fontBody)
  ]
}

let mkSubtitle = @(text) text == "" ? null : {
  rendObj = ROBJ_TEXTAREA
  size = FLEX_H
  behavior = Behaviors.TextArea
  text
}.__update(fontSub)

function getMaxCount(shopItem) {
  let { limit = 0, premiumDays = 0, squads = [] } = shopItem
  let isSoldier = isContentSoldier(shopItemContentCtor(shopItem)?.get().content)
  return limit > 0 ||  premiumDays > 0 || squads.len() > 0 ? 1
    : isSoldier ? min(99, max(curArmyReserveCapacity.get() - curArmyReserve.get().len(), 0))
    : 99
}


function mkSeasonBpIcon(shopItem){
  let { offerGroup = null } = shopItem
  return offerGroup != "weapon_battlepass_group" ? null : bpIcon
}

function mkShopItemTitle(shopItem, crateContent, showDiscount, countWatched = null) {
  let { armyId = null, content = {} } = crateContent?.get()
  local shopIcon
  local seasonBpIcon = mkSeasonBpIcon(shopItem)
  let itemsList = extractItems(crateContent) ?? []
  if (itemsList.len() == 1) {
    
    let { itemtype = null, itemsubtype = null
      } = findItemTemplate(allItemTemplates.get(), armyId, itemsList[0])
    shopIcon = itemTypeIcon(itemtype, itemsubtype)
  }

  let soldierClasses = extractClasses(crateContent) ?? []
  if (soldierClasses.len() == 1)
    shopIcon = kindIcon(soldierClasses[0], hdpx(22))

  let titleLoc = shopItem?.nameLocId ?? ""
  let titleText = loc(titleLoc)
  let subtitleText = loc($"{titleLoc}/subtitle", "")
  let itemMinAmount = content?.amount ?? 1
  let itemMaxAmount = max(itemMinAmount, content?.maxAmount ?? 1)
  let isBundle = (shopItem?.crates.len() ?? 0) > 1
  let maxCount = getMaxCount(shopItem)

  let squadRentTime = shopItem?.squads[0]?.rentTime ?? 0
  let squadRentInfo = squadRentTime > 0 ? mkRentInfo(squadRentTime) : null

  return {
    rendObj = ROBJ_SOLID
    size = FLEX_H
    gap = midPadding
    padding = const [0, fsh(2)]
    vplace = ALIGN_BOTTOM
    color = defBgColor
    children = [
      !showDiscount ? null
        : mkDiscountWidget(shopItem.discountInPercent, { pos = const [hdpx(20), -hdpx(20)] })
      {
        size = FLEX_H
        minHeight = fsh(6)
        flow = FLOW_HORIZONTAL
        gap = midPadding
        valign = ALIGN_CENTER
        vplace = ALIGN_BOTTOM
        children = [
          shopIcon
          seasonBpIcon
          {
            size = FLEX_H
            flow = FLOW_VERTICAL
            children = [
              mkTitle(titleText, itemMinAmount, itemMaxAmount, isBundle)
              mkSubtitle(subtitleText)
            ]
          }
          maxCount <= 1 || countWatched == null ? null : mkCounter(maxCount, countWatched)
          squadRentInfo
        ]
      }
    ]
  }
}

function mkTimeAvailable(shopItem) {
  let { showIntervalTs = [] } = shopItem
  let toTs = showIntervalTs?[1] ?? 0
  if (toTs < serverTime.get())
    return null

  return function() {
    let res = { watch = serverTime }
    let timeLeft = toTs - serverTime.get()
    if (timeLeft <= 0)
      return res

    return res.__update({
      children = mkRightHeaderFlag(
        {
          flow = FLOW_HORIZONTAL
          valign = ALIGN_BOTTOM
          gap = hdpx(2)
          padding = midPadding
          children = [
            mkTimerIcon(timerSize, { color = TextNormal })
            {
              rendObj = ROBJ_TEXT
              text = secondsToHoursLoc(timeLeft)
              color = TextNormal
            }.__update(fontSub)
          ]
        },
        primeFlagStyle.__merge({ offset = 0 })
      )
    })
  }
}

let mkShopItemView = kwarg(@(
  shopItem, purchasingItem = null, unseenSignalObj = null, onCrateViewCb = null,
  onInfoCb = null, isLocked = false, containerIcon = null, crateContent = null,
  showVideo = null, showDiscount = false) {
    size = FLEX
    halign = ALIGN_RIGHT
    children = [
      mkShopItemImg(shopItem?.image ?? "", {
          keepAspect = KEEP_ASPECT_FILL
          imageHalign = ALIGN_CENTER
          imageValign = ALIGN_TOP
          picSaturate = isLocked ? 0.1 : 1
        }
      ),
      showVideo ? mkShopItemVideo(shopItem.video) : null,
      mkShopItemTitle(shopItem, crateContent, showDiscount),
      containerIcon,
      purchasingItem == null ? null : mkPurchaseSpinner(shopItem, purchasingItem),
      {
        valign = ALIGN_CENTER
        hplace = ALIGN_RIGHT
        flow = FLOW_HORIZONTAL
        children = [
          unseenSignalObj
          mkTimeAvailable(shopItem)
        ]
      },
      onInfoCb != null ? mkInfoBtn(onInfoCb) : mkViewCrateBtn(crateContent, onCrateViewCb),
      itemHighlight(shopItem.guid)
    ]
  })

let mkProductView = @(shopItem, crateContent = null) {
  rendObj = ROBJ_SOLID
  size = shopItem?.squads[0] != null ? cardSquadPreviewSize : cardPreviewSize
  padding = hdpx(1)
  color = idleBgColor
  clipChildren = true
  children = mkShopItemView({ shopItem, crateContent })
}

let getGrStatus = @(growths, growthId) growths?[growthId].status ?? GrowthStatus.UNAVAILABLE

function getCantBuyData(army, req, growths, growthCfg, grTiers, grTierCfg, templates) {
  let { guid = "" } = army
  let { growthId = "", growthTierId = "" } = req

  if (growthId != "" && getGrStatus(growths, growthId) != GrowthStatus.REWARDED) {
    let { itemTemplate = null } = growthCfg?[growthId].reward
    if (itemTemplate != null) {
      let item = templates?[guid][itemTemplate]
      if (item != null) {
        return {
          order = 1000
          growthRequired = growthId
          lockTxt = loc("growth/reqToCompleteGrowth")
          lockFull = loc("growth/reqToResearchGrowth", { reqText = itemNameFromTemplate(item) })
        }
      }
    }
  }

  if (growthTierId != "" && getGrStatus(grTiers, growthTierId) < GrowthStatus.COMPLETED) {
    let growthTierIdx = grTierCfg.findindex(@(t) t.id == growthTierId)
    if (growthTierIdx != null) {
      let reqText = getRomanNumeral(growthTierIdx + 1)
      return {
        order = 1500 + growthTierIdx
        growthTierRequired = growthTierIdx
        lockTxt = loc("growth/reqToCompleteTier", { reqText })
        lockFull = loc("growth/reqToBuyTier", { reqText })
      }
    }
  }

  return null
}


function shopItemLockedMsgBox(lockData, cb = @() null) {
  let { growthRequired = null, growthTierRequired = null } = lockData
  let buttons = [{ text = loc("Ok"), isCancel = true }]

  if (growthRequired != null)
    buttons.append({ text = loc("GoToGrowth"), action = function() {
      jumpToArmyGrowth(growthRequired)
      cb()
    }})
  else if (growthTierRequired != null)
    buttons.append({ text = loc("GoToGrowth"), action = function() {
      jumpToArmyGrowthTier(growthTierRequired)
      cb()
    }})

  showMsgbox({
    text = "\n\n".join([loc("shop/lockItemHeader"), lockData.lockFull])
    buttons
  })
}

let colorStyle = @(sf) (sf & S_ACTIVE) ? defTxtColor
  : (sf & S_HOVER) ? darkTxtColor
  : defTxtColor

function getViewShopInfoBtnText(text) {
  return @(_textField, params, handler, group, sf) textButtonTextCtor({
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    margin = textMargin
    children = [
      {
        rendObj = ROBJ_TEXT
        margin = [0,midPadding,0]
        color = colorStyle(sf)
        text
      }
      faComp("question-circle", {color = colorStyle(sf)})
    ]
  }, params, handler, group, sf)
}

let warnIcon = faComp("exclamation-triangle", { fontSize = hdpx(16), color = attentionTxtColor })

let mkAlertObject = @(alertText) {
  flow = FLOW_HORIZONTAL
  margin = smallPadding
  gap = smallPadding
  valign = ALIGN_CENTER
  children = [
    warnIcon
    {
      rendObj = ROBJ_TEXT
      text = alertText
    }.__update(alertTxtStyle)
  ]
}

return freeze({
  DISCOUNT_WARN_TIME
  mkShopItemImg
  mkShopItemView
  mkProductView
  mkShopItemInfoBlock
  shopItemLockedMsgBox
  getViewShopInfoBtnText
  mkShopItemPriceLine
  mkClassCanUse
  mkClassCanUseCenter
  getCantBuyData
  cardSquadPreviewSize
  mkAlertObject
})
