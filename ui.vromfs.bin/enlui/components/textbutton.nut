import "%ui/components/fontawesome.map.nut" as fa
import "%ui/control/gui_buttons.nut" as JB
import "%ui/userstats/serverTime.nut" as serverTime
import "%ui/components/getGamepadHotkeys.nut" as getGamepadHotkeys
import "%ui/style/tooltipCtor.nut" as tooltipCtor
from "%ui/style/fontsStyle.nut" import fontawesome, fontBody
from "%ui/style/designConst.nut" import commonBtnHeight, commonBorderRadius, midPadding
from "%ui/components/gamepadImgByKey.nut" import mkImageCompByDargKey
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/style/cursors.nut" import setTooltip
from "%ui/style/buttonsStyle.nut" import purchaseButtonStyle, primaryFlatButtonStyle, loginBtnStyle, primaryStyle, faStyle, accentBtnStyle, pressedBtnStyle
  , transpBtnStyle, regularStyle, loginBtnStyleDisabled
from "%ui/ui_library.nut" import *
from "types" import Function, Table

let soundDefault = {
  click  = "ui/enlist/button_click"
  hover  = "ui/enlist/button_highlight"
}

let soundActive = soundDefault.__merge({  active = "ui/enlist/button_action" })

let defBorderStyle = {
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius
}

let defHotkeyParams = {
  hplace = ALIGN_LEFT
  margin = midPadding
}

function textColor(sf, style = {}, isEnabled = true) {
  if (!isEnabled) return style?.disabledTxtColor ?? regularStyle.disabledTxtColor
  if (sf & S_ACTIVE) return style?.activeTxtColor ?? regularStyle.activeTxtColor
  if (sf & S_HOVER)     return style?.hoverTxtColor ?? regularStyle.hoverTxtColor
  if (sf & S_KB_FOCUS)  return style?.hoverTxtColor ?? regularStyle.hoverTxtColor
  return style?.defTxtColor ?? regularStyle.defTxtColor
}

function borderColor(sf, style = {}, isEnabled = true) {
  if (!isEnabled)       return style?.disabledBdColor ?? regularStyle.disabledBdColor
  if (sf & S_ACTIVE)    return style?.activeBdColor ?? regularStyle.activeBdColor
  if (sf & S_HOVER)     return style?.hoverBdColor ?? regularStyle.hoverBdColor
  if (sf & S_KB_FOCUS)  return style?.hoverBdColor ?? regularStyle.hoverBdColor
  return style?.defBdColor ?? regularStyle.defBdColor
}

function fillColor(sf, style = {}, isEnabled = true) {
  if (!isEnabled)       return style?.disabledBgColor ?? regularStyle.disabledBgColor
  if (sf & S_ACTIVE)    return style?.activeBgColor ?? regularStyle.activeBgColor
  if (sf & S_HOVER)     return style?.hoverBgColor ?? regularStyle.hoverBgColor
  if (sf & S_KB_FOCUS)  return style?.hoverBgColor ?? regularStyle.hoverBgColor
  return style?.defBgColor ?? regularStyle.defBgColor
}


let defButtonBg = @(sf, style, isEnabled) {
  size = FLEX
  rendObj = style?.rendObj ?? ROBJ_BOX
  fillColor = fillColor(sf, style, isEnabled)
  borderWidth = style?.borderWidth ?? defBorderStyle.borderWidth
  borderRadius = style?.borderRadius ?? defBorderStyle.borderRadius
  borderColor = borderColor(sf, style, isEnabled)
}

function defTextCtor(text, params, _handler, group, sf) {
  let { isEnabled = true, textParams = fontBody, style = {} } = params
  return {
    rendObj = ROBJ_TEXT
    text
    group
    color = textColor(sf, style, isEnabled)
    margin = textParams?.margin ?? [hdpx(10), hdpx(20)]
  }.__update(textParams)
}


