import "%ui/hud/state/paratroopers_supply_slots.nut" as paratroopersSupplySlots
import "%ui/hud/components/paratroopers_supply_menu_item_ctor.nut" as mkPieItemCtor
import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "dasevents" import sendNetEvent, CmdOpenSupplyMenu, CmdCloseSupplyMenu, RequestApplySupplyScheme
from "%ui/ui_library.nut" import *

let radius = Watched(hdpx(365))
let elemSize = Computed(@() [(radius.get()*0.35).tointeger(),(radius.get()*0.35).tointeger()] )
let showSupplyMenu = mkWatched(persist, "showSupplyMenu", false)

let selectedSupplyMenuItemIdx = Watched(null)
let selectedBox = Watched(ecs.INVALID_ENTITY_ID)
let selectScheme = @(index) sendNetEvent(localPlayerEid.get(), RequestApplySupplyScheme({boxEid=selectedBox.get(), index}))

let mkMenuItem = @(slot, index) {
  action = @() selectScheme(index)
  text = slot?.text != null ? loc(slot?.text) : index
  ctor = mkPieItemCtor(slot)
}

let squadSupplyMenuItems = Computed(@() paratroopersSupplySlots.get().map(mkMenuItem))

ecs.register_es("paratroopers_supply_menu_ui_control",
  {
    [CmdOpenSupplyMenu] = function(evt, _eid, _comp) {
      showSupplyMenu.set(true)
      selectedBox.set(evt.boxEid)
    },
    [CmdCloseSupplyMenu] = function(evt, _eid, _comp) {
      showSupplyMenu.set(false)
      if (!evt.needApplyPreset) {
        selectedSupplyMenuItemIdx.set(null)
      }
    }
  },
  { comps_rq = ["localPlayer"] },
  { tags = "ui" })

return {
  squadSupplyMenuItems
  showSupplyMenu
  selectedSupplyMenuItemIdx
  radius
  elemSize
}
