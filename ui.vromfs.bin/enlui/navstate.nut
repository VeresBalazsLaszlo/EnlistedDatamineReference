from "%ui/ui_library.nut" import *


let scenesList = []

let scenesListGeneration = mkWatched(persist, "scenesListGeneration", 0)

let getTopScene = @() scenesList.len() > 0 ? scenesList.top() : null

let doesSceneExist = @(...) scenesList.len() > 0

function addScene(componentOrScene) {
  let idx = scenesList.indexof(componentOrScene)
  if (idx != null)
    scenesList.remove(idx)
  scenesList.append(componentOrScene)
  scenesListGeneration.modify(@(v) v + 1)
}

function removeScene(componentOrScene) {
  let idx = scenesList.indexof(componentOrScene)
  if (idx == null)
    return null
  scenesList.remove(idx)
  scenesListGeneration.modify(@(v) v + 1)
}

return freeze({
  scenesListGeneration
  doesSceneExist
  getTopScene
  addScene
  removeScene
})
