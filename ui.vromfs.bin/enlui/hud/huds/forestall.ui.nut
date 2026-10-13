from "%ui/hud/state/forestall_state.nut" import forestallMarkActive, forestallMarkPos, forestallMarkOpacity
from "%ui/ui_library.nut" import *

let forestallImageSize = [fsh(3),fsh(3)]
let forestallImage = freeze({
  size = forestallImageSize
  rendObj = ROBJ_IMAGE
  color = Color(255, 255, 255, 255)
  valign = ALIGN_CENTER
  transform = true
  image = Picture("ui/skin#sniper_rifle.svg:{0}:{0}".subst(forestallImageSize[1].tointeger()))
})

let animations = [
  { prop = AnimProp.scale, from =[0.25, 0.25], to = [1, 1], duration = 0.3, easing = InCubic, play = true}
]

function mkForestallMark(){
  return {
    data = {
      minDistance = 0.1
      clampToBorder = false
      worldPos = forestallMarkPos.get()
    }
    opacity = forestallMarkOpacity.get()
    watch = [forestallMarkPos, forestallMarkOpacity]
    animations = animations
    transform = true
    children = forestallImage
  }
}

function forestallMarkComp() {
  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    size = const [sw(100), sh(100)]
    children = forestallMarkActive.get() ? mkForestallMark : null
    watch = [forestallMarkActive]
    behavior = DngBhv.Projection
  }
}

return forestallMarkComp
