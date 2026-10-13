from "%ui/hud/state/building_tool_state.nut" import isBuildingToolMenuAvailable, selectedBuildingName, selectedDestroyableObjectName, isBuildingAlive, buildingRepairText, buildingPreviewId, buildingAllowRecreates
  , canInteractWithDeadBuilding, availableBuildings, selectedBuildingAllowRepair
from "%ui/hud/state/enlisted_hero_state.nut" import isRadioMode
from "%ui/hud/state/mortar.nut" import isMortarMode
from "%ui/hud/state/health_state.nut" import isAlive, isDowned
from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/hud/state/building_tool_menu_state.nut" import showBuildingToolMenu
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR, FAIL_TEXT_COLOR
from "%ui/hud/state/fortification_preview_can_be_rotated.nut" import fortificationPreviewCanBeRotated
from "%ui/hud/state/useful_box_state.nut" import usefulBoxHintFull, usefulBoxHintEmpty, isUsefulBoxEmpty, usefulBoxPrice, usefulBoxHintCost
from "%ui/ui_library.nut" import *

function notAbleBuildStructures() {
  let watch = [selectedBuildingName, buildingPreviewId, buildingAllowRecreates, availableBuildings, isBuildingToolMenuAvailable]
  if (!isBuildingToolMenuAvailable.get() || selectedBuildingName.get() != null)
    return { watch }

  if ((availableBuildings.get()?[buildingPreviewId.get()] ?? -1) != 0)
    return { watch }

  let allowRecreate = buildingAllowRecreates.get()?[buildingPreviewId.get()] ?? false
  return {
    watch
    hplace = ALIGN_LEFT
    vplace = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    children = tipCmp({
      text = allowRecreate
        ? loc("building_previous_will_be_destroyed", "The previous building of this type will be destroyed automatically.")
        : loc("building_blocked_by_no_available_buildings_by_type", "Cant build anymore")
      style = { color = FAIL_TEXT_COLOR }
    })
  }
}

function buildStructure() {
  let watch = [isBuildingToolMenuAvailable, showBuildingToolMenu, fortificationPreviewCanBeRotated]
  if (!isBuildingToolMenuAvailable.get() || showBuildingToolMenu.get())
    return { watch }

  return {
    watch
    hplace = ALIGN_CENTER
    vplace = ALIGN_BOTTOM
    flow = FLOW_HORIZONTAL
    children = [
      tipCmp({
        text = loc("hud/build_building", "Build structure")
        inputId = "Human.Shoot"
      })
      tipCmp({
        text = loc("tips/open_building_menu", "Select structure")
        inputId = "HUD.BuildingToolMenu"
      })
      fortificationPreviewCanBeRotated.get()
        ? tipCmp({
            text = loc("tips/mirror_building", "Mirror structure")
            inputId = "Human.RotateBuilding"
          })
        : null
    ]
  }
}

function destroyStructure() {
  let watch = [selectedDestroyableObjectName, inVehicle, isAlive, isDowned, isMortarMode, isRadioMode]
  if (!selectedDestroyableObjectName.get() || inVehicle.get() || !isAlive.get() || isDowned.get()
      || isMortarMode.get() || isRadioMode.get())
    return { watch }

  return {
    watch
    children = tipCmp({
      text = "{0} : {1}".subst(loc("hud/destroy_building"), loc(selectedDestroyableObjectName.get()))
      inputId = "Human.DestroyBuilding"
    })
  }
}

function resupplyCannonStructure() {
  let watch = [selectedBuildingName, inVehicle, isBuildingAlive, buildingRepairText, canInteractWithDeadBuilding,
    isAlive, isDowned, isMortarMode, isRadioMode, isBuildingToolMenuAvailable, selectedBuildingAllowRepair]

  let canInteractWithBuilding = (isBuildingAlive.get() || canInteractWithDeadBuilding.get())
  if (!isBuildingToolMenuAvailable.get() || !selectedBuildingName.get() || inVehicle.get()
      || !canInteractWithBuilding || !isAlive.get() || isDowned.get() || isMortarMode.get()
      || isRadioMode.get() || !selectedBuildingAllowRepair.get())
    return { watch }

  return {
    watch
    children = tipCmp({
      text = "{0} : {1}".subst(loc(buildingRepairText.get()), loc(selectedBuildingName.get()))
      inputId = "Human.RepairBuilding"
    })
  }
}

function useUsefulBox() {
  let watch = [usefulBoxHintFull, usefulBoxHintEmpty, isUsefulBoxEmpty, usefulBoxPrice, usefulBoxHintCost]
  let text = usefulBoxPrice.get() > 0 ? usefulBoxHintCost
    : isUsefulBoxEmpty.get() ? usefulBoxHintEmpty
    : usefulBoxHintFull
  if (!text.get())
    return { watch }

  return {
    watch
    children = [
      tipCmp({
        text = loc(text.get(), { currency = "{star}", price = usefulBoxPrice.get() }) 
        inputId = isUsefulBoxEmpty.get() ? "" : "Human.Use"
        style = { color = isUsefulBoxEmpty.get() ? Color(120, 120, 120, 120) : DEFAULT_TEXT_COLOR }
      })
    ]
  }
}

return [
  notAbleBuildStructures
  buildStructure
  useUsefulBox
  destroyStructure
  resupplyCannonStructure
]
