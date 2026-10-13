import "%ui/hud/state/machinegunner_state.nut" as isMachinegunner
from "%ui/hud/state/hero_weapons.nut" import curWeaponAmmo
from "%ui/hud/state/breath_state.nut" import isHoldBreath, isHoldBreathAvailable
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let tip = tipCmp({
  inputId = "Human.HoldBreath"
  text = loc("tips/hold_breath_to_aim")
})

let showHoldBrief = Computed(@() isHoldBreathAvailable.get()
  && !isMachinegunner.get()
  && !isHoldBreath.get()
  && (curWeaponAmmo.get() > 0))

return @() {
  watch = showHoldBrief
  size = SIZE_TO_CONTENT
  children = showHoldBrief.get() ? tip : null
}
