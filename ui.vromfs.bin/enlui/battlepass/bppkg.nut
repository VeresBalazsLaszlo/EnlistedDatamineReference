import "%ui/control/gui_buttons.nut" as JB
import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontHeading1, fontHeading2, fontSub, fontBody
from "%ui/style/designConst.nut" import smallPadding, midPadding, bigPadding, titleTxtColor, attentionTxtColor, startBtnWidth, defSlotBgColor
  , defTxtColor, activeTxtColor, defBgColor, commonBorderRadius, accentTitleTxtColor, totalBlack, bigOffset
from "%ui/components/mkProgressBar.nut" import progressBarHeight, completedProgressLine, acquiredProgressLine, progressContainerCtor, gradientProgressLine, inactiveProgressCtor
from "%ui/components/glareAnimation.nut" import glareAnimation
from "%ui/components/unseenSignal.nut" import blinkUnseenIcon
from "%ui/battlepass/bpState.nut" import seasonEndTime
from "%ui/battlepass/rewardsPkg.nut" import mkSeasonTimeWithText, mkRewardIcon, mkRewardImages, rewardWidthToHeight, defCardSize
from "%ui/components/mkHeaderFlag.nut" import mkHeaderFlag, casualFlagStyle, primeFlagStyle
from "%ui/components/textButton.nut" import Purchase
from "%ui/components/mkXpBooster.nut" import mkXpBooster, mkBoosterInfo, mkBoosterLimits
from "%ui/style/cursors.nut" import setTooltip
from "%ui/battlepass/eliteBattlePass.nut" import hasEliteBattlePass
from "%ui/components/itemsInfo.nut" import itemNameFromGametemplate
from "%ui/components/msgbox.nut" import showMessageWithContent
from "%ui/battlepass/battlePassPkg.nut" import dynamicSeasonBPIcon
from "%ui/battlepass/bpWindowState.nut" import RewardState
from "%ui/ui_library.nut" import *

const DAY_SEC = 86400
const BP_LEFT_DAYS_ALERT = 3
const BP_RANK_DAYS_ALERT = 7

const sizeBlocks        = fsh(40)
let hugePadding       = midPadding * 4
const sizeIcon          = hdpx(35)
let sizeCard          = [hdpx(180), hdpx(230)]
const imageHeight       = hdpx(210)
let imageSize         = [rewardWidthToHeight * imageHeight, imageHeight]
let btnSize           = [hdpx(330), hdpx(55)]
let cardSelectAnim    = [ { prop = AnimProp.translate, duration = 0.15, easing = InOutCubic } ]
let cardStateCommon   = { translate = [0, 0] }
let cardStateSelected = { translate = [0, -hugePadding] }
const gapCards          = hdpx(32)
let lockBPLarge       = [hdpxi(90), hdpxi(90)]
let previewImageSize  = [hdpxi(495), hdpxi(360)]
let bgFree            = [hdpxi(180), hdpxi(30)]
let logoBP            = [hdpxi(30), hdpxi(30)]
let recurringIcon     = [hdpxi(36), hdpxi(30)]
const progressWidth     = hdpxi(174)
let unseenIcon = blinkUnseenIcon(1, attentionTxtColor)

let timeTracker = mkSeasonTimeWithText(seasonEndTime, { margin = [0, 0, 0, midPadding]},
  { color = defTxtColor })

let curItemName = @(locId) locId == null ? null : {
  rendObj = ROBJ_TEXT
  padding = [midPadding, 0]
  text = loc(locId)
  color = titleTxtColor
}.__update(fontHeading2)

let textAreaStyle = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
}.__update(fontSub)

let curItemDescription = @(locId) locId == null ? null : {
  size = const [hdpx(720), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  margin = [midPadding, 0]
  color = titleTxtColor
  text = loc(locId)
}.__update(textAreaStyle)

function lockScreenBlock() {
  let res = { watch = hasEliteBattlePass }
  if (hasEliteBattlePass.get())
    return res

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
        onHover = @(on) setTooltip(on ? loc("bp/required/tip") : null)
        image = Picture($"!ui/uiskin/battlepass/lock_bp.svg:{lockBPLarge[0]}:{lockBPLarge[1]}:K")
      }
      {
        rendObj = ROBJ_TEXT
        text = loc("bp/required")
        color = titleTxtColor
      }.__update(fontHeading2)
    ]
  })
}

