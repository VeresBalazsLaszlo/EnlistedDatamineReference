import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/components/colorize.nut" as colorize
import "%ui/components/spinner.nut" as spinner
from "%ui/navState.nut" import addScene, removeScene
from "%ui/style/fontsStyle.nut" import fontBody, fontGiant
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/style/designConst.nut" import midPadding, titleTxtColor, strokeStyle, accentTitleTxtColor
from "%ui/components/textButton.nut" import Regular, Primary
from "%ui/soldiers/mkSquadPromo.nut" import primeDescBlock, mkDescBlock, mkBackWithImage, mkSquadBodyBig, mkPromoSquadIcon, mkUnlockInfo, mkPromoBackBtn, mkFullScreenBack
from "%ui/soldiers/components/campaignPromoPkg.nut" import btnSizeBig, receivedCommon
from "%ui/soldiers/model/chooseSquadsState.nut" import openChooseSquadsWnd
from "%ui/mainMenu/sectionsState.nut" import curSection
from "%ui/soldiers/model/state.nut" import armySquadsById, curUnlockedSquads, selectArmy
from "%ui/battleData/testDrive.nut" import isTestDriveProfileInProgress, startSquadTestDrive
from "%ui/components/mkSpecialItemIcon.nut" import SIGN_PREMIUM
from "%ui/ui_library.nut" import *

let viewData = Watched(null)
let isUnlockSquadSceneVisible = Watched(false)
let waitingSpinner = spinner(btnSizeBig[1]/2)

let open = @(armyId, squadCfg, unlockInfo = null, isNewSquad = false)
  viewData.set({ armyId, squadCfg, unlockInfo, isNewSquad })

let close = @() viewData.set(null)

let closeBtn = {
  padding = midPadding
  hplace = ALIGN_RIGHT
  children = closeBtnBase({ onClick = close })
}

let mkAnimationsList = @(delay, onEnter = null, onFinish = null) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = delay,
      play = true, easing = InOutCubic }
  { prop = AnimProp.opacity, delay = delay, from = 0, to = 1, duration = 0.9,
      play = true, easing = InOutCubic }
  { prop = AnimProp.scale, delay = delay, from = [3,3], to = [1,1], duration = 0.9,
      play = true, easing = InOutCubic }
  { prop = AnimProp.translate, delay = delay, from = [sh(30),-sh(10)], to = [0,0],
      duration = 0.9, play = true, easing = InOutCubic, onEnter = onEnter, onFinish = onFinish }
]

let newSquadReceivedText = {
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  vplace = ALIGN_CENTER
  color = titleTxtColor
  pos = const [0,hdpx(150)]
  margin = const [hdpx(80), 0, 0, hdpx(80)]
  text = "{0} \n {1}".subst(colorize(accentTitleTxtColor, loc("mainmenu/congratulations")), loc("squad/gotNewSquad"))
  transform = true
  animations = mkAnimationsList(0, @() sound_play("ui/squad_unlock_text"),
    @() sound_play("ui/squad_unlock_text_2"))
}.__update(fontGiant, strokeStyle)

function onManage() {
  if (viewData.get() == null)
    return
  let { armyId, squadCfg } = viewData.get()
  close()
  selectArmy(armyId)
  openChooseSquadsWnd(armyId, squadCfg.id, true)
}

let mkTestDriveButton = @(squadId) @() {
  watch = isTestDriveProfileInProgress
  size = btnSizeBig
  halign = ALIGN_CENTER
  children = isTestDriveProfileInProgress.get() ? waitingSpinner
    : Regular(loc("testDrive/squad"), @() startSquadTestDrive(squadId), {
        size = btnSizeBig
        hotkeys = [[ "^J:X", { description = { skip = true }} ]]
      })
}

function mkNewSquadButtons() {
  return {
    size = [btnSizeBig[0], SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    halign = ALIGN_CENTER
    gap = midPadding
    children = [
      {
        rendObj = ROBJ_TEXT
        color = titleTxtColor
        text = loc("squad/openManageRequest")
      }.__update(fontBody, strokeStyle)
      Primary(loc("squads/squadManage"), onManage, {
        key = "SquadManageBtnInSquadPromo" 
        size = btnSizeBig
        hotkeys = [[ "^J:X | Enter", { description = {skip = true}} ]]
      })
      Regular(loc("squads/later"), close, {
        size = btnSizeBig
        hotkeys = [[ $"^{JB.B} | Esc", { description = {skip = true}} ]]
      })
    ]
    transform = true
    animations = mkAnimationsList(0.7,  null, @() sound_play("ui/squad_unlock_buttons"))
  }
}

function unlockSquadWnd() {
  if (viewData.get() == null)
    return null

  let { armyId, unlockInfo, squadCfg, isNewSquad } = viewData.get()
  let { isShowcase = false, isNextToBuyExp = false, unlockCb = null, unlockText = null,
    hasTestDrive = false } = unlockInfo
  let squadId = squadCfg.id
  let isPrimeSquad = squadCfg?.sign == SIGN_PREMIUM
  let hasReceived = curUnlockedSquads.get().findvalue(@(s) s.squadId == squadId) != null
  let squadCfgExt = squadCfg.__merge({
    armyId, isPrimeSquad = isPrimeSquad || isShowcase, hasReceived })

  let descBlock = isNewSquad ? newSquadReceivedText
    : isShowcase ? primeDescBlock(squadCfgExt)
    : mkDescBlock(squadCfgExt.announceLocId)

  let children = []
  if (isNewSquad)
    children.append(mkNewSquadButtons())
  else if (!hasReceived) {
    if (isNextToBuyExp || hasTestDrive)
      children.append(mkTestDriveButton(squadCfgExt.id))
    if (unlockCb != null)
      children.append(Primary(
        unlockText ?? loc("squads/receive"),
        unlockCb,
        {
          size = btnSizeBig
          hotkeys = [[ "^J:X | Enter", { description = {skip = true}} ]]
        }))
    else if (unlockText != null)
      children.append(mkUnlockInfo(unlockText, { size = btnSizeBig }))
    children.append(mkPromoBackBtn(close))
  } else
    children.append(mkPromoBackBtn(close))

  let buttons = children.len() <= 1 ? children?[0] : {
    flow = FLOW_VERTICAL
    gap = midPadding
    vplace = ALIGN_BOTTOM
    valign = ALIGN_BOTTOM
    children
  }

  return {
    key = "unlockSquadScene" 
    watch = [viewData, armySquadsById]
    onAttach = @() isUnlockSquadSceneVisible.set(true)
    onDetach = @() isUnlockSquadSceneVisible.set(false)
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    size = FLEX
    vplace = ALIGN_CENTER
    children = {
      rendObj = ROBJ_WORLD_BLUR_PANEL
      size = FLEX
      color = Color(150,150,150,255)
      children = mkFullScreenBack(
        mkBackWithImage(squadCfgExt?.image, !hasReceived),
        [
          mkSquadBodyBig(squadCfgExt, descBlock, buttons)
          mkPromoSquadIcon(squadCfgExt?.icon, !hasReceived)
          !hasReceived ? null : receivedCommon
          isNewSquad ? null : closeBtn
        ]
      )
    }
  }
}

if (viewData.get() != null)
  addScene(unlockSquadWnd)

viewData.subscribe(
  function(val) {
    if (val)
      addScene(unlockSquadWnd)
    else
      removeScene(unlockSquadWnd)
  }
)

curSection.subscribe(@(_) close() )

return {
  openUnlockSquadScene = open
  closeUnlockSquadScene = close
  isUnlockSquadSceneVisible
  unlockSquadViewData = viewData
}
