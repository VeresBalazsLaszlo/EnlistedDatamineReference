from "%ui/hud/state/mortar.nut" import isMortarMode
from "%ui/hud/state/user_points.nut" import user_points
from "%ui/ui_library.nut" import *

let textSize = calc_str_box("1234")

let mortar = memoize(function(eid){
  return {
    transform = true
    pos = const [0, sh(1)]
    data = { eid }
    children = {
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      halign = ALIGN_CENTER
      targetEid = eid
      rendObj = ROBJ_TEXT
      color = Color(200,50,50,250)
      behavior = DngBhv.DistToEntity
      size = textSize
      markerFlags = DngBhv.MARKER_KEEP_SCALE
    }
  }
})
return {
  user_point_mortar_dist_ctor = {
    watch = [user_points, isMortarMode]
    ctor = @() !isMortarMode.get() ? [] : user_points.get().keys().map(mortar)
  }
}
