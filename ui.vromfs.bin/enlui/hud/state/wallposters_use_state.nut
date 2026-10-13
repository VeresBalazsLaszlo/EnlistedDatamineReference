from "%ui/hud/state/health_state.nut" import isDowned, isAlive
from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid
from "%ui/hud/state/binocular.nut" import isBinocularMode
from "%ui/ui_library.nut" import *

let canUseWallposter = Computed(@() isAlive.get()
  && (controlledHeroEid.get() == watchedHeroEid.get())
  && !isDowned.get()
  && !inVehicle.get()
  && !isBinocularMode.get())

return {
  canUseWallposter
}