from "%ui/hud/state/breath_state.nut" import breath_shortness, breath_low_threshold
from "%ui/hud/huds/player_info/style.nut" import barHeight, barWidth
from "%ui/ui_library.nut" import *

let { breath_low_anim_trigger } = require("%ui/hud/state/breath_state.nut")

let breathAnim = [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.5, easing=CosineFull, trigger=breath_low_anim_trigger, loop=true}
  { prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic }
]


const breathBgColor = Color(30, 30, 50, 40)
const breathFgColor = Color(80, 180, 250, 205)
const breathWarnColor = Color(255, 30, 300, 255)

function breath() {
  local ratio = 0
  local children = null
  if (breath_shortness.get() != null && breath_shortness.get() < 1.0) {
    ratio = breath_shortness.get()

    let breathWarning = breath_shortness.get() < breath_low_threshold ? {
      rendObj = ROBJ_SOLID
      color = breathWarnColor
      size = [barWidth * ratio,FLEX]
      animations = breathAnim
    } : null

    children = [
      {
        rendObj = ROBJ_SOLID
        size = [barWidth, barHeight]
        color = breathBgColor
        halign = ALIGN_RIGHT
        children = [
          {
            rendObj = ROBJ_SOLID
            color = breathFgColor
            size = [barWidth*ratio,FLEX]
          }
         breathWarning
        ]
      }
    ]
  }


  return {
    size = [barWidth, barHeight]
    watch = breath_shortness
    children = children
  }
}

return breath