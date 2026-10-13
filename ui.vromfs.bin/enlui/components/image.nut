from "%ui/ui_library.nut" import *
from "types" import Array, String

function image(val, params={}, addchildren = null) {

  local children = params?.children
  if (children && !(children instanceof Array))
    children = [children]
  if (addchildren && children) {
    if (addchildren instanceof Array)
      children.extend(addchildren)
    else
      children.append(addchildren)
  }

  if (val instanceof String)
    val=Picture(val) 

  return {
    rendObj = ROBJ_IMAGE
    image = val
    size=SIZE_TO_CONTENT
  }.__update(params, {children})
}

return image