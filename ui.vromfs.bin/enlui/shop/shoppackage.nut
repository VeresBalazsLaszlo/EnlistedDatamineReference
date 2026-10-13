import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/vehicles/allowedVehicles.nut" as allowedVehicles
import "%ui/components/faComp.nut" as faComp
import "%ui/components/mkCountdownTimer.nut" as mkCountdownTimer
import "%ui/components/mkGlareAnim.nut" as mkGlare
import "%ui/soldiers/model/equipClassSchemes.nut" as getEquipClasses
import "%ui/style/tooltipCtor.nut" as tooltipCtor
from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/style/fontsStyle.nut" import fontSub, fontHeading2, fontBody, fontawesome
from "%ui/style/designConst.nut" import defTxtColor, titleTxtColor, panelBgColor, midPadding,
  darkTxtColor, largePadding, miniPadding, leftAppearanceAnim, defItemBlur, defSlotBgColor,
  hoverSlotBgColor, attentionTxtColor, darkBgColor, accentColor, smallPadding, highlightLineBottom,
  brightAccentColor, msgHighlightedTxtColor
from "%ui/shop/shopPricePackage.nut" import mkShopItemPrice
from "%ui/components/itemsInfo.nut" import trimUpgradeSuffix
from "%ui/soldiers/components/itemTypesData.nut" import itemTypeIcon
from "%ui/components/soldiersUiComps.nut" import kindIcon, classIcon
from "%ui/components/mkFireParticles.nut" import mkFireParticles, mkAshes, mkSparks
from "%ui/debriefing/components/mkXpImage.nut" import mkPremiumSquadXpImage
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, getTierInterval
from "%ui/shop/armyShopState.nut" import shopItemContentCtor, isContentSoldier
from "%ui/soldiers/model/reserve.nut" import curArmyReserve, curArmyReserveCapacity
from "%ui/shop/mkCounter.nut" import mkCounter
from "%ui/shop/currencyComp.nut" import mkDiscountWidget
from "%ui/components/soldierClasses.nut" import getClassCfg, getKindCfg, soldierKindsList
from "%ui/soldiers/model/state.nut" import armySquadsById, lockedArmySquadsById
from "%ui/components/squadsUiComps.nut" import mkSquadCard, mkRentInfo
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/style/cursors.nut" import withTooltip, setTooltip
from "%ui/components/itemTier.nut" import mkZeroStars
from "%ui/vehicles/vehDecorState.nut" import vehCamouflageCfg
from "%ui/soldiers/model/chooseSquadsState.nut" import curArmyLockedSquadsData
from "%ui/shop/previewDrops.nut" import dropDetails
from "%ui/soldiers/model/cratesContent.nut" import getPossibleCratesList
from "%ui/meta/metaConfigUpdater.nut" import isLootBoxProhibited
from "%ui/shop/shopPkg.nut" import mkAlertObject
from "%ui/ui_library.nut" import *

const itemIconSize = hdpxi(32)
const lowerSlotSize = [hdpxi(370), hdpxi(308)]
const soldierSlotSize = [hdpx(280), hdpx(370)]
const baseSlotSize = [hdpxi(370), hdpxi(370)]
const promoSlotSize = [hdpxi(756), hdpxi(370)]

const btnSound = {
  hover = "ui/enlist/button_highlight"
  click = "ui/enlist/button_click"
  active = "ui/enlist/button_action"
}


let defTxtStyle = const { color = defTxtColor }.__merge(fontSub)
let defFeaturedTxtStyle = const { color = defTxtColor }.__merge(fontHeading2)
let activeTxtStyle = const { color = darkTxtColor }.__merge(fontSub)
let titleTxtStyle = const { color = titleTxtColor }.__merge(fontSub)
let titleFeaturedTxtStyle = const { color = titleTxtColor }.__merge(fontHeading2)
let discountInfoStyle = const { color = darkTxtColor }.__merge(fontHeading2)
let discountDescStyle = const { color = darkTxtColor }.__merge(fontSub)

let lockIcon = faComp("lock", { fontSize = hdpx(20), color = titleTxtColor })

const infoBtnSize = hdpxi(30)
const hoveredInfoBtnSize = hdpxi(33)


