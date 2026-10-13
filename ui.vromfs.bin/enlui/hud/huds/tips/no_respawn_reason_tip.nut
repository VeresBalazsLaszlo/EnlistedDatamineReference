from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/respawnState.nut" import squadsCanSpawn, isSpectatorEnabled
from "%ui/ui_library.nut" import *

const SHOW_TIME = 15

let showTip = Watched(false)
let hideTip = @() showTip.set(false)
let isTipAvailable = keepref(Computed(@() isSpectatorEnabled.get() && !squadsCanSpawn.get()))

let tip = tipCmp({
  text = loc("respawn/no_spawn_squads")
  style = fontSub
})

function showNoRespawnReason(state) {
  if (!state)
    return

  showTip.set(true)
  gui_scene.resetTimeout(SHOW_TIME, hideTip)
}

isTipAvailable.subscribe(showNoRespawnReason)

let no_respawn_reason_tip = @() {
  watch = showTip
  text = showTip.get() ? tip : null
}

return no_respawn_reason_tip