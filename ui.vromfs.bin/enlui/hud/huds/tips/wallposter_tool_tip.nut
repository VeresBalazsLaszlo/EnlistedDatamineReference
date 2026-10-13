from "%ui/hud/state/wallposter.nut" import wallPosterPreview
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

function wallposterTips() {
  let watch = wallPosterPreview
  if (!wallPosterPreview.get())
    return { watch }

  return {
    watch
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    children = [
      tipCmp({
        text = loc("wallposter/place")
        inputId = "Wallposter.Place"
      })
      tipCmp({
        text = loc("wallposter/cancel")
        inputId = "Wallposter.Cancel"
      })
      {
        behavior = DngBhv.ActivateActionSet
        actionSet = "Wallposter"
      }
    ]
  }
}

return [
  wallposterTips
]