let mkText = @(text, override = defTxtStyle) {
  rendObj = ROBJ_TEXT
  text
}.__update(override)

let bgColor = @(sf, isSelected) isSelected ? accentColor
  : sf & S_HOVER ? hoverSlotBgColor
  : defSlotBgColor


let mkBgParticles = @(effectSize) {
  children = [
    mkFireParticles(8, effectSize, mkAshes)
    mkFireParticles(2, effectSize, mkSparks)
  ]
}


let mkShopItemImg = @(img, sf = 0, override = {}) (img ?? "") == "" ? null
  : {
      size = FLEX
      rendObj = ROBJ_IMAGE
      image = Picture(img)
      imageHalign = ALIGN_CENTER
      imageValign = ALIGN_TOP
      keepAspect = KEEP_ASPECT_FILL
      transform = { scale = sf & S_HOVER ? const [1.1, 1.1] : const [1, 1] }
      transitions = const [{ prop = AnimProp.scale, duration = 0.3, easing = InOutCubic }]
    }.__update(override)


let mkMkDiscount = @(poly) @(color) {
  size = [midPadding, FLEX]
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = color
  commands = [
    [VECTOR_COLOR, color],
    poly
  ]
}

let mkDiscountRightTail = mkMkDiscount([VECTOR_POLY, 0, 0, 100, 100, 0, 100])
let mkDiscountLeftTail = mkMkDiscount([VECTOR_POLY, 100, 0, 100, 100, 0, 100])


let mkDiscountPolyCmds = @(color) [
  [VECTOR_COLOR, color],
  [VECTOR_POLY, 0,0, 100,0, 100, 100, 0, 100]
]

let mkDiscountBar = @(children, isTailOnLeft = true, color = brightAccentColor, offset = midPadding) {
  flow = FLOW_HORIZONTAL
  children = [
    isTailOnLeft ? mkDiscountLeftTail(color) : null
    {
      flow = FLOW_HORIZONTAL
      gap = midPadding
      padding = [0, offset]
      valign = ALIGN_CENTER
      rendObj = ROBJ_VECTOR_CANVAS
      fillColor = color
      commands = mkDiscountPolyCmds(color)
      children
    }
    isTailOnLeft ? null : mkDiscountRightTail(color)
  ]
}


function mkDiscount(sItem) {
  let { discountInPercent = 0, curShopItemPrice = {}, curItemCost = {} } = sItem
  if (discountInPercent <= 0)
    return null

  let { price = 0 } = curShopItemPrice
  if (price == 0 && curItemCost.len() > 0)
    return null

  let { hideDiscount = false, showSpecialOfferText = false } = sItem
  return mkDiscountBar([
      hideDiscount ? null : {
        rendObj = ROBJ_TEXT
        text = $"-{discountInPercent}%"
      }.__update(discountInfoStyle)
      {
        rendObj = ROBJ_TEXT
        text = loc(showSpecialOfferText ? "specialOfferShort" : "shop/discountTxt")
      }.__update(discountDescStyle)
    ])
}

let mkSpecOfferInfo = @(discount, endTime) mkDiscountBar([
  {
    rendObj = ROBJ_TEXT
    text = $"-{discount}%"
  }.__update(discountInfoStyle)
  {
    rendObj = ROBJ_TEXT
    text = loc("shop/discountTxt")
  }.__update(discountDescStyle)
  mkCountdownTimer({ timestamp = endTime, color = darkTxtColor })
])

function mkTimeAvailable(showIntervalTs) {
  let endTime = showIntervalTs?[1] ?? 0
  return endTime < serverTime.get() ? null
    : mkCountdownTimer({ timestamp = endTime, color = attentionTxtColor })
}


