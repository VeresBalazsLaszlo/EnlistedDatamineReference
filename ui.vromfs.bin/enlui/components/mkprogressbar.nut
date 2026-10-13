from "%ui/components/glareAnimation.nut" import animChildren
from "%ui/style/designConst.nut" import accentColorOld
from "%ui/ui_library.nut" import *

let pbColorAcquired = accentColorOld
const pbColorCompleted = Color(255, 168, 0, 225)
const progressBarHeight = hdpxi(40)
const gradientWidth = hdpxi(18)
let offs = [0, (0.8 * gradientWidth).tointeger(), 0, 0]

function progressContainerCtor(mask, borderImg, size) {
  let maskImage = $"{mask}:{size[0]}:{size[1]}"
  let borderImage = $"{borderImg}:{size[0]}:{size[1]}"
  return @(progressComp, addChild = null) {
    size
    valign = ALIGN_CENTER
    children = [
      {
        size = FLEX
        rendObj = ROBJ_MASK
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        image = Picture(maskImage)
        children = progressComp
      }
      {
        rendObj = ROBJ_IMAGE
        size = FLEX
        image = Picture(borderImage)
      }
      addChild
    ]
  }
}

let inactiveProgressCtor = @() {
  rendObj = ROBJ_SOLID
  size = const [pw(100), FLEX]
  color = Color(112, 112, 112)
}

let gradientProgressLine = @(progress, image = "!ui/uiskin/progress_bar_gradient.svg") {
  size = FLEX
  clipChildren = true
  children = {
    rendObj = ROBJ_9RECT
    image = Picture($"{image}:{gradientWidth}:{4}:F?Ac")
    size = [pw(progress * 100), progressBarHeight]
    texOffs = offs
    screenOffs = offs
  }
}


let solidProgressCtor = @(key = "progress_bar")
  @(progress, animations = [], color = pbColorCompleted, amimColor = null) {
    key
    rendObj = ROBJ_SOLID
    size = [pw(progress * 100), FLEX]
    color
    clipChildren = true
    animations = [{ prop = AnimProp.color, from = amimColor ?? pbColorAcquired, to = color
      easing = CosineFull, duration = 1.5, loop = true, play = true}]
    children = animations.len() > 0
      ? animChildren(animations)
      : null
  }

return {
  progressBarHeight
  progressContainerCtor
  gradientProgressLine
  completedProgressLine = solidProgressCtor("animated_progress_bar")
  acquiredProgressLine = solidProgressCtor()
  inactiveProgressCtor
}
