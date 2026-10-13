import "%ui/components/fontawesome.map.nut" as fa
import "%ui/control/gui_buttons.nut" as JB
import "%ui/components/base_combobox.nut" as baseCombo
from "%ui/style/fontsStyle.nut" import fontBody, fontawesome
from "%ui/style/colors.nut" import BtnTextHover, comboboxBorderColor, BtnBgActive, BtnBgHover, ControlBgOpaque, Active, Inactive
  , TextHighlight, TextDefault
from "%ui/style/sounds.nut" import buttonSound
from "%ui/components/gamepadImgByKey.nut" import mkImageCompByDargKey
from "%ui/control/active_controls.nut" import isGamepad, isTouch
from "%ui/ui_library.nut" import *

let listItemSound = {
  click  = "ui/button_click_inactive"
  hover = "ui/menu_highlight_settings"
  active = "ui/button_action"
}

let defaultStyle = freeze({
  borderColor     = comboboxBorderColor
  borderWidth     = hdpx(1)
  borderRadius    = hdpx(3)
  fillColorActive = BtnBgActive
  fillColorHover  = BtnBgHover
  fillColor       = ControlBgOpaque
  color           = Active
  colorDisabled   = Inactive
  colorHover      = BtnTextHover
  liColor         = TextDefault
  liColorCurrent  = TextHighlight
  liColorHover    = BtnTextHover
  liPadding       = [0, hdpx(8)]
  liMargin        = fsh(0.5)
  labelMargin     = [fsh(0.5),fsh(1.0)]
  arrowMargin     = hdpx(3)
  arrowPadding    = [hdpx(1), 0, 0, hdpx(2)]
  gapSize         = hdpx(1)
})

function fillColor(sf, style) {
  if (sf & S_ACTIVE)
    return style.fillColorActive
  if (sf & S_HOVER)
    return style.fillColorHover
  return style.fillColor
}

let hotkeyLoc = loc("controls/check/toggleOrEnable/prefix", "Toggle")

function comboStyle(style_params) {
  let style = defaultStyle.__merge(style_params?.style ?? {})

  function label(params) {
    let sf = params?.sf ?? 0
    local color = style.color
    let disabled = params?.disabled ?? false
    if (disabled)
      color = style.colorDisabled
    else if (sf & S_HOVER)
      color = style.colorHover

    let labelText = {
      group = params?.group
      rendObj = ROBJ_TEXT
      
      margin = style.labelMargin
      text = params?.text
      color
      size = FLEX_H
    }.__update(fontBody)

    function popupArrow() {
      return !disabled ? {
        size = ph(100)
        margin = style.arrowMargin
        children = {
          rendObj = ROBJ_TEXT
          padding = style.arrowPadding
          text = isGamepad.get() ? fa["caret-right"] : fa["caret-down"]
          color
          hplace = ALIGN_CENTER
          vplace = ALIGN_CENTER
        }.__update(fontawesome)
      } : null
    }

    return {
      size = FLEX
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      children = [
        labelText
        popupArrow
      ]
    }
  }


  function boxCtor(params) {
    let {comboOpen, disabled, text, stateFlags, group} = params
    let toggle = @() comboOpen.set(!comboOpen.get())
    let hotkeysElem = style_params?.useHotkeys ? {
      key = "hotkeys"
      hotkeys = [
        ["Left | J:D.Left", hotkeyLoc, toggle],
        ["Right | J:D.Right", hotkeyLoc, toggle],
      ]
    } : null

    return function() {
      let sf = stateFlags.get()
      return{
        rendObj = ROBJ_BOX
        fillColor = fillColor(sf, style)
        size = FLEX
        borderColor = style.borderColor
        children = [
          label({text=text, sf=sf, group=group, disabled=disabled}),
          sf & S_HOVER ? hotkeysElem : null
        ]
        borderWidth = style.borderWidth
        borderRadius = style.borderRadius
        watch = stateFlags
        margin = 0
      }
    }
  }

  function listItem(text, action, is_current, params = null) {
    let group = ElemGroup()
    let stateFlags = Watched(0)

    return function() {
      let sf = stateFlags.get()
      let textColor = sf & S_HOVER ? style.colorHover
        : is_current ? style.liColorCurrent
        : style.liColor
      let bgColor = sf & S_HOVER ? style.fillColorHover : style.fillColor
      let hotkey_hint = (sf & S_HOVER) && isGamepad.get()
        ? mkImageCompByDargKey(JB.A, {hplace = ALIGN_RIGHT vplace = ALIGN_CENTER}) : null

      return {
        behavior = [Behaviors.Button, Behaviors.Marquee]
        xmbNode = params?.xmbNode
        scrollOnHover=true
        eventPassThrough = isTouch.get()
        speed =[hdpx(100),hdpx(1000)]
        delay =0.5
        size = FLEX_H
        group = group
        watch = [stateFlags, isGamepad]

        rendObj = ROBJ_BOX
        fillColor = bgColor
        padding = style.liPadding
        borderWidth = 0
        flow = FLOW_HORIZONTAL
        onClick = action
        onElemState = @(nsf) stateFlags.set(nsf)
        sound = listItemSound

        children = [
          {
            rendObj = ROBJ_TEXT
            margin = style.liMargin
            group
            text
            color = textColor
          }.__update(fontBody)
          {size = const [FLEX,0]}
          hotkey_hint
        ]
      }
    }
  }


  function closeButton(onClick) {
    return {
      size = FLEX
      behavior = Behaviors.Button
      onClick
      hotkeys = [[$"^{JB.B} | Esc"]]
    }
  }

  function onOpenDropDown(itemXmbNode) {
    gui_scene.setXmbFocus(isGamepad.get() ? itemXmbNode : null)
  }

  function onCloseDropDown(boxXmbNode) {
    if (isGamepad.get())
      gui_scene.setXmbFocus(boxXmbNode)
  }

  let rootBaseStyle = {
    sound = buttonSound
  }

  return {
    popupBgColor = style.fillColor
    popupBdColor = style.borderColor
    popupBorderWidth = style.borderWidth
    dropDir = style_params?.dropDir
    boxCtor
    rootBaseStyle
    listItem
    itemGap = {
      rendObj = ROBJ_SOLID
      size = [FLEX, style.gapSize]
      color = style.borderColor
    }
    closeButton
    onOpenDropDown
    onCloseDropDown
  }
}


function combo(wdata, options, style_params) {
  return baseCombo(wdata, options, comboStyle(style_params))
}

let export = class{
  
  _call = @(_self, wdata, options, style_params={}) combo(wdata, options, style_params)
}()

return export
