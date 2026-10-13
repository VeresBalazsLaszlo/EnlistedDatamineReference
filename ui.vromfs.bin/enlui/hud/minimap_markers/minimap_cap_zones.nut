from "%ui/hud/state/capZones.nut" import minimapVisibleCurrentCapZonesEids, getZoneWatch
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid
from "%ui/hud/components/capzone.nut" import capzoneWidget
from "%ui/components/unseenSignal.nut" import blinkUnseenIcon
from "%ui/ui_library.nut" import *

let iconSz= [hdpxi(18), hdpxi(16)]
let unseenIcon =  blinkUnseenIcon(0.7).__update({
  key = "blink_on"
  padding = const [0 hdpx(15) 0 0]
})
let defIcon = {rendObj = ROBJ_IMAGE image=Picture("ui/skin#waypoint.svg:{0}:{1}".subst(iconSz[0],iconSz[1])) size = iconSz transform={}}
let capzoneSettings = {canHighlight=false, size=fsh(3), useBlurBack=false}

function mkContract(zone, capz) {
  let {attackTeam, alwaysHide=false} = zone
  if (localPlayerTeam.get() != attackTeam)
    return null

  return !alwaysHide ? capz : {
    flow     = FLOW_HORIZONTAL
    children = [
      unseenIcon
      capz
    ]
  }
}

function minimapCapZone(eid, transform){
  let zoneWatch = getZoneWatch(eid)
  let watch = [zoneWatch, localPlayerTeam, watchedHeroEid]
  let capz = capzoneWidget(eid, capzoneSettings)

  return function() {
    let {attackTeam, title="", icon = "", isBattleContract=false, clipThreshold=1.0} = zoneWatch.get()
    let heroTeam = localPlayerTeam.get()
    let isDefendZone = (attackTeam >= 0 && attackTeam != heroTeam)
    let zoneIcon = (!isDefendZone && title == "" && icon == "") ? defIcon : null

    return {
      watch
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      key = eid
      data = {
        zoneEid = eid
        clampToBorder = true
        squareClipThreshold = clipThreshold
      }
      transform

      children = [
        isBattleContract ? mkContract(zoneWatch.get(), capz) : capz
        zoneIcon
      ]
    }
  }
}

let memoizedMapByTransform = memoize(@(transform) mkMemoizedMapSet(@(eid) minimapCapZone(eid, transform)))
return {
  watch = minimapVisibleCurrentCapZonesEids
  ctor = @(o) memoizedMapByTransform(o?.transform ?? {})(minimapVisibleCurrentCapZonesEids.get()).values()
}