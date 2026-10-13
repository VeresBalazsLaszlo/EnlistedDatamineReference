from "%ui/hud/state/grenade_rethrow_state.nut" import showGrenadeRethrowTip
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

return function() {
  let watch = showGrenadeRethrowTip
  if (!showGrenadeRethrowTip.get())
    return { watch }

  return {
    watch
    children = tipCmp({
      text = loc("hud/throw_back")
      inputId = "Human.ThrowBack"
    })
  }
}
