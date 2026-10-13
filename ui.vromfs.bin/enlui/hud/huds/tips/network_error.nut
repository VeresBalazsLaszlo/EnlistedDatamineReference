from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/hud/state/network.nut" import connectivity
from "%dngscripts/sound_system.nut" import sound_play
from "connectivity" import CONNECTIVITY_OK, CONNECTIVITY_NO_PACKETS
from "%ui/ui_library.nut" import *

connectivity.subscribe(function(value) {
  if (value == CONNECTIVITY_NO_PACKETS)
    sound_play("ui/network_error")
})

const color0 = Color(200,40,40,110)
const color1 = Color(200,200,40,180)
let msgDisrupted = freeze({
  rendObj = ROBJ_TEXT
  margin = fsh(1)
  text = loc("hud/NetworkDisrupted")
  color = Color(200,40,40,110)
  hplace = ALIGN_CENTER
  pos = const [0, sh(15)]

  transform = true

  animations = [
    { prop=AnimProp.scale, from=[0,1], to=[1,1], duration=0.25, play=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=0, to=1, duration=0.15, play=true, easing=OutCubic }
    { prop=AnimProp.scale, from=[1,1], to=[0,1], duration=0.25, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.color, from=color0, to=color1, duration=1.0, play=true, loop=true, easing=CosineFull }
  ]
}.__update(fontHeading2))

function root() {
  return {
    key = "network-state"
    size = FLEX
    watch = connectivity
    children = connectivity.get() != CONNECTIVITY_OK ? msgDisrupted : null
  }
}


return root
