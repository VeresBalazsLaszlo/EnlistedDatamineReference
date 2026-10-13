import "%dngscripts/ecs.nut" as ecs
from "dasevents" import EventOnEntityHit
from "%ui/hud/state/watched_hero.nut" import watchedHeroEid
from "%ui/ui_library.nut" import *

let hitAnimTrigger = persist("hitAnimTrigger", @() {})

ecs.register_es("hit_trigger_ui_es", {
  [EventOnEntityHit] = function onEntityHit(evt, _eid, _comp) {
      let victim_eid = evt.victim
      if (victim_eid == watchedHeroEid.get()) {
        anim_start(hitAnimTrigger)
      }
  },
})

return {hitAnimTrigger}