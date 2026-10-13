from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/vehicle_state.nut" import inPlane, isDriver
from "%ui/components/controlHudHint.nut" import mkHasBinding
from "%ui/ui_library.nut" import *

let DRIVER_TIPS = ["Human.SeatNext", "Plane.Throttle", "Plane.Ailerons","Plane.Elevator", "plane.Rudder","Plane.EngineToggle", "Plane.ToggleGear"] 
let PASSENGER_TIPS = ["Human.SeatNext"]
let watches = {}
foreach (key in [].extend(DRIVER_TIPS).extend(PASSENGER_TIPS))
  watches[key] <- mkHasBinding(key)

let showTip = Watched(true)
let animations =[{ prop=AnimProp.opacity, from=1, to=0, duration=0.5, playFadeOut = true, easing=InOutCubic}]
let defWatches = [inPlane, isDriver]
let fullWatches = [showTip].extend(defWatches, watches.values())

const showTipFor = 15
inPlane.subscribe(@(v) showTip.set(v))
let hideTip = @() gui_scene.resetTimeout(showTipFor, @() showTip.set(false))
showTip.subscribe(function(v) {if (v) hideTip()})
hideTip()

return function() {
  if (!inPlane.get())
    return { watch = defWatches }

  let tips = isDriver.get() ? DRIVER_TIPS : PASSENGER_TIPS
  let children = showTip.get() ? tips.filter(@(key) watches[key].get()).map(@(key) tipCmp({
      inputId = key
      text = loc($"controls/{key}")
      style = {rendObj = null}.__update(fontSub)
      animations
    })) : null
  return {
    watch = fullWatches
    rendObj = ROBJ_WORLD_BLUR
    flow = FLOW_VERTICAL
    gap = hdpx(3)
    children = children
  }
}
