import "%ui/components/mkHeader.nut" as mkHeader
import "%ui/components/closeBtn.nut" as closeBtnBase
import "%ui/soldiers/mkItemWithMods.nut" as mkItemWithMods
from "%ui/components/textButton.nut" import Regular
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/soldiers/model/all_items_templates.nut" import allItemTemplates
from "%ui/state/safeArea.nut" import safeAreaBorders
from "%ui/soldiers/components/itemDetailsComp.nut" import mkViewDetailsFull
from "%ui/sceneWithCamera.nut" import sceneWithCameraAdd, sceneWithCameraRemove
from "%ui/style/designConst.nut" import midPadding, smallPadding, blurBgColor, blurBgFillColor, unitSize
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/showState.nut" import curSelectedItem, changeCameraFov
from "%ui/shop/shopPkg.nut" import mkClassCanUse
from "%ui/components/itemsInfo.nut" import getItemOrigin
from "%ui/battleData/testDrive.nut" import mkItemTestDriveButtonUi
from "%ui/helpers/metalink.nut" import getLinkedArmyName
from "%ui/ui_library.nut" import *

const ADD_CAMERA_FOV_MIN = -10
const ADD_CAMERA_FOV_MAX = 35

let itemToShow = mkWatched(persist, "itemToShow", null)
let selectedKey = Watched(null)

let shopItemWidth = 9.0 * unitSize

let mkItemContent = @(item) item == null ? null : @(){
  watch = [allItemTemplates, selectedKey]
  size = FLEX_V
  padding = midPadding
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  fillColor = blurBgFillColor
  xmbNode = XmbContainer({
    canFocus = false
    scrollSpeed = 5.0
    isViewport = true
  })
  children =
    makeVertScroll(
      mkItemWithMods({
        item
        selectedKey
        selectKey = item?.basetpl
        isXmb = true
        canDrag = false
        itemSize = [shopItemWidth, 2.0 * unitSize]
        hideStatus = true
        isAvailable = true
      }),
      {
        size = FLEX_V
        needReservePlace = false
      })
}

let backBtn = @() {
  watch = isGamepad
  size = FLEX_H
  children = isGamepad.get() ? null : Regular(loc("BackBtn"), @() itemToShow.set(null), {
    size = const [FLEX, hdpx(50)]
  })
}

function viewItemScene() {
  let watch = [safeAreaBorders, itemToShow, allItemTemplates]
  let item = itemToShow.get()
  if (item == null)
    return { watch }

  let armyId = getLinkedArmyName(item)
  let templates = allItemTemplates.get()?[armyId]
  return {
    watch
    size = const [sw(100), sh(100)]
    flow = FLOW_VERTICAL
    padding = safeAreaBorders.get()
    behavior = [DngBhv.MenuCameraControl, Behaviors.TrackMouse]
    onMouseWheel = function(mouseEvent) {
      changeCameraFov(mouseEvent.button * 5, ADD_CAMERA_FOV_MIN, ADD_CAMERA_FOV_MAX)
    }
    children = [
      mkHeader({
        textLocId = getItemOrigin(item)
        closeButton = closeBtnBase({ onClick = @() itemToShow.set(null) })
      })
      {
        size = FLEX
        children = [
          {
            rendObj = ROBJ_SOLID
            opacity = 0
            size = FLEX
            animations = [
              { prop = AnimProp.opacity, from = 1, to = 0,
                duration = 0.5, play = true }
              { prop = AnimProp.color, from = Color(0,0,0), to = Color(0,0,0),
                duration = 0.5, play = true }
            ]
          }
          {
            size = FLEX_V
            flow = FLOW_VERTICAL
            gap = smallPadding
            children = [
              mkClassCanUse(item.basetpl, armyId, templates)
              mkItemContent(item)
              mkItemTestDriveButtonUi(item, { size = const [FLEX, hdpx(50)] })
              backBtn
            ]
          }
          {
            hplace = ALIGN_RIGHT
            vplace = ALIGN_BOTTOM
            children = mkViewDetailsFull(itemToShow.get(), fsh(95))
          }
        ]
      }
    ]
  }
}


itemToShow.subscribe(function(val) {
  if (val == null) {
    curSelectedItem.set(null)
    sceneWithCameraRemove(viewItemScene)
    return
  }
  curSelectedItem.set(val)
  sceneWithCameraAdd(viewItemScene, "new_items")
})

if (itemToShow.get() != null)
  sceneWithCameraAdd(viewItemScene, "new_items")

return @(val) itemToShow.set(val)
