import "%ui/meta/perks/perksList.nut" as perksList
import "%ui/components/faComp.nut" as faComp
import "%ui/soldiers/components/viewItemScene.nut" as viewItemScene
from "%ui/style/fontsStyle.nut" import fontTitle, fontBody, fontSub
from "%ui/style/designConst.nut" import activeTxtColor, lockedSquadBgColor, smallPadding,
  midPadding, largePadding, defTxtColor, darkBgColor, accentTitleTxtColor
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/state/safeArea.nut" import safeAreaHorPadding, safeAreaBorders
from "%ui/soldiers/components/perksPackage.nut" import getStatDescList, getSoldierClassPerksPoints,
  getStatDescFull, getRecommendedPerksCount
from "%ui/components/soldiersUiComps.nut" import classIcon, className
from "%ui/components/squadsUiComps.nut" import mkSquadIcon
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates, findItemTemplate
from "%ui/components/itemsInfo.nut" import iconByGameTemplate, itemNameFromTemplate, getItemDesc
from "%ui/components/textButton.nut" import Regular
from "%ui/components/soldierClasses.nut" import getClassCfg
from "%ui/soldiers/model/items_list_lib.nut" import mkShopItem
from "%ui/meta/perks/perksStats.nut" import perksStatsCfg
from "%ui/soldiers/components/campaignPromoPkg.nut" import campaignName, btnSizeSmall, btnSizeBig,
  weapInfoBtn
from "%ui/shop/dropRouletteState.nut" import needOpenRouletteWnd
from "%ui/components/battleRatingPkg.nut" import mkBattleRatingShort
from "%ui/components/msgbox.nut" import removeAllMsgboxes
from "%ui/helpers/gradients.nut" import mkColoredGradientX, mkColoredGradientY
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/ui_library.nut" import *

const mainBgColor = Color(98, 98, 80)
const descBlockMargin = hdpx(100)
let sizeNewWeapon = [btnSizeBig[0], hdpx(120)]

let mkText = @(txt, style = {}) {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = txt
}.__update(fontBody, style)
let squadBigIconSize = [hdpx(100), hdpx(120)]

let newSquadBlock = @(armyId, sClassId){
  flow = FLOW_VERTICAL
  size = FLEX_H
  valign = ALIGN_CENTER
  gap = midPadding
  children = [
    mkText(loc("mainmenu/newInfantryClass"),
            { color = accentTitleTxtColor }.__update(fontSub))
    {
      flow = FLOW_HORIZONTAL
      gap = smallPadding
      valign = ALIGN_CENTER
      children = [
        classIcon(armyId, sClassId, hdpxi(30), {
          vplace = ALIGN_BOTTOM, hplace = ALIGN_RIGHT })
        className(sClassId).__update({ color = Color(255, 255,255) }).__update(fontBody)
      ]
    }
  ]
}

let starterPerkBlock = @(perk) perk == null ? null : {
  flow = FLOW_VERTICAL
  size = FLEX_H
  valign = ALIGN_CENTER
  gap = midPadding
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("squads/starterPerk")
      color = accentTitleTxtColor
    }.__update(fontSub)
    @() {
      watch = [perksList, perksStatsCfg]
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      size = FLEX_H
      text = "\n".join(getStatDescList(perksStatsCfg.get(), perksList.get()?[perk]))
    }.__update(fontSub)
  ]
}

let mkSquadDescBlock = @(text, style = {}){
  rendObj = ROBJ_TEXTAREA
  maxWidth = hdpx(600)
  behavior = Behaviors.TextArea
  size = FLEX_H
  color = activeTxtColor
  text
}.__update(fontSub, style)

let primePerkBlock = @(primeDesc){
  flow = FLOW_VERTICAL
  size = FLEX_H
  gap = midPadding
  children = [
    mkSquadDescBlock(loc("squads/primeStarterPerks"), {color = accentTitleTxtColor})
    mkSquadDescBlock(loc(primeDesc))
  ]
}

