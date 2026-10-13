from "%ui/components/wndManager.nut" import registerWnd, Wnd
from "%ui/components/wndPermissionFlags.nut" import canShowNewItems, autoClose
from "%ui/ui_library.nut" import *


let dropRoulette = Watched(null)
let needOpenRouletteWnd = registerWnd({
  dataWatch = Computed(@() dropRoulette.get() != null)
  showWatch = canShowNewItems
  closeWatch = autoClose
  name = Wnd.ROULETTE
  order = []
})

let closeRouletteWindow = @() dropRoulette.set(null)
autoClose.subscribe(function(v) {
  if (v) closeRouletteWindow()
})

return {
  needOpenRouletteWnd
  dropRoulette
  closeRouletteWindow
}
