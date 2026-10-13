from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/components/openUrl.nut" import openUrl
from "%ui/style/colors.nut" import Active, Inactive, ButtonHover
from "%ui/ui_library.nut" import *

function url(text, link = null, params = {}) {
  let group = ElemGroup()
  let stateFlags = Watched(0)

  return function() {
    let sf = stateFlags.get()
    let color = sf & S_ACTIVE ? Active
      : sf & S_HOVER ? ButtonHover
      : Inactive

    return {
      watch = stateFlags
      rendObj = ROBJ_TEXT
      behavior = Behaviors.Button
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
      }
      text
      color
      group
      children = {
        rendObj = ROBJ_FRAME
        borderWidth = const [0,0,2,0]
        color
        group
        size = FLEX
        pos = const [0, 2]
      }.__update(params?.childParams ?? {})
      onClick = @() openUrl(link ?? text)
      onElemState = @(newSF) stateFlags.set(newSF)
    }.__update(fontBody, params)
  }
}

return url
