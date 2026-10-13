from "%ui/ui_library.nut" import *

const barWidth = sw(7)
const barHeight = fsh(0.5)

let blurBack = {
  rendObj = ROBJ_WORLD_BLUR
  size = FLEX
  color=Color(250,250,250,250)
}

return freeze({
  DEFAULT_TEXT_COLOR = Color(180, 180, 180, 120)
  HUD_ITEMS_COLOR = Color(180,180,180,50)
  blurBack = blurBack
  barWidth = barWidth
  barHeight = barHeight
  notSelectedItemColor = Color(180,180,180,150)
  iconSize = [hdpxi(18), hdpxi(18)]
  itemAppearing = [
    {prop=AnimProp.opacity, from=0, to=1, duration=0.5, play=true, easing=InOutCubic}
  ]
})