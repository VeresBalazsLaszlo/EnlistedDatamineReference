from "%ui/hud/state/hudGameModes.nut" import forcedMinimalHud
from "%ui/hud/state/total_medkits.nut" import selfHealMedkits
from "%ui/hud/state/health_state.nut" import needDisplayHealTip, needDisplayRessurrectTip, ressurrectItemCount
from "dagor.time" import get_time_msec
from "%ui/hud/state/ui_time.nut" import curTimePerSec as uiTime
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/vehicle_state.nut" import inGroundVehicle
from "%ui/ui_library.nut" import *

const color0 = Color(200,40,40,110)
const color1 = Color(200,200,40,180)
const stopAnimateAfter = 15
const hideAfter = 25

let showedMedTipAtTime = mkWatched(persist, "showedMedTipAtTime", 0)

needDisplayHealTip.subscribe(function(need) {
  if (need)
    showedMedTipAtTime.set((get_time_msec()/1000).tointeger())
  else
    showedMedTipAtTime.set(0)
})

let trigger = {}
function mkTip(text, inputId) {
  return tipCmp({
    inputId
    text
    sound = {
      attach = {name="ui/need_reload", vol=0.1}
    }
    transform = {pivot=[0,0.5]}
    animations = [{ prop=AnimProp.translate, from=[sw(50),0], to=[0,0], duration=0.5, play=true, easing=InBack}]
    textAnims = [
      { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull, trigger = trigger}
      { prop=AnimProp.scale, from=[1,1], to=[1.0, 1.1], duration=3.0, play=true, loop=true, easing=CosineFull, trigger = trigger}
    ]
  })
}

let medkitTip = mkTip(loc("tips/need_medkit"), "Inventory.UseMedkit")
let medkitTipInVehicle = mkTip(loc("tips/need_medkit"), "Vehicle.UseMedkit")
let revivePerkTip = mkTip(loc("tips/need_revive_perk"), "Inventory.UseMedkit")

let ressurrectPerkText = Computed(@() loc("tips/need_resurrect_perk_count", { count = ressurrectItemCount.get() }))
let ressurrectPerkTip = mkTip(ressurrectPerkText, "Inventory.UseMedkit")

let showMedkitTip = Computed(@() showedMedTipAtTime.get() > uiTime.get() - hideAfter)

function htip(){
  return {
    size = SIZE_TO_CONTENT
    watch = [showMedkitTip, needDisplayHealTip, forcedMinimalHud, inGroundVehicle]
    children = !showMedkitTip ? null
      : (!needDisplayHealTip.get() ? revivePerkTip
      : forcedMinimalHud.get() ? null
      : inGroundVehicle.get() ? medkitTipInVehicle
      : medkitTip)
  }
}


local oldTotal = 0
selfHealMedkits.subscribe(function(v){
  if (v > oldTotal)
    anim_start(trigger)
  oldTotal = v
})
uiTime.subscribe(function(time){
  if (!needDisplayHealTip.get())
    return
  if (showedMedTipAtTime.get() + stopAnimateAfter < time)
    anim_skip(trigger)
  else
    anim_start(trigger)
})

return function() {
  return {
    watch = [needDisplayHealTip, needDisplayRessurrectTip]
    size = SIZE_TO_CONTENT
    children = needDisplayRessurrectTip.get() ? ressurrectPerkTip : (!needDisplayHealTip.get() ? null : htip)
  }
}
