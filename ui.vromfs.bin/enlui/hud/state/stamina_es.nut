import "%dngscripts/ecs.nut" as ecs
from "%sqstd/frp.nut" import watchedTable2TableOfWatched
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

const defValue = {
  stamina = null
  scaleStamina = 0
  staminaCanAim = true
  staminaUseFlask = false
  lowStamina = false
}

let heroStamina = mkEcsComputed({
  comps = [
    ["view_stamina", ecs.TYPE_INT],
    ["view_lowStamina", ecs.TYPE_BOOL],
    ["entity_mods__staminaBoostMult", ecs.TYPE_FLOAT, 1.0],
    ["human_weap__staminaCanAim", ecs.TYPE_BOOL, true],
    ["ui__flaskUseTipMinStamina", ecs.TYPE_FLOAT],
  ]
  comps_rq = ["watchedByPlr"]
})


let state = Computed(function() {
  let hero = heroStamina.get()
  if (hero == null)
    return defValue
  return {
    stamina = hero.view_stamina
    staminaCanAim = hero.human_weap__staminaCanAim
    lowStamina = hero.view_lowStamina
    scaleStamina = hero.entity_mods__staminaBoostMult
    staminaUseFlask = hero.view_stamina < hero.ui__flaskUseTipMinStamina
  }
})
let { stamina, scaleStamina, staminaCanAim, staminaUseFlask, lowStamina } = watchedTable2TableOfWatched(state)

let staminaAnimTrigger = persist("staminaAnimTrigger", @() {})
lowStamina.subscribe(function(is_low) {
  if (is_low) {
    anim_start(staminaAnimTrigger)
  } else {
    anim_request_stop(staminaAnimTrigger)
  }
})

return {
  stamina, staminaAnimTrigger, scaleStamina, staminaCanAim, staminaUseFlask
}