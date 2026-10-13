from "%ui/style/designConst.nut" import accentColor, titleTxtColor, smallPadding, panelBgColor, defBdColor, hoverTxtColor, hoverBdColor
  , disabledTxtColor, disabledBgColor, hoverPanelBgColor, darkPanelBgColor
from "%dngscripts/sound_system.nut" import sound_play
from "%ui/ui_library.nut" import *

let knobSize = [hdpxi(14), hdpxi(14)]
let blockPadding = smallPadding
let blockSize = [hdpx(50), knobSize[1] + 2 * blockPadding]
let transitions = [ { prop = AnimProp.translate, duration = 0.15, easing = InOutCubic } ]
let disabledPos = { translate = [knobSize[0] / 2 + blockPadding, 0] }
let activePos = { translate = [blockSize[0] - knobSize[0] / 2 - blockPadding, 0] }


function mkToggleSwitch(curValue, isEnabled = true){
  let group = ElemGroup()
  let knob = watchElemState(@(sf) {
    watch = curValue
    size = knobSize
    transform = curValue.get() ? activePos : disabledPos
    transitions
    group
    rendObj = ROBJ_VECTOR_CANVAS
    commands = [[ VECTOR_ELLIPSE, 0, 50, 50, 50 ]]
    fillColor = !isEnabled ? disabledTxtColor
      : sf & S_ACTIVE ? panelBgColor
      : sf & S_HOVER ? accentColor
      : hoverPanelBgColor
    color = !isEnabled ? disabledBgColor
      : sf & S_ACTIVE ? titleTxtColor
      : hoverTxtColor
  })

  return watchElemState(@(sf) {
    watch = curValue
    rendObj = ROBJ_BOX
    fillColor = curValue.get() ? darkPanelBgColor : panelBgColor
    borderRadius = blockSize[0] * 0.5
    borderColor = sf & S_HOVER ? hoverBdColor : defBdColor
    borderWidth = hdpx(1)
    group
    size = blockSize
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick = function() {
      if (isEnabled) {
        curValue.set(!curValue.get())
        sound_play(curValue.get() ? "ui/enlist/flag_set" : "ui/enlist/flag_unset")
      }
    }
    children = knob
  })
}

return mkToggleSwitch