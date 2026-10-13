from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/soldiers/model/boosters.nut" import boostersConfig, isBooster
from "%ui/soldiers/components/itemComp.nut" import mkItem
from "%ui/battlepass/rewardsPkg.nut" import mkRewardIcon, mkRewardImages, rewardWidthToHeight
from "%ui/style/designConst.nut" import defBgColor, midPadding, smallPadding, activeTxtColor, titleTxtColor, accentTitleTxtColor
from "%ui/components/mkXpBooster.nut" import mkXpBooster, mkBoosterInfo, mkBoosterLimits
from "%ui/components/defcomps.nut" import txt
from "%ui/items/crateInfo.nut" import crateItemsSort
from "%ui/components/itemsInfo.nut" import boosterName, itemNameFromItem
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/meta/profile.nut" import commonArmy
from "%ui/ui_library.nut" import *

const sizeCard = [hdpxi(180), hdpxi(200)]
const sizeIcon = hdpx(35)

const trigger = "rewardAnim"
const wndPadding = sh(1)
const rewardWidth = hdpxi(160)

const wndParams = {
  bgColor = Color(11, 11, 19)
  baseColor  = Color(112, 112, 112)
  activeColor  = Color(219, 219, 219)
  rewardColor  = accentTitleTxtColor
}

let cardBottom = @(count, cardIcon){
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  margin = midPadding
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  children = [
    count == 1 ? null
      : {
          rendObj = ROBJ_TEXT
          padding = [0, smallPadding]
          text = loc("common/amountShort", { count })
          color = activeTxtColor
        }.__update(fontBody)
    cardIcon
  ]
}


function mkRewardCardByTemplate(itemTemplate) {
  if (itemTemplate == null)
    return null

  return function() {
    let res = {
      watch = [allItemTemplates, boostersConfig]
      size = sizeCard
      padding = smallPadding
    }

    local template = boostersConfig.get()?[itemTemplate]
    if (template != null)
      return res.__update({
        children = [
          mkXpBooster(template)
          mkBoosterInfo(template, fontBody.__merge({ color = titleTxtColor }))
          mkBoosterLimits(template, fontBody.__merge({ color = titleTxtColor }))
        ]
      })

    foreach (armyTemplates in allItemTemplates.get())
      if (itemTemplate in armyTemplates) {
        template = armyTemplates[itemTemplate]
        break
      }

    if (template == null)
      return null

    return res.__update({
      children = mkItem({
        item = template
        canDrag = false
        isInteractive = true
        isAvailable = true
        itemSize = sizeCard
      })
    })
  }
}

function mkRewardCardByPresentation(presentation, count = 1, addObject = null, size = sizeCard) {
  let cardIcon = mkRewardIcon(presentation, sizeIcon, { vplace = ALIGN_CENTER })
  let imageHeight = (size[1] * 0.8).tointeger()
  let imageSize = [(rewardWidthToHeight * imageHeight).tointeger(), imageHeight]
  return {
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    rendObj = ROBJ_SOLID
    color = defBgColor
    children = [
      mkRewardImages(presentation, imageSize, {
        hplace = ALIGN_CENTER
        pos = [0, smallPadding]
      })
      addObject
      count > 0 ? cardBottom(count, cardIcon) : null
    ]
  }
}

let mkBoosterItemRow = @(item) {
  flow = FLOW_HORIZONTAL
  gap = smallPadding
  children = [
    txt({
      text = loc("common/amountShort", { count = item.count })
      color = wndParams.rewardColor
    }).__update(fontSub)
    txt(isBooster(item) ? boosterName(item) : itemNameFromItem(item))
  ]
}

let mkTextArea = @(text) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  size = FLEX_H
  text
  color = activeTxtColor
}.__update(fontSub)

let boosterTopHint = mkTextArea(loc("boosterTooltipHeader"))
let boosterBottomHint = mkTextArea(loc("boosterTooltipHint"))

let boosterItem = { itemtype = "booster" }

