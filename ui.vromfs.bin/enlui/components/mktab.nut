from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import bigPadding, midPadding, titleTxtColor, defTxtColor, commonBorderRadius, hoverSlotBgColor, darkTxtColor
from "%sqstd/string.nut" import utf8ToUpper
from "%ui/components/unseenComponents.nut" import blinkUnseen
from "%ui/components/textButton.nut" import soundActive
from "%ui/ui_library.nut" import *

let markerTarget = MoveToAreaTarget()

function requestMoveToElem(elem) {
  let x = elem.getScreenPosX()
  let y = elem.getScreenPosY()
  let w = elem.getWidth()
  let h = elem.getHeight()
  markerTarget.set(x, y, x + w, y + h)
}


let tabTxtStyle = @(sf, isSelected) {
  color = sf & S_HOVER ? darkTxtColor
    : (sf & S_ACTIVE) || isSelected ? titleTxtColor
    : defTxtColor
  fontFx = sf & S_HOVER ? null : FFT_GLOW
  fontFxFactor = min(24, hdpx(24))
  fontFxColor = 0xDD000000
}.__update(fontBody)


let tabBottomPadding = midPadding * 2


function mkTab(section, action, curSection) {
  let {
    id, locId, isUnseenWatch = Watched(false), addChild = null, mkChild = null
  } = section
  let isSelected = @(curSec) curSec == id
  let stateFlags = Watched(0)
  function textTabComp() {
    let isSel = isSelected(curSection.get())
    return {
      watch = [curSection, stateFlags]
      rendObj = ROBJ_TEXT
      text = utf8ToUpper(loc(locId))
      size = FLEX_V
      padding = [0, midPadding, tabBottomPadding, midPadding]
      valign = ALIGN_BOTTOM
    }.__update(tabTxtStyle(stateFlags.get(), isSel))
  }

  function boxTabComp() {
    let isSel = isSelected(curSection.get())
    return {
      watch = [curSection, stateFlags]
      size = FLEX
      margin = [bigPadding, 0, 0, 0]
      rendObj = ROBJ_SOLID
      color = stateFlags.get() & S_HOVER ? hoverSlotBgColor : 0
      key = id
      behavior = Behaviors.RecalcHandler
      onRecalcLayout = function(initial, elem) {
        if (initial || isSel)
          requestMoveToElem(elem)
      }
    }
  }

  let childTabComp = @() {
    size = FLEX_H
    watch = stateFlags
    children = mkChild?(stateFlags.get()) ?? addChild
  }
  return @() {
    watch = isUnseenWatch
    size = FLEX_V
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    sound = soundActive
    minWidth = fsh(8.5)
    onClick = action
    onElemState = @(s) stateFlags.set(s)
    skipDirPadNav = true
    children = [
      boxTabComp
      textTabComp
      isUnseenWatch.get() ? blinkUnseen : null
      childTabComp
    ]
  }
}

let backgroundMarker = freeze({
  behavior = Behaviors.MoveToArea
  subPixel = true
  target = markerTarget
  viscosity = 0.1
  valign = ALIGN_BOTTOM
  children = {
    rendObj = ROBJ_BOX
    size = const [FLEX, hdpxi(4)]
    borderWidth = 0
    borderRadius = commonBorderRadius
    fillColor = Color(255,255,255)
  }
})



return {
  mkTab
  backgroundMarker
}
