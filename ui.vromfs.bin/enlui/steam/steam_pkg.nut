from "math" import round
from "%ui/ui_library.nut" import *

let logoSize = [sw(10), round(sw(10) * (66.0 / 210.0))]

let mkSteamLogo = @(pos) {
  rendObj = ROBJ_IMAGE
  pos
  size = logoSize
  image = Picture($"!ui/uiskin/steam/steam_logo.svg:{logoSize[0]}:{logoSize[1]}:K")
  keepAspect = KEEP_ASPECT_FIT
}

return {
  mkSteamLogo
}
