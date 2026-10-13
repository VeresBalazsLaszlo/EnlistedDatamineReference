from "%ui/state/appState.nut" import isInMainMenuState, isInBattleState
from "%ui/mainMenu/sectionsState.nut" import isMainMenuVisible
from "%ui/components/modalWindows.nut" import hasModalWindows
from "%ui/components/msgbox.nut" import hasMsgBoxes
from "%ui/ui_library.nut" import *

return {
  canShowRewards = isMainMenuVisible
  canShowNewItems = Computed(@() isInMainMenuState.get() && !hasModalWindows.get())
  canShowWindows = Computed(@() isMainMenuVisible.get() && !hasModalWindows.get() && !hasMsgBoxes.get())

  autoClose = isInBattleState
}
