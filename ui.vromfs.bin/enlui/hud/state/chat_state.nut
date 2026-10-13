import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "dagor.system" import DBGLEVEL
from "%ui/ui_library.nut" import *


let switchSendModesAllowed = mkEcsComputed({
  comps = [["game_option__allowSwitchChatMode", ecs.TYPE_BOOL]]
  defVal = DBGLEVEL > 0
})

return {
  switchSendModesAllowed
}