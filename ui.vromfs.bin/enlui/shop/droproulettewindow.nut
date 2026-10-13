import "%ui/control/gui_buttons.nut" as JB
import "%ui/items/itemsMapping.nut" as itemMapping
import "%sqstd/rand.nut" as Rand
from "dagor.random" import rnd_int
from "math" import sin, PI
from "datetime" import date
from "%ui/style/fontsStyle.nut" import fontSub, fontBody, fontHeading1
from "%ui/shop/dropRouletteState.nut" import needOpenRouletteWnd, dropRoulette,
  closeRouletteWindow
from "%ui/components/modalWindows.nut" import addModalWindow, removeModalWindow
from "%ui/soldiers/model/cratesContent.nut" import crateContentWatch, getPossibleCratesList,
  unpackCrate, DropKind
from "%ui/items/crateUtils.nut" import mkCrateItemView, rewardSize, getMainVehicles
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/meta/profile.nut" import commonArmy
from "%ui/components/textButton.nut" import Regular, Primary
from "%ui/vehicles/vehDecorState.nut" import vehCustomizationCfg, vehCamouflageCfg
from "%ui/meta/metaConfigUpdater.nut" import isLootBoxProhibited
from "%ui/shop/previewDrops.nut" import dropDetails
from "%ui/battlepass/rewardsPkg.nut" import mkRewardImages
from "%sqstd/timers.nut" import debounce
from "%ui/components/scrollbar.nut" import makeHorizScroll
from "%ui/style/designConst.nut" import attentionTxtColor, defBgColor, smallPadding, midPadding,
  bigPadding, mainContentOffset, commonBtnHeight
from "%ui/ui_library.nut" import *


let spinner = require("%ui/components/spinner.nut")(hdpxi(90))


enum RollStatus {
  ROLL = "ROLL"
  STOP = "STOP"
}


const WND_UID = "dropRouletteWnd"
const PREV_ITEMS = 20
const BRAKE_ITERATIONS = 900
const ITEMS_IN_SCROLL_AREA = 5

let cardWidth = rewardSize[0]

let ROLL_MAX_SPEED = cardWidth / 2
const ROLL_MIN_SPEED = hdpx(1)

let rewardIdx = Watched(0)
let isRollInProgress = Watched(false)

let lineWidth = cardWidth * (PREV_ITEMS + 1)
let cardCount = (sw(100) / cardWidth ).tointeger()
let viewCardCount = cardCount - (cardCount + 1) % 2
let viewBoxWidth = viewCardCount * cardWidth
let xNeedOffset = lineWidth * 4 + cardWidth * (viewCardCount + 1) / 2
let crateImageSize = [hdpxi(260), hdpxi(260)]
let scrollWidth = ITEMS_IN_SCROLL_AREA * cardWidth + (ITEMS_IN_SCROLL_AREA - 1) * bigPadding
let randomFactor = (cardWidth / 2.3).tointeger()

local randomOffset = 0
local xMaxOffset = 0
local brakePath = 0.0
local iteration = 0
while (iteration <= BRAKE_ITERATIONS) {
  let angle = iteration.tofloat() * 90.0 / BRAKE_ITERATIONS
  brakePath += ROLL_MIN_SPEED + (1 - sin(angle * PI / 180.0)) * (ROLL_MAX_SPEED - ROLL_MIN_SPEED)
  iteration += max(1, (BRAKE_ITERATIONS - iteration) / 200)
}

let scrollHandler = ScrollHandler()

let cardsLineStyle = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  transform = true
  behavior = Behaviors.RtPropUpdate
}

let pointerStyle = {
  size = [rewardSize[0], smallPadding]
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_SOLID
  transform = true
  behavior = Behaviors.RtPropUpdate
  color = attentionTxtColor
}

let mkArrow = @(polyCommand, override = {}) {
  size = [bigPadding, bigPadding]
  pos = [0, smallPadding]
  rendObj = ROBJ_VECTOR_CANVAS
  color = attentionTxtColor
  commands = [
    [VECTOR_WIDTH, hdpx(1)],
    [VECTOR_FILL_COLOR, attentionTxtColor],
    polyCommand
  ]
}.__update(override)


local brakeIteration = 0
local pointFactor = 0.0
local xCurSpeed = ROLL_MAX_SPEED
local xCurOffset = (xMaxOffset - brakePath) % ROLL_MAX_SPEED
local rollStatus = RollStatus.ROLL

