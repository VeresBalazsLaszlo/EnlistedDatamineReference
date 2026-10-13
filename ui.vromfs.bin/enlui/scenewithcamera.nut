from "%ui/mainMenu/sectionsState.nut" import curSectionDetails
from "%ui/navState.nut" import addScene, removeScene
from "%ui/ui_library.nut" import *

const DEFAULT_CAMERA = "soldiers"

let cameras = Watched([])
let sceneToCamera = {}
let curCamera = Computed(@() (cameras.get().len() > 0 ? cameras.get().top() : null)
  ?? curSectionDetails.get()?.camera
  ?? DEFAULT_CAMERA)

function sceneWithCameraAdd(content, camera) {
  addScene(content)
  let idx = cameras.get().indexof(sceneToCamera?[content])
  sceneToCamera[content] <- camera
  cameras.mutate(function(v) {
    if (idx != null)
      v.remove(idx)
    v.append(camera)
  })
}

function sceneWithCameraRemove(content) {
  removeScene(content)
  let idx = cameras.get().indexof(sceneToCamera?[content])
  if (idx != null) {
    sceneToCamera.$rawdelete(content)
    cameras.mutate(@(v) v.remove(idx))
  }
}

return {
  curCamera
  sceneWithCameraAdd
  sceneWithCameraRemove
}