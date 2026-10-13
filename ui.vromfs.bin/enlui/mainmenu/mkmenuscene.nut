from "%sqstd/math.nut" import lerp
from "%ui/mainMenu/mainmenu.style.nut" import navHeight
from "%ui/style/designConst.nut" import gap
from "%ui/state/safeArea.nut" import safeAreaAmount, safeAreaBorders
from "%ui/ui_library.nut" import *

let menuContentAnimation = const [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.5, play = true, easing = OutCubic }
  { prop = AnimProp.translate, from =[hdpx(150), 0], play = true, to = [0, 0], duration = 0.2, easing = OutQuad }
]

let lerp_top_margin = @(v) lerp(0.9, 1.0, 0.3, 1, v)
let lerp_bottom_margin = @(v) lerp(0.9, 1.0, 1.15, 1, v)


let mainMenuGap = @() {
  watch = safeAreaAmount
  size = [0, fsh(2) * lerp_top_margin(safeAreaAmount.get())]
}

let mkMenuScene = @(headerBar, content, bottomBar) function() {
  let borders = safeAreaBorders.get()
  let saAmount = safeAreaAmount.get()
  return {
    watch = [safeAreaBorders, safeAreaAmount]
    size = const [sw(100), sh(100)]
    flow = FLOW_VERTICAL
    gap = mainMenuGap
    hplace = ALIGN_CENTER
    behavior = DngBhv.MenuCameraControl
    children = [
      {
        size = [FLEX, navHeight]
        margin = [borders[0], 0, 0, 0]
        padding = [0, max(borders[1], fsh(1)), 0, max(borders[3], fsh(0.5))]
        children = headerBar
      }
      {
        size = FLEX
        flow = FLOW_VERTICAL
        padding = [0, borders[1], borders[2]*lerp_bottom_margin(saAmount), borders[3]]
        gap = gap
        children = [
          content
          bottomBar
        ]
      }
    ]
  }
}

return freeze({
  mkMenuScene
  menuContentAnimation
  mainMenuGap
})
