from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/menus/controls_state.nut" import generation
from "%ui/hud/style.nut" import HUD_TIPS_HOTKEY_FG
from "%ui/control/formatInputBinding.nut" import textListFromAction, buildElems, mkHasBinding, keysImagesMap
from "%ui/control/active_controls.nut" import isGamepad, isTouch
from "%ui/ui_library.nut" import *

function container(children, params={}){
  return {
    children = {
      speed = const [60,800]
      delay = 0.3
      children
      flow = FLOW_HORIZONTAL
      gap = hdpx(3)
      behavior = Behaviors.Marquee
      scrollOnHover = true
      maxWidth = pw(100)
      size = SIZE_TO_CONTENT
      halign = ALIGN_LEFT valign = ALIGN_CENTER
    }
    clipChildren = true
    size = SIZE_TO_CONTENT
  }.__update(params)
}

function controlHudHint(params, _group = null) {
  if (typeof params == "string")
    params = {id = params}
  let frame = params?.frame ?? true
  let font = params?.text_params?.font ?? fontSub?.font
  let fontSize = params?.text_params?.fontSize ?? fontSub.fontSize
  let color = params?.color ?? HUD_TIPS_HOTKEY_FG
  let width = params?.width ?? SIZE_TO_CONTENT
  let height = params?.height ?? fontH(100)
  let frameC = freeze({
    rendObj = ROBJ_FRAME
    color
    size = FLEX
    opacity = 0.3
    borderWidth = hdpx(1)
  })

  function makeControlText(text) {
    return {
      text, fontSize, font, color, rendObj = ROBJ_TEXT padding = hdpx(4)
    }
  }

  let hasBinding = mkHasBinding(params.id)
  return function(){
    local disableFrame = params?.disableFrame ?? isGamepad.get()
    let column = isGamepad.get() ? 1 : 0
    let textList = textListFromAction(params.id, column)
    local hasTexts = false
    foreach (e in textList) {
      if (keysImagesMap.get()?[e] == null){
        hasTexts=true
        break
      }
    }
    disableFrame = disableFrame || !hasTexts
    let controlElems = buildElems(textList, {textFunc = makeControlText, compact = true})
    let elems = container(controlElems, params?.text_params ?? {})
    return {
      size = [width, height]
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      minWidth = height
      font
      fontSize
      clipChildren = width != SIZE_TO_CONTENT
      rendObj = ROBJ_FRAME
      borderWidth = 0
      children = [
        elems
        frame && !disableFrame
          ? frameC
          : null
      ]
      watch = [isGamepad, hasBinding, generation, keysImagesMap]
    }
  }
}

function mkShortHudHintFromList(controlElems, watch = null){
  local modifier = null
  let hasModifier = controlElems.len()==2
  if (hasModifier) {
    modifier = controlElems[1]
    controlElems = [controlElems[0]]
  }
  modifier = {hplace = ALIGN_RIGHT, size = SIZE_TO_CONTENT, children = modifier, padding = const [0,0,0,hdpx(15)], pos=const [0,-hdpx(2)]}
  controlElems.append(modifier)
  return {
    watch = [isGamepad,isTouch].extend(watch ?? [])
    size = SIZE_TO_CONTENT
    flow = hasModifier ? null : FLOW_HORIZONTAL
    valign = hasModifier ? null : ALIGN_CENTER
    children = isTouch.get() ? null : controlElems
    vplace = ALIGN_CENTER
  }
}

return {
  controlHudHint
  mkShortHudHintFromList
  mkHasBinding
}
