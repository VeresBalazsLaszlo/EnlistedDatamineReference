from "%ui/style/fontsStyle.nut" import fontBody
from "%sqstd/math.nut" import ceil
from "%ui/ui_library.nut" import *

const STEPS_PER_SEC = 40


function mkCounting(from, to, duration = 2, delay = 0, override = fontBody) {
  let delta = to - from
  if (delta == 0)
    return {
      rendObj = ROBJ_TEXT
      text = to
    }.__update(override)

  local steps = min(STEPS_PER_SEC * duration, delta)
  let addVal = ceil(delta.tofloat() / steps)
  let countingVal = Watched(from)
  function doCount() {
    steps--
    countingVal.set(steps > 0 ? countingVal.get() + addVal : to)
    if (steps <= 0)
      gui_scene.clearTimer(doCount)
  }
  function doStart() {
    gui_scene.setInterval(1.0 / STEPS_PER_SEC, doCount, doCount)
  }

  return @() {
    watch = countingVal
    rendObj = ROBJ_TEXT
    text = countingVal.get()
    onAttach = @() gui_scene.resetTimeout(delay, doStart, doStart)
    onDetach = function() {
      gui_scene.clearTimer(doStart)
      gui_scene.clearTimer(doCount)
    }
  }.__update(override)
}


return mkCounting
