import "%ui/components/mkPieMenuHoldable.nut" as mkPieMenu
import "%dngscripts/ecs.nut" as ecs
from "dasevents" import CmdUpdateArtilleryMenu, CmdArtilleryMenu, RequestOpenArtilleryMap
from "%ui/hud/menus/artillery_radio_map_shell_type.nut" import currentShellTypeIndex
from "%dngscripts/common_queries.nut" import get_controlled_hero
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/style/designConst.nut" import disabledTxtColor, textBgBlurColor
from "%ui/hud/state/pie_menu_state.nut" import pieMenuItems
from "%ui/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")

let radius = Watched(hdpx(365))
let elemSize = Computed(@() array(2, (radius.get() * 0.35).tointeger()))
let iconSize = Computed(@() array(2, (radius.get() * 0.23).tointeger()))

let artilleryMenuSlotsStates = Watched([])
let showArtilleryMenu = Watched(false)
let artilleryMenuAvaialable = Watched(false)

function openArtilleryMapAction(index){
  currentShellTypeIndex.set(artilleryMenuSlotsStates.get()[index].shellType)
  showArtilleryMenu.set(false)
  let hero = get_controlled_hero()
  if (hero != ecs.INVALID_ENTITY_ID)
    ecs.g_entity_mgr.sendEvent(hero, RequestOpenArtilleryMap())
}

ecs.register_es("artillery_menu_ui_control",
  { [CmdArtilleryMenu] = @() showArtilleryMenu.set(!showArtilleryMenu.get()) },
  { comps_rq = ["localPlayer"] },
  { tags = "ui" }
)

ecs.register_es("artillery_menu_slots_state",
  {
    [[CmdUpdateArtilleryMenu]] = function(_eid, comp){
      let res = []
      let shellTypes = comp.artillery_menu__index.getAll() ?? []
      let coolDowns = comp.artillery_menu__cooldown.getAll() ?? []
      let names = comp.artillery_menu__names.getAll() ?? []
      let icons = comp.artillery_menu__icons.getAll() ?? []
      let localization = comp.artillery_menu__localization.getAll() ?? []
      artilleryMenuAvaialable.set(comp.artillery_menu__active)
      for (local idx = 0; idx < names.len(); idx++) {
        res.append({
          shellType = shellTypes[idx]
          coolDown = coolDowns[idx]
          name = names[idx]
          icon = icons[idx]
          localization = localization[idx]
        })
      }
      artilleryMenuSlotsStates.set(res)
    },
  },
  {
    comps_ro = [
      ["artillery_menu__active", ecs.TYPE_BOOL],
      ["artillery_menu__index", ecs.TYPE_INT_LIST],
      ["artillery_menu__cooldown", ecs.TYPE_FLOAT_LIST],
      ["artillery_menu__names", ecs.TYPE_STRING_LIST],
      ["artillery_menu__icons", ecs.TYPE_STRING_LIST],
      ["artillery_menu__localization", ecs.TYPE_STRING_LIST]
    ],
    comps_rq = ["localPlayer"]
  },
)

let mkIcon = @(slot) @() {
  watch = iconSize
  rendObj = ROBJ_IMAGE
  size = iconSize.get()
  keepAspect = KEEP_ASPECT_FIT
  imageHalign = ALIGN_CENTER
  imageValign = ALIGN_CENTER
  color = slot.shellType > -1 ? textBgBlurColor : disabledTxtColor
  image = Picture($"!ui/uiskin/{slot.icon}.svg:{iconSize.get()[0]}:{iconSize.get()[1]}:K")
}

let mkText = @(slot) {
  rendObj = ROBJ_TEXTAREA
  size = const [hdpxi(150), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  behavior = Behaviors.TextArea
  color = slot.shellType > -1 ? textBgBlurColor : disabledTxtColor
  text = loc($"research/{slot.localization}")
  transform = true
}.__update(fontSub)

let mkPieItemCtor = @(slot) @(...) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  children = [
    mkIcon(slot)
    mkText(slot)
  ]
}

let showMsg = @(text) playerEvents.pushEvent({ text = text, ttl = 5 })

let mkMenuItem = @(slot, index) {
  action = @() openArtilleryMapAction(index)
  text = "\n".concat(loc($"research/{slot.localization}"), $"{loc("artillery_menu/cooldown")}: {slot.coolDown} {loc("measureUnits/seconds")}")
  ctor = mkPieItemCtor(slot)
  available = slot.shellType > -1
  disabledtext = "\n".concat(loc($"research/{slot.localization}"), loc("artillery_menu/try_to_call_not_researched_artillery"))
  disabledAction = @() showMsg(loc("artillery_menu/try_to_call_not_researched_artillery") )
}

artilleryMenuSlotsStates.subscribe(function(artilleryMenuSlots) {
  if (artilleryMenuSlots != null)
    pieMenuItems.mutate(@(arr) arr[3] = artilleryMenuSlots.map(mkMenuItem))
})

let artilleryMenuItems = Computed(@() artilleryMenuSlotsStates.get().map(mkMenuItem))

let menu = mkPieMenu({
  actions = artilleryMenuItems
  showPieMenu = showArtilleryMenu
  radius = radius,
  elemSize = elemSize,
  stickNo = 1
})

let artilleryMenu = {
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = menu
  key = "artilleryMenuTabs"
}

return {
  artilleryMenu
  showArtilleryMenu
  artilleryMenuAvaialable
}