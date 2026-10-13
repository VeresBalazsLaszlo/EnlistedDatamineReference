import "%dngscripts/ecs.nut" as ecs
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/huds/crosshair_state_es.nut" import isAiming
from "%ui/hud/state/vehicle_state.nut" import inPlane, isDriver, isGunner
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/hero_weapons.nut" import currentGunEid
from "%ui/ui_library.nut" import *

let entityAimRangePreset = Watched(0)
let aimRangeValues = Watched([])

const inactiveColor = Color(50,50,50,25)
const activeColor = Color(200,200,200,110)

let tipIncreaseAim = tipCmp({
  inputId = "Human.SightNext"
  text = loc("tips/increase_aim_range")
})

let tipDecreaseAim = tipCmp({
  inputId = "Human.SightPrev"
  text = loc("tips/decrease_aim_range")
})

ecs.register_es("aim_range_preset",{
  [["onChange"]] = function(eid,comp){
    if (eid == currentGunEid.get())
      entityAimRangePreset.set(comp["weap__current_sight_preset"])
  }
}, {comps_track=[["weap__current_sight_preset", ecs.TYPE_INT]]})

let aimRangePresetQuery = ecs.SqQuery("get_aim_range_preset",
  { comps_ro = [["weap__current_sight_preset", ecs.TYPE_INT]] })

let aimRangePresetsQuery = ecs.SqQuery("get_aim_range_presets",
  { comps_ro = [["sightPresets", ecs.TYPE_ARRAY]] })

currentGunEid.subscribe(function(eid) {
  local preset = 0
  aimRangePresetQuery.perform(eid, @(_, comp) preset = comp["weap__current_sight_preset"])
  aimRangeValues.set(aimRangePresetsQuery(currentGunEid.get(), @(_, comp) comp.sightPresets.getAll()))
  entityAimRangePreset.set(preset)
})

let canShowTip = Computed(@() isAiming.get() && !inPlane.get()
                                  && !isDriver.get() && !isGunner.get())

let needTip = Computed(@() canShowTip.get() && aimRangeValues.get() != null)

function swithAimBtnTip (){
  return {
    watch = needTip
    size = SIZE_TO_CONTENT
    flow = FLOW_VERTICAL
    children = needTip.get() ? [tipIncreaseAim, tipDecreaseAim] : null
  }
}

function aimRangeValuesTip(){
  let watch = [needTip, entityAimRangePreset, currentGunEid]
  if (!needTip.get())
    return { watch }

  return {
    watch
    flow = FLOW_VERTICAL
    animations = [{prop = AnimProp.opacity, from = 0, to = 0,
                  duration = 0.1, play = true}]
    children = (aimRangeValues.get() ?? []).map(@(item, idx)
      tipCmp({
        text = loc(item.loc)
        style = entityAimRangePreset.get() == idx
          ? { color = activeColor }
          : { color = inactiveColor }.__update(fontSub)
      })
    )
  }
}

return {
  swithAimBtnTip
  aimRangeValuesTip
}
