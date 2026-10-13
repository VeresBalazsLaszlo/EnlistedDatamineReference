import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%dngscripts/common_queries.nut" import get_controlled_hero
from "dasevents" import CmdOpenRepairMenu, CmdCloseRepairMenu
from "%ui/hud/components/vehicle_repair_menu_item_ctor.nut" import mkPieItemCtor, getIconName
from "%ui/ui_library.nut" import *

let heroVehicleRepairSlots = mkEcsComputed({
  comps = [
    ["dm_parts_repair_inside_ids", ecs.TYPE_UINT16_LIST],
    ["dm_parts_repair_inside_names", ecs.TYPE_STRING_LIST],
    ["dm_state", ecs.TYPE_UINT16_LIST]
  ]
  comps_rq = ["heroVehicle"]
})


let vehicleInsideRepairSlotsStates = Computed(function() {
  let comp = heroVehicleRepairSlots.get()
  if (comp == null)
    return []
  let res = []
  let names = comp.dm_parts_repair_inside_names
  let states = comp.dm_state
  foreach (idx, id in comp.dm_parts_repair_inside_ids) {
    res.append({
      name = names?[idx] ?? "unknown"
      state = states?[id] ?? 0
    })
  }
  return res
})

let radius = Watched(hdpx(365))
let elemSize = Computed(@() [(radius.get()*0.35).tointeger(),(radius.get()*0.35).tointeger()] )
let showRepairMenu = Watched(false)

let repairMenuItemIdx = Watched(null)
let selectScheme = @(index) ecs.g_entity_mgr.sendEvent(get_controlled_hero(), CmdCloseRepairMenu({partId=index}))

let mkMenuItem = @(slot, index) {
  action = @() selectScheme(index)
  text = loc($"xray/part/{getIconName(slot.name)}")
  ctor = mkPieItemCtor(slot)
}

let repairMenuItems = Computed(@() vehicleInsideRepairSlotsStates.get().map(mkMenuItem))

ecs.register_es("vehicle_repair_menu_ui_control",
  {
    [CmdOpenRepairMenu] = function(...) {
      showRepairMenu.set(!showRepairMenu.get())
    },
    [CmdCloseRepairMenu] = function(...) {
      showRepairMenu.set(false)
    }
  },
  { comps_rq = ["hero"] },
  { tags = "ui" })

return {
  repairMenuItems
  showRepairMenu
  repairMenuItemIdx
  radius
  elemSize
}
