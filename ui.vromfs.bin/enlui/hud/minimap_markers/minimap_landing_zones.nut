import "%ui/hud/huds/getPicture.nut" as getPicture
from "%ui/hud/state/aircraft_respawn_landing_zones_state.nut" import landing_zones_GetWatched, landing_zones_Set
from "%ui/ui_library.nut" import *

const markerSize = hdpxi(21)
let iconSize = (markerSize/1.5).tointeger()

let darkback = freeze({
  size = const [markerSize, markerSize]
  rendObj = ROBJ_IMAGE
  image = Picture("!ui/uiskin/white_circle.svg:{0}:{0}:K".subst(markerSize))
  color = Color(0, 0, 0, 120)
})

let sizeIco = [iconSize, iconSize]

let ico = memoize(@(iconWatch) @(){
  rendObj = ROBJ_IMAGE
  size = sizeIco
  watch = iconWatch
  image = getPicture(iconWatch.get(), iconSize)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  transform = {rotate = -90}
})

let size = [markerSize.tointeger(), markerSize.tointeger()]

let mkMarker = memoize(function(eid) {
  let zoneWatch = landing_zones_GetWatched(eid)
  let icoWatch = Computed(@() zoneWatch.get()?.icon)
  let icon = ico(icoWatch)
  return freeze({
    data = { eid }
    transform = true
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [
      darkback
      icon
    ]
  })
})

let memoizedMap = mkMemoizedMapSet(mkMarker)

return {
  watch = landing_zones_Set
  ctor = @(_) memoizedMap(landing_zones_Set.get()).values()
}