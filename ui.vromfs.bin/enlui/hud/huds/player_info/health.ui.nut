import "%ui/hud/huds/player_info/mk_health_bar.nut" as healthBar
from "%ui/hud/state/health_state.nut" import hp, maxHp, scaleHp
from "%ui/hud/huds/player_info/style.nut" import barHeight, barWidth
from "%ui/ui_library.nut" import *

let { hitAnimTrigger } = require("%ui/hud/state/hit_anim_trigger_es.nut")


maxHp.subscribe(function(maxHpValue) {
  if (maxHpValue > 0 && hp.get() > 0)
    anim_start("hero_max_hp_changed")

})
let maxHpTrigger = {}
let health = @() {
  watch = [hp, maxHp, scaleHp]
  size = [barWidth, barHeight]
  valign = ALIGN_BOTTOM
  flow = FLOW_VERTICAL
  children = healthBar({hp = hp.get(), maxHp = maxHp.get(),
    scaleHp = scaleHp.get(), hitTrigger=hitAnimTrigger, maxHpTrigger
  })
}
return health
