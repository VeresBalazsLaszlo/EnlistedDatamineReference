import "%ui/hud/state/burning.nut" as burningState
from "%ui/hud/state/burning_state_es.nut" import isBurning
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/ui_library.nut" import *

const color0 = Color(200,40,40,110)
const color1 = Color(200,200,40,180)

let animColor = [
  { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.scale, from=[1,1], to=[1.0, 1.1], duration=3.0, play=true, loop=true, easing=CosineFull }
]
let animAppear = [{ prop=AnimProp.translate, from=[sw(50),0], to=[0,0], duration=0.5, play=true, easing=InBack }]

let tip = tipCmp({
  inputId = "Inventory.UseMedkit"
  text = loc("tips/burning_tip")
  style = { color = color0 }
  animations = animAppear
  textAnims = animColor
})

let tipLeaveFromVehicle = tipCmp({
  inputId = "Human.Use"
  text = loc("tips/burning_in_vehicle_tip", "Leave from vehcile from extinguish a fire")
  style = { color = color0 }
  animations = animAppear
  textAnims = animColor
})

return function() {
  return {
    watch = [isBurning, inVehicle, burningState]
    size = SIZE_TO_CONTENT
    children = !isBurning.get() || burningState.get().isPuttingOut ? null
      : inVehicle.get() ? tipLeaveFromVehicle
      : tip
  }
}
