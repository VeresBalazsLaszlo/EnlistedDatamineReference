from "%ui/style/cursors.nut" import setTooltip
from "%ui/hud/state/interactive_state.nut" import hudIsInteractive
from "%ui/matchingClient.nut" import serverResponseError
from "%ui/ui_library.nut" import *

const picSz = hdpxi(54)

let isSavingData = Watched(false)

function pic(name) {
  return Picture("ui/skin#info/{0}.svg:{1}:{1}".subst(name, picSz))
}

let mkIcon = @(iconName, tipText, isVisibleWatch, color) @() {
    watch = [isVisibleWatch, hudIsInteractive]
    key = iconName
    children =  isVisibleWatch.get()
                ? {
                    flow = FLOW_HORIZONTAL
                    rendObj = ROBJ_SOLID
                    color = Color(0,0,0,200)
                    size = const [picSz * 5, picSz * 1.5]
                    halign = ALIGN_RIGHT
                    valign = ALIGN_CENTER
                    margin = hdpx(5)
                    children = [
                    {
                      text = loc(tipText, "")
                      rendObj = ROBJ_TEXTAREA
                      behavior = Behaviors.TextArea
                      color = color
                      size = const [picSz * 3.2, picSz]
                      halign = ALIGN_CENTER
                      valign = ALIGN_CENTER
                    }
                    {
                      behavior = hudIsInteractive.get() ? Behaviors.Button : null
                      onHover = @(on) setTooltip(on ? loc(tipText, "") : null)
                      image = pic(iconName)
                      rendObj = ROBJ_IMAGE
                      color = color
                      margin = hdpx(15)
                      animations = [{ prop = AnimProp.opacity, from = 0.5, to = 1.0,
                        duration = 1, play = true, loop = true, easing = Blink}]
                    }]
                  }
                : null
}

let noServerStatus = mkIcon("no_connection_error", "connectingToServer", serverResponseError, Color(200, 50, 0, 160))
let saveDataStatus = mkIcon("data_saving", "hud/saving_data", isSavingData, Color(255, 200, 15, 160))

return {
  
  noServerStatus
  saveDataStatus
}