let mkTopPointer = @() {
  children = mkArrow([VECTOR_POLY, 0,0, 50,100, 100,0])
  update = @() {
    transform = {
      translate = [0, rollStatus == RollStatus.STOP || xCurOffset < xMaxOffset / 1.3
        ? -midPadding
        : -(midPadding + pointFactor * bigPadding)]
    }
  }
}.__update(pointerStyle)

let mkBtmPointer = @() {
  vplace = ALIGN_BOTTOM
  children = mkArrow([VECTOR_POLY, 0,100, 50,0, 100,100], {
    vplace = ALIGN_BOTTOM
    pos = [0, -smallPadding]
  })
  update = @() {
    transform = {
      translate = [0, rollStatus == RollStatus.STOP || xCurOffset < xMaxOffset / 1.3
        ? midPadding
        : midPadding + pointFactor * bigPadding]
    }
  }
}.__update(pointerStyle)


let mkText = @(text, override = {}) {
  rendObj = ROBJ_TEXT
  color = attentionTxtColor
  text
}.__update(fontSub, override)


function finishRoll() {
  rollStatus = RollStatus.STOP
  xCurOffset = xMaxOffset
  anim_skip("hide_drop")
  anim_start("show_drop")
}

isRollInProgress.subscribe(function(v) {
  if (!v)
    finishRoll()
  scrollHandler.scrollToX(10000000)
})

function mkRouletteView(idx, drop, cContent, params) {
  if (drop == null)
    return null

  let time = date()
  let rand = Rand(time.min * 60 + time.sec)
  let children = []
  let dropList = clone cContent
  local dropLeft = dropList.len()
  while (children.len() < PREV_ITEMS && dropLeft > 0) {
    --dropLeft
    let reward = dropList.remove(rand.rint(0, dropLeft))
    children.append(mkCrateItemView(reward, params))
  }
  children.append({
    children = [
      mkCrateItemView(drop, params)
      {
        size = FLEX
        rendObj = ROBJ_SOLID
        color = attentionTxtColor
        opacity = 0
        animations = [
          { prop = AnimProp.opacity, from = 0.0, to = 0.3, duration = 0.3,
            trigger = "show_drop" }
          { prop = AnimProp.opacity, from = 0.3, to = 0.0, duration = 0.7,
            delay = 0.3, trigger = "show_drop" }
        ]
      }
    ]
  })

  return {
    key = $"roulette_{idx}"
    size = FLEX_H
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = bigPadding * 2
    onAttach = function() {
      randomOffset = rnd_int(-randomFactor, randomFactor)
      xMaxOffset = xNeedOffset + randomOffset
      brakeIteration = 0
      xCurSpeed = ROLL_MAX_SPEED
      xCurOffset = (xMaxOffset - brakePath) % ROLL_MAX_SPEED
      pointFactor = 0
      rollStatus = RollStatus.ROLL
      isRollInProgress.set(true)
    }
    children = [
      mkText(loc("roulette/possibleRewardsHeader"), fontBody)
      {
        size = [viewBoxWidth, SIZE_TO_CONTENT]
        children = [
          {
            children
            update = function() {
              if (rollStatus == RollStatus.ROLL) {
                if (brakeIteration > BRAKE_ITERATIONS)
                  finishRoll()
                else if (xCurOffset >= xMaxOffset - brakePath) {
                  let angle = brakeIteration.tofloat() * 90.0 / BRAKE_ITERATIONS
                  xCurSpeed = ROLL_MIN_SPEED + (1 - sin(angle * PI / 180.0)) * (ROLL_MAX_SPEED - ROLL_MIN_SPEED)
                  brakeIteration += max(1, (BRAKE_ITERATIONS - brakeIteration) / 200)
                }
                xCurOffset = min(xMaxOffset, xCurOffset + xCurSpeed)
              }
              pointFactor = (xCurOffset % cardWidth).tofloat() / cardWidth
              return { transform = { translate = [xCurOffset % lineWidth, 0] } }
            }
          }.__update(cardsLineStyle)
          {
            children
            update = @() { transform = { translate = [xCurOffset % lineWidth - lineWidth, 0] } }
          }.__update(cardsLineStyle)
          mkTopPointer()
          mkBtmPointer()
        ]
      }
    ]
  }
}