let mkShopItemName = @(nameLocId, sf, icon, showIntervalTs) {
  size = const [FLEX, hdpx(86)]
  rendObj = ROBJ_WORLD_BLUR
  fillColor = bgColor(sf, false)
  color = defItemBlur
  children = {
    size = FLEX
    flow = FLOW_HORIZONTAL
    gap = largePadding
    padding = const [miniPadding, largePadding]
    valign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    children = [
      icon
      {
        size = FLEX
        rendObj = ROBJ_TEXTAREA
        behavior = const [Behaviors.TextArea, Behaviors.Marquee]
        valign = ALIGN_CENTER
        text = utf8ToUpper(loc(nameLocId))
        orientation = O_VERTICAL
      }.__update(sf & S_HOVER ? activeTxtStyle : defTxtStyle)
      mkTimeAvailable(showIntervalTs)
    ]
  }
}


function mkShopPremIcon(sItem) {
  let { squads = [] } = sItem
  let squad = squads?[0]
  if (squad == null)
    return null

  let { armyId } = squad
  return mkPremiumSquadXpImage(hdpxi(32), armyId)
}

let labelByOfferGroup = {
  soldier_battlepass_group = function() {
    let { heroExpBonus = 0.0 } = gameProfile.get()
    let watch = gameProfile
    return heroExpBonus <= 0 ? { watch }
      : {
          watch
          children = withTooltip(mkDiscountBar({
            flow = FLOW_HORIZONTAL
            gap = smallPadding
            valign = ALIGN_CENTER
            children = [
              {
                rendObj = ROBJ_TEXT
                text = $"+{(100 * heroExpBonus).tointeger()}%"
              }.__update(discountInfoStyle)
              {
                rendObj = ROBJ_TEXT
                text = loc("exp")
              }.__update(discountDescStyle)
            ]
          }), @() tooltipCtor({
            size = const [sh(30), SIZE_TO_CONTENT]
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = loc("tooltip/shopHeroBonusInfo")
          }))
        }
  }
}

function mkShopItemInfo(sItem, offer, sf, icon, lockObject, curGroup, unseenIcon = null) {
  let { nameLocId = "", showIntervalTs = [], isPriceHidden = false, offerContainer = "" } = sItem
  let isContainer = offerContainer != ""
  let squadRentTime = sItem?.squads[0]?.rentTime ?? 0
  let squadRentInfo = squadRentTime > 0 ? mkRentInfo(squadRentTime) : null
  let priceObject = isPriceHidden || isContainer ? null : mkShopItemPrice(sItem, lockObject)

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = midPadding
    vplace = ALIGN_BOTTOM
    children = [
      curGroup?.hideDiscountItems ? null
        : offer == null ? mkDiscount(sItem)
        : mkSpecOfferInfo(offer.discountInPercent, offer.endTime)
      labelByOfferGroup?[sItem?.offerGroup]
      isPriceHidden || isContainer ? null : {
        size = FLEX_H
        children = [
          priceObject
          squadRentInfo
          priceObject == null ? null : mkGlare({
            nestWidth = hdpx(248)
            glareWidth = hdpx(124)
            glareDuration = 0.7
            hasMask = true
          })
        ]
      }
      {
        size = FLEX_H
        children = [
          mkShopItemName(nameLocId, sf, icon, showIntervalTs)
          unseenIcon
          highlightLineBottom
        ]
      }
    ]
  }
}


let mkFeaturedName = @(nameLocId, sf, icon) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = largePadding
  padding = largePadding
  valign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    icon
    {
      size = FLEX_H
      maxWidth = hdpx(600)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = utf8ToUpper(loc(nameLocId).split("\r\n")[0])
    }.__update(sf & S_HOVER ? titleFeaturedTxtStyle : defFeaturedTxtStyle)
  ]
}


function mkShopFeaturedInfo(sItem, offer, sf, icon, lockObject, curGroup) {
  let { nameLocId = "", showIntervalTs = [], isPriceHidden = false } = sItem
  let priceObject = isPriceHidden ? null : mkShopItemPrice(sItem, lockObject)

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    gap = midPadding
    vplace = ALIGN_BOTTOM
    children = [
      curGroup?.hideDiscountItems ? null
        : offer == null ? mkDiscount(sItem)
        : mkSpecOfferInfo(offer.discountInPercent, offer.endTime)
      priceObject == null ? null : {
        children = [
          priceObject
          mkGlare({
            nestWidth = hdpx(248)
            glareWidth = hdpx(124)
            glareDuration = 0.7
            hasMask = true
          })
        ]
      }
      {
        size = FLEX_H
        valign = ALIGN_CENTER
        margin = [0, 0, largePadding, 0]
        children = [
          mkFeaturedName(nameLocId, sf, icon)
          {
            margin = [0, largePadding]
            hplace = ALIGN_RIGHT
            children = mkTimeAvailable(showIntervalTs)
          }
        ]
      }
    ]
  }
}


