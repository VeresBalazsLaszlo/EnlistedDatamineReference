import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/checkbox.nut" as checkbox
import "%ui/components/mkGlareAnim.nut" as mkGlare
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontSub
from "%ui/style/designConst.nut" import titleTxtColor, accentColor, defTxtColor, startBtnWidth, leftAppearanceAnim, weakTxtColor, midPadding
from "%ui/state/appState.nut" import isInBattleState
from "%ui/quickMatchQueue.nut" import leaveQueue, isInQueue
from "%ui/quickMatch.nut" import joinQueue, queuesCampaignsData, matchRandomTeam
from "%ui/state/roomState.nut" import leaveRoom, isInRoom
from "%ui/mpRoom/showCreateRoom.nut" import showCreateRoom
from "%ui/tutorial/battleTutorial.nut" import curUnfinishedBattleTutorial
from "%ui/gameLauncher.nut" import startGame
from "%ui/gameModes/gameModeState.nut" import currentGameMode
from "%ui/squad/squadManager.nut" import isInSquad, isSquadLeader, squadSelfMember, getUnsuitableCrossplayConditionMembers, getUnsuitableVersionConditionMembers, tryResolveLiveCrossplayPrivilege
from "%ui/soldiers/model/notReadySquadsState.nut" import showCurNotReadySquadsMsg
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/components/msgbox.nut" import showMsgbox, showMessageWithContent
from "%ui/mainMenu/mkActiveBoostersMark.nut" import mkActiveBoostersMark, hasBoostersMark
from "%ui/restrictionWarnings.nut" import showSquadMembersCrossPlayRestrictionMsgBox, showSquadVersionRestrictionMsgBox, showNegativeBalanceRestrictionMsgBox
from "%ui/currency/currencies.nut" import hasValidBalance
from "%ui/components/textButton.nut" import Regular
from "%ui/shop/armyShopState.nut" import realCurrencies
from "%ui/mainMenu/sectionsState.nut" import setCurSection, jumpToArmyGrowth, Section, isMainMenuVisible
from "%ui/options/dontShowAgain.nut" import setDontShowToday, getDontShowToday, mkDontShowTodayComp
from "%ui/soldiers/armySquadTier.nut" import updateBROnMatchStart
from "%sqstd/math.nut" import getRomanNumeral
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/meta/profile.nut" import curArmiesList
from "%ui/soldiers/model/state.nut" import curArmy, selectArmy
from "%ui/meta/servProfile.nut" import armies
from "%ui/soldiers/components/armyPackage.nut" import mkArmyIcon
from "%ui/growth/growthState.nut" import GrowthStatus, growthConfig, curGrowthState
from "%ui/offers/offersState.nut" import visibleOffersInWindow, curOfferIdx, isSpecOffersOpened, hasOfferStartBtn, markOfferSeen, getUnseenTestDriveOffer
from "%sqstd/platform.nut" import is_gdk
from "%ui/ui_library.nut" import *

let spinner = require("%ui/components/spinner.nut")(hdpx(24))
let { myExtSquadData } = require("%ui/squad/squadManager.nut")


const DONT_SHOW_TODAY_ID = "silver_full"
const btnHeight = hdpxi(94)

let defStartTxtStyle = {
  defTextColor = titleTxtColor
  hoverTextColor = accentColor
  activeTextColor = titleTxtColor
}

let leaveMatchTxtStyle = {
  defTextColor = defTxtColor
  hoverTextColor = titleTxtColor
  activeTextColor = defTxtColor
  textParams = {
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    lineSpacing = hdpx(-4)
  }.__update(fontHeading2)
}

let mkButtonStyle = @(hasBoosters) hasBoosters
  ? { align = ALIGN_LEFT }
  : { align = ALIGN_CENTER }

let defBtnBg = Picture("ui/uiskin/startBtn/start_btn_regular.avif")
let hoverBtnBg = Picture("ui/uiskin/startBtn/start_btn_hover.avif")
let activeBtnBg = Picture("ui/uiskin/startBtn/start_btn_active.avif")
let defPressedBtnBg = Picture("ui/uiskin/startBtn/start_btn_pressed_regular.avif")
let hoverPressedBtnBg = Picture("ui/uiskin/startBtn/start_btn_pressed_hover.avif")
let activePressedBtnBg = Picture("ui/uiskin/startBtn/start_btn_pressed_active.avif")


