import "%ui/components/fontawesome.map.nut" as fa
import "%ui/components/faComp.nut" as faComp
import "%ui/components/getGamepadHotkeys.nut" as getGamepadHotkeys
from "%ui/style/fontsStyle.nut" import fontawesome
from "%ui/style/colors.nut" import CheckBoxContentActive, CheckBoxContentHover, CheckBoxContentDefault, ControlBg
from "%ui/style/sounds.nut" import stateChangeSounds
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/gamepadImgByKey.nut" import mkImageCompByDargKey
from "%ui/ui_library.nut" import *

const checkFontSize = hdpx(12)
const boxSize = hdpx(20)
let calcColor = @(sf) sf & S_ACTIVE ? CheckBoxContentActive
  : sf & S_HOVER ? CheckBoxContentHover
  : CheckBoxContentDefault

function box(stateFlags, state) {
  let size = [boxSize, boxSize]
  let watch = [stateFlags, state]
  return function() {
    let color = calcColor(stateFlags.get())
    return {
      watch
      size
      rendObj = ROBJ_BOX
      fillColor = ControlBg
      borderWidth = hdpx(1)
      borderColor = color
      borderRadius = hdpx(3)
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      children = state.get()
        ? faComp("check", {color, fontSize = checkFontSize})
        : null
    }
  }
}

const boxHeight = hdpx(25)
let mkCheckMark = @(stateFlags, state, group) @(){
  watch = [stateFlags, state]
  validateStaticText = false
  text = state.get() ? fa["check"] : null
  vplace = ALIGN_CENTER
  color = calcColor(stateFlags.get())
  size = const [boxHeight, SIZE_TO_CONTENT]
  group
  rendObj = ROBJ_INSCRIPTION
  halign = ALIGN_CENTER
}.__update(fontawesome, {fontSize = checkFontSize})

let mkSwitchKnob = @(stateFlags, state, group) @(){
  size = [boxHeight-hdpx(2),boxHeight-hdpx(2)] rendObj = ROBJ_BOX, borderRadius = hdpx(3),
  borderWidth = hdpx(1),
  fillColor = calcColor(stateFlags.get())
  borderColor = Color(0,0,0,30)
  hplace = state.get() ? ALIGN_RIGHT : ALIGN_LEFT
  vplace = ALIGN_CENTER
  watch = [stateFlags, state]
  margin = hdpx(1)
  group
}

function switchbox(stateFlags, state, group) {
  let checkMark = mkCheckMark(stateFlags, state, group)
  let switchKnob = mkSwitchKnob(stateFlags, state, group)
  return function(){
    return {
      rendObj = ROBJ_BOX
      fillColor = ControlBg
      borderWidth = hdpx(1)
      borderColor = calcColor(stateFlags.get())
      borderRadius = hdpx(3)
      watch = stateFlags
      size = const [boxHeight*2+hdpx(2), boxHeight]
      children = [checkMark, switchKnob]
    }
  }
}

function label(stateFlags, params, group, onClick) {
  if (type(params) != type({})){
    params = { text = params }
  }
  return @() {
    rendObj = ROBJ_TEXT
    margin = const [fsh(1), 0, fsh(1), 0]
    color = calcColor(stateFlags.get())
    watch = stateFlags
    group = group
    behavior = [Behaviors.Marquee, Behaviors.Button]
    onClick = onClick
    speed = [hdpx(40),hdpx(40)]
    delay =0.3
    scrollOnHover = true
  }.__update(params)
}

let hotkeyLoc = loc("controls/check/toggleOrEnable/prefix", "Toggle")

return function (state, label_text_params=null, params = {}) {
  let group = params?.group ?? ElemGroup()
  let stateFlags = Watched(0)
  let setValue = params?.setValue ?? @(v) state.set(v)
  function onClick(){
    setValue(!state.get())
    sound_play(state.get() ? "ui/enlist/flag_set" : "ui/enlist/flag_unset")
  }

  let { hotkeys = null } = params
  let hotkeyName = getGamepadHotkeys(hotkeys)
  let image = hotkeyName != "" ? mkImageCompByDargKey(hotkeyName) : null
  let hotkeysElem = hotkeys ? {
        key = "hotkeys"
        hotkeys = hotkeys.map(@(hotkey) hotkey.append(onClick))
      }
    : params?.useHotkeys ? {
        key = "hotkeys"
        hotkeys = [
          ["Left | J:D.Left | Right | J:D.Right", hotkeyLoc, onClick]
        ]
      }
    : null
  return function(){
    let children = [
      isGamepad.get() ? image : null
      isGamepad.get() ? switchbox(stateFlags, state, group) : box(stateFlags, state)
      label(stateFlags, label_text_params, group, onClick)
      hotkeys || (stateFlags.get() & S_HOVER) ? hotkeysElem : null
    ]
    if (params?.textOnTheLeft)
      children.reverse()
    return {
      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      gap = fsh(1)
      key = state
      group
      watch = [state, stateFlags, isGamepad]
      behavior = [Behaviors.Button]
      size = SIZE_TO_CONTENT
      onElemState = @(sf) stateFlags.set(sf)
      onClick
      sound = stateChangeSounds
      xmbNode = params?.xmbNode
      children
    }.__update(params?.override ?? {})
  }
}
