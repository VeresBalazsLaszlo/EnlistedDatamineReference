from "%ui/hud/hud_markers/components/hud_markers_components.nut" import makeArrow
from "%ui/hud/state/active_grenades.nut" import active_grenades_Set, active_grenades_GetWatched
from "%ui/ui_library.nut" import *

const colorWhite   = Color(255,  255,  255, 220)
const colorRedBlink =Color(255, 141, 29, 220)
const colorRed     = Color(255,  40,  30, 220)

let grenadeAnim = [{
  prop = AnimProp.color, from = colorRed, to = colorRedBlink,
  duration = 0.3, play = true, loop = true, easing = CosineFull
}]

let grenadePic = Picture("ui/skin#grenade.avif")
let arrow = makeArrow({color=colorRed, anim = grenadeAnim, yOffs=0, pos=const [0,-fsh(1.8)]})
let mkGrenadeImage = memoize(@(willDamageHero) {
  size = fsh(2.5)
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  color = willDamageHero ? colorRed : colorWhite
  image = grenadePic
  animations = willDamageHero ? grenadeAnim : null
})


function grenadeMarker(eid) {
  let watch = active_grenades_GetWatched(eid)

  return @(){
    data = {
      eid
      minDistance = 0.7
      maxDistance = watch.get().maxDistance
      yOffs = 0.1
      distScaleFactor = 0.5
      clampToBorder = true
    }
    watch
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    transform = true
    key = eid
    sortOrder = eid
    children = [
      mkGrenadeImage(watch.get()?.willDamageHero ?? true)
      arrow
    ]
  }
}

let memoizedMap = mkMemoizedMapSet(grenadeMarker)

return {
  grenade_ctor = {watch = active_grenades_Set, ctor = @() memoizedMap(active_grenades_Set.get()).values()}
}