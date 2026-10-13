import "%ui/hud/state/session_id.nut" as sessionId
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/ui_library.nut" import *

return function(){
  return {
    text = sessionId.get()
    rendObj = ROBJ_TEXT
    opacity = 0.5
    color = Color(120,120,120, 100)
    watch = sessionId
  }.__update(fontSub)
}