from "%ui/hud/state/fortification_preview_forward_marker.nut" import fortificationPreviewForwardArrows
from "%ui/ui_library.nut" import *

let arrowPicSize = array(2, hdpxi(130))
let arrow = freeze({
  rendObj = ROBJ_IMAGE
  color = Color(255, 255, 255, 128)
  size = arrowPicSize
  pos = const [0, 0]
  image = Picture($"ui/skin#v_arrow.svg:{arrowPicSize[0]}:{arrowPicSize[1]}")
})

function ctor(eid) {
  let yawRotation = Computed(@() fortificationPreviewForwardArrows.get()?[eid] ?? 0.0)
  return @(){
    data = { eid }
    watch = yawRotation
    transform = true
    children = {
      transform = const { scale = [1, 0.5] }
      children = {
        transform = {
          rotate = yawRotation.get()
        }
        children = arrow
      }
    }
  }
}

let memoizedMap = mkMemoizedMapSet(ctor)
return {
  fortification_preview_forward_ctor = {
    watch =  fortificationPreviewForwardArrows
    ctor = @() memoizedMap(fortificationPreviewForwardArrows.get()).values()
  }
}