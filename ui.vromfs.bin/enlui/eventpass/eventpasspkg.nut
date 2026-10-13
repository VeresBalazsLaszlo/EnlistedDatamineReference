import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/components/faComp.nut" as faComp
import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/control/gui_buttons.nut" as JB
from "%ui/style/designConst.nut" import midPadding, bigPadding, titleTxtColor, attentionTxtColor,
  activeTxtColor, defTxtColor, startBtnWidth, defSlotBgColor
from "%ui/components/unseenSignal.nut" import blinkUnseenIcon
from "%ui/eventPass/eventTaskRewardsState.nut" import seasonEndTime
from "%ui/battlepass/rewardsPkg.nut" import mkSeasonTimeWithText, rewardWidthToHeight, defCardSize, mkRewardIcon, mkRewardImages
from "%ui/battlepass/bpPkg.nut" import cardBottom
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, casualFlagStyle, primeFlagStyle
from "%ui/style/cursors.nut" import setTooltip, withTooltip
from "%ui/components/itemsInfo.nut" import itemNameFromGametemplate
from "%ui/components/msgbox.nut" import showMessageWithContent
from "%ui/eventPass/eventPassIconPkg.nut" import eventPassIcon
from "%ui/eventPass/bpEventSettings.nut" import bpEventSettings
from "%ui/vehicles/vehiclesListState.nut" import viewVehicle, selectVehParams
from "%ui/shop/previewDrops.nut" import squadPreview, itemPreview
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/components/mkXpBooster.nut" import mkXpBooster, mkBoosterInfo, mkBoosterLimits
from "%ui/soldiers/model/all_items_templates.nut" import findTemplateInArmies
from "%ui/ui_library.nut" import *
from "%ui/style/fontsStyle.nut" import fontHeading1, fontHeading2, fontSub, fontBody


let { hasEliteEventPass } = require("eliteEventPass.nut")


const DAY_SEC = 86400
const BP_LEFT_DAYS_ALERT = 3

const sizeBlocks        = fsh(40)
const iconSize          = hdpx(35)
const cardBpIconSize    = [hdpxi(30), hdpxi(30)]
const lockBPLarge       = [hdpxi(90), hdpxi(90)]
const previewImageSize  = [hdpxi(550), hdpxi(400)]
const imageHeight       = hdpx(210)
const imageSize         = [rewardWidthToHeight * imageHeight, imageHeight]
const rewardCardSize    = [hdpx(180), hdpx(250)]

let unseenIcon = blinkUnseenIcon(1, attentionTxtColor)

let timeTracker = mkSeasonTimeWithText(seasonEndTime, const { margin = [0, 0, 0, midPadding]},
  const { color = defTxtColor })

let curItemName = @(text, style = fontHeading2) {
  rendObj = ROBJ_TEXT
  padding = const [midPadding, 0]
  text
  color = titleTxtColor
}.__update(style)

