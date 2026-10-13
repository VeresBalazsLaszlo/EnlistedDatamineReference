import "%ui/hud/state/enemy_attack_markers.nut" as markers
from "%ui/style/unit_colors.nut" import MAP_COLOR_ENEMY
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/ui_library.nut" import *

const iconSz = hdpxi(35)


let marker = freeze({
  rendObj = ROBJ_IMAGE
  size = const [iconSz, iconSz]
  color = MAP_COLOR_ENEMY
  image = Picture("ui/skin#enemy_attack_arrow.svg:{0}:{1}".subst(iconSz, iconSz))
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
})
let transform = {pivot = [0.5, 0.35]} 
let mkMapMarker = memoize(@(eid) {
  key = eid
  data = {
    eid
    dirRotate = true
    clampToBorder = true
  }
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  transform
  children = marker
})

let marksList = Computed(@() isReplay.get() ? [] : markers.get().keys())

return {
  watch = marksList
  ctor = @(_) marksList.get().map(mkMapMarker)
}