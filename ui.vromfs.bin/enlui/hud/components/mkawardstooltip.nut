import "%ui/style/tooltipCtor.nut" as tooltipCtor
import "%ui/components/battleHeroAwardIcon.nut" as mkBattleHeroAwardIcon
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/components/text.nut" import dtext
from "%ui/ui_library.nut" import *

let mkAwardsTooltip = @(awards, iconSize) tooltipCtor({
  flow = FLOW_VERTICAL
  children = awards.map(@(award) {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    children = [
      mkBattleHeroAwardIcon(award?.icon ?? award, iconSize)
      dtext(loc(award?.text ?? $"debriefing/award_{award}"), {padding = const [0, hdpx(10)]}.__update(fontBody))
    ]
  })
})

return mkAwardsTooltip