import "%ui/hud/state/machinegunner_state.nut" as isMachinegunner
import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed, mkEcsComputedEidMap
from "%ui/hud/state/health_state.nut" import isAlive, isDowned
from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/hud/state/local_player.nut" import localPlayerEid, localPlayerTeam
from "team" import TEAM_UNASSIGNED
from "%ui/ui_library.nut" import *

let heroGunEid = mkEcsComputed({
  comps = [["human_weap__currentGunEid", ecs.TYPE_EID]]
  comps_rq = ["hero"]
  defVal = ecs.INVALID_ENTITY_ID
})



let buildingGuns = mkEcsComputedEidMap({
  comps = [
    ["currentPreviewId", ecs.TYPE_INT],
    ["previewTemplate", ecs.TYPE_STRING_LIST],
    ["buildingLimits", ecs.TYPE_INT_LIST],
  ]
})
let heroGun = Computed(@() buildingGuns.get()?[heroGunEid.get()])

let buildingTemplates = Computed(@() heroGun.get()?.previewTemplate ?? [])

let heroSquadEid = mkEcsComputed({
  comps = [["squad_member__squad", ecs.TYPE_EID]]
  comps_rq = ["hero"]
  defVal = ecs.INVALID_ENTITY_ID
})


let squadUnlocks = mkEcsComputedEidMap({ comps = [["buildings__unlockIds", ecs.TYPE_INT_LIST]] })
let buildingUnlocks = Computed(@() squadUnlocks.get()?[heroSquadEid.get()] ?? [])

let availableBuildings = mkEcsComputed({
  comps = [["availableBuildings", ecs.TYPE_INT_LIST]]
  comps_rq = ["player"]
  comps_filter = [["is_local", ecs.TYPE_BOOL]]
  filter = "is_local"
  defVal = []
})
let availableStock = mkEcsComputed({
  comps = [["stockOfBuilderCapabilities", ecs.TYPE_FLOAT]]
  comps_rq = ["hero"]
  defVal = 0.0
})
let buildingPrices = Computed(function() {
  let previewCostRequirements = []
  let previewAllowRecreates = []
  foreach (templateName in buildingTemplates.get()) {
    let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(templateName)
    if (template == null) {
      
      previewCostRequirements.append(0.0)
      previewAllowRecreates.append(false)
      continue
    }
    let price = template.getCompValNullable("buildingCost")
    let destroySimilarBuilding = template.getCompValNullable("destroySimilarBuilding") != null
    previewCostRequirements.append(price ?? 0.0)
    previewAllowRecreates.append(destroySimilarBuilding)
  }
  return { previewCostRequirements, previewAllowRecreates }
})
let requirePrice = Computed(@() buildingPrices.get().previewCostRequirements)
let buildingLimits = Computed(@() heroGun.get()?.buildingLimits ?? [])
let selectedBuildingAllowRepair = Watched(false)
let buildingRepairText = Watched("hud/resupply_cannon")
let buildingAllowRecreates = Computed(@() buildingPrices.get().previewAllowRecreates)
let isBuildingToolEquipped = Computed(@() heroGun.get() != null)
let isBuildingAlive = Watched(true)
let canInteractWithDeadBuilding = Watched(false)
let isBuildingToolAvailable = mkEcsComputed({
  comps = [["engieer__buildingToolAvailable", ecs.TYPE_BOOL]]
  comps_filter = [["is_local", ecs.TYPE_BOOL]]
  filter = "is_local"
  defVal = true
})
let isBuildingToolMenuAvailable = Computed(@() isBuildingToolAvailable.get() && isBuildingToolEquipped.get() && isAlive.get() &&
  !isDowned.get() && !inVehicle.get() && !isMachinegunner.get())
let selectedBuildingName = Watched()
let selectedBuildingEid = Watched()
let selectedDestroyableObjectName = Watched()
let buildingPreviewId = Computed(@() heroGun.get()?.currentPreviewId)


let selectedBuildingQuery = ecs.SqQuery("selectedBuildingQuery", {
  comps_ro = [
    ["building_menu__text", ecs.TYPE_STRING],
    ["fortification_repair__costPercent", ecs.TYPE_FLOAT, null],
    ["fortification_repair__text", ecs.TYPE_STRING, "hud/resupply_cannon"],
    ["isAlive", ecs.TYPE_BOOL, true],
    ["undestroyableBuilding", ecs.TYPE_TAG, null],
    ["building__canDismantle", ecs.TYPE_TAG, null],
    ["fortification__canRepairDead", ecs.TYPE_TAG, null],
    ["additiveBuildNeedRepair", ecs.TYPE_BOOL, true],
    ["buildByPlayer", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
    ["builder_info__team", ecs.TYPE_INT, TEAM_UNASSIGNED],
    ["undestroyableyByTeammates", ecs.TYPE_TAG, null],
  ]
})

ecs.register_es("ui_building_selected_object_es",
  {
    [["onChange", "onInit"]] = function (_eid, comp) {
      let selectedObject = comp["human_use_object__selectedBuilding"]
      local name = null
      local allowRepair = false
      local alive = true
      local canBeDestroyed = false
      local fortificationRepairText = "hud/resupply_cannon"
      local canRepairDead = false
      selectedBuildingQuery(selectedObject, function(_eid, objComp) {
        name = objComp["building_menu__text"]
        allowRepair = objComp["additiveBuildNeedRepair"] && (objComp["fortification_repair__costPercent"] != null)
        alive = objComp["isAlive"]
        canRepairDead = objComp["fortification__canRepairDead"] != null
        fortificationRepairText = objComp["fortification_repair__text"]
        canBeDestroyed = objComp.building__canDismantle != null && objComp.undestroyableBuilding == null
        && (objComp.buildByPlayer == localPlayerEid.get() || objComp.builder_info__team != localPlayerTeam.get() || objComp.undestroyableyByTeammates == null)
      })
      selectedBuildingName.set(name)
      selectedDestroyableObjectName.set(canBeDestroyed ? name : null)
      selectedBuildingAllowRepair.set(allowRepair)
      isBuildingAlive.set(alive)
      canInteractWithDeadBuilding.set(canRepairDead)
      buildingRepairText.set(fortificationRepairText)
      selectedBuildingEid.set(selectedObject)
    },
  },
  {
    comps_track = [["human_use_object__selectedBuilding", ecs.TYPE_EID]],
    comps_ro = [["human_weap__currentGunEid", ecs.TYPE_EID]],
    comps_rq = ["hero"]
  }
)

ecs.register_es("ui_additive_build_need_repair_additive_es",
  {
    [["onChange", "onInit"]] = function (eid, comp) {
      if (selectedBuildingEid.get() == eid) {
        selectedBuildingAllowRepair.set(comp["additiveBuildNeedRepair"])
      }
    }
  },
  {
    comps_track = [["additiveBuildNeedRepair", ecs.TYPE_BOOL]],
  }
)



let capzoneDistPreview = mkEcsComputed({
  comps = [["preview__lastCheckPos", ecs.TYPE_POINT3]]
  comps_no = ["onlyForEngineer"]
})
let showCapzonesDistForPreview = Computed(@() capzoneDistPreview.get() != null)

return {
  buildingTemplates
  buildingUnlocks
  requirePrice
  availableStock
  isBuildingToolMenuAvailable
  selectedBuildingName
  selectedDestroyableObjectName
  selectedBuildingAllowRepair
  buildingPreviewId
  buildingAllowRecreates
  availableBuildings
  buildingLimits
  isBuildingAlive
  buildingRepairText
  canInteractWithDeadBuilding
  showCapzonesDistForPreview
}
