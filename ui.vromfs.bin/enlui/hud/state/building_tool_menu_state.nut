from "%ui/hud/tutorial/state/tutorial_state.nut" import isTutorial
from "%ui/ui_library.nut" import *
from "types" import Array

let buildingToolMenuItems = mkWatched(persist, "items", [])
let radius = Computed(@() isTutorial.get() ? hdpx(320) : hdpx(365))
let elemSize = Computed(@() array(2, (radius.get() * 0.3).tointeger()))

let showBuildingToolMenu = mkWatched(persist, "showBuildingToolMenu", false)
let openPath = mkWatched(persist, "openPath", [])
let path = mkWatched(persist, "path", [])

let mkNextPathItem = @(item) item.__merge({
  text = loc(item?.id ?? "")
  closeOnClick = false
  action = @() path.mutate(@(p) p.append(item?.id ?? ""))
  available = Watched(true)
})

let curBuildingToolMenuItems = Computed(function() {
  local list = buildingToolMenuItems.get()
  foreach (id in path.get()) {
    list = list.findvalue(@(p) p?.id == id)?.items
    if (!(list instanceof Array))
      return [] 
  }
  return list.map(@(item) item?.items instanceof Array ? mkNextPathItem(item) : item)
})

openPath.subscribe(@(v) path.set(clone v))
showBuildingToolMenu.subscribe(@(v) v ? null : openPath.set([]))

return {
  buildingToolMenuItems
  radius
  elemSize
  showBuildingToolMenu
  curBuildingToolMenuItems
}
