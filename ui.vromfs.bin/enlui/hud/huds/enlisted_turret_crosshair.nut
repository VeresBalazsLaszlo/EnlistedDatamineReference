import "%ui/hud/huds/turret_crosshair.nut" as gunnerCrosshair
import "%ui/hud/huds/commander_crosshair.nut" as commanderCrosshair
from "%ui/hud/state/vehicle_state.nut" import inTank, requireCrosshair, isGunner
from "%ui/ui_library.nut" import *

return function(){
  return {
    watch = [inTank,isGunner,requireCrosshair]
    children = (!inTank.get() && !requireCrosshair.get()) ? null
      : (isGunner.get() || requireCrosshair.get()) ? gunnerCrosshair
      : commanderCrosshair
  }
}
