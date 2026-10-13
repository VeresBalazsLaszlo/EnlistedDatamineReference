from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/items/itemCollageState.nut" import viewTemplates
from "%ui/ui_library.nut" import *

let isOpened = mkWatched(persist, "isOpened", false)

let itemCollage = {
  size = FLEX
}

function open() {
  sceneWithCameraAdd(itemCollage, "inv_items")
}

function close() {
  sceneWithCameraRemove(itemCollage)
}

isOpened.subscribe(@(v) v ? open() : close())
if (isOpened.get())
  open()

viewTemplates.subscribe(function(tplList) {
  if (tplList.findvalue(@(v) v != "") == null)
    isOpened.set(false)
  else
    isOpened.set(true)
})
