from "%enlSqGlob/dasenums.nut" import SquadBehaviour, SquadFormationSpread, SquadBehaviour_COUNT, SquadFormationSpread_COUNT
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/hud/style.nut" import HUD_TIPS_HOTKEY_FG
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/hud/state/squad_formation.nut" import setSquadFormation, squadFormation
from "%ui/hud/state/squad_behaviour.nut" import setSquadBehaviour, squadBehaviour
from "%ui/ui_library.nut" import *

function textFunc(text) {
  return {
    fillColor = HUD_TIPS_HOTKEY_FG
    borderWidth = 0
    borderRadius = hdpx(2)
    size = SIZE_TO_CONTENT
    padding = const [0, hdpx(3)]
    rendObj = ROBJ_BOX
    children = [
      {rendObj = ROBJ_TEXT text = text color=Color(0,0,0)}
    ]
  }
}

let mkStatus = @(action, children) watchElemState(@(sf) {
  behavior = isGamepad.get() ? null : Behaviors.Button
  rendObj = ROBJ_WORLD_BLUR
  flow = FLOW_HORIZONTAL
  VALIGN = ALIGN_CENTER
  padding = hdpx(5)
  gap = hdpx(10)
  color = sf & S_HOVER ? Color(200,200,200) : Color(240,240,240)
  onClick = action
  children
})


let squadBehaviourNames = {
  [SquadBehaviour.ESB_AGGRESSIVE] = loc("squad_orders/behaviour_aggressive", "Aggressive"),
  [SquadBehaviour.ESB_PASSIVE] = loc("squad_orders/behaviour_passive", "Passive")
}

let squadBehaviourDescs = {
[SquadBehaviour.ESB_AGGRESSIVE] = loc("squad_orders/behaviour_aggressive/desc"),
  [SquadBehaviour.ESB_PASSIVE] = loc("squad_orders/behaviour_passive/desc")
}

let currentSquadBehaviourText = Computed(@()
  loc("squad_orders/current_behaviour", {current=squadBehaviourNames[squadBehaviour.get()]}))

let currentSquadBehaviourDescText = Computed(@() squadBehaviourDescs[squadBehaviour.get()])

let selectNextBehaviour = @() setSquadBehaviour((squadBehaviour.get() + 1) % SquadBehaviour_COUNT)

let changeBehaviour = mkStatus(selectNextBehaviour, [
  mkHotkey("E | J:Y", selectNextBehaviour, { textFunc })
  {
    flow = FLOW_VERTICAL
    children = [
      @() {
        rendObj = ROBJ_TEXT
        watch = currentSquadBehaviourText
        text = currentSquadBehaviourText.get()
      }.__update(fontBody)
      @() {
        rendObj = ROBJ_TEXT
        watch = currentSquadBehaviourDescText
        text = currentSquadBehaviourDescText.get()
      }.__update(fontSub)
    ]
  }
])


let squadFormationNames = {
  [SquadFormationSpread.ESFN_CLOSEST] = loc("squad_orders/formation_close", "Closest"),
  [SquadFormationSpread.ESFN_STANDARD] = loc("squad_orders/formation_standard", "Standard"),
  [SquadFormationSpread.ESFN_WIDE] = loc("squad_orders/formation_wide", "Wide")
}

let squadFormationDescs = {
  [SquadFormationSpread.ESFN_CLOSEST] = loc("squad_orders/formation_close/desc"),
  [SquadFormationSpread.ESFN_STANDARD] = loc("squad_orders/formation_standard/desc"),
  [SquadFormationSpread.ESFN_WIDE] = loc("squad_orders/formation_wide/desc")
}

let currentSquadFormationText = Computed(@()
  loc("squad_orders/current_formation", {current=squadFormationNames[squadFormation.get()]}))

let currentSquadFormationDescText = Computed(@() squadFormationDescs[squadFormation.get()])

let selectNextFormation = @() setSquadFormation((squadFormation.get() + 1) % SquadFormationSpread_COUNT)

let changeFormation = mkStatus(selectNextFormation, [
  mkHotkey("Q | J:X", selectNextFormation, { textFunc })
  {
    flow = FLOW_VERTICAL
    children = [
      @() {
        rendObj = ROBJ_TEXT
        watch = currentSquadFormationText
        text = currentSquadFormationText.get()
      }.__update(fontBody)
      @() {
        rendObj = ROBJ_TEXT
        watch = currentSquadFormationDescText
        text = currentSquadFormationDescText.get()
      }.__update(fontSub)
    ]
  }
])

return {
  changeBehaviour
  changeFormation
}
