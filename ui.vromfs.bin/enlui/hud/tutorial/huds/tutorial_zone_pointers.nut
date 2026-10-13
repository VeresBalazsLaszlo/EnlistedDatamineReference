from "%ui/state/safeArea.nut" import safeAreaHorPadding, safeAreaVerPadding
from "%ui/hud/tutorial/state/tutorial_zones_state.nut" import tutorialZones
from "%ui/ui_library.nut" import *

let icons = {
  waypoint = {
    image = Picture($"ui/skin#waypoint_tutorial.svg:{hdpxi(32)}:{hdpxi(32)}")
    size = hdpxi(32)
  }
}

const arrowColor = Color(230, 230, 230, 250)

let arrowIconInside = memoize(function(icon) {
  let { image, size } = icons?[icon] ?? icons.waypoint
  return {
    rendObj = ROBJ_IMAGE
    size
    image
    color = arrowColor
    markerFlags = DngBhv.MARKER_SHOW_ONLY_IN_VIEWPORT
    transform = true
    animations = [
      { prop = AnimProp.translate, from = [0,fsh(2)], to = [0,0], duration = 1, play = true, loop = true, easing = CosineFull }
    ]
  }
})

let arrowIconOutside = memoize(@(icon) {
  markerFlags = DngBhv.MARKER_SHOW_ONLY_WHEN_CLAMPED | DngBhv.MARKER_ARROW
  transform = true
  children = arrowIconInside(icon).__merge({
    transform = { rotate = 180 }
  })
})

let mkArrow = @(eid, comp) {
  size = 0
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  data = { eid, clampToBorder = true }
  transform = true
  children = [
    arrowIconInside(comp.tutorial_zone__icon)
    arrowIconOutside(comp.tutorial_zone__icon)
  ]
}

function tutorialZonePointers() {
  let children = tutorialZones.get().reduce(@(res, comp, eid) res.append(mkArrow(eid, comp)), [])
  return {
    watch = [tutorialZones, safeAreaHorPadding, safeAreaVerPadding]
    size = [sw(100)-safeAreaHorPadding.get()*2 - fsh(40), sh(100) - safeAreaVerPadding.get()*2-fsh(40)]
    behavior = DngBhv.Projection
    halign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = children
  }
}

return tutorialZonePointers