function mkClassDescBlock(armyId, newClass, newPerk = null, isPrimeSquad = false) {
  if (newClass == null)
    return null

  let { perksId } = getClassCfg(newClass)
  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    vplace = ALIGN_CENTER
    gap = largePadding
    children = [
      newSquadBlock(armyId, newClass)
      starterPerkBlock(newPerk)
      isPrimeSquad ? primePerkBlock(getStatDescFull(perksId, armyId)) : null
      mkSquadDescBlock(getSoldierClassPerksPoints(perksId))
    ]
  }
}

function mNewItemBlock(armyId, itemId, size, idx = 0) {
  
  let item = findItemTemplate(allItemTemplates.get(), armyId, itemId)
  if (item == null)
    return null

  let { gametemplate = null } = item
  let itemToView = mkShopItem(itemId, item, armyId)
  if (gametemplate == null)
    return null

  return {
    size = FLEX_H
    margin = [0, largePadding,0,0]
    flow = FLOW_VERTICAL
    gap = midPadding
    children = [
      {
        size = FLEX_H
        flow = FLOW_VERTICAL
        gap = midPadding
        children = [
          idx > 0 ? null : {
            rendObj = ROBJ_TEXT
            color = accentTitleTxtColor
            text = loc(item?.itemtype == "vehicle"
              ? "mainmenu/newVehicle"
              : "mainmenu/newWeapon")
          }.__update(fontSub)
          {
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            size = FLEX_H
            text = itemNameFromTemplate(item)
          }.__update(fontBody)
          mkSquadDescBlock(getItemDesc(item), { color = defTxtColor })
        ]
      }
      watchElemState(@(sf) {
        watch = [needOpenRouletteWnd]
        rendObj = ROBJ_BOX
        behavior = Behaviors.Button
        onClick = needOpenRouletteWnd.get() ? null : function() {
          viewItemScene(itemToView)
          removeAllMsgboxes()
        }
        borderWidth = hdpx(1)
        size
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        fillColor = sf & S_HOVER ? mainBgColor : darkBgColor
        borderColor = sf & S_HOVER ? activeTxtColor : defTxtColor
        clipChildren = true
        children = [
          iconByGameTemplate(gametemplate, {
            width = size[0]/1.5
            height = size[1]
          })
          weapInfoBtn(sf)
          {
            hplace = ALIGN_LEFT
            vplace = ALIGN_BOTTOM
            padding = [smallPadding, midPadding]
            children = mkBattleRatingShort(item?.growthTier ?? 1)
          }
        ]
      })
    ]
  }
}

let primeDescGap = {
  rendObj = ROBJ_SOLID
  size = const [hdpx(1), hdpx(200)]
  color = defTxtColor
}

function mkSquadBodyBig(squadData, descBlock, buttons) {
  let { armyId, newClass, newPerk, newWeapon, isPrimeSquad = false } = squadData
  return {
    size = FLEX
    flow = FLOW_HORIZONTAL
    gap = sh(5)
    children = [
      {
        size = FLEX
        children = [
          { size = FLEX, maxHeight = ph(45) }
          campaignName(squadData.__merge({ sClass = newClass }))
          descBlock
        ]
      }
      {
        size = [btnSizeBig[0], FLEX]
        flow = FLOW_VERTICAL
        gap = largePadding
        children = [
          { size = const [FLEX, flex(1.5)] }
          makeVertScroll({
            size = FLEX_H
            flow = FLOW_VERTICAL
            gap = largePadding
            children = [
              mkClassDescBlock(armyId, newClass, newPerk, isPrimeSquad)
              {
                size = FLEX_H
                flow = FLOW_VERTICAL
                gap = largePadding
                children = newWeapon.map(@(weapon)
                  mNewItemBlock(armyId, weapon, sizeNewWeapon))
              }
            ]
          }, { size = const [FLEX, flex(10)] })
          buttons
        ]
      }
    ]
  }
}

