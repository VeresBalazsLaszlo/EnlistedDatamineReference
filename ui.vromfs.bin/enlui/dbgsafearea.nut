from "%ui/state/safeArea.nut" import showSafeArea, safeAreaAmount
from "%ui/ui_library.nut" import *

function dbgSafeArea(){
  return {
    size = [sw(100*safeAreaAmount.get()), sh(100*safeAreaAmount.get())]
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = showSafeArea.get() ? ROBJ_FRAME : null
    watch = [showSafeArea, safeAreaAmount]
    borderWidth = hdpx(1)
    color = Color(255,128,128)
  }
}

return { dbgSafeArea }