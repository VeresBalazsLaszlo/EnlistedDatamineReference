import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/hud/state/hero_weapons.nut" import curWeaponWeapType
from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let tipCountData = mkOnlineSaveData("ui/hud/lie_down_to_shoot", @() 0)
let shownTipCount = tipCountData.watch
let showTip = Watched(false)
let hasShownCurGame = mkWatched(persist, "hasShownCurGame", false)

const TIP_SHOW_TIME = 5
const TIP_SHOW_COUNT = 5

let entityStopedShooting = mkEcsComputed({
  comps = [["human_weap__lastShotAtTime", ecs.TYPE_FLOAT]]
  comps_rq = ["watchedByPlr"]
  defVal = 0
})

let entityIsCrawling = mkEcsComputed({
  comps = [["human_net_phys__isCrawl", ecs.TYPE_BOOL]]
  comps_rq = ["watchedByPlr"]
  defVal = false
})

let needShowTip = Computed(@() curWeaponWeapType.get() == "submachine_gun"
                                && !entityIsCrawling.get() && shownTipCount.get() < TIP_SHOW_COUNT
                                && !hasShownCurGame.get()
                                && !inVehicle.get())

function makeShowTipTrue() {
  if (!needShowTip.get())
    return
  showTip.set(true)
  tipCountData.setValue(shownTipCount.get() + 1)
  gui_scene.resetTimeout(TIP_SHOW_TIME, @() hasShownCurGame.set(true))
}

needShowTip.subscribe(function(tip) {
  if (tip){
    entityStopedShooting.subscribe(function(shootingTime) {
      if (shootingTime >= 10){
        gui_scene.resetTimeout(0.5 , makeShowTipTrue)
      }
    })
  }
  showTip.set(false)
})

let hideTip = @() showTip.set(false)

let machineGunTip = tipCmp({
  text = loc("hint/lieDownToShootAccurately")
  inputId = "Human.Crawl"
  style = {
    onAttach = @() gui_scene.resetTimeout(TIP_SHOW_TIME, hideTip)
    onDetach = @() hasShownCurGame.set(true)
  }
})

let lie_down_to_shoot_accurately_tip = @() {
  watch = showTip
  children = showTip.get() ? machineGunTip : null
}

return lie_down_to_shoot_accurately_tip