let horBottomGradient = {
  rendObj = ROBJ_IMAGE
  vplace = ALIGN_BOTTOM
  size = const [FLEX, ph(40)]
  image = mkColoredGradientY({
    colorTop = 0x00000000
    colorBottom = 0xFF000000
    height = 32
  })
}

let verticalRightGradient = {
  rendObj = ROBJ_IMAGE
  hplace = ALIGN_RIGHT
  size = const [pw(45), FLEX]
  image = mkColoredGradientX({
    colorLeft = 0x00000000
    colorRight = 0xFF000000
    width = 32
  })
}

let mkSquadBackground = @(img, saturate = 1.0) {
  rendObj = ROBJ_IMAGE
  size = const [ph(133), ph(100)]
  keepAspect = KEEP_ASPECT_FIT
  imageValign = ALIGN_TOP
  imageHalign = ALIGN_LEFT
  image = Picture(img)
  picSaturate = saturate
  children = [
    horBottomGradient
    verticalRightGradient
  ]
}

let mkBackWithImage = @(img, isLocked = false) {
  size = FLEX
  valign = ALIGN_TOP
  children = img == null ? null : mkSquadBackground(img, isLocked ? 0.3 : 1.0)
}

let mkUnlockInfo = @(t, override = {}) {
  rendObj = ROBJ_SOLID
  size = [SIZE_TO_CONTENT, btnSizeSmall[1]]
  minWidth = btnSizeSmall[0]
  halign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = lockedSquadBgColor
  children = mkText(t, {
    color = activeTxtColor
  })
}.__update(override)

let mkPromoBackBtn = @(cb) cb != null
  ? @() {
      watch = isGamepad
      children = !isGamepad.get()
        ? Regular(loc("squads/back"), cb, {size = btnSizeBig})
        : null
    }
  : null

let mkFullScreenBack = @(bgChildren, bodyChildren) {
  size = FLEX
  rendObj = ROBJ_SOLID
  color = Color(0,0,0)
  halign = ALIGN_CENTER
  children = [
    @() {
      watch = safeAreaHorPadding
      pos = [-safeAreaHorPadding.get(), 0]
      size = FLEX
      maxWidth = hdpx(1920)
      children = bgChildren
    }
    @() {
      watch = safeAreaBorders
      size = FLEX
      maxWidth = hdpx(1920)
      padding = safeAreaBorders.get().map(@(v) max(v, largePadding))
      children = bodyChildren
    }
  ]
}

let mkPromoSquadIcon = @(icon, isLocked = false) mkSquadIcon(icon, {
  size = squadBigIconSize
  margin = hdpx(20)
  picSaturate = isLocked ? 0.3 : 1
})

let mkDescBlock = @(announceLocId) {
  size = FLEX_H
  margin = const [0,0,descBlockMargin,0]
  vplace = ALIGN_BOTTOM
  children = mkSquadDescBlock(loc(announceLocId), { maxWidth = FLEX })
}

let starIcon = faComp("star",{
  fontSize = hdpx(40)
  color = accentTitleTxtColor
})

let mkDescTitle = @(text) {
  rendObj = ROBJ_TEXT
  color = accentTitleTxtColor
  text
}.__update(fontTitle)

let primeDescTitle = @(titleText, soldierCount, rank, perksCount, addChild) {
  flow = FLOW_HORIZONTAL
  size = const [SIZE_TO_CONTENT, hdpx(50)]
  hplace = ALIGN_LEFT
  valign = ALIGN_BOTTOM
  gap = midPadding
  children = [
    rank != null ? starIcon
      : soldierCount != null ? mkDescTitle(soldierCount)
      : perksCount != null ? mkDescTitle(perksCount)
      : mkDescTitle(loc(titleText))
    addChild
  ]
}

