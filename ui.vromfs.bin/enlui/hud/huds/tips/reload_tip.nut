import "%ui/hud/state/machinegunner_state.nut" as isMachinegunner
from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/hud/state/hero_weapons.nut" import needReload
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

const color0 = Color(200,40,40,110)
const color1 = Color(200,200,40,180)

let tip = tipCmp({
  inputId = "Human.Reload"
  text = loc("tips/need_reload")
  sound = {
    attach = {name="ui/need_reload", vol=0.1}
  }
  textAnims = [
    { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull }
  ]
})

let showReloadTip = Computed(@() needReload.get() && !inVehicle.get() && !isMachinegunner.get())

return @() {
  watch = showReloadTip
  children = showReloadTip.get() ? tip : null
}
