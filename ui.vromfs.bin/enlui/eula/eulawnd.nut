import "%ui/style/colors.nut" as colors
import "%ui/control/gui_buttons.nut" as JB
import "%ui/helpers/isChineseVersion.nut" as isChineseVersion
from "dagor.debug" import logerr
from "%dngscripts/platform.nut" import is_mobile
from "%ui/components/msgbox.nut" import msgboxStyling, showMessageWithContent
from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/state/safeArea.nut" import safeAreaSize
from "%ui/hotkeysPanel.nut" import hotkeysBarHeight
from "%ui/ui_library.nut" import *
from "%ui/eula/eulaState.nut" import isNoVersion, getVersion, getDocument

let customStyleA = {hotkeys=[[$"^J:X | Enter | Space", {description={skip=true}}]]}
let customStyleB = {hotkeys=[[$"^Esc | {JB.B}", {description={skip=true}}]]}
let customStyleOK = {hotkeys=[[$"^Esc | {0} | Enter | Space | {JB.B} | {JB.A} | J:X", {description={skip=true}}]]}
let customStyleNoChoice = {hotkeys=[[$"^Esc | {0} | Enter | Space | J:X", {description={skip=true}}]]}

let forcedMsgBoxStyle = (clone msgboxStyling)
forcedMsgBoxStyle.rawdelete("closeKeys")

function show(eulaTxt, decisionCb, isUpdated, isForced) {
  
  let eulaSize = Computed(@()
    [safeAreaSize.get()[0] - (is_mobile ? fsh(10) : 0),
    safeAreaSize.get()[1] - fsh(15) - hotkeysBarHeight.get()])

  let eulaUiContent = @() {
    watch = [eulaSize]
    size = eulaSize.get()
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children = [
      {
        rendObj = ROBJ_TEXT
        text = loc(isUpdated ? "LegalsUpdated" : "Legals")
        hplace = ALIGN_CENTER
      }.__update(fontHeading2)
      makeVertScroll({
        size = [eulaSize.get()[0], SIZE_TO_CONTENT]
        halign = ALIGN_LEFT
        children = {
          size = [eulaSize.get()[0] - hdpx(20), SIZE_TO_CONTENT]
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          color = colors.BtnTextNormal
          text = eulaTxt
        }.__update(sh(100) <= 720 ? fontHeading2 : fontBody)
      }, {
        size = FLEX
        styling = thinStyle
        needReservePlace = false
        maxHeight = eulaSize.get()[1]
        wheelStep = 30
      })
    ]
  }

  let eulaUi = {
    uid = "eula"
    content = eulaUiContent
  }

  if (isForced || decisionCb == null) {
    eulaUi.buttons <- [
      {
        text = isUpdated ? loc("eula/accept") : loc("Ok")
        isCurrent = true
        action = @() decisionCb?(true)
        customStyle = isForced ? customStyleNoChoice : customStyleOK
      }
    ]
  }
  else {
    eulaUi.buttons <- [
      {
        text = loc("eula/accept")
        isCurrent = true
        action = @() decisionCb(true)
        customStyle = customStyleA
      },
      {
        text = loc("eula/reject")
        isCancel = true
        action = @() decisionCb(false)
        customStyle = customStyleB
      }
    ]
  }
  showMessageWithContent(eulaUi, isForced ? forcedMsgBoxStyle : null)
}

function showEula(cb = null, isUpdated = false, isForced = false) {
  
  let version = getVersion()
  if (isChineseVersion || isNoVersion(version)) {
    cb?(true)
    return
  }

  let eulaText = getDocument()
  if (eulaText == null) {
    logerr($"EULA of version {version} has no text")
    cb?(true)
    return
  }

  show(eulaText, cb, isUpdated, isForced)
}

console_register_command(@(isUpdated, isForced)
  show(getDocument(), @(a) log_for_user($"Result: {a}"), isUpdated, isForced), "eula.showManualOpen")

return {
  showEula
}
