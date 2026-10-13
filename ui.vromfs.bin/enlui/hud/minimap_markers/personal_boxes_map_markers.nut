from "%ui/hud/state/local_player.nut" import localPlayerEid
from "%ui/hud/state/special_box_markers.nut" import special_box_markers_GetWatched, special_box_markers_Set
from "%ui/hud/style.nut" import TEAM0_COLOR_FG
from "%ui/ui_library.nut" import *

const iconSz = hdpxi(18)

let mkSvg = memoize(function(img) {
  return $"!ui/uiskin/{img}.svg:{iconSz}:{iconSz}:K"
})

let size = [iconSz, iconSz]
function mkPersonalBoxMapMarker(eid, transform) {
  let data = freeze({
    eid
    minDistance = 0.7
    maxDistance = 2000
    clampToBorder = true
  })
  let marker = special_box_markers_GetWatched(eid)
  let watch = [localPlayerEid, marker]
  return function() {
    let {image, ownerEid} = marker.get()
    let isLocalOwner = localPlayerEid.get() == ownerEid

    return {
      data
      watch
      transform = true
      children = isLocalOwner ? {
        rendObj = ROBJ_IMAGE
        size
        color = TEAM0_COLOR_FG
        image = image ? Picture(mkSvg(image)) : null
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform
      } : null
    }
  }
}
let memoizedMapByTransform = memoize(@(transform) mkMemoizedMapSet(@(eid) mkPersonalBoxMapMarker(eid, transform)))
return {
  watch = special_box_markers_Set
  ctor = @(p) memoizedMapByTransform(p?.transform)(special_box_markers_Set.get()).values()
}
