from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/ui_library.nut" import *

function centeredText(text, options={}) {
  return {
    rendObj = ROBJ_TEXT
    text
    key = options?.key ?? text

    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
  }.__update(fontHeading2)
}


return centeredText
