import "%dngscripts/ecs.nut" as ecs
from "%ui/helpers/remap_nick.nut" import remap_nick
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/hud/state/watched_hero.nut" import watchedHeroPlayerEid
from "%ui/hud/state/local_player.nut" import localPlayerSpecTarget
from "%ui/ui_library.nut" import *

let isSpectator = Computed(@() localPlayerSpecTarget.get() != ecs.INVALID_ENTITY_ID && localPlayerSpecTarget.get()!=controlledHeroEid.get())

let spectatingPlayerName = Computed(@() remap_nick(ecs.obsolete_dbg_get_comp_val(watchedHeroPlayerEid.get(), "name", null)))

return {
  isSpectator
  spectatingPlayerName
}