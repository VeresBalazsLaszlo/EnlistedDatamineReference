from "%ui/hud/style.nut" import MY_SQUAD_TEXT_COLOR
from "%ui/hud/hud_markers/components/hud_markers_components.nut" import makeArrow
from "%ui/hud/state/squad_orders.nut" import localSquadOrder
from "%ui/ui_library.nut" import *

let moveToPicSize = array(2, hdpxi(43))
let moveToPicName = $"ui/skin#moveto.svg:{moveToPicSize[0]}:{moveToPicSize[1]}"

let squadOrderAnim = [
  { prop=AnimProp.scale, from=[0.9, 0.9], to=[1.1, 1.1], duration=2, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.rotate, from=0, to=360, duration=20, play=true, loop=true }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.3, play=true}
  { prop = AnimProp.opacity, from = 0.8, to = 1,
    duration = 2, play = true, loop = true, easing = CosineFull}
]

let squadOrderIcon = {
  transform = {
    scale = [1, 0.5]
  }
  children = {
    rendObj = ROBJ_IMAGE
    size = moveToPicSize
    pos = const [0, 0]
    color = MY_SQUAD_TEXT_COLOR
    image = Picture(moveToPicName)
    animations = squadOrderAnim
    transform = true
  }
}

let squadOrderArrow = makeArrow({ color=MY_SQUAD_TEXT_COLOR, yOffs=fsh(4), anim = squadOrderAnim })

let squadOrderChildren = freeze([squadOrderIcon, squadOrderArrow])

function ctor(...) {
  let watch = localSquadOrder
  return function() {
    let orderPosition = watch.get()
    if (orderPosition == null)
      return {watch}

    return {
      watch
      data = {
        minDistance = 0.5
        maxDistance = 10000
        distScaleFactor = 0.3
        worldPos = orderPosition
      }
      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      transform = true
      key = orderPosition
      children = squadOrderChildren
    }
  }
}

return {
  squad_order_ctor = {
    ctor
    watch = null
  }
}