let defStartBgStyle = {
  defBg = defBtnBg
  hoverBg = hoverBtnBg
  activeBg = activeBtnBg
}

let leaveMatchBgStyle = {
  defBg = defPressedBtnBg
  hoverBg = hoverPressedBtnBg
  activeBg = activePressedBtnBg
}


let blinkAnimation = [{prop = AnimProp.color, from = 0x00F27272 , to = 0x44AA7272, duration = 3,
  loop = true, play = true, easing = CosineFull }]

let brAnimState = { from = null, to = null }

const DUR_GROW = 0.9
const DUR_FADE = 0.4
const DUR_APPEAR = 0.5
const DELAY_INIT = 0.1
const FST_VISIBLE = DELAY_INIT + DUR_GROW
const SND_VISIBLE = FST_VISIBLE + DUR_FADE
const OFFSET = hdpxi(30)
let inAnimation = const [
  { prop = AnimProp.opacity, from = 0, to = 0, easing = Linear, play = true,
    duration = FST_VISIBLE }
  { prop = AnimProp.opacity, from = 0, to = 1, easing = InQuad, play = true,
    delay = FST_VISIBLE, duration = DUR_FADE }
  { prop = AnimProp.translate, from = [0, -OFFSET], to = [0,0], easing = InQuad, play = true,
    delay = FST_VISIBLE, duration = DUR_FADE }
  { prop = AnimProp.scale, from = [1,1], to = [1.5,1.5], easing = CosineFull, play = true,
    delay = SND_VISIBLE, duration = DUR_APPEAR }
]
let outAnimation = const [
  { prop = AnimProp.opacity, from = 1, to = 1, easing = Linear, play = true,
    duration = FST_VISIBLE }
  { prop = AnimProp.scale, from = [1,1], to = [1.5,1.5], easing = InQuad, play = true,
    delay = DELAY_INIT, duration = DUR_GROW }
  { prop = AnimProp.scale, from = [1.5,1.5], to = [1,1], easing = OutCirc, play = true,
    delay = FST_VISIBLE, duration = DUR_FADE }
  { prop = AnimProp.translate, from = [0, 0], to = [0, OFFSET], easing = Linear, play = true,
    delay = FST_VISIBLE, duration = DUR_FADE }
  { prop = AnimProp.opacity, from = 1, to = 0, easing = OutQuad, play = true,
    delay = FST_VISIBLE, duration = DUR_FADE }
]

let brText = @(from, to) {
  rendObj = ROBJ_TEXT
  color = weakTxtColor
  text = from == to
    ? getRomanNumeral(from)
    : "{0}-{1}".subst(getRomanNumeral(from), getRomanNumeral(to))
  transform = true
  animations = null
}.__update(fontSub)


function brAnimText(brData) {
  let { from = null, to = null } = brData
  let text = brText(from, to)
  let key = $"br_{from}_{to}"
  let size = const [SIZE_TO_CONTENT, hdpxi(20)]

  if (brAnimState.from == null)
    brAnimState.__update({ from, to })

  if (brAnimState.from == from && brAnimState.to == to)
    return text.__update({ key, size })

  let prevText = brText(brAnimState.from, brAnimState.to).__update({
    animations = outAnimation
    opacity = 0
  })
  text.__update({ animations = inAnimation })
  brAnimState.__update({ from, to })

  return {
    key
    size
    children = [
      text
      prevText
    ]
  }
}

let brCampaignData = Computed(@() queuesCampaignsData.get()?.BRs)

function brValue() {
  let BRs = brCampaignData.get()
  let watch = [brCampaignData, isMainMenuVisible]
  if (BRs == null || !isMainMenuVisible.get())
    return { watch }

  return {
    watch
    flow = FLOW_HORIZONTAL
    gap = midPadding
    children = [
      {
        rendObj = ROBJ_TEXT
        color = weakTxtColor
        text = loc("start/br")
      }.__update(fontSub)
      brAnimText(BRs)
    ]
  }
}

