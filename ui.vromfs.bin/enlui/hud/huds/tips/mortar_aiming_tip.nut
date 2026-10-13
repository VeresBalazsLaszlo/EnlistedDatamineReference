import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let isMortarMode = mkEcsComputed({
  comps = [["human_weap__mortarMode", ecs.TYPE_BOOL]]
  comps_rq = ["watchedByPlr"]
  defVal = false
})



let mortarDistance = mkEcsComputed({
  comps = [["mortar__targetDistance", ecs.TYPE_FLOAT]]
  comps_rq = ["mortar", "watchedPlayerItem"]
  defVal = 0.0
})

let mkAimDistance = @(distance) tipCmp({
  text = loc("hud/mortar_aiming", { distance = distance })
  inputId = "Human.Aim"
})

function mortar() {
  let watch = [isMortarMode, mortarDistance]
  if (!isMortarMode.get())
    return { watch }

  return {
    watch
    children = mkAimDistance(mortarDistance.get().tointeger())
  }
}

return mortar
