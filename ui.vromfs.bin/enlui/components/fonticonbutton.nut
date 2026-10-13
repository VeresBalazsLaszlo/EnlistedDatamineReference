import "%ui/components/gamepadImgByKey.nut" as gamepadImgByKey
import "%ui/components/faComp.nut" as faComp
import "%ui/components/getGamepadHotkeys.nut" as getGamepadHotkeys
from "%ui/style/colors.nut" import TextActive, TextHighlight, TextDefault
from "%ui/style/sounds.nut" import buttonSound
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/ui_library.nut" import *

let defIconColor = @(sf) sf & S_ACTIVE ? TextActive
  : sf & S_HOVER ? TextHighlight
  : TextDefault

function fontIconButton(icon, params = null) {
  let stateFlags = params?.stateFlags ?? Watched(0)
  let gamepadHotkey = getGamepadHotkeys(params?.hotkeys, true)
  let { skipDirPadNav = gamepadHotkey != "" } = params
  let gamepadImg = (gamepadHotkey == "") ? null : gamepadImgByKey.mkImageCompByDargKey(gamepadHotkey)
  local { watch = [] } = params
  watch = (typeof watch == "array" ? clone watch : [watch])
  watch.append(stateFlags, isGamepad)

  let p = (params ?? {}).__merge({ watch, skipDirPadNav })
  local iconParams = {
    fontSize = hdpx(20)
    color = null
  }
  if (params?.iconParams)
    iconParams.__update(params.iconParams)

  return function() {
    let sfVal = stateFlags.get()
    if (p?.byStateFlags)
      p.__update(p.byStateFlags.set(sfVal))

    local children = gamepadImg
    if (!isGamepad.get() || gamepadImg == null) {
      iconParams.color = params?.iconColor(sfVal) ?? defIconColor(sfVal)
      children = faComp(icon, iconParams)
    }

    return {
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      behavior = Behaviors.Button
      onElemState = @(sf) stateFlags.set(sf & ~S_TOP_HOVER)
      children
      sound = buttonSound
    }.__merge(p)
  }
}

return fontIconButton