let appearDropAnim = {
  transform = true
  animations = [
    { prop = AnimProp.opacity, from = 0, to = 0, duration = 1,
      loop = true, play = true, trigger = "hide_drop" }
    { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3,
      trigger = "show_drop", onEnter = @() isRollInProgress.set(false) }
    { prop = AnimProp.translate, from = [0, hdpx(160)], to = [0, 0],
      duration = 0.3, easing = OutCubic, trigger = "show_drop" }
  ]
}


let indefineDropObject = {
  size = FLEX
  rendObj = ROBJ_BOX
  borderWidth = [smallPadding, 0, smallPadding, 0]
  borderColor = attentionTxtColor
  fillColor = defBgColor
  children = spinner
  opacity = 0
  animations = [
    { prop = AnimProp.opacity, from = 1, to = 1, duration = 1,
      loop = true, play = true, trigger = "hide_drop" }
    { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.3,
      trigger = "show_drop" }
  ]
}


function mkDropView(idx, drops, params) {
  let content = {
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    margin = [midPadding, 0]
    children = drops.slice(0, idx + 1).map(@(drop, curIdx) {
      children = [
        curIdx == idx ? indefineDropObject : null
        {
          key = $"drop_{curIdx}_{curIdx == idx}"
          children = mkCrateItemView(drop, params)
        }.__update(curIdx == idx ? appearDropAnim : {})
      ]
    })
  }
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    gap = bigPadding
    children = [
      mkText(loc("roulette/youReceivedHeader"), fontBody)
      drops.len() <= ITEMS_IN_SCROLL_AREA ? content
        : makeHorizScroll(content, {
            scrollHandler
            size = [scrollWidth, SIZE_TO_CONTENT]
            rootBase = {
              behavior = Behaviors.Pannable
            }
          })
    ]
  }
}


let skipRoll = debounce(@() isRollInProgress.set(false), 0.1)
let btnParams = { hotkeys = [[$"^{JB.B} | Esc | Enter", { description = { skip = true }}]] }

let mkSkipAllButton = @(idx, drops, isRolling)
  Regular(loc("shop/skipAllWithCount", { count = drops.len() - idx - (isRolling ? 0 : 1) }),
    function() {
      rewardIdx.set(drops.len() - 1)
      skipRoll()
    }, {
      hotkeys = [["^J:Y", { description = { skip = true }}]]
    }
  )

let skipButton = Regular(loc("Skip"), @() isRollInProgress.set(false), btnParams)
let closeButton = Regular(loc("Close"), closeRouletteWindow, btnParams)
let nextButton = Primary(loc("shop/nextItem"), @() rewardIdx.modify(@(v) v + 1), btnParams)


let mkButtons = @(idx, drops) function() {
  let isRolling = isRollInProgress.get()
  let hasRemains = idx < drops.len() - 1
  return {
    watch = isRollInProgress
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    children = [
      isRolling ? skipButton
        : hasRemains ? nextButton
        : closeButton
      drops.len() > 1 && hasRemains ? mkSkipAllButton(idx, drops, isRolling) : null
    ]
  }
}


function dropCompareFunction(content, drop) {
  let { kind, id, count } = content
  return kind == DropKind.HERO ? content.heroTpl == drop?.heroTpl
    : kind == DropKind.SOLDIER ? id == drop?.sClass && content.armyId == drop?.armyId
    : kind == DropKind.ITEM ? id == drop?.basetpl && count == (drop?.count ?? 1)
    : kind == DropKind.VEHICLE ? id == drop?.basetpl
    : kind == DropKind.OUTFIT ? id == drop?.basetpl
    : kind == DropKind.CURRENCY ? id == drop?.notify.currency.id && count == (drop?.notify.currency.amount ?? 1)
    : kind == DropKind.BOOSTER ? id == drop?.basetpl
    : kind == DropKind.SQUAD ? id == drop?.squadId
    : kind == DropKind.DECORATOR ? id == drop?.guid
    : kind == DropKind.VEHDECORATOR ? id == drop?.id
    : kind == DropKind.CAMOUFLAGE ? id == drop?.basetpl
    : id == drop?.id
}


