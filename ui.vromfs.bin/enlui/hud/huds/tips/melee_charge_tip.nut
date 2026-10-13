from "%ui/hud/state/hero_weapons.nut" import canStartMeleeCharge
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let tip = tipCmp({
  text = loc("tips/melee_charge")
  inputId = "Human.Melee"
  animations = [{ prop=AnimProp.opacity, from=0.0, to=0.0, duration=1.0, play=true }]
})

return @(){
  watch = canStartMeleeCharge
  children = canStartMeleeCharge.get() ? tip : null
}
