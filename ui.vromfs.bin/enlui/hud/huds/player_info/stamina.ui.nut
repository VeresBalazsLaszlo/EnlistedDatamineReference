from "%ui/hud/state/stamina_es.nut" import stamina, scaleStamina
from "%ui/hud/state/flask.nut" import flaskAffectApplied
from "%ui/hud/huds/player_info/style.nut" import barHeight, barWidth
from "%ui/ui_library.nut" import *

let { staminaAnimTrigger } = require("%ui/hud/state/stamina_es.nut")

let staminaAnim = [
  { prop=AnimProp.fgColor, from=Color(255,255,250), to=Color(220,225,100), easing=CosineFull,
    duration=0.5, trigger=staminaAnimTrigger, loop=true
  }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.2, playFadeOut=true, easing=InOutCubic }
]


let showStamina = Computed(@() stamina.get() != null
  && stamina.get() >= 0
  && (stamina.get() < 100 || flaskAffectApplied.get()))

function staminaComp() {
  local ratio = 0
  local children = null

  local width = barWidth
  if (showStamina.get()) {
    ratio = clamp(stamina.get(), 0.0, 100.0) / 100.0
    let ir = 1.0-ratio
    const colorBg = Color(30, 30, 50, 40)
    let colorFg = flaskAffectApplied.get()
      ? Color(30+ir*170, 135+ir*120, 255-ir*150, 255)
      : Color(70+ir*170, 80+ir*170, 255-ir*150, 255)
    width *= scaleStamina.get()

    children = [
      {
        rendObj = ROBJ_SOLID
        size = [width, barHeight]
        color = colorBg
        halign = ALIGN_RIGHT
        children = {
          rendObj = ROBJ_SOLID
          color = colorFg
          size = [width*ratio,FLEX]
        }
        animations = staminaAnim
      }
    ]
  }


  return {
    size = [width, barHeight]
    watch = [stamina, showStamina, flaskAffectApplied]
    children = children
  }
}

return staminaComp