import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/selected_bomb_site_state.nut" import selectedBombSite, isBombPlanted, bombPlantedTimeEnd, bombResetTimeEnd, bombDefuseTimeEnd, bombTimeToPlant, bombTimeToResetPlant, bombTimeToDefuse
from "%ui/helpers/timers.nut" import mkCountdownTimer
from "%ui/ui_library.nut" import *

let isPlanting = Computed(@() bombPlantedTimeEnd.get() >= 0)
let bombTimeEnd = Computed(@()
  isBombPlanted.get() ? bombDefuseTimeEnd.get()
    : isPlanting.get() ? bombPlantedTimeEnd.get()
    : bombResetTimeEnd.get())
let bombTotalTime = Computed(@()
  isBombPlanted.get() ? bombTimeToDefuse.get()
    : isPlanting.get() ? bombTimeToPlant.get()
    : bombTimeToResetPlant.get())
let bombTimer = mkCountdownTimer(bombTimeEnd)
let bombProgress = Computed(@() bombTotalTime.get() > 0 ? (1 - (bombTimer.get() / bombTotalTime.get())) : 0)

let commands = [
  [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
  [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
]
let sector = commands[1]
let indicatorSize = [hdpx(80), hdpx(80)]
const iconSz = hdpx(60)

let icon = freeze({
  rendObj = ROBJ_IMAGE
  image = Picture("ui/skin#time_bomb.svg:{0}:{0}".subst(iconSz.tointeger()))
  size = const [iconSz, iconSz]
})

let mkIndicator = @(fill = true) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    icon,
    {
      behavior = Behaviors.RtPropUpdate
      size = indicatorSize
      lineWidth = hdpx(6.0)
      color = Color(0, 255, 0)
      fillColor = Color(122, 1, 0, 0)
      rendObj = ROBJ_VECTOR_CANVAS
      commands = commands
      update = function() {
        sector[6] = 360.0 * (fill ? bombProgress.get() : (1.0 - bombProgress.get()))
      }
    }
  ]
}

const PROGRESS_DIRECTION_FILL = true
const PROGRESS_DIRECTION_RESET = false
let plant_indicator = mkIndicator(PROGRESS_DIRECTION_FILL)
let reset_indicator = mkIndicator(PROGRESS_DIRECTION_RESET)
let defuse_indicator = mkIndicator(PROGRESS_DIRECTION_RESET)

return function () {
  return {
    watch = [selectedBombSite, isBombPlanted, isPlanting, bombProgress]
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM

    children = selectedBombSite.get() == ecs.INVALID_ENTITY_ID ? null
      : isBombPlanted.get() ? defuse_indicator
      : isPlanting.get() ? plant_indicator
      : reset_indicator
  }
}