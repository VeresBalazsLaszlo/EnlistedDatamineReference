from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/hud/state/team_scores.nut" import anyTeamFailTimer
from "%ui/helpers/time.nut" import secondsToStringLoc
from "%ui/style/designConst.nut" import accentColor, mkTimerIcon, midPadding
from "%ui/hud/state/capZones.nut" import capZones
from "%ui/ui_library.nut" import *

const timerSize = hdpxi(24)
let hasFailTimer = Computed(@() capZones.get().findindex(@(zone) zone?.failTimer) != null)

return function() {
  let watch = [hasFailTimer, anyTeamFailTimer]
  if (!hasFailTimer.get() || anyTeamFailTimer.get() <= 0)
    return { watch }

  return {
    watch
    flow = FLOW_HORIZONTAL
    gap = midPadding
    valign = ALIGN_CENTER
    children = [
      mkTimerIcon(timerSize, { color = accentColor })
      {
        rendObj = ROBJ_TEXT
        text = secondsToStringLoc(anyTeamFailTimer.get())
        color = accentColor
      }.__update(fontBody)
    ]
  }
}
