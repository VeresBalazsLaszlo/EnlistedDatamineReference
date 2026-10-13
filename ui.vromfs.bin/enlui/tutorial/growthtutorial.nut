import "%ui/control/gui_buttons.nut" as JB
import "%ui/soldiers/model/getPayItemsData.nut" as getPayItemsData
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/meta/profile.nut" import curCampItems
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/style/designConst.nut" import airSelectedBgColor
from "%ui/soldiers/chooseSquadsSlots.nut" import mkHorizontalSlot
from "%ui/mainMenu/sectionsState.nut" import jumpToArmyGrowth, Section
from "%ui/squad/squadManager.nut" import isInSquad
from "%ui/debriefing/debriefingDbgState.nut" import dbgShow
from "%ui/debriefing/debriefingState.nut" import debriefingShow
from "%ui/components/msgbox.nut" import hasMsgBoxes
from "%ui/components/modalWindows.nut" import hasModalWindows
from "%sqstd/timers.nut" import debounce
from "%ui/tutorial/growthTutorialState.nut" import curGrowthGuidToPurchase, needTutorial
from "%ui/soldiers/model/chooseSquadsState.nut" import openChooseSquadsWnd, closeChooseSquadsWnd, applyAndClose, chosenSquads, reserveSquads, changeList, moveIndex
  , selectedSquadId, findLastIndexToTakeSquad
from "%ui/soldiers/unlockSquadScene.nut" import isUnlockSquadSceneVisible, closeUnlockSquadScene, unlockSquadViewData
from "%ui/tutorial/tutorialWndState.nut" import setTutorialConfig, finishTutorial, goToStep, isTutorialActive, nextStep, seenTutorials
from "%ui/tutorial/tutorialWndDefStyle.nut" import mkSizeTable, mkMessageCtorWithGamepadIcons
from "%ui/growth/growthState.nut" import isGrowthVisible, curGrowthConfig, callGrowthPurchase, curGrowthId
from "%ui/mainMenu/sectionsState.nut" import isMainMenuVisible
from "%ui/ui_library.nut" import *


const SILVER_ID = "enlisted_silver"
const TUTORIAL_ID = "newGrowthSquad"

let showTutorial = keepref(Computed(function() {
  let isSeen = seenTutorials.get()?[TUTORIAL_ID] ?? false
  return !(isInSquad.get() || debriefingShow.get() || dbgShow.get())
    && !isSeen && needTutorial.get()
    && (isGrowthVisible.get() || isMainMenuVisible.get())
    && !hasMsgBoxes.get()
    && !hasModalWindows.get()
}))

let newReceivedSquadId = Watched(null)

function openSquadManage() {
  if (unlockSquadViewData.get() == null)
    return

  let { armyId, squadCfg } = unlockSquadViewData.get()
  closeUnlockSquadScene()
  closeChooseSquadsWnd() 
  newReceivedSquadId.set(squadCfg.id)
  openChooseSquadsWnd(armyId, squadCfg.id, true)
}

let getSquadKey = @(squad, idx) squad == null ? $"empty_slot{idx}" : $"slot{squad.guid}{idx}"

function moveReserveSquadToActive(idx) {
  let squadId = newReceivedSquadId.get() ?? reserveSquads.get()?[0].squadId
  if (chosenSquads.get()?[idx] != null) {
    selectedSquadId.set(chosenSquads.get()?[idx].squadId)
    changeList()
  }
  selectedSquadId.set(squadId)
  changeList()
}

let mkDropSquadSlot = @(box, idx, squad) mkSizeTable(box, {
  rendObj = ROBJ_SOLID,
  color = 0xF0000000
  children = squad == null ? null
    : [
        mkHorizontalSlot(squad.__merge({
          idx
          fixedSlots = chosenSquads.get().len()
          onClick = @() null
          onDropCb = @(_, __) null
        }))
        {
          size = FLEX
          rendObj = ROBJ_BOX
          borderWidth = hdpx(1)
        }
      ]
})

let mkDropTarget = @(box, onDrop) watchElemState(@(sf) mkSizeTable(box, {
  behavior = Behaviors.DragAndDrop
  onDrop
  rendObj = ROBJ_BOX
  fillColor = sf & S_ACTIVE? airSelectedBgColor : 0
  borderWidth = hdpx(1)
}))


