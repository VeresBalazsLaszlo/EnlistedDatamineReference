import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "dasevents" import EventEntityDied
from "dm" import get_shell_template_by_shell_id, DM_EXPLOSION
from "%ui/ui_library.nut" import *

let showTip = Watched(false)

const TIP_SHOW_TIME = 5

let hideTip = @() showTip.set(false)

ecs.register_es(
  "show_bomb_tip_es",
  {
    [EventEntityDied] = function(evt, _eid, _comp) {
      let { shellId, damageType } = evt

      let shellTemplateName = get_shell_template_by_shell_id(shellId) ?? ""
      if (shellTemplateName == "")
        return

      let shellTemplate = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(shellTemplateName)
      let isBomb = shellTemplate?.getCompValNullable("projectile__isBomb") != null

      if (damageType != DM_EXPLOSION || !isBomb)
        return

      if (!showTip.get()) {
        showTip.set(true)
        gui_scene.resetTimeout(TIP_SHOW_TIME, hideTip)
      }
    }
  },
  {
    comps_rq = ["watchedByPlr"]
  }
)

let explTip = tipCmp({
  text = loc("hint/lieDownToSaveFromExplosion")
  style = {
    onAttach = @() gui_scene.resetTimeout(TIP_SHOW_TIME, hideTip)
    onDetach = hideTip
  }
})

let lie_down_to_save_from_expl_tip = @() {
  watch = showTip
  children = showTip.get() ? explTip : null
}

return lie_down_to_save_from_expl_tip