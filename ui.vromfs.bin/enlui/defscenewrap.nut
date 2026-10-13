from "%ui/style/designConst.nut" import sidePadding, maxContentWidth, hotkeysBarHeight
from "%ui/state/safeArea.nut" import safeAreaVerPadding, safeAreaHorPadding
from "%ui/ui_library.nut" import *

function defSceneWrap (content, params = {}) {
  let bottomPadding = safeAreaVerPadding.get() + hotkeysBarHeight
  let safeSidePadding = max(sidePadding, safeAreaHorPadding.get())
  
  return {
    size = FLEX
    maxWidth = maxContentWidth
    hplace = ALIGN_CENTER
    padding = [safeAreaVerPadding.get(), safeSidePadding, bottomPadding, safeSidePadding]
    children = content
    transform = true
    animations = [{ prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }]
  }.__update(params)
}

return defSceneWrap
