from "settings" import get_setting_by_blk_path
from "dagor.system" import DBGLEVEL
from "%ui/style/fontsStyle.nut" import fontSub
from "daRg" import gui_scene
from "%ui/style/designConst.nut" import defTxtColor

if (fontSub!=null) {
  gui_scene.setConfigProps({
    defaultFont = fontSub?.font ?? gui_scene.config.defaultFont
    defaultFontSize = fontSub?.fontSize ?? gui_scene.config.defaultFontSize
    defTextColor = defTxtColor
  })
}

gui_scene.setConfigProps({
  reportNestedWatchedUpdate = (DBGLEVEL > 0) ? true : get_setting_by_blk_path("debug/reportNestedWatchedUpdate") ?? false
  kbCursorControl = true
  gamepadCursorSpeed = 1.85
  

  gamepadCursorNonLin = 0.5
  gamepadCursorHoverMinMul = 0.07
  gamepadCursorHoverMaxMul = 0.8
  gamepadCursorHoverMaxTime = 1.0
  
  

  
  
  clickRumbleLoFreq = 0
  clickRumbleHiFreq = 0.8
  clickRumbleDuration = 0.04
})
