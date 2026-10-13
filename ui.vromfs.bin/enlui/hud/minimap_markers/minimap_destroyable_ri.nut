import "%enlSqGlob/is_teams_friendly.nut" as is_teams_friendly
from "%ui/hud/state/destroyable_score_ri_markers.nut" import destroyable_ri_Set, destroyable_ri_GetWatched
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/hud/state/vehicle_state.nut" import inPlane
from "%ui/style/unit_colors.nut" import HUD_COLOR_ENEMY_INNER
from "%ui/ui_library.nut" import *

const iconSz = hdpxi(18)

let pic = Picture($"ui/skin#unit_inner.svg:{iconSz}:{iconSz}")
let mkMarker = memoize(@(transform) freeze({
  rendObj = ROBJ_IMAGE
  size = const [iconSz, iconSz]
  color = HUD_COLOR_ENEMY_INNER
  image = pic
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  transform
}))

function mkDestoyableRiMarker(eid, transform = null) {
  let markerState = destroyable_ri_GetWatched(eid)
  let data = freeze({
    eid
    minDistance = 0.7
    maxDistance = 2000
    clampToBorder = true
  })
  let marker = mkMarker(transform)
  let watch = [markerState localPlayerTeam]

  return function() {
    let addScoreTeam = markerState.get()
    return {
      data
      transform = true
      watch
      children = is_teams_friendly(localPlayerTeam.get(), addScoreTeam) ? marker : null
    }
  }
}

let watchState = Computed(@() inPlane.get() ? destroyable_ri_Set.get() : null)
let memoizedMapByTransform = memoize(@(transform) mkMemoizedMapSet(@(eid) mkDestoyableRiMarker(eid, transform)))

return {
  watch = watchState
  ctor = @(p) memoizedMapByTransform(p?.transform)(watchState.get() ?? {}).values()
}
