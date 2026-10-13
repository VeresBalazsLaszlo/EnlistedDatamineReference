import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed, mkEcsComputedEidMap
from "math" import ceil
from "dm" import DM_EFFECT_FIRE, DM_EFFECT_EXPL
from "dasevents" import EventOnVehicleDamaged, EventOnVehicleDamageEffects
from "%ui/ui_library.nut" import *

let victimState = mkWatched(persist, "victimVehicleHp", {
  vehicle = ecs.INVALID_ENTITY_ID
  vehicleIconName = null
  damage = 0.0
  hp = 0.0
  maxHp = 0.0
  show = false
  effects = 0
})

let defHeroState = {
  vehicle = ecs.INVALID_ENTITY_ID
  hp = 0.0
  maxHp = 0.0
  isBurn = false
}

ecs.register_es("ui_vehicle_hp_es", {
  [EventOnVehicleDamaged] = function(evt, _eid, _comp) {
    let state = victimState.get()

    let vehicle = evt.vehicle
    let damage = evt.damage
    let hp = evt.hp
    let maxHp = evt.maxHp

    let totalDamage = damage + (vehicle == state.vehicle && state.show ? state.damage : 0)
    let data = {
      show = true
      vehicle = vehicle
      damage = totalDamage
      hp = hp
      maxHp = maxHp
      vehicleIconName = null
    }
    if (vehicle != state.vehicle || !state.show)
      data.__update({effects = 0})

    victimState.mutate(@(v) v.__update(data))
  },
  [EventOnVehicleDamageEffects] = function(evt, _eid, _comp) {
    let vehicle = evt.vehicle
    let effects = evt.effects
    let data = {
      show = true
      vehicle = vehicle
      effects = effects
      vehicleIconName = null
    }

    let state = victimState.get()

    if (vehicle != state.vehicle || !state.show)
      data.__update({hp = 0, maxHp = 0, damage = 0})

    victimState.mutate(@(v) v.__update(data))
  }
},
{comps_rq=["hero"]})



let heroVehicleRow = mkEcsComputedEidMap({
  comps = [
    ["vehicle__hp", ecs.TYPE_FLOAT],
    ["vehicle__maxHp", ecs.TYPE_FLOAT],
    ["fire_damage__isBurn", ecs.TYPE_BOOL],
  ]
  comps_rq = ["heroVehicle"]
})



let heroInVehicle = mkEcsComputed({
  comps = [["isInVehicle", ecs.TYPE_BOOL, false]]
  comps_rq = ["hero"]
  defVal = false
})

let heroState = Computed(function() {
  let rows = heroVehicleRow.get()
  let eid = heroInVehicle.get() ? rows.findindex(@(_) true) : null
  if (eid == null)
    return defHeroState
  let row = rows[eid]
  return {
    vehicle = eid
    hp = ceil(row.vehicle__hp).tointeger()
    maxHp = ceil(row.vehicle__maxHp).tointeger()
    isBurn = row.fire_damage__isBurn
  }
})

console_register_command(@() victimState.mutate(@(v) v.show = true), "vehicle_hp.repeat_last_hit")

console_register_command(
@()
  victimState.mutate(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 300.0
    v.damage = 150.0
    v.maxHp = 450.0
  }),
"vehicle_hp.debug_hit")

console_register_command(
@()
  victimState.mutate(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 300.0
    v.damage = 150.0
    v.maxHp = 450.0
    v.effects = (1 << DM_EFFECT_FIRE)
  }),
"vehicle_hp.debug_fire")

console_register_command(
@()
  victimState.mutate(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 0.0
    v.damage = 450.0
    v.maxHp = 450.0
    v.effects = 0
  }),
"vehicle_hp.debug_destroy")

console_register_command(
@()
  victimState.mutate(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 0.0
    v.damage = 450.0
    v.maxHp = 450.0
    v.effects = (1 << DM_EFFECT_FIRE)
  }),
"vehicle_hp.debug_destroy_fire")

console_register_command(
@()
  victimState.mutate(function(v) {
    v.show = true
    v.vehicleIconName = "t_26_1940_char"
    v.hp = 0.0
    v.damage = 450.0
    v.maxHp = 450.0
    v.effects = (1 << DM_EFFECT_EXPL)
  }),
"vehicle_hp.debug_destroy_expl")

return { victim = victimState, hero = heroState }