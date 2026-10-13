from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/ui_library.nut" import *

return {
  navBottomBarHeight = hdpx(56)
  navHeight = calc_comp_size({size=SIZE_TO_CONTENT children={margin = const [fsh(1), 0] size=[0, fontH(100)] rendObj=ROBJ_TEXT}.__update(fontHeading2)})[1]
}