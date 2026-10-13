import "dainput2" as dainput
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/vehicle_state.nut" import inGroundVehicle, controlledVehicleEid
from "%ui/hud/state/vehicle_steer_tips.nut" import steerTipDuration, vehicleSteerTips
from "%ui/control/formatInputBinding.nut" import textListFromAction, keysImagesMap
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/ui_library.nut" import *

let showTip = Watched(true)
let animations =[{ prop=AnimProp.opacity, from=1, to=0, duration=0.5, playFadeOut = true, easing=InOutCubic}]
let defWatches = [inGroundVehicle, showTip]
let fullWatches = [keysImagesMap, vehicleSteerTips, steerTipDuration].extend(defWatches)

inGroundVehicle.subscribe(@(v) showTip.set(v))
let hideTipCb = @() showTip.set(false)
function hideTip() {
  let duration = steerTipDuration.get()
  if (duration > 0)
    gui_scene.resetTimeout(duration, hideTipCb)
}
steerTipDuration.subscribe(function(duration) {
  if (duration < 0)
    gui_scene.clearTimer(hideTipCb)
  else
    gui_scene.resetTimeout(duration, hideTipCb)
})
showTip.subscribe(function(v) {if (v) hideTip()})
hideTip()
controlledVehicleEid.subscribe(@(_) showTip.set(true))

function prepareTipCmp(key,imageMap) {
  if (isGamepad.get()) {
    let hasImage = textListFromAction(key, 1).findvalue(@(e) e in imageMap) != null
    if (!hasImage)
      return null
  }

  return tipCmp({
    inputId = key
    text = loc($"controls/{key}")
    style = { rendObj = null }.__update(fontSub)
    animations
  })
}

return function() {
  if (!inGroundVehicle.get() || !showTip.get())
    return { watch = defWatches }

  let children = vehicleSteerTips.get()
    .filter(@(key) dainput.is_action_binding_set(dainput.get_action_handle(key, 0xFFFF), isGamepad.get() ? 1 : 0))
    .map(@(key) prepareTipCmp(key, keysImagesMap.get()))
  return {
    watch = fullWatches
    rendObj = ROBJ_WORLD_BLUR
    flow = FLOW_VERTICAL
    gap = hdpx(3)
    children
  }
}
