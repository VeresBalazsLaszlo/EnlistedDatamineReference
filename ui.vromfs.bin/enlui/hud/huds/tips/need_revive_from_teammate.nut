import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let reviveFromTeammateTip = tipCmp({
  text = loc("tips/need_revive_from_teammate")
  style = { color = Color(200,40,40,110) }
  transform = {pivot=[0,0.5]}
})

let heroReviveState = mkEcsComputed({
  comps = [
    ["isDowned", ecs.TYPE_BOOL],
    ["human_inventory__canSelfRevive", ecs.TYPE_BOOL, true],
  ]
  comps_rq = ["watchedByPlr"]
})

let needDisplayReviveFromTeamTip = Computed(function() {
  let hero = heroReviveState.get()
  return hero != null && hero.isDowned && !hero.human_inventory__canSelfRevive
})

return @() {
  watch = [needDisplayReviveFromTeamTip]
  children = needDisplayReviveFromTeamTip.get() ? reviveFromTeammateTip : null
}