function startButtonCtor(text, action, params = {}) {
  let { bgStyle, txtStyle, isEnabled = true, hotkeys = null } = params
  let { defTextColor, hoverTextColor, activeTextColor,
    textParams = fontHeading2, align = ALIGN_CENTER } = txtStyle

  let txtCtor = @(_txt, txtCtorParams, _handler, _group, sf) {
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    padding = midPadding
    gap = midPadding
    children = [
      mkHotkey((sf & S_HOVER) || (sf & S_ACTIVE) ? $"^{JB.A}" : hotkeys, action, { hideForKeyboard = true })
      {
        flow = FLOW_VERTICAL
        size = FLEX_H
        halign = align
        valign = ALIGN_CENTER
        children = [
          leaveMatchTxtStyle.textParams.__merge({
            rendObj = ROBJ_TEXTAREA
            size = const [pw(75), SIZE_TO_CONTENT]
            halign = align
            text
          }, txtCtorParams)
          {
            valign = ALIGN_CENTER
            children = [
              isEnabled ? null
                : {
                    pos = const [-hdpx(30), 0]
                    children = spinner
                  }
              brValue
            ]
          }
        ]
      }
    ]
  }

  function bgChild(sf, isEnabl = true) {
    let { defBg, hoverBg, activeBg } = bgStyle
    let isActive = sf & S_ACTIVE
    return {
      key = $"{isActive}"
      size = FLEX
      rendObj = ROBJ_IMAGE
      image = isActive ? activeBg
        : sf & S_HOVER ? hoverBg
        : defBg
      picSaturate = isEnabl ? 1 : 0
      animations = [
        { prop = AnimProp.opacity, from = 0.0, to = 1.0, duration = 0.3, play = true }
        { prop = AnimProp.opacity, from = 1.0, to = 0.0, duration = 0.3, playFadeOut = true }
      ]
    }
  }

  return Regular(txtCtor, action, {
    isEnabled
    btnWidth = startBtnWidth
    btnHeight
    style = {
      defTxtColor = defTextColor
      hoverTxtColor = hoverTextColor
      activeTxtColor = activeTextColor
    }
    textParams
    bgChild
  })
}

function quickMatchFn(testOffer = null) {
  if (isInRoom.get())
    leaveRoom()

  showCreateRoom.set(false)
  if (currentGameMode.get().queues.len() > 0)
    joinQueue(currentGameMode.get(), testOffer)
}

function onLeaveQueuePressed() {
  myExtSquadData.ready.set(false)
  leaveQueue()
}

let leaveQuickMatchButton = @() {
  watch = hasBoostersMark
  children = startButtonCtor(loc("Leave queue"), onLeaveQueuePressed,
    {
      bgStyle = leaveMatchBgStyle
      txtStyle = leaveMatchTxtStyle.__merge(mkButtonStyle(hasBoostersMark.get()))
      hotkeys = $"^{JB.B}"
    })
  hotkeys=[["^Esc", onLeaveQueuePressed]]
}


function checkPlayAvailability(testOffer = null) {
  if (isSquadLeader.get()) {
    let membersList = getUnsuitableCrossplayConditionMembers()
    if (membersList.len() > 0) {
      showSquadMembersCrossPlayRestrictionMsgBox(membersList)
      return
    }
  }

  let unsuitableByVersion = getUnsuitableVersionConditionMembers(currentGameMode.get())
  if (unsuitableByVersion.len() != 0) {
    showSquadVersionRestrictionMsgBox(unsuitableByVersion.values())
    return
  }

  if (!hasValidBalance.get()) {
    showNegativeBalanceRestrictionMsgBox()
    return
  }

  if (!getDontShowToday(DONT_SHOW_TODAY_ID)) {
    let curSilver = realCurrencies.get()?["enlisted_silver"] ?? 0
    let { silverCurrencyLimit = 0 } = gameProfile.get()
    if (silverCurrencyLimit - curSilver < silverCurrencyLimit * 0.1) {
      let dontShowMeToday = mkDontShowTodayComp(DONT_SHOW_TODAY_ID)
      let text = curSilver >= silverCurrencyLimit
        ? loc("msg/silverFull")
        : loc("msg/silverAlmostFull")
      let dontShowCheckbox = checkbox(dontShowMeToday, loc("dontShowMeAgainToday"), {
        setValue = @(v) setDontShowToday(DONT_SHOW_TODAY_ID, v)
        override = {
          vplace = ALIGN_BOTTOM
        }
        hotkeys = [["^J:RS"]]
      })
      let silverLimitContent = {
        uid = "silverLimitMsgbox"
        content = {
          minHeight = fsh(32)
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          children = [
            {
              rendObj = ROBJ_TEXTAREA
              maxWidth = sw(60)
              behavior = Behaviors.TextArea
              halign = ALIGN_CENTER
              text
            }.__update(fontHeading2)
            dontShowCheckbox
          ]
        }
        buttons = [
          {
            text = loc("btnGoShop")
            action = @() setCurSection(Section.SHOP)
            customStyle = { hotkeys = [["^J:X"]] }
          }
          {
            text = loc("btnStartAnyway")
            action = @() showCurNotReadySquadsMsg(@() quickMatchFn(testOffer))
            customStyle = { hotkeys = [["^J:Y"]] }
          }
        ]
      }
      showMessageWithContent(silverLimitContent)
      return
    }
  }

  showCurNotReadySquadsMsg(@() quickMatchFn(testOffer))
}


