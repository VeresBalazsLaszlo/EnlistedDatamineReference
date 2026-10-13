import "%ui/hud/state/custom_markers.nut" as markers
from "%ui/ui_library.nut" import *

let mkMarker = memoize(@(icon, size, color) {
  rendObj = ROBJ_IMAGE
  size = [hdpxi(size.x), hdpxi(size.y)]
  color
  image = Picture($"{icon}:{hdpxi(size.x)}:{hdpxi(size.y)}")
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
})

let transform = {pivot = [0.5, 0.35]} 
function mkMapMarker(eid) {
  let markerInfo = markers.get()[eid]
  return {
    key = eid
    data = {
      eid
      dirRotate = true
      clampToBorder = true
    }
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    transform
    children = mkMarker(markerInfo.icon, markerInfo.size, markerInfo.color)
  }
}


return {
  watch = markers
  ctor = @(_) markers.get().keys().map(mkMapMarker)
}
