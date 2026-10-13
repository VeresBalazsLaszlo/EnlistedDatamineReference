import "%ui/components/faComp.nut" as faComp
from "%ui/style/designConst.nut" import smallPadding, titleTxtColor, defTxtColor, activeTxtColor, activeBgColor
from "%ui/ui_library.nut" import *

const defDotSize = hdpx(12)

let mkProgressLine = @(trigger, page, duration) {
  key = $"page_{page}"
  rendObj = ROBJ_SOLID
  size = const [FLEX, hdpx(2)]
  opacity = 0
  color = activeBgColor
  transform = { pivot = [0,0] }
  animations = [
    { prop = AnimProp.opacity, from = 0.4, to = 0.4,
      duration = duration, play = true, trigger }
    { prop = AnimProp.scale, from = [0, 1], to = [1, 1],
      duration = duration, play = true, trigger }
  ]
}

let mkDot = @(sf, isSelected = false, dotSize = defDotSize) faComp(isSelected ? "circle" : "circle-o", {
  padding = smallPadding
  fontSize = dotSize
  color = isSelected ? titleTxtColor
    : sf & S_HOVER ? activeTxtColor
    : defTxtColor
})

function mkDotPaginator(id, pageWatch, dotSize = defDotSize, switchTime = Watched(0)) {
  local pages = 1
  let gotoNextPage = @() pageWatch.modify(@(v) (v + 1) % pages)
  function startSwitchTimer(_ = null) {
    anim_skip(id)
    gui_scene.clearTimer(gotoNextPage)
    if (pages > 1 && switchTime.get() > 0) {
      anim_start(id)
      gui_scene.resetTimeout(switchTime.get(), gotoNextPage)
    }
  }
  function onAttach() {
    foreach (v in [pageWatch, switchTime])
      v.subscribe(startSwitchTimer)
    startSwitchTimer()
  }
  function onDetach() {
    foreach (v in [pageWatch, switchTime])
      v.unsubscribe(startSwitchTimer)
    gui_scene.clearTimer(gotoNextPage)
  }

  return function(curPages) {
    pages = curPages
    if (pages <= 1)
      return null

    return {
      size = FLEX_H
      flow = FLOW_VERTICAL
      halign = ALIGN_CENTER
      onAttach
      onDetach
      children = [
        {
          flow = FLOW_HORIZONTAL
          children = array(pages).map(function(_, idx) {
            let isSelected = Computed(@() pageWatch.get() == idx)
            return watchElemState(@(sf) {
              watch = isSelected
              behavior = Behaviors.Button
              onClick = @() pageWatch.set(idx)
              onHover = function(on) {
                if (on) {
                  anim_skip(id)
                  gui_scene.clearTimer(gotoNextPage)
                }
                else
                  startSwitchTimer()
              }
              children = mkDot(sf, isSelected.get(), dotSize)
            })
          })
        }
        mkProgressLine(id, pageWatch.get(), switchTime.get())
      ]
    }
  }
}

let mkDotPages = @(pageWatch, totalPages, dotSize = defDotSize) {
  flow = FLOW_HORIZONTAL
  children = array(totalPages).map(function(_, idx) {
    let isSelected = Computed(@() pageWatch.get() == idx)
    return watchElemState(@(sf) {
      watch = isSelected
      behavior = Behaviors.Button
      onClick = @() pageWatch.set(idx)
      children = mkDot(sf, isSelected.get(), dotSize)
    })
  })
}

return {
  mkDotPaginator
  mkDotPages
}
