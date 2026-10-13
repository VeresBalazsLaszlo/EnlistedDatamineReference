import "%ui/hud/huds/player_info/health.ui.nut" as health
import "%ui/hud/huds/player_info/breath.ui.nut" as breath
import "%ui/hud/huds/player_info/stamina.ui.nut" as stamina
from "%ui/ui_library.nut" import *

return freeze({
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  halign = ALIGN_RIGHT
  gap = fsh(0.2)
  children = [
    health, stamina, breath
  ]
})
