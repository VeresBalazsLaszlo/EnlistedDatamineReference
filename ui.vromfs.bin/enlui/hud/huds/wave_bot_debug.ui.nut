from "%ui/ui_library.nut" import *
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/designConst.nut" import scoreNestGradientL
from "%ui/hud/huds/wave_bot_spawner_state.nut" import botsWaitingCount1, nextWaveSpawnTime1, botsWaitingCount2, nextWaveSpawnTime2, curGroupActive
from "%ui/helpers/timers.nut" import mkCountdownTimerPerSec

let isVisible = mkWatched(persist, "waveBotDebugVisible", false)
console_register_command(@() isVisible.modify(@(v) !v), "ui.wave_bot_debug_toggle")

const labelColor = 0xFFFFAA33

let nextWaveTimeLeft1 = mkCountdownTimerPerSec(nextWaveSpawnTime1)
let nextWaveTimeLeft2 = mkCountdownTimerPerSec(nextWaveSpawnTime2)

let mkText = @(txt, override = {}) {
  rendObj = ROBJ_TEXT
  text = txt
  color = labelColor
}.__merge(fontBody).__merge(override)

function mkValueRow(label, watched) {
  return @() {
    watch = [watched]
    size = const [FLEX, SIZE_TO_CONTENT]
    flow = FLOW_HORIZONTAL
    gap = hdpx(8)
    children = [
      mkText(label)
      mkText($"{watched.get()}")
    ]
  }
}

function waveBotDebugUi() {
  return {
    watch = [isVisible, botsWaitingCount1, nextWaveTimeLeft1, botsWaitingCount2, nextWaveTimeLeft2]
    children = !isVisible.get() ? null : {
      size = const [hdpx(280), SIZE_TO_CONTENT]
      padding = const [fsh(1.1), fsh(2)]
      margin = fsh(1.5)
      rendObj = ROBJ_IMAGE
      image = scoreNestGradientL
      color = 0xFF000000
      flow = FLOW_VERTICAL
      gap = fsh(0.5)
      children = [
        mkValueRow("Current active group:", curGroupActive)
        mkValueRow("team1 squads:", botsWaitingCount1)
        mkValueRow("team1 next spawn:", nextWaveTimeLeft1)
        mkValueRow("team2 squads:", botsWaitingCount2)
        mkValueRow("team2 next spawn:", nextWaveTimeLeft2)
      ]
    }
  }
}

return waveBotDebugUi
