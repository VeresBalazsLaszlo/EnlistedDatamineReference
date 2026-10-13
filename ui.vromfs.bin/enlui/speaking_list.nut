import "%ui/hud/state/voice_chat.nut" as speakingPlayers
import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/helpers/remap_nick.nut" import remap_others
from "%ui/state/safeArea.nut" import safeAreaHorPadding, safeAreaVerPadding
from "%ui/ui_library.nut" import *

const speakingColor = Color(0, 255, 0)
let speakingIcon = faComp("volume-up", {
  vplace = ALIGN_BOTTOM
  color = speakingColor
  transform = true
  animations = [
    { prop=AnimProp.scale, from=[1.2, 1.2], duration=0.1, play=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=0, to=1, duration=0.1, play=true, easing=OutCubic }
    { prop=AnimProp.scale, to=[0, 0], duration=0.1, playFadeOut=true, easing=OutCubic }
    { prop=AnimProp.opacity, from=1, to=0, duration=0.1, playFadeOut=true, easing=OutCubic }
  ]
  fontSize = hdpx(12)
})

function mkSpeaker(name) {
  return {
    flow = FLOW_HORIZONTAL
    valing = ALIGN_BOTTOM
    gap = fsh(0.2)
    children = [
      speakingIcon
      {
        color = speakingColor
        text = name
        rendObj = ROBJ_TEXT
      }.__update(fontSub, {fontSize = hdpx(12)})
    ]
  }
}

function mapTable(table, func= @(v) v){
  let ret = []
  foreach (k, _ in table)
    ret.append(func(k))
  return ret
}

return @() {
  flow = FLOW_VERTICAL
  gap = fsh(0.2)
  margin = [safeAreaVerPadding.get(), hdpx(10) + safeAreaHorPadding.get()]
  hplace = ALIGN_LEFT
  vplace = ALIGN_CENTER
  rendObj = ROBJ_WORLD_BLUR
  zOrder = Layers.Tooltip
  size = SIZE_TO_CONTENT
  watch = [speakingPlayers, safeAreaHorPadding, safeAreaVerPadding]
  children = mapTable(speakingPlayers.get(), @(name) mkSpeaker(remap_others(name)))
}
