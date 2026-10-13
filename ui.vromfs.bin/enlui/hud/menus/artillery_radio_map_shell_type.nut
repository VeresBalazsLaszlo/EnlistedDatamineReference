from "%ui/hud/state/artillery.nut" import artilleryAvailableShellTypes
from "%ui/hud/menus/mapComps.nut" import hintTextFunc
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR
from "%ui/ui_library.nut" import *

const tipChangeShell = "map/artilleryChangeShell"

let currentShellTypeIndex = Watched(0)
let currentShellType = Computed(@() artilleryAvailableShellTypes.get()?[currentShellTypeIndex.get()])

artilleryAvailableShellTypes.subscribe(function(shellTypes) {
  if (currentShellTypeIndex.get() >= shellTypes.len())
    currentShellTypeIndex.set(0)
})

const artilleryChangeShellInputId = "Artillery.ChangeShell"
function changeShell() {
  let typesCount = artilleryAvailableShellTypes.get().len()
  if (typesCount > 1)
    currentShellTypeIndex.set((currentShellTypeIndex.get()+1) % typesCount)
}

let changeShellTips = @() (artilleryAvailableShellTypes.get().len() > 1)
  ? {
      flow = FLOW_HORIZONTAL
      gap = hdpx(10)
      watch = [artilleryAvailableShellTypes, currentShellType]
      children = [
        hintTextFunc(loc($"map/{currentShellType.get()?.name}"), DEFAULT_TEXT_COLOR)
        tipCmp({
          inputId = artilleryChangeShellInputId
          text = loc(tipChangeShell)
        })
      ]
      hotkeys = [[$"^@{artilleryChangeShellInputId}", {action = changeShell}]]
    }
  : { watch = [artilleryAvailableShellTypes] }

return {
  currentShellType
  currentShellTypeIndex
  changeShellTips
}
