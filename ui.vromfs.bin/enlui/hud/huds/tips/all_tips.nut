from "%ui/hud/state/tips.nut" import getTips, tipsGen
from "%ui/ui_library.nut" import *

let tipsBlock = {
  gap = fsh(1)
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}

return @() {
  watch = tipsGen
  size = FLEX
  children = (getTips() ?? []).map(@(tipGroup) tipsBlock.__merge(tipGroup))
}