let primeDesc = @(text, soldierClass = null) {
  size = const [FLEX, hdpx(100)]
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  children = [
    {
      size = FLEX_H
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text
    }
    soldierClass != null
      ? className(soldierClass).__update({ color = Color(255, 255,255) }, fontSub)
      : null
  ]
}

function primeDescription(texts, desc = ""){
  let {titleText = null, rank = null, perksCount = null,
    soliderClass = null, soldierCount = null, addChild = null } = texts
  return {
    size = FLEX_H
    margin = const [0, fsh(3)]
    flow = FLOW_VERTICAL
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    gap = midPadding
    children = [
      primeDescTitle(titleText, soldierCount, rank, perksCount, addChild)
      primeDesc(loc(desc), soliderClass)
    ]
  }
}

function soldiersCountDesc(classes){
  let countOverall = classes.values().reduce(@(res, count) res + count, 0)
  let children = classes.map(@(count, sClass) {
    size = FLEX_H
    flow = FLOW_VERTICAL
    hplace = ALIGN_CENTER
    children = className(sClass, count).__update({ color = Color(255, 255,255) }, fontSub)
  }).values()

  return {
    size = FLEX_H
    margin = const [0, fsh(3)]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    vplace = ALIGN_CENTER
    gap = midPadding
    children = [
      primeDescTitle(null, countOverall, null, null, {
        rendObj = ROBJ_TEXT
        text = loc("squads/soldiers", { count =  countOverall } )
        margin = const [hdpx(7),0]
      }.__update(fontBody))
      {
        flow = FLOW_VERTICAL
        gap = smallPadding
        size = const [FLEX, hdpx(100)]
        children
      }
    ]
  }
}

function primeDescBlock(squadCfg, addObject = null) {
  let { newClass, announceLocId, vehicleType = "", battleExpBonus = 0.0 } = squadCfg
  let { perksId } = getClassCfg(newClass)
  let perksCount = getRecommendedPerksCount(perksId, squadCfg.armyId)
  let hasVehicle = vehicleType != ""

  local rank = 0
  let soldierClasses = {}
  foreach (soldierData in squadCfg.startSoldiers) {
    let soldierClass = soldierData.sClass
    if (newClass == soldierClass && rank == 0)
      rank = soldierData.tier
    soldierClasses[soldierClass] <- (soldierClasses?[soldierClass] ?? 0) + 1
  }

  return {
    size = const [FLEX, hdpx(450)]
    maxWidth = hdpx(1000)
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    flow = FLOW_VERTICAL
    gap = hdpx(20)
    children = [
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        gap = primeDescGap
        children = [
          soldierClasses.len() > 1
            ? soldiersCountDesc(soldierClasses)
            : primeDescription({soldierCount = soldierClasses.values()[0],
                                soliderClass = soldierClasses.keys()[0]},
                                loc("squads/primeSoldiersCount", { count = squadCfg.size }))
          primeDescription({ rank }, loc(hasVehicle
            ? "squads/primeMaxRankVehicle"
            : "squads/primeMaxRankInfantry",
            { rank }))
          primeDescription({ perksCount }, loc("squads/primeOptimalPerks"))
          battleExpBonus <= 0.0 ? null : primeDescription({
            titleText = $"+{(100 * battleExpBonus).tointeger()}%",
            addChild = {
              rendObj = ROBJ_TEXT
              text = loc("squads/primeExp")
              margin = const [hdpx(7),0]
            }.__update(fontBody)},
            loc("squads/primeMoreExp"))
        ]
      }
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        children = [
          mkDescBlock(announceLocId)
          addObject
        ]
      }
    ]
  }
}

return {
  mkSquadBackground
  mkBackWithImage
  mkUnlockInfo
  mkDescBlock
  primeDescBlock
  mkFullScreenBack
  mkSquadBodyBig
  mkPromoSquadIcon
  mkPromoBackBtn
  newSquadBlock
  starterPerkBlock
  primePerkBlock
}
