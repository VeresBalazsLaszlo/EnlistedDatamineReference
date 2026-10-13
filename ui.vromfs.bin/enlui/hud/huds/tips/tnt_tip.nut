import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let tntTipState = mkEcsComputed({
  comps = [["human_weap__tntTipState", ecs.TYPE_INT]]
  comps_rq = ["hero"]
  defVal = 0
})

let switchTntBlockTip = tipCmp({
  inputId = "Human.SpecialItemSlot"
  text = loc("hud/switch_to_tnt_block")
  transform = {pivot=[0,0.5]}
})

let switchTntExploderTip = tipCmp({
  inputId = "Human.SpecialItemSlot"
  text = loc("hud/switch_to_tnt_exploder")
  transform = {pivot=[0,0.5]}
})

return function() {
  let watch = [tntTipState]
  if (tntTipState.get() <= 0)
    return { watch }

  return {
    watch
    children = tntTipState.get() == 1 ? switchTntBlockTip : switchTntExploderTip
  }
}
