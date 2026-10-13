from "%ui/components/decoratorsPresentation.nut" import frameNick
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/ui_library.nut" import *

let statusIconSize = fontSub.fontSize.tointeger()

let mkStatusImg = @(icon, color) {
  rendObj = ROBJ_IMAGE
  size = [statusIconSize, statusIconSize]
  color
  image = Picture("ui/skin#{0}:{1}:{1}".subst(icon, statusIconSize))
}

let memberName = @(name, frame = "") {
  rendObj = ROBJ_TEXT
  text = frameNick(name, frame)
}.__update(fontSub)

return {
  memberName
  mkStatusImg
}