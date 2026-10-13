from "%ui/hud/state/fortification_builder_action.nut" import actionTimer
from "%ui/helpers/timers.nut" import mkCountdownTimer
from "%ui/ui_library.nut" import *

let endTimerTime = Computed(@() actionTimer.get().endTimeToComplete ?? 0.0)
let countDownTimer = mkCountdownTimer(endTimerTime)
let curProgressW = Computed(@() actionTimer.get().totalTime > 0 ?
 (1 - (countDownTimer.get() / actionTimer.get().totalTime)) * actionTimer.get().actionTimerMul + actionTimer.get().curProgress : 0)
let showProgress = Computed(@() curProgressW.get() > 0.0 && curProgressW.get() < 0.99)
let actionTimerColor = Computed(@() actionTimer.get().actionTimerColor)

let commands = [
  [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
  [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
]
let sector = commands[1]

const progressIconSize = hdpxi(50)

let destroyingProgress = {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_IMAGE
      color = Color(255, 255, 255)
      size = const [progressIconSize, progressIconSize]
      image = Picture($"!ui/uiskin/building_hammer.svg:{progressIconSize}:{progressIconSize}:K")
    }
    @() {
      watch = actionTimerColor
      behavior = Behaviors.RtPropUpdate
      size = hdpx(80)
      lineWidth = hdpx(6.0)
      color = actionTimerColor.get()
      fillColor = Color(122, 1, 0, 0)
      commands
      rendObj = ROBJ_VECTOR_CANVAS
      function update() {
        sector[6] = 360.0 * curProgressW.get()
      }
    }
  ]
}

return @() {
  watch = showProgress
  children = showProgress.get() ? destroyingProgress : null
}
