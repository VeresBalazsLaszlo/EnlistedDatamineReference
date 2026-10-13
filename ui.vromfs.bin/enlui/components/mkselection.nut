import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontBody, fontSub
from "%ui/style/designConst.nut" import panelBgColor, commonBtnHeight, defTxtColor, midPadding, darkTxtColor, accentColor, commonBorderRadius
  , defBdColor, hoverBdColor, smallBtnHeight, disabledBgColor
from "%ui/ui_library.nut" import *

let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")

let isExpanded = Watched(false)
const WND_UID = "SELECTION_WND"

let calcLineBgColor = @(sf) sf & S_HOVER ? accentColor : panelBgColor
const borderWidth = hdpx(1)

let defTxtStyle = {
  color = defTxtColor
}.__update(fontBody)

let hoverTxtStyle = {
  color = darkTxtColor
}.__update(fontBody)


let dropDownHead = @(label, onClick, sf, isEnabled) {
  rendObj = ROBJ_BOX
  borderRadius = commonBorderRadius
  borderWidth = hdpx(1)
  borderColor = !isEnabled ? defBdColor
    : sf & S_HOVER ? hoverBdColor
    : defBdColor
  fillColor = onClick == null || !isEnabled ? disabledBgColor
    : sf & S_HOVER ? accentColor
    : panelBgColor
  size = FLEX
  flow = FLOW_HORIZONTAL
  gap = { size = FLEX }
  padding = [0, midPadding]
  valign = ALIGN_CENTER
  behavior = Behaviors.Button
  onClick
  children = [
    {
      rendObj = ROBJ_TEXT
      text = label
    }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle)
    faComp("chevron-down", {
      fontSize = fontSub.fontSize
      color = sf & S_HOVER ? hoverTxtStyle.color : defTxtStyle.color
    })
  ]
}

let mkOptionItem = @(option, idx) watchElemState(@(sf){
  rendObj = ROBJ_SOLID
  color = calcLineBgColor(sf)
  size = [FLEX, smallBtnHeight]
  padding = [0, midPadding]
  valign = ALIGN_CENTER
  behavior = Behaviors.Button
  onClick = function() {
    option.setValue(idx)
    isExpanded.set(false)
  }
  children = {
    rendObj = ROBJ_TEXT
    text = option.loc
  }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle)
})

isExpanded.subscribe(@(v) v ? null : modalPopupWnd.remove(WND_UID))

function mkSelection(options, curValue, params = {}){
  let group = ElemGroup()
  let canBeExpanded = options.len() > 0
  let { header = "", isEnabled = true } = params

  function expandWnd(event) {
    if (!isEnabled)
      return
    isExpanded.set(true)
    modalPopupWnd.add(event.targetRect, {
      uid = WND_UID
      borderColor = defBdColor
      borderWidth = borderWidth
      size = [event.targetRect.r - event.targetRect.l,  SIZE_TO_CONTENT]
      popupHalign = ALIGN_LEFT
      padding = borderWidth
      borderRadius = commonBorderRadius
      flow = FLOW_VERTICAL
      group
      children = options.map(@(v, idx) mkOptionItem(v, idx))
    })
  }
  return watchElemState(@(sf) {
    watch = curValue
    size = [FLEX, commonBtnHeight]
    behavior = Behaviors.Button
    children = dropDownHead(options?[curValue.get()].loc ?? header,
      canBeExpanded ? expandWnd : null, sf, isEnabled)
  }.__update(params))
}

let mkSmallSelection = @(options, curValue, params = {})
  mkSelection(options, curValue, { size = [FLEX, smallBtnHeight] }.__update(params))


return {
  mkSmallSelection
}