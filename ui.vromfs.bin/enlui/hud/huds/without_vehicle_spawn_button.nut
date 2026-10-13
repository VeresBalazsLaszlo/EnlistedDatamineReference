import "%ui/components/checkbox.nut" as checkbox
from "%ui/hud/state/respawnState.nut" import showSquadSpawn, spawnWithVehicleRequested, spawnWithoutVehicleAvailable, spawnWithoutVehicleForced
from "%ui/ui_library.nut" import *

let showWithoutVehicleButton = Computed(@() showSquadSpawn.get() && (spawnWithoutVehicleAvailable.get() && !spawnWithoutVehicleForced.get()))

let withoutVehicleSpawnButtonBlock = @() {
  watch = [ showWithoutVehicleButton ]
  size = FLEX_H
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = showWithoutVehicleButton.get() ? checkbox(spawnWithVehicleRequested, loc("respawn/spawnWithVehicle")) : null
}

return withoutVehicleSpawnButtonBlock