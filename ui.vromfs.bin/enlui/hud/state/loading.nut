import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *


let loadingImagesList = mkEcsComputed({ comps = [["loading_images", ecs.TYPE_STRING_LIST]] })

let loadingImages = Computed(function() {
  let images = loadingImagesList.get()
  return (images?.len() ?? 0) > 0 ? images : null
})

return {loadingImages}