from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/huds/spy_clothes_change_state.nut" import spyDetected, spyDisguised,
  spyCanChangeClothes, spyClothesChangeEndTime, spyClotheTotalChangeTime
from "%ui/helpers/timers.nut" import mkCountdownTimer
from "%ui/ui_library.nut" import *

let mkClothesIcon = @(icon, size = const [hdpxi(40), hdpxi(40)], color = Color(255, 255, 255)) {
  rendObj = ROBJ_IMAGE
  size
  image = Picture($"ui/skin#{icon}.svg:{size[0]}:{size[1]}")
  color
}

let clothesChangeIcon = mkClothesIcon("uniform_icon")
let spyDisguisedIcon = mkClothesIcon("stealth_icon_man", const [hdpxi(25), hdpxi(25)])
let spyRevealedIcon = mkClothesIcon("stealth_icon_eye", const [hdpxi(25), hdpxi(25)], Color(220, 50, 50, 200))

let spyDetectedTip = tipCmp({ text = loc("tips/spy_you_are_detected") })
let spyCanChangeClothesTip = tipCmp({ text = loc("tips/spy_cant_change_clothes_try_to_hide") })

let spyDetectedDelayed = Watched(false)
let hideSpyDetectedDelayed = @() spyDetectedDelayed.set(false)

spyDetected.subscribe(function(detected) {
  if (detected) {
    spyDetectedDelayed.set(true)
    gui_scene.resetTimeout(5, hideSpyDetectedDelayed)
  } else {
    gui_scene.clearTimer(hideSpyDetectedDelayed)
    spyDetectedDelayed.set(false)
  }
})

let spyDetectedTipUi = @() {
  watch = spyDetectedDelayed
  margin = const [0, 0, hdpx(40), 0]
  children = spyDetectedDelayed.get() ? spyDetectedTip : null
}

let spyDetectedIcon = @() {
  watch = [spyDetected, spyDisguised]
  halign = ALIGN_RIGHT
  children = spyDetected.get() ? spyRevealedIcon
   : spyDisguised.get() ? spyDisguisedIcon
   : null
}

let spyCanChangeClothesTipUi = @() {
  watch = [spyCanChangeClothes]
  margin = const [0, 0, hdpx(40), 0]
  children = spyCanChangeClothes.get() ? null : spyCanChangeClothesTip
}

let clothesTimer = mkCountdownTimer(spyClothesChangeEndTime)
let clothesProgress = Computed(@() spyClotheTotalChangeTime.get() > 0
  ? clamp(1.0 - (clothesTimer.get() / spyClotheTotalChangeTime.get()), 0.0, 1.0)
  : 0.0)

let commands = [
  [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
  [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
]
let indicatorSize = [hdpx(80), hdpx(80)]

function clothesChangeProgress() {
  commands[1][6] = 360.0 * clothesProgress.get()
  return {
    watch = [clothesProgress]
    size = indicatorSize
    lineWidth = hdpx(6.0)
    color = Color(0, 255, 0)
    fillColor = Color(122, 1, 0, 0)
    rendObj = ROBJ_VECTOR_CANVAS
    commands
  }
}

let spyClothesChangeProgressUi = {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    clothesChangeIcon
    clothesChangeProgress
  ]
}

let spyClothesChangeProgress = @() {
  watch = [spyClothesChangeEndTime]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  children = spyClothesChangeEndTime.get() > 0 ? spyClothesChangeProgressUi : null
}

return {
  spyDetectedTipUi
  spyCanChangeClothesTipUi
  spyClothesChangeProgress
  spyDetectedIcon
}