function textButton(text, handler, params={}) {
  let group = ElemGroup()
  let { enabledDelay = 0, isEnabled = true, stateFlags = Watched(0), overrideBySf = null } = params

  let usingCustomCtor = text instanceof Function

  let enableTs = serverTime.get() + enabledDelay
  let enableByDelay = enabledDelay <= 0
    ? Watched(0)
    : Computed(@() max(0, enableTs - serverTime.get()))

  function builder(sf) {
    let secToEnabled = enableByDelay.get()
    let isTimerEnabled = isEnabled && secToEnabled <= 0

    let paramsExt = overrideBySf == null
      ? params.__merge({ isEnabled = isTimerEnabled })
      : params.__merge(overrideBySf(sf, isTimerEnabled) ?? {})

    local btnText = usingCustomCtor ? text(null, paramsExt, handler, group, sf) : text
    if (secToEnabled > 0)
      btnText = $"{btnText} ({secToEnabled})"

    let {
      textParams = fontBody, style = {}, bgChild = null, fgChild = null,
      btnHeight = commonBtnHeight, btnWidth = null, sound = {}, hint = null, onHoverFunc = null,
      clipChildren = false, bgChildBorder = false, minWidth = null
    } = paramsExt

    local gamepadHotkey = usingCustomCtor ? "" : getGamepadHotkeys(params?.hotkeys)
    local gamepadBtn = null
    if (gamepadHotkey != "") {
      if ((sf & S_HOVER) || (sf & S_ACTIVE)) {
        gamepadHotkey = JB.A
      }
      gamepadBtn = mkImageCompByDargKey(gamepadHotkey
        defHotkeyParams.__merge({ height = textParams.fontSize}, params?.hotkeyParams ?? {}))
    }
    local bgComp = bgChild instanceof Table ? bgChild
      : bgChild?(sf, isTimerEnabled) ?? defButtonBg(sf, style, isTimerEnabled)

    bgComp = bgChildBorder ? bgComp.__merge({borderColor = borderColor(sf, style, isTimerEnabled)})
      : bgComp

    let btnContent = btnText == null ? null
      : usingCustomCtor ? text(null, paramsExt, handler, group, sf)
      : defTextCtor(btnText, paramsExt, handler, group, sf)

    return {
      watch = [stateFlags, isGamepad, enableByDelay]
      size = [btnWidth ?? SIZE_TO_CONTENT, btnHeight]
      key = handler
      group
      minWidth = minWidth ?? btnWidth ?? SIZE_TO_CONTENT
      onElemState = @(v) stateFlags.set(v)
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      clipChildren
      behavior = Behaviors.Button
      onDetach = @() stateFlags.set(0)
      onHover = function(on) {
        onHoverFunc?(on)
        if (hint != null)
          setTooltip(!on ? null : tooltipCtor(hint))
      }
      onClick = isTimerEnabled ? handler : null
      sound = isTimerEnabled ? soundActive.__update(sound) : null

      children = [
        bgComp
        {
          flow = FLOW_HORIZONTAL
          halign = ALIGN_CENTER
          valign = ALIGN_CENTER
          size = [btnWidth ?? SIZE_TO_CONTENT, btnHeight]
          clipChildren = true
          children = [
            isGamepad.get() ? gamepadBtn : null
            btnContent
          ]
        }
        fgChild
      ]
    }.__merge(paramsExt)
  }

  return @() builder(stateFlags.get())
}

return freeze({
  Regular = @(text, handler, params = {}) textButton(text, handler, params)
  Secondary = @(text, handler, params = {}) textButton(text, handler, {
    style = transpBtnStyle
  }.__merge(params))
  Pressed = @(text, handler, params = {}) textButton(text, handler, {
    style = pressedBtnStyle
  }.__merge(params))
  Accented = @(text, handler, params = {}) textButton(text, handler, {
    style = accentBtnStyle
  }.__merge(params))
  Purchase = @(text, handler, params = {}) textButton(text, handler, {
    bgChildBorder = true
  }.__merge(purchaseButtonStyle, params))
  Primary = @(text, handler, params = {}) textButton(text, handler, {
    bgChildBorder = true
    borderWidth = hdpx(1)
  }.__merge(primaryFlatButtonStyle, params))
  FARegular = @(iconId, handler, params = {}) function() {
    let icon = isGamepad.get() && params?.hotkeys != null ? null : fa[iconId]
    return {
      watch = isGamepad
      children = textButton(icon, handler, {
          btnWidth = commonBtnHeight
          textParams = fontawesome
        }.__merge(params))
    }
  }
  FASecondary = @(iconId, handler, params = {}) function() {
    let icon = isGamepad.get() && params?.hotkeys != null ? null : fa[iconId]
    return {
      watch = isGamepad
      children = textButton(icon, handler, {
          btnWidth = commonBtnHeight
          textParams = fontawesome
          style = transpBtnStyle.__merge({ borderWidth = 0 rendObj = ROBJ_WORLD_BLUR_PANEL })
        }.__merge(params))
    }
  }
  FAPrimary = @(iconId, handler, params = {}) function() {
    let icon = isGamepad.get() && params?.hotkeys != null ? null : fa[iconId]
    return {
      watch = isGamepad
      children = textButton(icon, handler, {
          btnWidth = commonBtnHeight
          textParams = fontawesome
          style = faStyle
        }.__merge(params))
    }
  }

  loginBtnStyleDisabled
  loginBtnStyle
  primaryStyle

  soundDefault
  soundActive
  textColor
})
