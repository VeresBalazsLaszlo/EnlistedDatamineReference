import "%ui/components/mkSoldierCard.nut" as mkSoldierCard
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontSub
from "%ui/soldiers/model/config/squadsConfig.nut" import squadsCfgById
from "%ui/style/designConst.nut" import smallPadding, midPadding, largePadding, bigPadding, defSlotBgColor, hoverSlotBgColor, unitSize
  , slotBaseSize, listCtors, warningColor, hoverBgColor
from "%ui/components/std.nut" import gray
from "%ui/components/text.nut" import dtext as dtxt
from "%ui/soldiers/components/itemComp.nut" import mkItem
from "%sqstd/math.nut" import calc_golden_ratio_columns
from "%ui/components/mkXpBooster.nut" import mkXpBooster, mkBoosterInfo, mkBoosterLimits
from "%ui/meta/perks/perksExp.nut" import perkLevelsGrid
from "%ui/eventPass/eventItemPkg.nut" import mkEventItemCard
from "%ui/ui_library.nut" import *

let { txtColor } = listCtors


let itemSizeShort = [3.4 * unitSize, 2.5 * unitSize]
let itemSizeLong = [8.0 * unitSize, 2.5 * unitSize]
let itemSizeByTypeMap = {
  soldier = slotBaseSize
  sideweapon = itemSizeShort
  grenade = itemSizeShort
  scope = itemSizeShort
  knife = itemSizeShort
  repair_kit = itemSizeShort
  medkits = itemSizeShort
  melee = itemSizeShort
  booster = itemSizeShort
}

let extraHeightByTypeMap = {
  ticket = bigPadding * 2
  vehicle = largePadding
  currency = bigPadding * 2
}
let getExtraHeight = @(itemType) extraHeightByTypeMap?[itemType] ?? 0

local animDelay = 0
local trigger = ""
let getItemSize = @(itemType) itemSizeByTypeMap?[itemType] ?? itemSizeLong
const minColumns = 2

const TITLE_DELAY = 0.5
const ITEM_DELAY = 0.3
const ADD_OBJ_DELAY = 0.5
const SKIP_ANIM_POSTFIX = "_skip"


let dropTitle = @(titleText) {
  size = SIZE_TO_CONTENT
  margin = [midPadding, 0]
  transform = true
  animations = [
    { prop = AnimProp.opacity,   from = 0, to = 1, duration = 0.8, play = true, easing = InOutCubic}
    { prop = AnimProp.scale,     from = [1.5, 2], to = [1, 1], duration = 0.3, play = true, easing = InOutCubic}
    { prop = AnimProp.translate, from = [sh(40), -sh(20)], to = [0, 0], duration = 0.3, play = true, easing = OutQuart}
    { prop = AnimProp.opacity, from = 1, to = 0 duration = 0.1, playFadeOut = true, easing = InOutCubic}
  ]
  children = dtxt(titleText, {
    size = SIZE_TO_CONTENT
  }.__update(fontHeading2))
}

function blockTitle(blockId, params) {
  animDelay += TITLE_DELAY

  return {
    transform = true
    animations = params.hasAnim ? [
      { prop = AnimProp.opacity, from = 0, to = 0, duration = animDelay,
        play = true, easing = InOutCubic, trigger = $"{trigger}{SKIP_ANIM_POSTFIX}" }
      { prop = AnimProp.opacity,   delay = animDelay, from = 0, to = 1, duration = 0.8,
        play = true, easing = InOutCubic, trigger = trigger }
      { prop = AnimProp.scale,     delay = animDelay, from = [1.5, 2], to = [1, 1], duration = 0.8,
        play = true, easing = InOutCubic, trigger = trigger }
      { prop = AnimProp.translate, delay = animDelay, from = [sh(40), -sh(20)], to = [0, 0], duration = 0.8,
        play = true, easing = OutQuart, trigger = trigger }
      { prop = AnimProp.opacity, from = 1, to = 0 duration = 0.1, playFadeOut = true, easing = InOutCubic}
    ] : []
    children = dtxt(loc($"received/{blockId}"), {
      size = SIZE_TO_CONTENT
      hplace = ALIGN_LEFT
      color = gray
    }.__update(fontBody))
  }
}

