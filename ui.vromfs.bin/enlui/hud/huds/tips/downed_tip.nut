from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/hud/state/health_state.nut" import isDowned, isAlive
from "%ui/hud/state/spectator_state.nut" import isSpectator
from "%ui/hud/state/downed_state.nut" import downedEndTime
from "%ui/hud/state/entity_use_state.nut" import medkitEndTime, medkitStartTime
from "%ui/hud/state/time_state.nut" import curTime
from "string" import format
from "%ui/ui_library.nut" import *

const color0 = Color(200,40,40,110)
const color1 = Color(200,200,40,180)
const overlapTipWithHeal = 1.0
let isInDowned = Computed(@() isDowned.get() && isAlive.get())

let animColor = [
  { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull }
  { prop=AnimProp.scale, from=[1,1], to=[1.0, 1.1], duration=3.0, play=true, loop=true, easing=CosineFull }
]
let animAppear = [{ prop=AnimProp.translate, from=[sw(50),0], to=[0,0], duration=0.5, play=true, easing=InBack }]

let centerPivot = const { pivot=[0,0.5] }

let tip = {
  rendObj = ROBJ_WORLD_BLUR
  padding = hdpx(2)
  size = SIZE_TO_CONTENT
  valign = ALIGN_CENTER
  transform = centerPivot
  animations = animAppear
  flow = FLOW_HORIZONTAL
  children = [
    @(){
      rendObj = ROBJ_TEXT
      text = loc(isSpectator.get() ? "tips/spectator_downed_tip" : "tips/downed_tip", {
        timeLeft = format("%d", max(downedEndTime.get() - curTime.get(), 0.0))
      })
      color = color0
      transform = centerPivot
      watch = [downedEndTime, curTime, isSpectator]
      animations = animColor
    }.__update(fontBody)
  ]
}
function mkTip(){
  let needTip = Computed(@()
      (downedEndTime.get() > curTime.get()) && ((medkitEndTime.get() < curTime.get()) || (medkitStartTime.get() + overlapTipWithHeal > curTime.get())))
  return @(){
    watch = needTip
    size = SIZE_TO_CONTENT
    children = needTip.get() ? tip : null
  }
}
return function() {
  return {
    watch = isInDowned
    size = SIZE_TO_CONTENT
    children = !isInDowned.get() ? null : mkTip()
  }
}
