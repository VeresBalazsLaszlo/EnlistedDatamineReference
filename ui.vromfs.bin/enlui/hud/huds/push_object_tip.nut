from "%ui/hud/state/push_object_state.nut" import showPushObjectTip
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

function push_object_tip() {
  let watch = showPushObjectTip
  if (!showPushObjectTip.get())
    return { watch }

  return {
    watch
    children = tipCmp({
      text = loc("hint/pushObject")
      inputId = "Human.PushObject"
    })
  }
}

return push_object_tip
