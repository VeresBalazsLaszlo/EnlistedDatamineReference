from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/hud/style.nut" import HIGHLIGHT_COLOR
from "%ui/ui_library.nut" import *

function optionLabel(opt, _group) {
  let stateFlags = Watched(0)
  let { nameChild = null } = opt

  function nameComp() {
    let color = (stateFlags.get() & S_HOVER) ? HIGHLIGHT_COLOR : Color(160, 160, 160)
    let text = opt?.restart ? $"{opt.name}*" : opt.name
    return {
      size = FLEX_H
      halign = ALIGN_LEFT
      
      watch = stateFlags
      onElemState = @(sf) stateFlags.set(sf)
      clipChildren = true
      rendObj = ROBJ_TEXT 
      behavior = Behaviors.Marquee
      delay = [3, 1]
      speed = 50
      
      text
      color
      sound = {
        hover = "ui/menu_highlight_settings"
      }
    }.__update(fontBody)
  }

  if (nameChild == null)
    return nameComp

  return {
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = [
      nameComp
      nameChild
    ]
  }
}

return optionLabel
