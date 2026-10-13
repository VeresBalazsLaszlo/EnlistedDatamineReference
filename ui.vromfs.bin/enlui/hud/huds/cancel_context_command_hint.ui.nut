from "%enlSqGlob/dasenums.nut" import SquadOrder
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/hud/menus/big_map.nut" import showBigMap
from "%ui/hud/state/hero_squad.nut" import heroSquadNumAliveMembers, heroSquadOrderType, hasPersonalOrder
from "%ui/hud/state/squad_members.nut" import watchedHeroSquadMembers, isPersonalContextCommandMode
from "%ui/ui_library.nut" import *

let hasAnySquadmatePersonalOrder = @(members)
  members.findvalue(@(m) m.isAlive && m.isPersonalOrder) != null

let tipLocId = Computed(@()
  showBigMap.get() || inVehicle.get() || heroSquadNumAliveMembers.get() <= 1 ? null
    : (isPersonalContextCommandMode.get() && hasAnySquadmatePersonalOrder(watchedHeroSquadMembers.get()))
      ? "squad_orders/cancel_personal_order"
    : (heroSquadOrderType.get() != SquadOrder.ESO_FOLLOW_ME || hasPersonalOrder.get())
      ? "squad_orders/cancel_all_orders"
    : null
)

return function() {
  let watch = tipLocId
  if (tipLocId.get() == null)
    return { watch }

  return {
    watch
    children = tipCmp({
      text = loc(tipLocId.get())
      inputId = "Human.CancelContextCommand"
      style = fontSub
    })
  }
}