function bpItemInfo(showingItem, infoObject) {
  if (showingItem == null)
    return null

  let { name = null, description = null, isSpecial = false, gametemplate = null } = showingItem
  let itemName = curItemName(name)
  let itemDescription = curItemDescription(description)
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
  {
    padding = [midPadding * 2, midPadding * 3]
    rendObj = ROBJ_TEXT
    text = hasPremiumBp ? loc("bp/eliteBP") : loc("bp/battlePass")
  }.__update(fontHeading1),
  {
    tail = tailWidth
    transform = true
    animations = [
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
        text = loc("bp/endSeasonMsg")
      }.__update(fontBody)
    ]
  }
  buttons = [
    { text = loc("Close"), isCurrent = true, customStyle = { hotkeys = [[$"^{JB.B}"]] } }
  ]
})

let endSeasonAlert = {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    unseenIcon
    {
      rendObj = ROBJ_TEXTAREA
      behavior = [Behaviors.TextArea]
      size = FLEX_H
      text = loc("bp/endSeasonMsgShort")
      color = attentionTxtColor
    }.__update(fontSub)
  ]
}

let bpAlertBlock = watchElemState(@(sf) {
  rendObj = ROBJ_BOX
  size = [startBtnWidth, SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  behavior = Behaviors.Button
  onClick = msgEndSeason
  padding = [midPadding, bigPadding]
  margin = [0, midPadding]
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
        endSeasonAlert
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


function mkLessRankAlert() {
  let hasAlert = Computed(@() seasonEndTime.get() <= serverTime.get() + BP_RANK_DAYS_ALERT * DAY_SEC)
  return @() {
    watch = hasAlert
    hplace = ALIGN_CENTER
    children = hasAlert.get()
      ? {
          size = const [hdpx(300), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc("rank/seasonEndAlert")
          color = attentionTxtColor
          animations = [{ prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1,
            play = true, loop = true, easing = Blink }]
        }.__update(fontSub)
      : null
  }
}

function mkTimerBlock() {
  let hasAlert = Computed(@() seasonEndTime.get() <= serverTime.get() + BP_LEFT_DAYS_ALERT * DAY_SEC)
  return @() {
    watch = hasAlert
    children = hasAlert.get() ? bpAlertBlock
      : timeTracker
  }
}

let bpHeader = @(showingItem, closeButton, infoObject = null) {
  size = FLEX_H
  children = [
    mkTimerBlock()
    bpItemInfo(showingItem, infoObject)
    {
      margin = [0, bigOffset]
      hplace = ALIGN_RIGHT
      children = mkLessRankAlert()
    }
    closeButton
  ]
}

function previewImageCmp(showingItem) {
  let { previewImage = null, previewSize = previewImageSize } = showingItem
  if (previewImage == null)
    return null

  return {
    rendObj = ROBJ_IMAGE
    size = previewSize
    image = Picture("{0}:{1}:{2}".subst(previewImage, previewSize[0], previewSize[1]))
    keepAspect = KEEP_ASPECT_FIT
  }
}

let lockScreen = @(showingItem) (showingItem?.isPremium || showingItem?.isSpecial)
  ? lockScreenBlock
  : null

let cardIconReceivedHeader = {
  size = logoBP
  padding = smallPadding
  hplace = ALIGN_CENTER
  children = faComp("check", {
    fontSize = hdpx(20)
    color = activeTxtColor
  })
}

let cardFreeHeader = {
  size = bgFree
  rendObj = ROBJ_IMAGE
  image = Picture($"!ui/uiskin/battlepass/bg_free.svg:{bgFree[0]}:{bgFree[1]}:K")
  children = {
    rendObj = ROBJ_TEXT
    padding = smallPadding
    text = loc("bp/freeReward")
    color = activeTxtColor
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
  }.__update(fontSub)
}


function cardPremiumHeader() {
  let iconName = hasEliteBattlePass.get() ? "bp_logo" : "lock_bp"
  return {
    watch = hasEliteBattlePass
    hplace = ALIGN_CENTER
    children = {
      size = logoBP
      rendObj = ROBJ_IMAGE
      image = Picture($"!ui/uiskin/battlepass/{iconName}.svg:{logoBP[0]}:{logoBP[1]}:K")
      behavior = Behaviors.Button
      onHover = @(on) setTooltip(!on ? null
        : hasEliteBattlePass.get() ? loc("bp/reward")
        : loc("bp/required/tip")
      )
    }
  }
}

let cardCount = @(count, style = {}) {
  children = {
    rendObj = ROBJ_TEXT
    padding = [0, smallPadding]
    text = count > 99 ? count : loc("common/amountShort", { count = count })
    color = style?.color ?? attentionTxtColor
  }.__update(fontBody)
}.__update(style)

let mkCardCountCtor = @(size, fontStyle) @(count) {
  size = [size, size]
  rendObj = ROBJ_IMAGE
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  margin = midPadding
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  image = Picture($"!ui/uiskin/battlepass/Ellipse.svg:{size}:{size}:K")
  children = {
    rendObj = ROBJ_TEXT
    padding = [0, smallPadding]
    text = count > 99 ? count : loc("common/amountShort", { count = count })
    color = titleTxtColor
  }.__update(fontStyle)
}

let cardCountCircle = mkCardCountCtor(hdpxi(43), fontBody)
let cardCountCircleSmall = mkCardCountCtor(hdpxi(30), fontSub)

let cardBottom = @(count, cardIcon){
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  margin = midPadding
  vplace = ALIGN_BOTTOM
  valign = ALIGN_BOTTOM
  halign = ALIGN_RIGHT
  children = [
    {
      size = const [FLEX, sizeIcon]
      flow = FLOW_HORIZONTAL
      halign = ALIGN_RIGHT
      valign = ALIGN_BOTTOM
      children = [
        cardCount(count)
        cardIcon
      ]
    }
  ]
}

let mkSubtaskReward = @(count, cardIcon) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      children = cardCount(count, {
        color = totalBlack
        pos = [bigPadding, 0]
        padding = [0, midPadding, 0, smallPadding]
        rendObj = ROBJ_BOX
        borderRadius = commonBorderRadius * 2
        fillColor = accentTitleTxtColor
      })
    }
    cardIcon
  ]
}

let loopObject = {
  size = recurringIcon
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"!ui/uiskin/recurring_level_icon.svg:{recurringIcon[0]}:{recurringIcon[1]}:K")
  behavior = Behaviors.Button
  onHover = @(on) setTooltip(!on ? null : loc("bp/recurring/tip"))
}