function tryGetReward() {
  let growthGuid = curGrowthGuidToPurchase.get()
  if (growthGuid == null)
    return false

  let growthCfg = curGrowthConfig.get()?[growthGuid]
  if (growthCfg == null)
    return false

  let { id, rewardCost = 0 } = growthCfg
  if (rewardCost == 0)
    return false

  let buyInfo = getPayItemsData({ [SILVER_ID] = rewardCost }, curCampItems.get())
  if (buyInfo == null)
    return false

  callGrowthPurchase(curArmy.get(), id, buyInfo)
  return true
}


function startTutorial() {
  let chosenSquadsKeys = Computed(@() chosenSquads.get().map(getSquadKey))
  let reserveSquadsKeys = Computed(@() reserveSquads.get().map(
    @(s, idx) "guid" in s ? getSquadKey(s, idx + chosenSquads.get().len()) : null ))
  let newReceivedIdxInReserve = Computed(@() reserveSquads.get().findindex(@(s) s.squadId == newReceivedSquadId.get()) ?? 0)
  let newReceivedKeyInReserve = Computed(@() reserveSquadsKeys.get()?[newReceivedIdxInReserve.get()])
  let newSquadIdx = Watched(-1)
  let newSquadKey = Computed(@() newSquadIdx.get() < 0 ? null : getSquadKey(chosenSquads.get()?[newSquadIdx.get()], newSquadIdx.get()))

  setTutorialConfig({
    id = TUTORIAL_ID
    onStepStatus = @(_stepId, _status) null
    steps = [
      
      {
        id = "w0s1_check_growth_squad_rewards"
        nextStepAfter = isGrowthVisible
        text = loc("tutorial_open_growth_window")
        objects = [{
          keys = [Section.GROWTH]
          sizeIncAdd = hdpx(5)
          onClick = @() jumpToArmyGrowth(curGrowthGuidToPurchase.get())
          needArrow = true
          hotkey = $"^{JB.A}"
        }]
      }
      {
        id = "w0s2_wait_growth_opening"
        nextStepAfter = isGrowthVisible
        objects = []
      }
      
      {
        id = "w1s1_completed_growth"
        nextKeyDelay = -1
        text = loc("tutorial_growth_reward")
        objects = [{
          keys = $"growth_{curGrowthGuidToPurchase.get()}"
          needArrow = true
          onClick = @() curGrowthId.set(curGrowthGuidToPurchase.get())
        }]
      }
      {
        id = "w1s2_completed_growth"
        text = loc("tutorial_growth_buy_reward")
        function onSkip() {
          if (tryGetReward())
            goToStep("w1s3_wait_for_get_squad")
          return true
        }
        objects = [{
          keys = "growth_action_button"
          needArrow = true
          ctor = @(box) mkSizeTable(box, {
            behavior = Behaviors.Button
            hotkeys = [ ["^J:Y", { description = { skip = true }, sound = "click"}] ]
            onClick = function() {
              if (tryGetReward())
                goToStep("w1s3_wait_for_get_squad")
              return true
            }
          })
        }]
      }
      {
        id = "w1s3_wait_for_get_squad"
        nextStepAfter = isUnlockSquadSceneVisible
        text = loc("xbox/waitingMessage")
        objects = [{ keys = "squadReadyToUnlock", onClick = @() true }]
      }
      
      {
        id = "w2s1_new_squad_received_window"
        objects = [{
          keys = "unlockSquadScene"
          ctor = @(box) mkSizeTable(box, {
            behavior = Behaviors.Button
            onClick = @() null
          })
        }]
        beforeStart = @() gui_scene.resetTimeout(2.5, nextStep)
      }
      {
        id = "w2s2_press_manage_squad_btn"
        text = loc("tutorial_meta_add_new_squad")
        objects = [{
          keys = "SquadManageBtnInSquadPromo"
          onClick = @() openSquadManage()
          hotkey = "^J:X"
          needArrow = true
        }]
      }
      
      {
        id = "w3s1_battle_squads_info"
        text = loc("tutorial_meta_squad_menu_intro_01")
        nextKeyDelay = -1
        objects = [{ keys = chosenSquadsKeys }]
      }
      {
        id = "w3s2_reserve_squads_info"
        text = loc("tutorial_meta_squad_menu_intro_02")
        nextKeyDelay = -1
        objects = [{ keys = reserveSquadsKeys }]
      }
      {
        id = "w3s3_change_squads_info"
        text = Computed(@() loc(isGamepad.get() ? "tutorial_meta_squad_menu_how_to_change_gamepad"
          : "tutorial_meta_squad_menu_how_to_change_mouse"))
        textCtor = mkMessageCtorWithGamepadIcons(["J:LB", "J:RB"])
        nextKeyDelay = -1
        objects = [
          { keys = chosenSquadsKeys }
          { keys = Computed(@() ["dropToReserveSquad"].extend(reserveSquadsKeys.get())) }
          { keys = ["manageSquadsBtnUp", "manageSquadsBtnDown", "manageSquadsBtnLeft", "manageSquadsBtnRight"] }
        ]
      }
      {
        id = "w3s4_move_new_squad_to_active"
        text = Computed(@() loc("{0}/{1}".subst(
            isGamepad.get() ? "tutorial_meta_squad_menu_choose_squad_by_gamepad" : "tutorial_meta_squad_menu_drag_squad",
            chosenSquads.get().findindex(@(s) s == null) == null ? "last" : "empty")))
        textCtor = mkMessageCtorWithGamepadIcons(["J:LB"])
        beforeStart = @() reserveSquads.get().len() == 0 ? null
          : newSquadIdx.set(findLastIndexToTakeSquad(reserveSquads.get()[newReceivedIdxInReserve.get()]))
        arrowLinks = [[0, 2], [1, 2]]
        objects = [
          
          { keys = Computed(@() isGamepad.get() ? newReceivedKeyInReserve.get() : null)
            hotkey = "^J:LB"
            onClick = function() {
              moveReserveSquadToActive(newSquadIdx.get())
              defer(nextStep) 
              return true
            }
          }
          
          { keys = Computed(@() isGamepad.get() ? null : newReceivedKeyInReserve.get())
            ctor = @(box) mkDropSquadSlot(box, chosenSquads.get().len(), reserveSquads.get()?[newReceivedIdxInReserve.get()])
          }
          
          { keys = newSquadKey
            ctor = @(box) mkDropTarget(box,
              function onDrop(_) {
                moveReserveSquadToActive(newSquadIdx.get())
                gui_scene.resetTimeout(0.1, nextStep) 
              })
          }
        ]
      }
      {
        id = "w3s5_move_squad_to_first"
        text = loc("tutorial_meta_squad_menu_place_squad_1st")
        textCtor = mkMessageCtorWithGamepadIcons(["J:Y"])
        beforeStart = @() newSquadIdx.get() > 0 ? null : defer(nextStep)
        arrowLinks = [[1, 2]]
        objects = [
          
          { keys = Computed(@() isGamepad.get() ? newSquadKey.get() : null)
            hotkey = "^J:Y"
            onClick = function() {
              if (newSquadIdx.get() > 0) {
                let idx = newSquadIdx.get()
                newSquadIdx.set(idx - 1)
                chosenSquads.set(moveIndex(chosenSquads.get(), idx, idx - 1))
              }
              return newSquadIdx.get() > 0
            }
            needArrow = true
          }
          
          { keys = Computed(@() isGamepad.get() ? null : newSquadKey.get())
            ctor = @(box) mkDropSquadSlot(box, newSquadIdx.get(), chosenSquads.get()?[newSquadIdx.get()])
          }
          {
            keys = Computed(@() isGamepad.get() ? null : getSquadKey(chosenSquads.get()?[0], 0))
            onClick = @() true
            ctor = @(box) mkDropTarget(box,
              function onDrop(_) {
                chosenSquads.set(moveIndex(chosenSquads.get(), newSquadIdx.get(), 0))
                nextStep()
              })
          }
        ]
        onSkip = function() {
          if (newSquadIdx.get() in chosenSquads.get()) {
            chosenSquads.set(moveIndex(chosenSquads.get(), newSquadIdx.get(), 0))
            return false
          }
          finishTutorial()
          return true
        }
      }
      {
        id = "w3s6_show_result"
        beforeStart = @() gui_scene.resetTimeout(1.0, nextStep)
        onFinish = @() gui_scene.clearTimer(nextStep)
        objects = [{ keys = Computed(@() getSquadKey(chosenSquads.get()?[0], 0)) }]
      }
      {
        id = "w3s7_final"
        text = loc("tutorial_meta_squad_menu_leave")
        textCtor = mkMessageCtorWithGamepadIcons([JB.B])
        objects = [{ keys = "closeSquadsManage", hotkey = $"^{JB.B}", needArrow = true }]
        onFinish = applyAndClose
      }
    ]
  })
}


let startTutorialDelayed = debounce(function() {
  if (showTutorial.get() && !isTutorialActive.get())
    startTutorial()
}, 0.3)

showTutorial.subscribe(@(v) v ? startTutorialDelayed() : null)
startTutorialDelayed()

console_register_command(startTutorial, "tutorial.startArmyLevel")
