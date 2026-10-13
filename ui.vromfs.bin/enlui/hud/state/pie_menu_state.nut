from "%ui/ui_library.nut" import *



const DEFAULT_LAYER = 1
let pieMenuAllLayersItems = mkWatched(persist, "items", [])
let pieMenuLayer = Watched(DEFAULT_LAYER)
let showPieMenu = mkWatched(persist, "showPieMenu", false)
const radius = hdpx(390)

let curPieMenuItems = Computed(@() pieMenuAllLayersItems.get()?[pieMenuLayer.get()] ?? [])


showPieMenu.subscribe(@(_val) pieMenuLayer.set(DEFAULT_LAYER))

return {
  pieMenuItems = pieMenuAllLayersItems
  pieMenuLayer
  curPieMenuItems
  radius = Watched(radius)
  elemSize = Watched([(radius*0.35).tointeger(),(radius*0.35).tointeger()])
  showPieMenu
}