let mkItemByTypeMap = {
  soldier = function(p){
    let group = ElemGroup()
    let soldierInfo = p.item
    let stateFlags = Watched(0)
    return @() {
      watch = [stateFlags, perkLevelsGrid]
      group = group
      behavior = Behaviors.Button
      onElemState = @(sf) stateFlags.set(sf)
      onClick = p.onClickCb

      children = mkSoldierCard({
        soldierInfo = soldierInfo
        squadInfo = squadsCfgById.get()?[soldierInfo?.armyId ?? ""][soldierInfo?.squadId ?? ""]
        expToLevel = perkLevelsGrid.get()?.expToLevel
        group = group
        sf = stateFlags.get()
        isDisarmed = p?.isDisarmed
      })
    }
  }

  booster = function(p) {
    let { item, onClickCb } = p
    let stateFlags = Watched(0)
    let { count = 1, template = {} } = item
    let { expMul = 0 } = template
    let boosterContainer = {
      size = const [ph(90), ph(105)]
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
    }
    return function() {
      let sf = stateFlags.get()
      let textColor = txtColor(sf)
      return {
        watch = stateFlags
        rendObj = ROBJ_SOLID
        size = FLEX
        behavior = Behaviors.Button
        onElemState = @(s) stateFlags.set(s)
        onClick = onClickCb
        color = sf & S_HOVER ? hoverSlotBgColor : defSlotBgColor
        children = [
          mkXpBooster(boosterContainer, expMul < 0)
          {
            size = FLEX
            padding = smallPadding
            children = [
              mkBoosterInfo(template, fontSub.__merge({ color = textColor }))
              mkBoosterLimits(template, fontSub.__merge({ color = textColor }))
              count <= 1 ? null
               : {
                    rendObj = ROBJ_TEXT
                    hplace = ALIGN_RIGHT
                    text = loc("common/amountShort", item)
                    color = textColor
                  }.__update(fontSub)
            ]
          }
        ]
      }
    }
  }
  consumables = function(p) {
    let { item, onClickCb } = p
    return mkEventItemCard(item, onClickCb)
  }
}

const alertIconSize = hdpxi(16)

let alertIconObject = {
  padding = smallPadding
  margin = smallPadding
  rendObj = ROBJ_SOLID
  color = warningColor
  hplace = ALIGN_RIGHT
  children = {
    size = const [alertIconSize, alertIconSize]
    rendObj = ROBJ_IMAGE
    image = Picture("!ui/uiskin/campaign/change_campaing.svg:{0}:{0}:K".subst(alertIconSize))
  }
}


let selectedLine = {
  size = const [FLEX, hdpx(2)]
  vplace = ALIGN_BOTTOM
  rendObj = ROBJ_SOLID
  color = hoverBgColor
}

function mkItemExt(item, selectedTpl, params) {
  let { hasAnim, onVisibleCb, armyByGuid, isDisarmed, onItemClick, pauseTooltip } = params

  let extraHeight = getExtraHeight(item?.itemtype)

  let ctor = mkItemByTypeMap?[item?.itemtype]
  let size = getItemSize(item?.itemtype)
  let itemSize = [size[0], size[1] - extraHeight]
  let itemObject = (ctor ?? mkItem)({
    item
    onClickCb = onItemClick != null ? @(...) onItemClick(item) : null
    itemSize
    canDrag = false
    isInteractive = onItemClick != null
    pauseTooltip = pauseTooltip ?? Watched(false)
  }.__update(ctor == null ? {} : { isDisarmed }))
  let campObject = item.guid in armyByGuid ? alertIconObject : null

  animDelay += ITEM_DELAY
  return {
    key = item?.guid ?? item
    size
    children = [
      itemObject
      campObject
      item?.basetpl == selectedTpl ? selectedLine : null
    ]
    transform = true
    animations = hasAnim ? [
      { prop = AnimProp.opacity,                      from = 0, to = 0, duration = animDelay,
        play = true, easing = InOutCubic, trigger = $"{trigger}{SKIP_ANIM_POSTFIX}"}
      { prop = AnimProp.opacity,   delay = animDelay, from = 0, to = 1, duration = 0.4,
        play = true, easing = InOutCubic, trigger = trigger, onFinish = onVisibleCb}
      { prop = AnimProp.scale,     delay = animDelay, from = [1.5, 2], to = [1, 1], duration = 0.5,
        play = true, easing = InOutCubic, trigger = trigger }
      { prop = AnimProp.translate, delay = animDelay, from = [sh(40), -sh(20)], to = [0, 0], duration = 0.5,
        play = true, easing = OutCubic, trigger = trigger }
    ] : []
  }
}

