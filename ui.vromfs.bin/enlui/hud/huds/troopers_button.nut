import "%ui/components/checkbox.nut" as checkbox
from "%ui/hud/state/respawnState.nut" import showSquadSpawn, isParatroopersSquad, paratroopersPointSelectorRequested
from "%ui/ui_library.nut" import *

let showButton = Computed(@() showSquadSpawn.get() && isParatroopersSquad.get())

let paratroopersButtonBlock = @() {
  watch = [ showButton ]
  size = FLEX_H
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = showButton.get() ? checkbox(paratroopersPointSelectorRequested, loc("respawn/airbornDeploy")) : null
}

return paratroopersButtonBlock