let mkLockInfo = @(lockTxt) lockTxt == "" ? null
  : {
      flow = FLOW_HORIZONTAL
      gap = largePadding
      valign = ALIGN_CENTER
      children = [
        lockIcon
        {
          rendObj = ROBJ_TEXT
          text = utf8ToUpper(lockTxt)
        }.__update(titleTxtStyle)
      ]
    }.__update(titleTxtStyle)


function extractItems(content) {
  let res = {}
  foreach (tmpl, _ in content?.items ?? {})
    res[trimUpgradeSuffix(tmpl)] <- true
  return res.keys()
}

function extractClasses(content) {
  let res = []
  foreach (sClass in content?.soldierClasses ?? {})
    res.append(getClassCfg(sClass))
  return res
}

function mkShopIcon(armyId, content, templates) {
  let itemsList = extractItems(content) ?? []
  if (itemsList.len() == 1) {
    let { itemtype = null, itemsubtype = null } = templates?[armyId][itemsList[0]]
    return itemTypeIcon(itemtype, itemsubtype, {
      size = const [itemIconSize, itemIconSize]
      color = titleTxtColor
    })
  }

  let sClasses = extractClasses(content) ?? []
  if (sClasses.len() == 1) {
    let { kind, sClass } = sClasses[0]
    return {
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      children = [
        classIcon(armyId, sClass, itemIconSize)
        kindIcon(kind, itemIconSize, titleTxtColor)
      ]
    }
  }

  return null
}


let infoIcon = {
  rendObj = ROBJ_IMAGE
  size = array(2, infoBtnSize)
  image = Picture($"ui/skin#info/info_icon.svg:{infoBtnSize}:{infoBtnSize}")
}

let infoIconHover = {
  rendObj = ROBJ_IMAGE
  size = array(2, hoveredInfoBtnSize)
  image = Picture($"ui/skin#info/info_icon.svg:{hoveredInfoBtnSize}:{hoveredInfoBtnSize}")
}

