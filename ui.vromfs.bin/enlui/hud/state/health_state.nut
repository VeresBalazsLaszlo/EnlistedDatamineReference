import "%dngscripts/ecs.nut" as ecs
from "%ui/ec_to_watched.nut" import mkFrameIncrementObservable
from "dasevents" import EventGameSessionFinished, EventSessionFinished
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *


const defState = {
  hp = null
  maxHp = 0
  scaleHp = 0
  isAliveState = false
  isDownedState = false
}

let {state, stateSetValue} = mkFrameIncrementObservable(defState,"state")

let hp = Computed(@() state.get().hp)
let maxHp = Computed(@() state.get().maxHp)
let scaleHp = Computed(@() state.get().scaleHp)
let isAliveState = Computed(@() state.get().isAliveState)
let isDownedState = Computed(@() state.get().isDownedState)


local currentWatchedEid = ecs.INVALID_ENTITY_ID

ecs.register_es("health_state_ui_es", {
  [["onChange", "onInit"]] = function trackComponentsHero(eid,comp) {
    currentWatchedEid = eid
    let isAlive = comp["isAlive"]
    let isDowned = comp["isDowned"]
    stateSetValue({
      hp = isAlive ? comp["hitpoints__hp"] : null
      maxHp = !isDowned ? comp["hitpoints__maxHp"] : -comp["hitpoints__deathHpThreshold"]
      scaleHp = comp["hitpoints__scaleHp"]
      isAliveState = isAlive
      isDownedState = isDowned
    })
  }
  onDestroy = function(eid, _comp) {
    if (eid == currentWatchedEid)
      stateSetValue(defState)
  },
  [[EventGameSessionFinished, EventSessionFinished]] = function(_eid, _comp) { 
    stateSetValue(defState)
  }
},
{
  comps_track = [
    ["hitpoints__hp", ecs.TYPE_FLOAT],
    ["hitpoints__maxHp", ecs.TYPE_FLOAT],
    ["hitpoints__scaleHp", ecs.TYPE_FLOAT],
    ["hitpoints__deathHpThreshold", ecs.TYPE_FLOAT, 0.0],
    ["isAlive", ecs.TYPE_BOOL, true],
    ["isDowned", ecs.TYPE_BOOL, false],
  ]
  comps_rq=["watchedByPlr"]
})


let needDisplayHealTip = mkEcsComputed({
  comps = [["human_medkit__needDisplayHealTip", ecs.TYPE_BOOL]]
  comps_rq = ["watchedByPlr"]
  defVal = false
})



let ressurectState = mkEcsComputed({
  comps = [
    ["human_medkit__needDisplayRessurectTip", ecs.TYPE_BOOL],
    ["total_kits__selfRessurrect", ecs.TYPE_INT]
  ]
  comps_rq = ["watchedByPlr"]
})

let needDisplayRessurrectTip = Computed(@() ressurectState.get()?.human_medkit__needDisplayRessurectTip ?? false)
let ressurrectItemCount = Computed(@() ressurectState.get()?.total_kits__selfRessurrect ?? 0)



return {
  isAlive = isAliveState
  isDowned = isDownedState
  hp
  maxHp
  scaleHp
  needDisplayHealTip
  needDisplayRessurrectTip
  ressurrectItemCount
}
