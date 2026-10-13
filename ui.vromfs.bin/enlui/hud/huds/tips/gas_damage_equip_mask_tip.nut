import "%dngscripts/ecs.nut" as ecs
from "dasevents" import CmdShowGasDamageMaskTip
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/gas_mask.nut" import hasHeroGasMask
from "%ui/ui_library.nut" import *

let showTip = Watched(false)

const TIP_SHOW_TIME = 5

let hideTip = @() showTip.set(false)

ecs.register_es(
  "gas_damage_equip_mask_tip_es",
  {
    [CmdShowGasDamageMaskTip] = function(_evt, _eid, _comp) {
      if (!hasHeroGasMask.get())
        return
      showTip.set(true)
      gui_scene.resetTimeout(TIP_SHOW_TIME, hideTip)
    }
  },
  {
    comps_rq = ["hero"]
  }
)

let tip = tipCmp({
  inputId = "Human.UseBinocular"
  text = loc("tips/gas_damage_equip_mask")
  style = {
    onAttach = @() gui_scene.resetTimeout(TIP_SHOW_TIME, hideTip)
    onDetach = hideTip
  }
})

return @() {
  watch = [showTip, hasHeroGasMask]
  children = showTip.get() && hasHeroGasMask.get() ? tip : null
}
