import "%ui/hud/state/engineers_in_squad.nut" as engineersInSquad
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/dasenums.nut" import ContextCommand
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/ui_library.nut" import *

let contextCommandState = require("%ui/hud/state/contextCommandState.nut")

return function () {
  local tip = null
  let orderType = contextCommandState.orderType.get()
  let orderUseEntity = contextCommandState.orderUseEntity.get()
  local text = null;

  if (orderType == ContextCommand.ECC_DEFEND_POINT) {
    if (orderUseEntity != ecs.INVALID_ENTITY_ID) {
      let capZoneTag = ecs.obsolete_dbg_get_comp_val(orderUseEntity, "capzone")
      if (capZoneTag != null) {
        let zoneName = loc(ecs.obsolete_dbg_get_comp_val(orderUseEntity, "capzone__caption", ""), "")
        if (zoneName.len() != 0) {
          let zoneTitle = ecs.obsolete_dbg_get_comp_val(orderUseEntity, "capzone__title", "")
          text = loc("hud/control_zone_name", {tag = zoneTitle, name = zoneName})
        } else
          text = loc("hud/control_zone")
      } else 
        text = loc("squad_orders/control_vehicle")
    } else {
      text = loc("squad_orders/defend_point")
    }
  }
  else if ( orderType ==  ContextCommand.ECC_CANCEL)
    text = loc("squad_orders/cancel_order")
  else if ( orderType ==  ContextCommand.ECC_REVIVE)
    text = loc("squad_orders/revive_me")
  else if ( orderType ==  ContextCommand.ECC_BRING_AMMO)
    text=loc("squad_orders/bring_ammo")
  else if ( orderType ==  ContextCommand.ECC_ATTACK_TARGET)
    text=loc("squad_orders/attack_target")
  else if ( orderType ==  ContextCommand.ECC_BUILD) {
    let isPreview = ecs.obsolete_dbg_get_comp_val(orderUseEntity, "builder_preview") != null
    text = engineersInSquad.get() > 1 || !isPreview
      ? loc(isPreview ? "squad_orders/build" : "squad_orders/dismantle")
      : null
  }
  else if ( orderType ==  ContextCommand.ECC_PLANT_BOMB)
    text=loc("squad_orders/plant_bomb")
  else if ( orderType ==  ContextCommand.ECC_DEFUSE_BOMB)
    text=loc("squad_orders/defuse_bomb")

  if (text != null) {
    tip = tipCmp({
      text
      inputId = "Human.ContextCommand"
      style = fontSub
    })
  }

  return {
    watch = [
      contextCommandState.orderType
      contextCommandState.orderUseEntity
      engineersInSquad
    ]

    children = tip
  }
}
