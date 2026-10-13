import "%ui/hud/huds/tips/mkTipComposite.nut" as mkTipComposite
from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/hud/style.nut" import BRIGHT_TEXT_COLOR, TEAM0_TEXT_COLOR, TEAM1_TEXT_COLOR
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/templateControls.nut" import controlHint
from "%ui/control/formatInputBinding.nut" import makeSvgImgFromText
from "dainput2" import is_action_binding_set, get_action_handle
from "%ui/hud/menus/controls_state.nut" import generation
from "%ui/ui_library.nut" import *

const hotkeyGap     = hdpx(5)
const hotkeyListGap = hdpx(5)

let defTextAnims = [
  { prop=AnimProp.scale, from=[1,0], to=[1,1], duration=0.33, play=true, easing=OutCubic }
]


let mkBigControlIcon = @(text, params = {})
  (text ?? "") == "" ? null : makeSvgImgFromText(text, {height=hdpx(36)}.__update(params))

let hasHotkey = @(key, isGamepadV)
  is_action_binding_set(get_action_handle(key, 0xFFFF), isGamepadV ? 1 : 0)

let textHeight = calc_str_box("A", fontHeading2)[1].tointeger()

function gkImg(h) {
  if (typeof h == "array")
    h = h.findvalue(@(key) hasHotkey(key, isGamepad.get()))
  if (typeof h != "string")
    throw null
  return controlHint(h, { imgFunc = mkBigControlIcon })
}

function mkHintComponent(hotkey) {
  if (hotkey == null)
    return null

  let watch = [isGamepad, generation]
  if (typeof hotkey != "array")
    hotkey = [hotkey]

  return function() {
    let children = hotkey.map(gkImg)
    if (children.len() == 0)
      return { watch }

    let hotkeyHint = {
      halign = ALIGN_CENTER
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = hotkeyListGap
      children
    }
    let hotkeySize = calc_comp_size(hotkeyHint)
    let hotkeyWidth = hotkeySize[0] + hotkeyGap
    hotkeyHint.pos <- [-hotkeyWidth, (textHeight - hotkeySize[1]) / 2]
    return {
      
      
      watch
      size = FLEX_H
      maxWidth = SIZE_TO_CONTENT
      children = hotkeyHint
    }
  }
}

function makeDefText(item) {
  let color = item?.color ?? ("myTeamScores" not in item ? BRIGHT_TEXT_COLOR
    : item.myTeamScores ? TEAM0_TEXT_COLOR
    : TEAM1_TEXT_COLOR)
  let { animations = defTextAnims, hotkey = null, text = item } = item
  let hintTextStyle = {
    fontFx = FFT_BLUR
    fontFxColor = Color(0, 0, 0, 150)
    fontFxFactor = min(64, hdpx(64))
    fontFxOffsY = hdpx(0.9)
    color
  }
  let hintComponent = mkHintComponent(hotkey)
  local hintText = mkTipComposite(text, hintTextStyle)
  if (hintText.len() == 1) {
    hintText = hintText.top().__update({
      size = FLEX_H
      maxWidth = SIZE_TO_CONTENT
    })
  } else {
    hintText = {
      flow = FLOW_HORIZONTAL
      children = hintText
    }
  }
  return {
    size = FLEX_H
    maxWidth = SIZE_TO_CONTENT
    key = item
    children = [
      hintComponent
      hintText
    ]
    transform = { pivot = [0, 1] }
    animations
  }
}

function makeItem(item){
  if ("ctor" in item)
    return item.ctor(item)
  return makeDefText(item)
}

return {
  makeItem
}
