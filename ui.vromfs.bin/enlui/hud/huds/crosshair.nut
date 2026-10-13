from "%ui/helpers/timers.nut" import mkCountdownTimer
from "%ui/hud/huds/crosshair_state_es.nut" import overheat, teammateAim, isAiming, debugForceCrosshair, crosshairType, crosshairColor, reloadEndTime, reloadTotalTime, crossHairEid, showCustomCrosshair, crosshairCustomType
from "%ui/hud/huds/hit_marks.nut" import hitMarks as hitHair
from "%ui/hud/state/hudOptionsState.nut" import showCrosshairHints
from "%ui/ui_library.nut" import *
from "weapons.behaviors" import Crosshair

let circleProgressImage = Picture("ui/skin#scanner_range.avif")
const hairColor = Color(160, 160, 160, 120 )
const overheatFg = Color(160, 0, 0, 180)
const overheatBg = Color(0, 0, 0, 0)
const reloadColor = Color(200, 200, 200, 150)



let reloadTimer = mkCountdownTimer(reloadEndTime)
let reloadProgress = Computed(@()
  (reloadTotalTime.get() ?? -1) > 0 ? max(0, (1 - (reloadTimer.get() / reloadTotalTime.get())))
  : 0.0
)
let crosshairs = {}

let forbid = freeze({
  rendObj = ROBJ_VECTOR_CANVAS
  size = fsh(1.5)
  commands = [
    [VECTOR_WIDTH, hdpx(1.8)],
    [VECTOR_LINE, 0, 0, 100, 100],
    [VECTOR_LINE, 0, 100, 100, 0],
  ]
  color = Color(20, 80, 220, 80)

  animations = [
    { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.1, playFadeOut=true, easing=OutCubic }
  ]
})

crosshairs.chevron <- @() {
  rendObj = ROBJ_VECTOR_CANVAS
  size = fsh(1.5)
  commands = [
    [VECTOR_WIDTH, hdpx(1.8)],
    [VECTOR_LINE, 0, 100, 50, 50, 100, 100],
  ]
  color = hairColor

  animations = [
    { prop=AnimProp.opacity, from=0, to=1, duration=0.2, play=true, easing=InOutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.1, playFadeOut=true, easing=OutCubic }
  ]
}
let ct = freeze([
  [VECTOR_WIDTH, hdpx(2)],
  [VECTOR_LINE, 0, 50, 30, 50],
  [VECTOR_LINE, 70, 50, 100, 50],
  [VECTOR_LINE, 50, 70, 50, 100],
])

crosshairs.t_post <- @() {
  size = FLEX
  watch = crosshairColor
  rendObj = ROBJ_VECTOR_CANVAS
  color = crosshairColor.get().u
  commands = ct
}


function hitMarkBlock() {
  return {
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = hitHair
  }
}

let forbidBlock = {
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = forbid
}

function reloadBlock(){
  return {
    watch = reloadProgress
  }.__update(reloadProgress.get() <= 0 ? {} : {
    color = reloadColor
    fillColor = Color(0, 0, 0, 0)
    rendObj = ROBJ_VECTOR_CANVAS
    size = fsh(4.0)
    commands = [
      [VECTOR_WIDTH, hdpx(1)],
      [VECTOR_SECTOR, 50, 50, 50, 50, -90.0, -90.0 + (reloadProgress.get() ?? 0.0) * 360.0],
    ]
  })
}

function overheatBlock() {
  return {
    watch = overheat
    opacity = min(1.0, overheat.get()*2.0)
    fValue = overheat.get()
    rendObj = ROBJ_PROGRESS_CIRCULAR
    image = circleProgressImage
    size = fsh(4)
    fgColor = overheatFg
    bgColor = overheatBg
  }
}


const w = sw(0.2*100)
const h = sh(0.2*100)

function mkCrosshair(childrenCtor, watch, size=[2*w, 2*h]){
  return @() {
    watch
    size
    lineWidth = hdpx(2)
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    behavior = Crosshair
    transform = true
    eid = crossHairEid.get()
    children = childrenCtor()
  }
}
let overlayTransparencyBlock = {
  size =  fsh(3)
  behavior = isAiming.get()? Behaviors.OverlayTransparency : null
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}

let mkCrosshairElement = @(children) {size = 0, children = {size = const [sw(100), sh(100)], children = children}}
let canShowForbidden = Computed(@() teammateAim.get() && !isAiming.get() && showCrosshairHints.get())
let crossHairTypeToShow = Computed(@() debugForceCrosshair.get() ? crosshairType?.get() : showCustomCrosshair.get() ? crosshairCustomType?.get() : null)

let forbiddenBlock = @(){
  watch = canShowForbidden
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = canShowForbidden.get() ? forbid : null
}

let crosshair = mkCrosshair(@() [
    forbiddenBlock,
    crosshairs?[crossHairTypeToShow.get()],
    hitMarkBlock,
    overheatBlock,
    overlayTransparencyBlock
  ],
  crossHairTypeToShow
)

let crosshairForbidden = mkCrosshair(@() showCrosshairHints.get() && teammateAim.get() ? forbidBlock : null, [showCrosshairHints, teammateAim])
let crosshairOverheat = mkCrosshair(@() overheatBlock, null)
let crosshairReload = mkCrosshair(@() reloadBlock, null)
let crosshairHitmarks = mkCrosshair(@() hitMarkBlock, null)

return {
  mkCrosshair
  mkCrosshairElement
  crosshair = mkCrosshairElement(crosshair)
  crosshairForbidden = mkCrosshairElement(crosshairForbidden)
  crosshairOverheat = mkCrosshairElement(crosshairOverheat)
  crosshairReload = mkCrosshairElement(crosshairReload)
  crosshairHitmarks = mkCrosshairElement(crosshairHitmarks)
  crosshairOverlayTransparency = mkCrosshairElement(overlayTransparencyBlock)
}