function blockContent(items, selectedTpl, columnsAmount, params) {
  let itemSize = getItemSize(items?[0].itemtype)
  let containerWidth = columnsAmount * itemSize[0] + (columnsAmount - 1) * midPadding
  return {
    flow = FLOW_HORIZONTAL
    children = wrap(items.map(@(item) mkItemExt(item, selectedTpl, params)), {
      width = containerWidth
      hGap = midPadding
      vGap = midPadding
      hplace = ALIGN_CENTER
      halign = ALIGN_CENTER
    })
  }
}

function itemsBlock(items, blockId, selectedTpl, params) {
  if (!items.len())
    return null

  let { hasItemTypeTitle, width } = params
  let viewBlockId = hasItemTypeTitle ? blockId : null

  let itemSize = getItemSize(items?[0].itemtype)
  let columnsAmount = width != null
    ? ((width - (width / itemSize[0] - 1).tointeger() * midPadding) / itemSize[0]).tointeger()
    : max(minColumns, calc_golden_ratio_columns(items.len(), itemSize[0] / itemSize[1]))

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = midPadding
    children = (viewBlockId ? [blockTitle(viewBlockId, params)] : []) 
      .append(blockContent(items, selectedTpl, columnsAmount, params))
  }
}

function appearAnim(comp, hasAnim) {
  animDelay += ADD_OBJ_DELAY
  return {
    size = FLEX_H
    halign = ALIGN_CENTER
    children = comp

    animations = hasAnim ? [
      { prop = AnimProp.opacity,                    from = 0, to = 0, duration = animDelay,
        play = true, trigger = $"{trigger}{SKIP_ANIM_POSTFIX}" }
      { prop = AnimProp.opacity, delay = animDelay, from = 0, to = 1, duration = 0.8,
        play = true, easing = InOutCubic, trigger = trigger }
    ] : []
  }
}

let ITEMS_REWARDS_PARAMS = {
  hasAnim = true
  titleText = ""
  addChildren = []
  baseAnimDelay = 0.0
  hasItemTypeTitle = true
  animTrigger = "mkAnimatedItems"
  onVisibleCb = null
  width = null
  onItemClick = null
  armyByGuid = {}
  isDisarmed = false
  pauseTooltip = null
}

function mkAnimatedItemsBlock(itemBlocks, selectedTpl, params = ITEMS_REWARDS_PARAMS) {
  params = ITEMS_REWARDS_PARAMS.__merge(params)

  let {
    baseAnimDelay, animTrigger, hasAnim, titleText, addChildren
  } = params

  animDelay = baseAnimDelay
  trigger = animTrigger
  let underline = {
    rendObj = ROBJ_FRAME
    size = const [pw(80), 1]
    margin = midPadding
    borderWidth = const [0, 0, 1, 0]
    color = Color(100, 100, 100, 50)
    transform = true
    animations = hasAnim ? [
      { prop = AnimProp.scale, from = [0, 1], to = [0, 1], duration = 0.2,
        play = true, easing = InOutCubic, trigger = trigger }
      { prop = AnimProp.scale, delay = 0.2 from = [0, 1], to = [1, 1], duration = 1,
        play = true, easing = InOutCubic, trigger = trigger }
    ] : []
  }

  let blocks = itemBlocks.keys()

  let children = []
  if (titleText.len())
    children.append(
      dropTitle(titleText)
      underline
    )
  else
    animDelay -= TITLE_DELAY

  children.append({
    flow = FLOW_VERTICAL
    gap = midPadding
    children = blocks.map(@(blockId)
      itemsBlock(itemBlocks[blockId], blockId, selectedTpl, params)
    )
  })

  children.extend(addChildren.map(@(comp) appearAnim(comp, hasAnim)))

  return {
    totalTime = hasAnim ? animDelay : 0
    component = {
      size = FLEX_H
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      children = children
    }
  }
}

return mkAnimatedItemsBlock
