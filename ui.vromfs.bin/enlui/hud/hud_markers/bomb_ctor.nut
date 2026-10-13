import "%enlSqGlob/is_teams_friendly.nut" as is_teams_friendly
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/missionType.nut" import isFriendlyFireMode
from "%ui/hud/hud_markers/components/hud_markers_components.nut" import makeArrow
from "%ui/hud/state/active_bombs.nut" import active_bombs_Set, active_bombs_GetWatched
from "%ui/hud/state/watched_hero.nut" import watchedTeam, watchedHeroEid
from "%ui/hud/state/get_team.nut" import getTeam
from "%ui/ui_library.nut" import *

const colorRedBlink = Color(255, 141, 29, 220)
const colorRed      = Color(255,  40, 30, 220)

let bombAnim = [{
  prop = AnimProp.color, from = colorRed, to = colorRedBlink,
  duration = 0.3, play = true, loop = true, easing = CosineFull
}]

let children = [
  {
    size = fsh(4.)
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    color = colorRed
    image = Picture("ui/skin#marker_bomb.svg")
    animations = bombAnim
  },
  makeArrow({color = colorRed, anim = bombAnim, yOffs = 0, pos = const [0, -fsh(1.8)]})
]

function bombMarker(eid) {
  let state = active_bombs_GetWatched(eid)
  let watch = [watchedHeroEid, state]
  return function() {
    let {bombOwnerEid, maxDistance} = state.get()
    let heroEid = watchedHeroEid.get() ?? ecs.INVALID_ENTITY_ID
    let showBombIndicatorToBombOwner =
      bombOwnerEid == heroEid
      && bombOwnerEid != ecs.INVALID_ENTITY_ID
    let showBombIndicatorToPlayer = isFriendlyFireMode()
      || !is_teams_friendly(watchedTeam.get(), getTeam(bombOwnerEid))

    if (!(showBombIndicatorToBombOwner || showBombIndicatorToPlayer))
      return {watch}
    return {
      data = {
        eid
        minDistance = 0.7
        maxDistance
        yOffs = 0.1
        distScaleFactor = 0.5
        clampToBorder = true
      }
      watch
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      transform = true
      key = eid
      sortOrder = eid
      children
    }
  }
}
let memoizedMap = mkMemoizedMapSet(bombMarker)
return {
  bomb_ctor = {
    watch = active_bombs_Set
    ctor = @() memoizedMap(active_bombs_Set.get()).values()
  }
}