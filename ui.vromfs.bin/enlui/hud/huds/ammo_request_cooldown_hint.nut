from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/actions_state.nut" import useActionAvailable
from "%ui/hud/state/requestAmmoState.nut" import requestAmmoTimeout
from "%ui/helpers/time.nut" import secondsToString
from "%ui/hud/human_actions.nut" import ACTION_REQUEST_AMMO
from "%ui/ui_library.nut" import *

let actions = {
  [ACTION_REQUEST_AMMO] = { hintText = @(time) loc("hud/ammo_requst_cooldown", "Ammo requst cooldown: {time} left", {time = time}) },
}

return function() {
  let watch = [requestAmmoTimeout, useActionAvailable]
  let action = actions?[useActionAvailable.get()]
  if (requestAmmoTimeout.get() <= 0 || action == null)
    return { watch }

  return {
    watch
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM

    children = tipCmp({
      text = action.hintText(secondsToString(requestAmmoTimeout.get()))
    })
  }
}