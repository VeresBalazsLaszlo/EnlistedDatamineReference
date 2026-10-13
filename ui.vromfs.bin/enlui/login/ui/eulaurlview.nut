import "%ui/components/urlText.nut" as urlText
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/eula/eulaWnd.nut" import showEula
from "%ui/state/safeArea.nut" import safeAreaVerPadding, safeAreaHorPadding
from "%ui/ui_library.nut" import *

let eulaUrlView = {
  zOrder = 1
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  margin = fsh(0.5)
  children = urlText(loc("eula/urlViewText"), null, {
    onClick = @() showEula()
    skipDirPadNav = true
  }.__update(fontSub))
}

let bottomEulaUrl = @(){
  watch = [safeAreaVerPadding]
  size = FLEX
  halign = ALIGN_LEFT
  valign = ALIGN_BOTTOM
  children = eulaUrlView
  padding = [safeAreaVerPadding.get()+fsh(5), safeAreaHorPadding.get()+sw(4)]
}

return {
  bottomEulaUrl
}
