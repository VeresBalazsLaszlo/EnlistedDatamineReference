from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/hero_weapons.nut" import curWeaponChargeTime
from "%ui/ui_library.nut" import *

const TIP_SHOW_TIME = 5

let hasToCharge = Computed(@() curWeaponChargeTime.get() > 0)
let needToShowTip = Watched(false)
let hideTip = @() needToShowTip.set(false)

hasToCharge.subscribe(@(v) v ? needToShowTip.set(true) : needToShowTip.set(false))

let chargeToShootTip = tipCmp({
  text = loc("hint/chargeToShootTip")
  inputId = "Human.Shoot"
  style = {
    onAttach = @() gui_scene.resetTimeout(TIP_SHOW_TIME, hideTip)
  }
})

return @() {
  watch = [hasToCharge, needToShowTip]
  children = hasToCharge.get() && needToShowTip.get() ? chargeToShootTip : null
}
