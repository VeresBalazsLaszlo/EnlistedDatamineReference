from "%ui/style/fontsStyle.nut" import fontBody, fontHeading2
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR
from "%ui/ui_library.nut" import *
from "types" import Table, Array, String

function text(txt, params={}) {
  return {
    rendObj = ROBJ_TEXT
    margin = hdpx(2)
    color = DEFAULT_TEXT_COLOR
    text = txt
  }.__update(fontHeading2, params)
}

function dtext(val, params={}, addchildren = null) {
  if (val == null)
    return null
  if (val instanceof Table) {
    params = val.__merge(params)
    val = params?.text
  }
  local children = params?.children
  if (children && !(children instanceof Array))
    children = [children]
  if (addchildren && children) {
    if (addchildren instanceof Array)
      children.extend(addchildren)
    else
      children.append(addchildren)
  }

  let watch = params?.watch
  local watchedtext = false
  local txt = ""
  if (val instanceof String)  {
    txt = val
  }
  if (isObservable(val)) {
    txt = val.get()
    watchedtext = true
  }
  let ret = {
    rendObj = ROBJ_TEXT
    size = SIZE_TO_CONTENT
    halign = ALIGN_LEFT
  }.__update(fontBody, params, {text = txt, children})
  if (watch || watchedtext)
    return @() ret
  else
    return ret
}

return {text, dtext}