let armiesReqGrowth = Computed(function() {
  let armiesData = armies.get()
  let armyList = matchRandomTeam.get() ? curArmiesList.get() : [curArmy.get()]
  let statuses = curGrowthState.get()
  return armyList.filter(function(armyId) {
    let { growthSelected = "" } = armiesData?[armyId]
    if (growthSelected != "")
      return false

    let armyCfg = growthConfig.get()?[armyId] ?? {}
    return armyCfg.findvalue(@(g) (g?.expRequired ?? 0) > 0
      && (statuses?[g.id].status ?? GrowthStatus.UNAVAILABLE) == GrowthStatus.ACTIVE
    ) != null
  })
})


function showGrowthAlert(action, armiesList) {
  showMessageWithContent({
    content = function() {
      return {
        watch = armiesReqGrowth
        children = {
          flow = FLOW_VERTICAL
          gap = midPadding
          halign = ALIGN_CENTER
          children = [
            {
              flow = FLOW_HORIZONTAL
              gap = midPadding
              children = armiesReqGrowth.get().map(@(armyId) mkArmyIcon(armyId))
            }
            {
              rendObj = ROBJ_TEXTAREA
              behavior = Behaviors.TextArea
              size = const [sw(50), SIZE_TO_CONTENT]
              halign = ALIGN_CENTER
              text = loc("growth/reqToSelectMessage")
            }.__update(fontBody)
          ]
        }
      }
    }
    buttons = [
      {
        text = loc("StartAnyway"),
        action,
        customStyle = { hotkeys = [["^J:Y"]] }
      }
      {
        text = loc("GoToGrowth")
        isCurrent = true
        action = function() {
          if (!armiesList.contains(curArmy.get()))
            selectArmy(armiesList[0])
          jumpToArmyGrowth()
        }
      }
    ]
  })
}


function checkSelectedGrowthAndDo(action) {
  let armiesList = armiesReqGrowth.get()
  if (armiesList.len() > 0)
    showGrowthAlert(action, armiesList)
  else
    action()
}

function startQuickMatchFunc() {
  checkSelectedGrowthAndDo(function() {
    updateBROnMatchStart()
    myExtSquadData.ready.set(true)
    checkPlayAvailability()
  })
}

function onStartQuickMatch() {
  let offer = getUnseenTestDriveOffer()
  if (offer == null) {
    startQuickMatchFunc()
    return
  }

  let offerIdx = visibleOffersInWindow.get().findindex(@(o) o.guid == offer.guid)
  curOfferIdx.set(offerIdx)
  hasOfferStartBtn.set(true)
  isSpecOffersOpened.set(true)
  markOfferSeen(offer)
}

let startButtonGlare = mkGlare({
  nestWidth = startBtnWidth
  glareWidth = hdpx(124)
  glareDuration = 0.7
  glareOpacity = 0.5
  glareDelay = 5
})

