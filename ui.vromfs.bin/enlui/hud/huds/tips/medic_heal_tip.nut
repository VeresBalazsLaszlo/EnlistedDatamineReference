from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/medic_state.nut" import canHealSelectedSoldier
from "%ui/ui_library.nut" import *

let tip = tipCmp({
  text = loc("medic/heal_player")
  inputId = "Human.Use"
})

return @() {
  watch = [canHealSelectedSoldier]
  children = canHealSelectedSoldier.get() ? tip : null
}
