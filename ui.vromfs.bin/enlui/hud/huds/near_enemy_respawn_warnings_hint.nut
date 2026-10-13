from "%ui/hud/state/near_enemy_respawn_warnings.nut" import displayNearEnemyRespawnWarning, displayNearEnemyRespawnWarningDamage
from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/ui_library.nut" import *

function nearEnemyRespawnHint () {
  let watch = displayNearEnemyRespawnWarning
  if (!displayNearEnemyRespawnWarning.get())
    return { watch = watch }

  return {
    watch = watch
    behavior = Behaviors.TextArea
    color = Color(255,180,180,200)
    rendObj = ROBJ_TEXTAREA
    halign = ALIGN_CENTER
    margin = fsh(20)
    text = loc("nearEnemyRespawn")
  }.__update(fontHeading2)
}

function nearEnemyRespawnDamageHint () {
  let watch = displayNearEnemyRespawnWarningDamage
  if (!displayNearEnemyRespawnWarningDamage.get())
    return { watch = watch }

  return {
    watch = watch
    behavior = Behaviors.TextArea
    color = Color(255,180,180,200)
    rendObj = ROBJ_TEXTAREA
    halign = ALIGN_CENTER
    margin = fsh(20)
    text = loc("nearEnemyRespawnDamage")
  }.__update(fontHeading2)
}

return {
  nearEnemyRespawnHint
  nearEnemyRespawnDamageHint
}