let mkBoosterItemsView = @(boostersItems, armyId)
  function() {
    let templates = allItemTemplates.get()
    let armyTemplates = templates?[armyId]
    let commonTemplates = templates?[commonArmy.get()]
    let boosters = boostersConfig.get()

    let items = boostersItems.map(@(pack) pack
      .map(function(item) {
          let { itemTemplate = "" } = item
          let rewardItem = item.__merge({ basetpl = itemTemplate })

          if (itemTemplate in boosters)
            rewardItem.__update(boosterItem, { template = boosters[itemTemplate] })
          else
            rewardItem.__update(armyTemplates?[itemTemplate] ?? commonTemplates?[itemTemplate] ?? {})

          return rewardItem
      })
      .sort(crateItemsSort))

    let packsIds = ["reinforcing", "instant"]
    return {
      watch = [commonArmy, allItemTemplates, boostersConfig]
      size = FLEX_H
      flow = FLOW_VERTICAL
      children = [boosterTopHint]
        .extend(packsIds.map(function(packId) {
          let pack = items?[packId] ?? []
          if (pack.len() == 0)
            return null

          return {
            size = FLEX_H
            flow = FLOW_VERTICAL
            children = pack.map(mkBoosterItemRow)
          }
        }))
        .append(boosterBottomHint)
    }
  }


let mkMoveDownAnim = @(delay = 0) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true }
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true, delay }
  { prop = AnimProp.translate, from = [0, -sh(15)], to = [0,0], duration = 0.5,
    play = true, easing = OutQuart, delay }
]

let mkAppearAnim = @(delay = 0, onFinish = null, soundName = null) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, play = true, trigger }
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true,
    easing = InOutCubic, delay = delay, trigger, sound = { stop = soundName }}
  { prop = AnimProp.scale, from = [2,2], to = [1,1], duration = 0.6, play = true,
    easing = InOutCubic, delay = delay, trigger }
  { prop = AnimProp.translate, from = [0, -sh(15)], to = [0,0], duration = 0.6,
    play = true, easing = OutQuart, delay = delay, trigger, onFinish }
]


let mkRollAnim = @(duration, yPos, onEnter = null, onFinish = null, soundName = null) [
  { prop = AnimProp.translate, from = [0,yPos], to = [0,hdpx(50)],
    duration, play = true, trigger, onEnter, sound = { stop = soundName }}
  { prop = AnimProp.translate, from = [0,hdpx(50)], to = [0,0], duration = 0.2,
    play = true, delay = duration - 0.05, trigger, onFinish }
]

let mkGrayBox = @[pure](w) freeze({
  rendObj = ROBJ_BOX
  fillColor = 0xFF404040
  borderColor = 0xFF606060
  borderWidth = hdpx(1)
  size = [hdpx(w), FLEX]
})

let mkGrayArrow = @(x, y, w, h) freeze({
  pos = [hdpx(x), hdpx(y)]
  rendObj = ROBJ_IMAGE
  size = [hdpxi(w), hdpxi(h)]
  image = Picture("ui/skin#rewards/arrow_rewards.svg:{0}:{1}".subst(hdpxi(w), hdpxi(h)))
})

let bigRewardSeparatorBoxes = freeze({
  padding = const [wndPadding / 2, 0]
  flow = FLOW_HORIZONTAL
  gap = hdpx(2)
  size = const [hdpx(10), rewardWidth]
  children = [
    mkGrayBox(4)
    mkGrayBox(6)
  ]
})

let bigRewardSeparatorArrows = freeze({
  size = const [hdpx(10), hdpx(40)]
  children = [
    mkGrayArrow(-6, 0, 19, 40)
    mkGrayArrow(2, 0, 19, 40)
  ]
})

return freeze({
  wndParams
  sizeCard
  mkRewardCardByPresentation
  mkRewardCardByTemplate
  mkBoosterItemsView
  mkMoveDownAnim
  mkAppearAnim
  mkRollAnim
  animTrigger = trigger
  bigRewardSeparatorBoxes
  bigRewardSeparatorArrows
  rewardWidth
})