let mkJoinQuickMatchButton = @(locId = "START", cb = onStartQuickMatch, params = {}) @() {
  watch = hasBoostersMark
  children = [
    startButtonCtor(loc(locId), cb, {
      bgStyle = defStartBgStyle
      txtStyle = defStartTxtStyle.__merge(mkButtonStyle(hasBoostersMark.get()))
      hotkeys = "^J:Y"
      animations = blinkAnimation
    }.__update(params))
    startButtonGlare
  ]
}

let boostersMark = mkActiveBoostersMark({
  hplace = ALIGN_RIGHT
  vplace = ALIGN_CENTER
  pos = const [hdpxi(20), 0]
})

let quickMatchButton = @() {
  watch = isInQueue
  children = [
    isInQueue.get() ? leaveQuickMatchButton : mkJoinQuickMatchButton()
    boostersMark
  ]
}

function onReadyBtnPressImpl() {
  tryResolveLiveCrossplayPrivilege(function(resolved) {
    if (resolved) {
      showCurNotReadySquadsMsg(function() {
        updateBROnMatchStart()
        myExtSquadData.ready.set(true)
      })
    }
  })
}

function onReadyBtnPress() {
  if (is_gdk) {
    let { try_resolve_multiplayer_privilege } = require("%ui/gdk/privileges.nut")
    try_resolve_multiplayer_privilege(function(resolved) {
      if (resolved)
        onReadyBtnPressImpl()
    })
    return
  }
  onReadyBtnPressImpl()
}

let pressWhenReadyBtn = @() {
  watch = hasBoostersMark
  children = startButtonCtor(loc("Press when ready"), onReadyBtnPress,
    {
      bgStyle = defStartBgStyle
      txtStyle = leaveMatchTxtStyle.__merge({ defTextColor = titleTxtColor },
        mkButtonStyle(hasBoostersMark.get()))
      hotkeys = "^J:Y"
      animations = blinkAnimation
    })
}

let setNotReadyBtn = @() {
  watch = hasBoostersMark
  children = startButtonCtor(loc("Set not ready"),
    @() isInQueue.get()
      ? showMsgbox(loc("msg/cantReadyStatus"))
      : myExtSquadData.ready.set(false),
    {
      bgStyle = leaveMatchBgStyle
      txtStyle = leaveMatchTxtStyle.__merge(mkButtonStyle(hasBoostersMark.get()))
      hotkeys = $"^{JB.B}"
    })
}

isInBattleState.subscribe(function(inBattle) {
  if (!inBattle) {
    myExtSquadData.ready.set(false)
  }
})

let squadMatchButton = @() {
  watch = [isInQueue, isSquadLeader, squadSelfMember, myExtSquadData.ready]
  children = [
    !isSquadLeader.get() && squadSelfMember.get() != null
      ? (myExtSquadData.ready.get() ? setNotReadyBtn : pressWhenReadyBtn)
      : (isInQueue.get() ? leaveQuickMatchButton : mkJoinQuickMatchButton())
    boostersMark
  ]
}


function startTutorial() {
  checkSelectedGrowthAndDo(function() {
    startGame({
      game = "enlisted", scene = curUnfinishedBattleTutorial.get()
    })
  })
}

let startTutorialBtn = startButtonCtor(loc("TUTORIAL"), startTutorial, {
  bgStyle = defStartBgStyle
  txtStyle = defStartTxtStyle
  hotkeys = "^J:Y"
  animations = blinkAnimation
})


function startLocalGameMode() {
  startGame({
    game = "enlisted", scene = currentGameMode.get()?.queues[0].scenes[0]
  })
}

let localGameBtn = startButtonCtor(loc("START"), startLocalGameMode, {
  bgStyle = defStartBgStyle
  txtStyle = defStartTxtStyle
  hotkeys = "^J:Y"
  animations = blinkAnimation
})


let startButton = @() {
  watch = [curUnfinishedBattleTutorial, isInSquad, currentGameMode]
  children = isInSquad.get() ? squadMatchButton
    : curUnfinishedBattleTutorial.get() != null ? startTutorialBtn
    : currentGameMode.get()?.isLocal ? localGameBtn
    : quickMatchButton
}.__update(leftAppearanceAnim(0.1))

return {
  startButton
  mkJoinQuickMatchButton
  checkPlayAvailability
  startQuickMatchFunc
}