let textAreaStyle = const {
  size = const [hdpx(500), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
}

let tooltipStyle = const {
  size = const [hdpxi(400), SIZE_TO_CONTENT]
  halign = ALIGN_LEFT
}

let curItemDescription = @(text, style = textAreaStyle) {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  margin = const [midPadding, 0]
  color = titleTxtColor
  text
}.__update(fontSub, style)

function lockScreenBlock() {
  let res = { watch = hasEliteEventPass }
  if (hasEliteEventPass.get())
    return res

  let { getLockIcon } = bpEventSettings.get()
  return res.__update({
    flow = FLOW_VERTICAL
    gap = sh(1)
    vplace = ALIGN_BOTTOM
    children = [
      {
        rendObj = ROBJ_IMAGE
        hplace = ALIGN_CENTER
        behavior = Behaviors.Button
        size = lockBPLarge
        onHover = @(on) setTooltip(on ? loc("eventPass/required") : null)
        image = Picture(getLockIcon(lockBPLarge))
      }
      {
        rendObj = ROBJ_TEXT
        text = utf8ToUpper(loc("eventPass/required"))
        color = titleTxtColor
      }.__update(fontHeading2)
    ]
  })
}

let lockScreen = @(showingItem)
  (showingItem?.isPremium || showingItem?.isSpecial) ? lockScreenBlock : null

function eventCardPremiumIcon() {
  let mkIconFn = hasEliteEventPass.get()
    ? bpEventSettings.get().getTokenIcon
    : bpEventSettings.get().getLockIcon
  return {
    watch = [bpEventSettings, hasEliteEventPass]
    hplace = ALIGN_CENTER
    children = {
      size = cardBpIconSize
      rendObj = ROBJ_IMAGE
      image = Picture(mkIconFn(cardBpIconSize))
      behavior = Behaviors.Button
      onHover = @(on) setTooltip(!on ? null
        : hasEliteEventPass.get() ? loc("eventPass/reward")
        : loc("eventPass/required")
      )
    }
  }
}

function bpItemInfo(showingItem, infoObject) {
  if (showingItem == null)
    return null

  let { name = null, description = null, isSpecial = false, gametemplate = null } = showingItem

  let itemName = name == null ? null : curItemName(loc(name))
  let itemDescription = description == null ? null : curItemDescription(loc(description))
  let specialDescription = !isSpecial ? null
    : curItemDescription(loc("bp/otherRewardsAvailable", {
      weapon = itemNameFromGametemplate(gametemplate)
    }))

  return {
    size = FLEX
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    children = [
      {
        flow = FLOW_VERTICAL
        hplace = ALIGN_CENTER
        halign = ALIGN_CENTER
        children = [
          itemName
          itemDescription
          specialDescription
          infoObject
        ]
      }
    ]
  }
}

let bpTitle = @(hasPremiumBp, tailWidth = null) mkHeaderFlag(
  @() {
    watch = bpEventSettings
    padding = [midPadding * 2, midPadding * 3]
    rendObj = ROBJ_TEXT
    text = loc(hasPremiumBp
      ? bpEventSettings.get().passTitlePrem
      : bpEventSettings.get().passTitle)
  }.__update(fontHeading1),
  {
    tail = tailWidth
    transform = true
    animations = const [
      { prop = AnimProp.translate, from = [-sizeBlocks, 0], to = [0, 0], duration = 0.2,
        easing = InOutCubic, play = true }
      { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5,
        easing = InOutCubic, play = true }
    ]
  }.__update(hasPremiumBp ? primeFlagStyle : casualFlagStyle)
)

let msgEndSeason = @() showMessageWithContent({
  content = {
    flow = FLOW_VERTICAL
    size = FLEX_H
    halign = ALIGN_CENTER
    gap = hdpx(40)
    children = [
      {
        size = const [sw(35), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        rendObj = ROBJ_TEXT
        color = attentionTxtColor
        text = loc("bp/attention")
      }.__update(fontHeading1)
      {
        size = const [sw(50), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = loc("eventPass/endSeasonMsg")
      }.__update(fontBody)
    ]
  }
  buttons = const [
    { text = loc("Close"), isCurrent = true, customStyle = { hotkeys = [[$"^{JB.B}"]] } }
  ]
})

let endEventAlert = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    unseenIcon
    {
      rendObj = ROBJ_TEXTAREA
      behavior = [Behaviors.TextArea]
      size = FLEX_H
      text = loc("eventPass/endSeasonMsgShort")
      color = attentionTxtColor
    }.__update(fontSub)
  ]
}

let eventAlertBlock = watchElemState(@(sf) {
  rendObj = ROBJ_BOX
  size = const [startBtnWidth, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  behavior = Behaviors.Button
  onClick = msgEndSeason
  padding = const [midPadding, bigPadding]
  margin = const [0, midPadding]
  valign = ALIGN_CENTER
  borderWidth = const [hdpx(1), 0, hdpx(1), 0]
  borderColor = sf & S_HOVER ? attentionTxtColor : defSlotBgColor
  opacity = sf & S_HOVER ? 0.8 : 1
  gap = bigPadding
  children = [
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      children = [
        timeTracker
        endEventAlert
      ]
    }
    faComp("chevron-right", {
      fontSize = hdpxi(26)
      vplace = ALIGN_CENTER
      hplace = ALIGN_RIGHT
      color = sf & S_HOVER ? attentionTxtColor : defTxtColor
    })
  ]
})

function mkTimerBlock() {
  let hasAlert = Computed(@() seasonEndTime.get() <= serverTime.get() + BP_LEFT_DAYS_ALERT * DAY_SEC)
  return @() {
    watch = hasAlert
    children = hasAlert.get() ? eventAlertBlock
      : timeTracker
  }
}

let bpHeader = @(showingItem, closeButton, infoObject = null) {
  size = FLEX_H
  children = [
    mkTimerBlock()
    bpItemInfo(showingItem, infoObject)
    closeButton
  ]
}

let previewImage = @(showingItem) showingItem?.previewImage == null ? null : {
  rendObj = ROBJ_IMAGE
  size = previewImageSize
  image = Picture("{0}:{1}:{2}"
    .subst(showingItem.previewImage, previewImageSize[0], previewImageSize[1]))
  keepAspect = KEEP_ASPECT_FIT
}

let premiumPassHeader = {
  flow = FLOW_HORIZONTAL
  gap = midPadding
  padding = const [sh(5), 0, 0, 0]
  children = [
    const {
      rendObj = ROBJ_TEXT
      text = loc("eventPass/elite")
      color = attentionTxtColor
    }.__merge(fontBody)
    @() {
      watch = bpEventSettings
      rendObj = ROBJ_TEXT
      text = loc(bpEventSettings.get().passTitle)
      color = titleTxtColor
    }.__update(fontBody)
  ]
}

let mkBpIconBlock = @(children = []) {
  size = const [sw(20), FLEX]
  hplace = ALIGN_RIGHT
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = midPadding
  children = [
    premiumPassHeader
    eventPassIcon(hdpxi(220))
  ].extend(children)
}

function getUniqueRewards(unlock) {
  let items = {}
  foreach (stage in unlock?.stages ?? []){
    let { rewards = {} } = stage
    foreach (idStr, amount in rewards)
      items[idStr] <- (items?[idStr] ?? 0) + amount
  }
  return { items }
}

function rewardTooltip(showingItem) {
  if (showingItem == null)
    return null

  let { name = null, description = null, isSpecial = false, gametemplate = null } = showingItem
  let children = []
  if (name != null)
    children.append(curItemName(loc(name), fontSub))
  if (description != null)
    children.append(curItemDescription(loc(description), tooltipStyle))
  if (isSpecial)
    children.append(curItemDescription(
      loc("bp/otherRewardsAvailable", { weapon = itemNameFromGametemplate(gametemplate) }),
      tooltipStyle))

  return tooltipCtor({
    flow = FLOW_VERTICAL
    children
  })
}

let mkBoosterCard = @(boosterTemplate, mkTooltip) [
  withTooltip({
    size = defCardSize
    hplace = ALIGN_CENTER
    children = mkXpBooster(boosterTemplate).__update(const { margin = 0 })
  }, mkTooltip)
  {
    size = FLEX
    padding = midPadding
    children = [
      mkBoosterInfo(boosterTemplate, const fontBody.__merge({ color = activeTxtColor }))
      mkBoosterLimits(boosterTemplate, const fontBody.__merge({ color = activeTxtColor }))
    ]
  }
]

let mkPreviewCamo = @(basetpl, armyId, template, vehCamouflageId)
  function() {
    selectVehParams.set({
      isCustomMode = true
      isHitcamMode = false
      isForced = true
      skin = { id = vehCamouflageId }
    })
    viewVehicle.set({
      basetpl
      guid = ""
      links = { [armyId] = "army" }
    }.__update(template))
  }


function mkPreviewCb(reward, crateContentVal, templates, armies) {
  let { squadId = null } = reward
  if (squadId != null)
    return @() squadPreview({ id = squadId })

  let { vehicle = null, camouflage = null } = reward
  if (vehicle != null && camouflage != null) {
    let { template = null, armyId = "" } = findTemplateInArmies(templates, armies, vehicle)
    if (template != null)
      return mkPreviewCamo(vehicle, armyId, template, camouflage)
  }

  let { crateId = null, itemTemplate = null } = reward
  let rewardItem = (crateId != null && crateId in crateContentVal)
    ? crateContentVal?[crateId].items[0][0].id
    : itemTemplate

  if (rewardItem != null)
    return @() itemPreview({ id = rewardItem })
  return null
}

function mkSmallCard(rewardData, armies,
    crateContentVal, templates, boostersConfigVal, addToContainer, infoIcon) {
  local cardChildren = []
  local onClick = null

  let { reward, count } = rewardData
  let { itemTemplate = null } = reward
  let boosterTemplate = boostersConfigVal?[itemTemplate]
  let mkTooltip = @() rewardTooltip(reward)
  if (boosterTemplate != null)
    cardChildren = mkBoosterCard(boosterTemplate, mkTooltip)

  else {
    let cardImages = mkRewardImages(reward, imageSize, const { hplace = ALIGN_CENTER })
    let cardIcon = mkRewardIcon(reward, iconSize, const { vplace = ALIGN_CENTER })
    cardChildren = [
      withTooltip(cardImages, mkTooltip)
      cardBottom(count, cardIcon)
    ]

    onClick = mkPreviewCb(reward, crateContentVal, templates, armies)
    if (onClick != null)
      cardChildren.append(infoIcon)
  }

  return {
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    vplace = ALIGN_BOTTOM
    halign = ALIGN_CENTER
    gap = bigPadding
    children = [
      {
        size = rewardCardSize
        xmbNode = XmbNode()
        behavior = Behaviors.Button
        onClick
        children = cardChildren
        sound = const {
          hover = "ui/enlist/button_highlight"
          click = "ui/enlist/button_click"
        }
      }
      addToContainer
    ]
  }
}

return freeze({
  timeTracker
  bpTitle
  bpHeader
  lockScreen
  previewImage
  previewImageSize
  premiumPassHeader
  mkBpIconBlock
  eventCardPremiumIcon
  getUniqueRewards
  mkSmallCard
  mkPreviewCb
})
