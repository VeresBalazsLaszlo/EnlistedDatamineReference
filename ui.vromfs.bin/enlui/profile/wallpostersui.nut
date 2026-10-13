import "%darg/helpers/hoverHoldAction.nut" as hoverHoldAction
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/profile/wallpostersState.nut" import wpCfgFiltered, wpIdSelected
from "%ui/profile/wallpostersPkg.nut" import mkWallposter, makeBigWpImage
from "%ui/profile/unseenProfileState.nut" import seenWallposters, markSeenWallposter, markWallpostersOpened
from "%ui/style/designConst.nut" import bigPadding, blurBgFillColor
from "%ui/ui_library.nut" import *

function mkWallposterBlock(wallposter, unseenList) {
  let { id } = wallposter
  let isUnseen = id in unseenList
  return watchElemState(@(sf) {
    watch = wpIdSelected
    size = FLEX_H
    behavior = wpIdSelected.get() ? null : Behaviors.Button
    onClick = function() {
      wpIdSelected.set(id)
      if (isUnseen)
        markSeenWallposter(id)
    }
    onHover = function(on) {
      if (isUnseen)
        hoverHoldAction("markSeenWallposter", id, @(v) markSeenWallposter(v))(on)
    }
    xmbNode = XmbNode()
    children = mkWallposter(wallposter, sf, isUnseen)
  })
}

function wallpostersListUi() {
  let wpFiltered = wpCfgFiltered.get()
  let { unseen = {}, unopened = {} } = seenWallposters.get()
  return {
    watch = [wpIdSelected, wpCfgFiltered, seenWallposters]
    rendObj = ROBJ_BOX
    size = FLEX
    padding = bigPadding
    onDetach = @() markWallpostersOpened(unopened.keys())
    children = wpIdSelected.get() == null
      ? {
          size = FLEX
          flow = FLOW_VERTICAL
          gap = bigPadding
          children = makeVertScroll({
            xmbNode = XmbContainer({
              canFocus = false
              scrollSpeed = 5.0
              isViewport = true
            })
            size = FLEX_H
            flow = FLOW_VERTICAL
            gap = bigPadding
            children = wpFiltered.map(@(wallposter) mkWallposterBlock(wallposter, unseen))
          }, {
            styling = thinStyle
          })
        }
      : {
          size = FLEX
          rendObj = ROBJ_SOLID
          color = blurBgFillColor
          children = makeBigWpImage(wpFiltered
            .findvalue(@(wp) wp.id == wpIdSelected.get()), @() wpIdSelected.set(null))
        }
  }
}

return {
  key = "wallposters"
  size = FLEX
  children = wallpostersListUi
  onAttach = @() wpIdSelected.set(null)
  onDetach = @() wpIdSelected.set(null)
}
