from "%ui/hud/state/token_markers.nut" import token_markers_GetWatched, token_markers_Set
from "%ui/ui_library.nut" import *

const iconSz = hdpxi(15)

let mkSvg = memoize(function(img) {
  return $"!ui/uiskin/{img}.avif:{iconSz}:{iconSz}:K"
})

let size = [iconSz, iconSz]
function mkTokenMapMarker(eid, transform) {
  let data = freeze({
    eid
    minDistance = 0.7
    maxDistance = 2000
    clampToBorder = true
  })
  let marker = token_markers_GetWatched(eid)
  let watch = [marker]
  return function() {
    let {image} = marker.get()

    return {
      data
      watch
      transform = true
      children = {
        rendObj = ROBJ_IMAGE
        size
        color = Color(255, 255, 255)
        image = image ? Picture(mkSvg(image)) : null
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform
      }
    }
  }
}
let memoizedMapByTransform = memoize(@(transform) mkMemoizedMapSet(@(eid) mkTokenMapMarker(eid, transform)))
return {
  watch = token_markers_Set
  ctor = @(p) memoizedMapByTransform(p?.transform)(token_markers_Set.get()).values()
}
