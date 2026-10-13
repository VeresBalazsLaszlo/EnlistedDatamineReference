import "%enlSqGlob/is_teams_friendly.nut" as is_teams_friendly
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/missionType.nut" import isFriendlyFireMode
from "%ui/hud/state/shell_activators.nut" import shell_activators_Set, shell_activators_GetWatched
from "%ui/hud/hud_markers/components/hud_markers_components.nut" import makeArrow
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid, watchedTeam
from "%ui/hud/state/get_team.nut" import getTeam
from "%ui/ui_library.nut" import *

const colorRedBlink = Color(255, 141, 29, 220)
const colorRed      = Color(255,  40, 30, 220)

let activatorAnim = [{
  prop = AnimProp.color, from = colorRed, to = colorRedBlink,
  duration = 0.3, play = true, loop = true, easing = CosineFull
}]
let arrow = makeArrow({color = colorRed, anim = activatorAnim, yOffs = 0, pos = const [0, -fsh(1.8)]})
let size = fsh(4.)
let getIcon = memoize(function(ico) {
  return freeze({
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    color = colorRed
    image = Picture($"ui/skin#{ico}")
    animations = activatorAnim
  })
})

function activatorMarker(eid) {
  let state = shell_activators_GetWatched(eid)
  let watch = [watchedHeroEid, watchedTeam, state]
  return function() {
    let {ownerEid, maxDistance, icon} = state.get()
    let heroEid = watchedHeroEid.get() ?? ecs.INVALID_ENTITY_ID
    let showActivatorIndicator = ownerEid == heroEid || isFriendlyFireMode()
      || !is_teams_friendly(watchedTeam.get(), getTeam(ownerEid))

    if (!showActivatorIndicator)
      return {watch}
    return {
      watch
      data = {
        eid
        minDistance = 0.7
        maxDistance
        yOffs = 0.1
        distScaleFactor = 0.5
        clampToBorder = true
      }
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      transform = true
      key = eid
      sortOrder = eid
      children = [ getIcon(icon) arrow ]
    }
  }
}

let memoizedMap = mkMemoizedMapSet(activatorMarker)
return {
  activator_ctor = {
    watch = shell_activators_Set
    ctor = @() memoizedMap(shell_activators_Set.get()).values()
  }
}