function mkRouletteUi() {
  let crateContent = Computed(function() {
    let { crate = null, possibleDrop = [] } = dropRoulette.get()
    if (crate == null)
      return null
    return possibleDrop
  })

  let drops = Computed(function() {
    let cContent = crateContent.get()
    let dropList = []
    let { items = [] } = dropRoulette.get()
    foreach (drop in items)
      foreach (content in cContent) {
        if (dropCompareFunction(content, drop)) {
          dropList.append(content)
          break
        }
      }
    return dropList
  })

  return function() {
    let watch = [rewardIdx, drops, crateContent, itemMapping, allItemTemplates, commonArmy,
      vehCustomizationCfg, vehCamouflageCfg]
    let dropsVal = drops.get()
    let cContentVal = crateContent.get()
    if (dropsVal.len() == 0 || cContentVal == null)
      return { watch }

    let params = {
      mapping = itemMapping.get()
      templates = allItemTemplates.get()
      commonArmyId = commonArmy.get()
      vCustCfg = vehCustomizationCfg.get()
      camoCfg = vehCamouflageCfg.get()
      camoVehicles = getMainVehicles(vehCamouflageCfg.get(), allItemTemplates.get(), cContentVal)
    }

    let idx = rewardIdx.get()
    let drop = dropsVal[idx % dropsVal.len()]
    return {
      watch
      size = FLEX
      flow = FLOW_VERTICAL
      gap = mainContentOffset
      valign = ALIGN_CENTER
      halign = ALIGN_CENTER
      children = [
        mkDropView(idx, dropsVal, params)
        mkRouletteView(idx, drop, cContentVal, params)
        mkButtons(idx, dropsVal)
      ]
    }
  }
}


function mkPreviewUi(previewInfo) {
  let { crate, items = [], possibleDrop = [] } = previewInfo
  let crateList = getPossibleCratesList(crate)

  local count = 0
  foreach (drop in items)
    foreach (content in possibleDrop)
      if (dropCompareFunction(content, drop)) {
        ++count
        break
      }

  return @() {
    watch = [itemMapping, isLootBoxProhibited]
    size = FLEX
    flow = FLOW_VERTICAL
    gap = mainContentOffset
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      {
        flow = FLOW_HORIZONTAL
        gap = mainContentOffset
        valign = ALIGN_CENTER
        children = [
          {
            flow = FLOW_VERTICAL
            gap = bigPadding
            children = [
              {
                children = [
                  mkRewardImages(itemMapping.get()?[crate] ?? {}, crateImageSize)
                  {
                    rendObj = ROBJ_TEXT
                    color = attentionTxtColor
                    text = loc("common/amountShort", { count })
                    hplace = ALIGN_RIGHT
                    vplace = ALIGN_BOTTOM
                  }.__update(fontHeading1)
                ]
              }
              Primary(loc("shop/openCrate"), @() dropRoulette.mutate(function(v) {
                v.hasChestPreview = false
              }), { size = [FLEX, commonBtnHeight] }.__update(btnParams))
            ]
          }
          dropDetails(crateList, isLootBoxProhibited.get())
        ]
      }
    ]
  }
}


let dropRouletteWnd = {
  key = WND_UID
  size = FLEX
  rendObj = ROBJ_WORLD_BLUR_PANEL
  onClick = @() null
  children = @() {
    watch = dropRoulette
    size = FLEX
    children = (dropRoulette.get()?.hasChestPreview ?? false)
      ? mkPreviewUi(dropRoulette.get())
      : mkRouletteUi()
  }
}

console_register_command(function(count) {
  let crate = "event_chest"
  let items = []
  let possibleDrop = unpackCrate("event_chest", crateContentWatch.get())

  let time = date()
  let rand = Rand(time.min * 60 + time.sec)
  let maxIdx = possibleDrop.len() - 1
  for (local i = 0; i < count; i++) {
    let drop = possibleDrop[rand.rint(0, maxIdx)]
    items.append({ count = drop?.count ?? 1, basetpl = drop?.basetpl ?? drop?.id })
  }
  dropRoulette.set({ crate, items, hasChestPreview = true })
}, "meta.openDropRoulette")

needOpenRouletteWnd.subscribe(function(isOpen) {
  if (!isOpen) {
    removeModalWindow(WND_UID)
    return
  }
  rewardIdx.set(0)
  addModalWindow(dropRouletteWnd)
})