function mkCard(
  reward, count, boostersConfigVal, onClick, isSelected, isReceived,
  isPremium, isLooped, addToContainer, premiumHeader
) {
  local cardChildren = []
  let verticalPos = -(0.09 * imageSize[0]).tointeger()

  let template = reward?.itemTemplate ?? reward?.boosterId
  let boosterTemplate = boostersConfigVal?[template]
  if (boosterTemplate != null) {
    cardChildren = [
      {
        size = defCardSize
        pos = [0, verticalPos]
        hplace = ALIGN_CENTER
        children = mkXpBooster(boosterTemplate)
          .__update({ margin = 0 })
      }
      {
        size = FLEX
        padding = midPadding
        children = [
          mkBoosterInfo(boosterTemplate, fontBody.__merge({ color = activeTxtColor }))
          mkBoosterLimits(boosterTemplate, fontBody.__merge({ color = activeTxtColor }))
        ]
      }
    ]
  }
  else {
    let cardIcon = mkRewardIcon(reward, sizeIcon, { vplace = ALIGN_CENTER })
    let cardImages = mkRewardImages(reward, imageSize, {
      pos = [0, verticalPos], hplace = ALIGN_CENTER
    })
    cardChildren = [
      cardImages
      cardBottom(count, cardIcon)
    ]
  }

  let cardBlock = {
    size = sizeCard
    rendObj = ROBJ_SOLID
    color = defBgColor
    children = cardChildren
  }
  return @() {
    watch = isSelected
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    vplace = ALIGN_BOTTOM
    halign = ALIGN_CENTER
    gap = midPadding * 2
    children = [
      {
        xmbNode = XmbNode()
        behavior = isSelected.get() ? null : Behaviors.Button
        onClick
        flow = FLOW_VERTICAL
        gap = smallPadding
        children = [
          isLooped ? loopObject : null
          {
            flow = FLOW_VERTICAL
            gap = 0.1 * imageHeight 
            children = [
              isReceived ? cardIconReceivedHeader
                : isPremium ? premiumHeader
                : cardFreeHeader
              cardBlock
            ]
          }
        ]
        transform = isSelected.get() ? cardStateSelected : cardStateCommon
        transitions = cardSelectAnim
        animations = isSelected.get()
          ? [
              { prop = AnimProp.translate, from = [0, 0], to = cardStateSelected.translate,
                duration = 0.6, easing = InOutCubic, play = true }
              { prop=AnimProp.scale from=[0,1], to=[1,1], duration=0.6, play=true, easing=InOutCubic}
            ]
          : null
        sound = {
          hover = "ui/enlist/button_highlight"
          click = "ui/enlist/button_click"
        }
      }
      addToContainer
    ]
  }
}

