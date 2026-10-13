import "%dngscripts/platform.nut" as platform
import "%ui/hud/huds/session_id.ui.nut" as sessionId
from "dagor.system" import DBGLEVEL
from "%ui/fpsBar.nut" import fpsBar, latencyBar
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/hud/replay/replayState.nut" import canShowGameHudInReplay
from "%ui/ui_library.nut" import *

let showFps = mkWatched(persist, "showFps", false)

let showService = Computed(@() !(isReplay.get() && !canShowGameHudInReplay.get())
  && (platform.is_pc || DBGLEVEL>0 || showFps.get()))
function serviceInfo() {
  let children = showService.get() ? [fpsBar, latencyBar] : []
  if (platform.is_pc || platform.is_gdk)
    children.append(sessionId)
  return {
    watch = showService
    flow = FLOW_HORIZONTAL
    gap = hdpx(5)
    vplace = DBGLEVEL > 0 ? ALIGN_TOP : ALIGN_BOTTOM
    padding = const [hdpx(2), hdpx(10)]
    children
  }
}
return {serviceInfo, showFps}