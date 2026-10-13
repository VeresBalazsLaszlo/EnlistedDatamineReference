from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/ui_library.nut" import *

function progressText(text) {
  return {
    rendObj = ROBJ_TEXT
    text
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER

    animations = [
      {
        prop=AnimProp.color, from=Color(255,255,250), to=Color(220,255,120), easing=CosineFull,
        duration=0.8, loop=true, play=true
      }
    ]
  }.__update(fontHeading2)
}


return progressText
