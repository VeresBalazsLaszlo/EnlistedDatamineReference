from "%ui/style/fontsStyle.nut" import fontHeading2, fontSub
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR
from "%ui/ui_library.nut" import *
from "types" import Table

function textarea(txt, params={}) {
  if (txt instanceof Table) {
    params = txt
    txt = params?.text
  }
  return {
    size = FLEX_H
    color = DEFAULT_TEXT_COLOR
    text = txt
  }.__update(fontHeading2, params, {
    rendObj=ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
  })
}
function smallTextarea(txt, params={}) {
  if (txt instanceof Table)
    txt = params?.text ?? ""
  return {
    size = FLEX_H
    halign = ALIGN_LEFT
    rendObj=ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text=txt
  }.__update(fontSub, params)
}


return {
  textarea
  smallTextarea
}