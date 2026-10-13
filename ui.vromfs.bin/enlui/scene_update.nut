from "%ui/ui_library.nut" import *

let frameUpdateCounter = Watched(0)

gui_scene.setUpdateHandler(function sceneUpdateHandler(_dt) {
  frameUpdateCounter.modify(@(v) v + 1)
})

return {
  frameUpdateCounter
}