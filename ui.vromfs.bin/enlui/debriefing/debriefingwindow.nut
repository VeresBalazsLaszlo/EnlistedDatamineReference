import "%ui/debriefing/debriefingCtor.nut" as ctor
from "%ui/navState.nut" import addScene, removeScene
from "%ui/debriefing/debriefingDbgState.nut" import dbgShow
from "%ui/state/appState.nut" import isInBattleState, isInMainMenuState
from "%ui/debriefing/debriefingState.nut" import debriefingShow
from "%ui/debriefing/debriefingDataState.nut" import dataToShow
from "%ui/ui_library.nut" import *

let needShow = keepref(Computed(@() isInMainMenuState.get()
  && (dataToShow.get()?.len() ?? 0) > 0
  && (dbgShow.get() || debriefingShow.get())))

isInBattleState.subscribe(function(active) {
  if (active)
    dbgShow.set(false)
})

let debriefingWnd = @() {
  key = "enlist_debriefing_root"
  watch = dataToShow
  size = FLEX
  children = ctor(dataToShow.get(), function() {
    if (dbgShow.get())
      dbgShow.set(false)
    else
      debriefingShow.set(false)
  })
}

needShow.subscribe(
  function(val) {
    if (val)
      addScene(debriefingWnd)
    else
      removeScene(debriefingWnd)
  }
)



if (needShow.get())
  addScene(debriefingWnd)
