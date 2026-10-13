import "%dngscripts/ecs.nut" as ecs
from "dainput2" import get_action_handle, set_analog_stick_action_smooth_value
from "gameevents" import EventHeroChanged
from "%ui/hud/state/controls_online_storage.nut" import aim_smooth
from "%ui/ui_library.nut" import *

ecs.register_es("aim_smooth_apply_es",
  {
    [EventHeroChanged] = function onHeroChanged() {
      let act = get_action_handle("Human.Aim", 0xFFFF)
      if (act != 0xFFFF)
        set_analog_stick_action_smooth_value(act, aim_smooth.get())
    }
  },
  {},
  {tags="gameClient"}
)