let cardProgressBar = progressContainerCtor(
  $"!ui/uiskin/battlepass/progress_bar_mask.svg",
  $"!ui/uiskin/battlepass/progress_bar_border.svg",
  [progressWidth, progressBarHeight]
)

let progressBarImage = @(isReceived, isPremium) !isReceived && isPremium
  ? "!ui/uiskin/progress_bar_gray.svg"
  : "!ui/uiskin/progress_bar_gradient.svg"

let progressTxt = @(text = "") {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  padding = const [0, hdpx(20), 0, 0]
  rendObj = ROBJ_TEXT
  text
}.__update(fontBody)

function mkCardProgressBar(reward) {
  let { stageIdx, isReceived, isPremium, progressState, progressVal } = reward
  return cardProgressBar(
    progressState == RewardState.COMPLETED ? completedProgressLine(1)
      : progressState == RewardState.ACQUIRED ? acquiredProgressLine(1, glareAnimation(0.5))
      : progressState == RewardState.IN_PROGRESS ? gradientProgressLine(
          progressVal, progressBarImage(isReceived, isPremium)
        )
      : inactiveProgressCtor(),
    progressTxt(stageIdx + 1))
}

let btnBuyPremiumPass = @(txt, cb) Purchase(txt, cb,
  {
    size = btnSize
    hotkeys = [["^J:Y", { description = { skip = true }}]]
  })

let premiumPassHeader = {
  flow = FLOW_HORIZONTAL
  gap = midPadding
  padding = const [sh(5), 0, 0, 0]
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("bp/elite")
      color = attentionTxtColor
    }.__update(fontBody)
    {
      rendObj = ROBJ_TEXT
      text = loc("bp/battlePass")
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
    dynamicSeasonBPIcon(hdpxi(220))
  ].extend(children)
}

return freeze({
  timeTracker
  bpTitle
  bpHeader
  mkCard
  sizeBlocks
  hugePadding
  sizeIcon
  sizeCard
  btnSize
  btnBuyPremiumPass
  cardCount
  cardCountCircle
  cardCountCircleSmall
  imageSize
  gapCards
  lockScreen
  previewImageCmp
  previewImageSize
  premiumPassHeader
  mkBpIconBlock
  cardBottom
  mkSubtaskReward
  cardPremiumHeader
  mkCardProgressBar
  mkLessRankAlert
})
