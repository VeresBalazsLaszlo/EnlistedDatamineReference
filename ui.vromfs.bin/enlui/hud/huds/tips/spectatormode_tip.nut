from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/state/spectator_state.nut" import isSpectator, spectatingPlayerName
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/ui_library.nut" import *

let spectatingName = Computed(@() isSpectator.get() && spectatingPlayerName.get() != null
  ? spectatingPlayerName.get()
  : null)

function spectatorMode_tip() {
  let res = { watch = [spectatingName, isReplay] }
  if (isReplay.get() || spectatingName.get() == null)
    return res
  return res.__update({
    rendObj = ROBJ_TEXT
    text = spectatingName.get() != null
      ? loc("hud/spectator_target", {user = spectatingName.get()})
      : null
    watch = spectatingName
    margin = hdpx(20)
    fontFx = FFT_GLOW
    fontFxColor = 0xCC000000
    fontFxFactor = min(16, hdpx(16))
  }.__update(fontSub))
}

return spectatorMode_tip
