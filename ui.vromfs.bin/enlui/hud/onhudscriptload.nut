from "%ui/ui_library.nut" import *

require("%ui/hud/game_console.nut")
require("%ui/hud/state/assists_es.nut")
require("%ui/hud/state/rumble_es.nut")
require("%ui/hud/state/gyro_only_in_aim_or_zoom.nut")
require("%ui/hud/spectator_console.nut")
require("%ui/hud/state/aiming_smooth.nut")
require("%ui/hud/state/cmd_hero_log_event.nut")
require("%ui/hud/state/battle_area_warnings.nut")
require("%ui/hud/state/team_score_warnings.nut")

require("%ui/hud/state/autoShowBriefing.nut")

require("%ui/hud/state/respawnPrioritySelector.nut")
require("%ui/hud/state/armyData.nut")
require("%ui/hud/state/hints.nut")
require("%ui/hud/state/goal.nut")
require("%ui/hud/state/kill_log_es.nut")
require("%ui/hud/state/gun_blocked_es.nut")

require("%ui/hud/huds/capzone_locked_player_event.nut")
require("%ui/hud/state/afk_warnings.nut")
require("%ui/hud/init_tips.nut")
require("%ui/hud/state/vehicle_hp.nut")
require("%ui/hud/state/plane_hud_state.nut")
require("%ui/hud/commands_menu_setup.nut")
require("%ui/hud/building_tool_menu_setup.nut")
require("%ui/hud/wallposter_menu_setup.nut")
require("%ui/hud/state/dominationModeEvents.nut")
require("%ui/hud/state/serviceNotificationToChat.nut")

require("%ui/hud/hud_menus.nut")

let hitMarksState = require("%ui/hud/state/hit_marks_es.nut")
hitMarksState.worldKillMarkColor.set(Color(220,220,220,150))
hitMarksState.hitSize.set([fsh(2), fsh(2)])
hitMarksState.killSize.set([fsh(2), fsh(2)])
hitMarksState.worldDownedMarkColor.set(0)
hitMarksState.worldKillTtl.set(2.5)

