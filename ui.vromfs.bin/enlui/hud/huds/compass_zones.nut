from "%ui/hud/state/watched_hero.nut" import watchedTeam
from "%ui/hud/components/capzone.nut" import capzoneWidget
from "%ui/hud/state/capZones.nut" import getZoneWatch, visibleCurrentCapZonesEids
from "%ui/ui_library.nut" import *

const zoneCompSize = fsh(1.8)

let iconSz= zoneCompSize.tointeger()
let defIcon = {
  rendObj = ROBJ_IMAGE
  image = Picture("ui/skin#waypoint.svg:{0}:{0}".subst(iconSz))
  size = iconSz
  transform = true
}

let settings = { canHighlight=false, size=zoneCompSize, useBlurBack=true}

let zoneComp = memoize(function(eid) {
  let zoneWatch = getZoneWatch(eid)
  let data = {eid, clampToBorder = false}
  let pos = const [0, fsh(2)]
  let capZ = capzoneWidget(eid, settings)

  return function() {
    let zone = zoneWatch.get()
    let watch = [watchedTeam, zoneWatch]
    if (zone == null)
      return {watch}

    let heroTeam = watchedTeam.get() ?? -1
    let isDefendZone = (zone.attackTeam >= 0 && zone.attackTeam != heroTeam)
    let zoneIcon = (!isDefendZone && (zone?.title ?? "") == "" && (zone?.icon ?? "") == "")
      ? defIcon.__merge({key=eid}) : null

    return {
      size = zoneCompSize
      watch
      children = [
        capZ
        zoneIcon
      ]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = true
      pos
      data
    }
  }
})

return {
  compassZoneCtor = @() visibleCurrentCapZonesEids.get().filter(@(v) v).keys().map(zoneComp)
  compassZoneWatch = visibleCurrentCapZonesEids
}