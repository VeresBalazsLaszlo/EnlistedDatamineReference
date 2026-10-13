from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/state/hero_weapons.nut" import curWeaponFiringMode
from "%ui/hud/huds/player_info/style.nut" import blurBack, DEFAULT_TEXT_COLOR
from "%ui/ui_library.nut" import *

let heightFireMode = calc_str_box("auto", fontSub)[1]


let firingModeTxtCmp = @(mode) {
  padding=const [0,hdpx(2),0,hdpx(2)]
  rendObj = ROBJ_TEXT
  minHeight=heightFireMode
  text = loc("firing_mode/{0}".subst(mode))
  color = DEFAULT_TEXT_COLOR
}.__update(fontSub)

let firingModeCmpStub = freeze({
  size = [0, calc_comp_size(firingModeTxtCmp("A"))[1]]
})

let firingModeCmp = @(){
  size = SIZE_TO_CONTENT
  watch = curWeaponFiringMode
  children = (curWeaponFiringMode.get() != "") ? [
    blurBack
    firingModeTxtCmp(curWeaponFiringMode.get())
  ] : firingModeCmpStub
}

return {
  firingModeCmp
}