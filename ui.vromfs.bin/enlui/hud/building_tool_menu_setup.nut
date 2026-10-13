import "%ui/hud/components/building_tool_menu_item_ctor.nut" as mkPieItemCtor
import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/sqevents.nut" import mkCmdSelectBuildingType
from "%ui/hud/state/building_tool_menu_state.nut" import buildingToolMenuItems, showBuildingToolMenu, elemSize
from "%ui/hud/state/building_tool_state.nut" import isBuildingToolMenuAvailable, buildingUnlocks, buildingTemplates, availableBuildings, availableStock, requirePrice, buildingAllowRecreates
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")

let showMsg = @(text) playerEvents.pushEvent({ text = text, ttl = 5 })

function selectBuildingType(index) {
  let weapEid = ecs.obsolete_dbg_get_comp_val(controlledHeroEid.get(), "human_weap__currentGunEid", ecs.INVALID_ENTITY_ID)
  ecs.client_send_event(weapEid, mkCmdSelectBuildingType({index}))
}

let svg = memoize(function(img) {
  return "!ui/uiskin/{0}.svg:{1}:{1}:K".subst(img, elemSize.get()[1])
})

function updateBuildingsPie (templates) {
  buildingToolMenuItems.set(templates.map(function (templateName, index) {
    let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(templateName)

    let blockedByUnlock = !buildingUnlocks.get().contains(index)
    if (blockedByUnlock)
      return null
    let text = template?.getCompValNullable?("building_menu__text") ?? ""
    let imageName = template?.getCompValNullable?("building_menu__image")
    let image = imageName ? svg(imageName) : null
    let buildCount = Computed(@() availableBuildings.get()?[index] ?? 0)
    let allowRecreate = Computed(@() buildingAllowRecreates.get()?[index] ?? false)

    let buildingCostText = Computed(@() "\n\n".concat(
      loc("buildingMenu/resourcesRequire", {count=requirePrice.get()?[index] ?? 0}),
      loc("buildingMenu/availableResources", {count=availableStock.get()}))
    )

    let hintText = Computed(@() "\n\n".concat(loc(text), buildingCostText.get()))
    let noRequirementResources = Computed(@() (requirePrice.get()?[index] ?? 0) > availableStock.get())
    return {
      action = @() selectBuildingType(index)
      disabledAction = @() showMsg(noRequirementResources.get() ? loc("msg/buildTypeLimitResourse") : loc("msg/buildTypeLimitReached"))
      text = hintText
      disabledtext = Computed(@() "{text} \n\n {buildingCostText}".subst({
        text=loc("buildingMenu/buildTypeLimitReached"),
        buildingCostText=buildingCostText.get()}))
      available = Computed(@() (allowRecreate.get() || buildCount.get() > 0) && !noRequirementResources.get())
      closeOnClick = true
      ctor = mkPieItemCtor(index, image, elemSize.get())
    }
  }).filter(@(v) v != null))
  if (templates.len() == 0)
    showBuildingToolMenu.set(false)
}

buildingUnlocks.subscribe(@(_) updateBuildingsPie(buildingTemplates.get()))

buildingTemplates.subscribe(updateBuildingsPie)


isBuildingToolMenuAvailable.subscribe(function(isAvailable) { if (!isAvailable) showBuildingToolMenu.set(false) })
