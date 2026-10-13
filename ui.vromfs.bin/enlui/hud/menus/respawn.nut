import "%ui/hud/menus/respawn_squad.ui.nut" as respawn_squad
import "%ui/hud/menus/respawn_member.ui.nut" as respawn_member
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/hud/state/respawnState.nut" import needSpawnMenu, updateSpawnSquadId, canChangeRespawnParams, respawnsInBot
from "%ui/ui_library.nut" import *

needSpawnMenu.subscribe(function(v) {
  if (v)
    updateSpawnSquadId()
})

let respawnBlock = @() {
  watch = [canChangeRespawnParams, needSpawnMenu, respawnsInBot, isGamepad]
  size = FLEX
  padding = isGamepad.get() ? [0, 0, hdpx(30), 0] : 0
  children = !needSpawnMenu.get() || !canChangeRespawnParams.get() ? null
    : respawnsInBot.get() ? respawn_member
    : respawn_squad
}

return respawnBlock
