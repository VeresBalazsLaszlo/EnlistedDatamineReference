from "%ui/hud/state/squad_orders.nut" import localSquadOrder
from "%ui/hud/style.nut" import MY_SQUAD_TEXT_COLOR
from "%ui/ui_library.nut" import *

const iconSize = hdpxi(27)
let moveto = Picture("ui/skin#moveto.svg:{0}:{0}".subst(iconSize))

let animations = [
  { prop=AnimProp.scale, from=[4,4], to=[1,1], duration=0.3, play=true}
  { prop=AnimProp.scale, from=[0.9, 0.9], to=[1.1, 1.1], duration=2, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.rotate, from=0, to=360, duration=20, play=true, loop=true }
  { prop=AnimProp.scale, from=[4,4], to=[1,1], duration=0.3, play=true}
  { prop=AnimProp.opacity, from=0, to=1, duration=0.3, play=true}
]

let size = [iconSize, iconSize]
let transform = { pivot = [0.5, 0.5] }

function ctor(...) {
  let watch = localSquadOrder
  return function() {
    let orderPosition = localSquadOrder.get()
    if (orderPosition==null)
      return {watch}
    return {
      watch
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      data = {
        worldPos = orderPosition
        clampToBorder = true
      }
      transform = true
      children = {
        rendObj = ROBJ_IMAGE
        image = moveto
        size
        color = MY_SQUAD_TEXT_COLOR
        transform
        animations = animations
      }
    }
  }
}


return {
  watch = null
  ctor
}
