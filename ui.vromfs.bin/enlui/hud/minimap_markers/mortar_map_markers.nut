from "%ui/hud/state/mortar_markers.nut" import mortarMarkers
from "%ui/ui_library.nut" import *

let mortarMarkerMapIconSize = [sh(2.25), sh(2.25)].map(@(v) v.tointeger())

let mortarImages = {
  mortarKill = Picture("ui/skin#skull.svg:{0}:{1}".subst(mortarMarkerMapIconSize[0], mortarMarkerMapIconSize[1]))
  mortarShellExplode = Picture("ui/skin#launcher.svg:{0}:{1}".subst(mortarMarkerMapIconSize[0], mortarMarkerMapIconSize[1]))
}
let transform = {
  pivot=[0.5, 0.5]
  rotate = -90
}

function mkMortarMarker(eid){
  
  
  let marker = Computed(@(prev) mortarMarkers.get()?[eid] ?? (prev == FRP_INITIAL ? null : prev))
  return @() {
    watch = marker
    image = mortarImages?[marker.get().type]
    size = mortarMarkerMapIconSize
    valign = ALIGN_CENTER
    transform
    rendObj = ROBJ_IMAGE
    data = {
      worldPos = marker.get().transform.getcol(3)
    }
  }
}

let memoizedMap = mkMemoizedMapSet(mkMortarMarker)
return {
  watch = mortarMarkers
  ctor = @(_) memoizedMap(mortarMarkers.get()).values()
}