let mkInfoBtn = @(onClick) onClick == null ? null : watchElemState(function(sf) {
  return {
    size = const [hoveredInfoBtnSize, hoveredInfoBtnSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    hplace = ALIGN_RIGHT
    margin = fsh(1)
    behavior = Behaviors.Button
    sound = btnSound
    onClick
    children = sf & S_HOVER ? infoIconHover : infoIcon
  }
})

let mkShopItem = @(slotSize) function(idx, armyId, sItem, offer, content, templates, lockTxt,
  onClick = null, onHover = null, alertText = null, infoCb = null, unseenIcon = null,
  curGroup = null
) {
  let picSaturate = lockTxt == "" ? 1 : 0.1
  let icon = mkShopIcon(armyId, content, templates)
  let alertObject = alertText == null ? null : mkAlertObject(alertText)
  let xmbNode = onClick == null ? null : XmbNode()
  let behavior = onClick == null ? null : Behaviors.Button
  let sound = onClick == null ? null : btnSound
  return watchElemState(@(sf) {
    key = sItem.guid
    size = slotSize
    rendObj = ROBJ_SOLID
    color = panelBgColor
    clipChildren = true
    behavior
    xmbNode
    onClick
    sound
    hotkeys = (sf & S_HOVER) && infoCb != null
      ? [["^J:Y", { description = loc("info"), action = infoCb }]]
      : null
    onHover
    children = {
      size = FLEX
      children = [
        {
          size = FLEX
          margin = const [0,0, hdpx(86),0]
          children = [
            mkShopItemImg(sItem?.image, sf, { picSaturate })
            mkBgParticles([slotSize[0], slotSize[1] - hdpx(86)])
          ]
        }
        mkShopItemInfo(sItem, offer, sf, icon, mkLockInfo(lockTxt), curGroup, unseenIcon)
        mkShopPremIcon(sItem)
        alertObject
        mkInfoBtn(infoCb)
      ]
    }
  }.__update(leftAppearanceAnim(idx * 0.05 + 0.1)))
}

let mkBaseShopItem = mkShopItem(baseSlotSize)
let mkLowerShopItem = mkShopItem(lowerSlotSize)
let mkSoldierShopItem = mkShopItem(soldierSlotSize)

function mkShopFeatured(_idx, armyId, sItem, offer, content, templates, lockTxt,
  onClick, onHover, _alertText, infoCb, _unseenIcon, curGroup
) {
  let picSaturate = lockTxt == "" ? 1 : 0.1
  let icon = mkShopIcon(armyId, content, templates)
  let xmbNode = onClick == null ? null : XmbNode()
  let behavior = onClick == null ? null : Behaviors.Button
  let sound = onClick == null ? null : btnSound
  return watchElemState(@(sf) {
    key = $"featured_{sItem.guid}"
    size = promoSlotSize
    rendObj = ROBJ_SOLID
    color = panelBgColor
    clipChildren = true
    behavior
    xmbNode
    onClick
    sound
    onHover
    hotkeys = (sf & S_HOVER) && infoCb != null
      ? [["^J:Y", { description = loc("info"), action = infoCb }]]
      : null
    children = {
      size = FLEX
      children = [
        mkShopItemImg(sItem?.image, sf, { picSaturate })
        mkBgParticles(promoSlotSize)
        mkShopFeaturedInfo(sItem, offer, sf, icon, mkLockInfo(lockTxt), curGroup)
        infoCb ? mkInfoBtn(infoCb) : null
      ]
    }
  }.__update(leftAppearanceAnim(0)))
}


function getMaxCount(shopItem) {
  let { limit = 0, premiumDays = 0, squads = [] } = shopItem
  let isSoldier = isContentSoldier(shopItemContentCtor(shopItem)?.get().content)
  return limit > 0 ||  premiumDays > 0 || squads.len() > 0 ? 1
    : isSoldier ? min(99, max(curArmyReserveCapacity.get() - curArmyReserve.get().len(), 0))
    : 99
}

function mkShopCounter(shopItem, countWatched) {
  let maxCount = getMaxCount(shopItem)
  return maxCount <= 1 || countWatched == null ? null
    : {
        size = const [FLEX, hdpx(86)]
        vplace = ALIGN_BOTTOM
        valign = ALIGN_CENTER
        halign = ALIGN_CENTER
        rendObj = ROBJ_WORLD_BLUR
        fillColor = bgColor(0, false)
        color = defItemBlur
        children = mkCounter(maxCount, countWatched)
      }
}


function mkShopItemInfoTier(minTier, maxTier, override = {}) {
  if (maxTier <= 0)
    return null

  let starsObj = maxTier == minTier
    ? mkZeroStars(maxTier)
    : {
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        valign = ALIGN_CENTER
        children = [
          mkZeroStars(minTier)
          mkText("—")
          mkZeroStars(maxTier)
        ]
      }
  let starsTxt = maxTier <= minTier ? null
    : {
        size = const [hdpxi(220), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("shop/upgradeLevel", { maxUpgrade = maxTier, minUpgrade = minTier })
        color = defTxtColor
      }.__update(fontSub, override)
  return {
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      mkText(utf8ToUpper(loc("itemLevel")))
      starsObj
      starsTxt
    ]
  }
}


const iconSize = hdpxi(36)
const iconGap = hdpxi(18)
let getKindIcon = memoize(@(img, sz) Picture("ui/skin#{0}:{1}:{1}".subst(img, sz.tointeger())))

let mkHintText = @(text, color = defTxtColor, fontStyle = fontBody) {
  rendObj = ROBJ_TEXT
  text
  color
}.__update(fontStyle)

function mkSquadTooltip(squad, isUnlocked) {
  return tooltipCtor({
    flow = FLOW_VERTICAL
    children = [
      mkHintText(loc(squad?.nameLocId ?? ""), msgHighlightedTxtColor)
      mkHintText(loc(isUnlocked ? "shop/have_squad" : "shop/no_squad"), defTxtColor, fontSub)
    ]
  })
}

function mkRestriction(squad) {
  let { growthData = null } = curArmyLockedSquadsData.get().findvalue(@(val)
    val.squadId == squad?.squadId)

  return {
    rendObj = ROBJ_SOLID
    color = darkBgColor
    size = const [FLEX, hdpxi(30)]
    vplace = ALIGN_BOTTOM
    valign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    padding = midPadding
    gap = smallPadding
    children = [
      faComp("lock", {
        valign = ALIGN_CENTER
        color = defTxtColor
      }.__update(fontawesome))
      {
        size = FLEX_H
        rendObj = ROBJ_TEXT
        behavior = Behaviors.Marquee
        text = loc(growthData?.lockTxt ?? "shop/not_available")
      }
    ]
  }
}

function mkCanUseInfo(itemtype, armyId, itemtmpl) {
  if (itemtype == "vehicle") {
    let vehicleSquadIds = (allowedVehicles.get()?[armyId] ?? {})
      .filter(@(squad) squad?[itemtmpl]).keys()
    let squadsCount = vehicleSquadIds.len()
    return {
      flow = FLOW_VERTICAL
      gap = iconGap
      halign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      children = [
        mkText(utf8ToUpper(loc("shop/squadsCanUse", { squadsCount })))
        @() {
          watch = [armySquadsById, lockedArmySquadsById]
          flow = FLOW_HORIZONTAL
          gap = iconGap
          children = vehicleSquadIds.map(function(squadId) {
            local isUnlocked = true
            local squad = armySquadsById.get()?[armyId][squadId]
            if (!squad) {
              isUnlocked = false
              squad = lockedArmySquadsById.get()?[armyId][squadId]
                ?? getSquadPresentation(squadId, armyId)
            }
            let card = mkSquadCard({
              idx = 0
              isSelected = Watched(false)
            }.__update(squad ?? {}))
            return {
              behavior = Behaviors.Button
              onHover = @(on) setTooltip(on ? mkSquadTooltip(squad, isUnlocked) : null)
              children = [
                {
                  opacity = isUnlocked ? 1.0 : 0.5
                  children = card
                }
                isUnlocked ? null : mkRestriction(squad)
              ]
            }
          })
        }
      ]
    }
  }

  let kindsList = getEquipClasses(armyId, itemtmpl, itemtype)
    .reduce(function(tbl, sClass) {
      let { kind, isPremium = false, isEvent = false } = getClassCfg(sClass)
      if (!isPremium && !isEvent)
        tbl[kind] <- true
      return tbl
    }, {}).keys()

  let count = kindsList.len()
  if (count == 0)
    return null

  let isAccessible = count == soldierKindsList.len()
  let headerTxt = loc(isAccessible ? "shop/allCanUse" : "shop/someCanUse", { classes = "" })
  let classesListObj = isAccessible ? null
    : {
        flow = FLOW_HORIZONTAL
        gap = iconGap
        children = kindsList.map(function(sKind) {
          let cfg = getKindCfg(sKind)
          return {
            flow = FLOW_VERTICAL
            gap = smallPadding
            halign = ALIGN_CENTER
            children = [
              {
                rendObj = ROBJ_IMAGE
                size = const [iconSize, iconSize]
                image = getKindIcon(cfg.icon, iconSize)
              }
              mkText(loc(cfg.locId))
            ]
          }
        })
      }
  return {
    flow = FLOW_VERTICAL
    gap = iconGap
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    children = [
      mkText(utf8ToUpper(headerTxt))
      classesListObj
    ]
  }
}

let mkCanUseShopItemInfo = @(crateContent) function() {
  let res = { watch = [allItemTemplates, crateContent] }
  let itemsList = extractItems(crateContent.get()?.content) ?? []
  if (itemsList.len() != 1)
    return res

  let { armyId = null } = crateContent.get()
  let templates = allItemTemplates.get()?[armyId]
  let itemtmpl = itemsList[0]
  let { itemtype = null } = templates?[itemtmpl]
  return res.__update(mkCanUseInfo(itemtype, armyId, itemtmpl) ?? {}, {halign = ALIGN_CENTER})
}

function mkUseForCamouflage(shopItem) {
  let { camouflages = [] } = shopItem
  if (camouflages.len() == 0)
    return null

  let watch = [allItemTemplates, vehCamouflageCfg]

  return function() {
    let camoCfg = vehCamouflageCfg.get()
    let templates = allItemTemplates.get()

    let vehicles = []
    foreach (skinId in camouflages)
      camoCfg.each(function(skins, basetpl) {
        if (skinId in skins)
          vehicles.append(basetpl)
      })

    let children = []
    foreach (basetpl in vehicles)
      foreach (armyId, armyTemplates in templates) {
        if (basetpl not in armyTemplates)
          continue

        let { itemtype = null } = armyTemplates?[basetpl]

        let useInfo = mkCanUseInfo(itemtype, armyId, basetpl)
        if (useInfo != null)
          children.append(useInfo)
      }

    return {
      watch
      halign = ALIGN_CENTER
      children
    }
  }
}

let msgBoxViewSize = [hdpxi(500), hdpxi(340)]
function crateView(shopItem, countWatched, discountVal) {
  let { showIntervalTs = [], isPriceHidden = false, image = null } = shopItem
  let priceObject = isPriceHidden ? null : mkShopItemPrice(shopItem)

  return {
    size = msgBoxViewSize
    children = [
      mkShopItemImg(image)
      mkBgParticles(msgBoxViewSize)
      mkShopPremIcon(shopItem)
      {
        margin = smallPadding
        children = mkTimeAvailable(showIntervalTs)
      }
      {
        size = FLEX
        flow = FLOW_VERTICAL
        gap = midPadding
        valign = ALIGN_BOTTOM
        children = [
          labelByOfferGroup?[shopItem?.offerGroup]
          {
            size = FLEX_H
            children = [
              mkDiscountWidget(discountVal, { pos = const [hdpx(10), 0] })
              priceObject == null ? null : {
                children = [
                  priceObject
                  mkGlare({
                    nestWidth = hdpx(248)
                    glareWidth = hdpx(124)
                    glareDuration = 0.7
                    hasMask = true
                  })
                ]
              }
            ]
          }
          mkShopCounter(shopItem, countWatched)
        ]
      }
    ]
  }
}

function mkShopMsgBoxView(shopItem, crateContent, countWatched, showDiscount = false) {
  if (crateContent == null)
    return null

  let { nameLocId = "", discountInPercent = 0 } = shopItem
  let discountVal = showDiscount ? discountInPercent : 0
  return function() {
    let { armyId = null, content = null, id = null } = crateContent.get()

    let crateList = getPossibleCratesList(id)
    let templates = allItemTemplates.get()
    let { minTier, maxTier } = getTierInterval(content?.items, templates?[armyId])
    let icon = mkShopIcon(armyId, content, templates)
    return {
      watch = [crateContent, allItemTemplates, isLootBoxProhibited]
      valign = ALIGN_CENTER
      halign = ALIGN_RIGHT
      children = [
        {
          flow = FLOW_VERTICAL
          gap = largePadding
          children = [
            {
              size = FLEX_H
              flow = FLOW_HORIZONTAL
              gap = smallPadding
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              children = [
                icon
                mkText(utf8ToUpper(loc(nameLocId)), titleTxtStyle)
              ]
            }
            {
              flow = FLOW_HORIZONTAL
              gap = largePadding
              children = [
                crateView(shopItem, countWatched, discountVal)
                dropDetails(crateList, isLootBoxProhibited.get())
              ]
            }
          ]
        }
        {
          size = const [hdpxi(220), SIZE_TO_CONTENT]
          pos = const [hdpxi(250), 0]
          children = mkShopItemInfoTier(minTier, maxTier)
        }
      ]
    }
  }
}


return freeze({
  mkBaseShopItem
  mkLowerShopItem
  mkSoldierShopItem
  mkDiscountBar
  mkShopFeatured
  lowerSlotSize
  mkAlertObject
  mkShopMsgBoxView
  mkCanUseShopItemInfo
  mkUseForCamouflage
})
