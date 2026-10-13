from "%ui/hud/state/hit_marks_es.nut" import hitMarks
from "%ui/ui_library.nut" import *

let markSize = [fsh(4.),fsh(4.)]
const markColor = Color(255, 255, 255, 255)
const fadeInTime = 0.5
const fadeOutTime = 0.3
const visibleTime = 0.8
let visImmunityMarks = keepref(Computed(
  @() hitMarks.get().reduce(@(res, mark) mark.isImmunityHit ? res + 1 : res, 0)))
let needShowImmunityMark = Watched(false)
let hideImmunityMark = @() needShowImmunityMark.set(false)
local lastVisibleImmunityMarks = visImmunityMarks.get()

visImmunityMarks.subscribe(function(v) {
  let oldValue = lastVisibleImmunityMarks
  lastVisibleImmunityMarks = v

  if (v == 0) {
    needShowImmunityMark.set(false)
    return
  }

  if (oldValue > v)
    return

  needShowImmunityMark.set(true)
  gui_scene.resetTimeout(visibleTime, hideImmunityMark)
})

let immunityMark = {
  size = markSize
  rendObj = ROBJ_IMAGE
  color = markColor
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  image = Picture("ui/skin#stand_icon.svg:{0}:{0}".subst(markSize[1].tointeger()))
  transform = true
  animations = [
    { prop = AnimProp.opacity, from = 1, to = 1, duration = fadeInTime,
      play  = true, easing = InCubic }
    { prop = AnimProp.opacity, from = 1, to = 0, duration = fadeOutTime,
      easing = InCubic, playFadeOut = true }
    { prop = AnimProp.scale, from = [1, 1], to = [1.4, 1.4], duration = fadeOutTime,
      easing = InOutCubic, playFadeOut = true }
  ]
}

let immunityMarksComp = @() {
  watch = needShowImmunityMark
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = needShowImmunityMark.get()
            ? immunityMark
            : null
}

return immunityMarksComp
