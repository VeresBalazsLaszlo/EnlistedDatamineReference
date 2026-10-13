from "%ui/helpers/timers.nut" import mkTimerByDuration
from "%ui/ui_library.nut" import *

function mkCircularIndicator(duration) {
  let { countDownTimer, stopCountDownTimer } = mkTimerByDuration(duration)
  let curProgress = Computed(@() (countDownTimer.get() / duration) * 360.0)
  let showProgress = Computed(@() curProgress.get() > 0.0 && curProgress.get() < 360.0)

  let commands = [
    [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
    [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, curProgress.get()],
  ]

  function changeProgress() {
    commands[1][6] = curProgress.get()
    return {
      watch = curProgress
      size = FLEX
      lineWidth = hdpx(2.0)
      color = 0x10FFFFFF
      rendObj = ROBJ_VECTOR_CANVAS
      commands
    }
  }

  return @() {
    watch = showProgress
    size = FLEX
    onDetach = stopCountDownTimer
    children = showProgress.get() ? changeProgress : null
  }
}

return mkCircularIndicator
