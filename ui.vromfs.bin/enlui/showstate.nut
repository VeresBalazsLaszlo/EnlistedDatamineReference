import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputedEidMap
from "%ui/sceneWithCamera.nut" import curCamera
from "%ui/soldiers/model/curSoldiersState.nut" import curSoldierGuid
from "%ui/soldiers/model/state.nut" import curVehicle, getSoldierItemSlots, armySquadsById
from "%ui/vehicles/vehiclesListState.nut" import viewVehicle, selectVehParams
from "%ui/vehicles/vehDecorState.nut" import getCurSkinFromTemplate
from "%ui/soldiers/model/config/outfitConfig.nut" import getSquadCamoByVehicle
from "%ui/soldiers/model/selectItemState.nut" import viewItem
from "%ui/soldiers/soldierCustomizationState.nut" import isCustomizationWndOpened
from "%ui/soldiers/squadOutfitPreview.nut" import isOutfitPreviewOpen
from "%ui/soldiers/model/chooseSquadsState.nut" import selectedSquadSoldiers
from "%ui/meta/profile.nut" import campItemsByLink, curCampItems, squadsByArmies
from "%ui/meta/servProfile.nut" import vehCamouflages
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfileLookCfg
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN
from "%ui/soldiers/model/all_items_templates.nut" import itemTypesInSlots
from "%ui/soldiers/model/chooseSoldiersState.nut" import soldiersSquad
from "%ui/ui_library.nut" import *

let curHoveredItem = mkWatched(persist, "curHoveredItem")
let curSelectedItem = mkWatched(persist, "curSelectedItem")


let cameraSceneEntities = mkEcsComputedEidMap({ comps = [["scene", ecs.TYPE_STRING]] })
let cameraScenes = Computed(@() cameraSceneEntities.get().values())

let cameraFovDelta = Watched(0)
function changeCameraFov(delta, minDelta = 0, maxDelta = 0) {
  cameraFovDelta.set(clamp(cameraFovDelta.get() - delta, minDelta, maxDelta))
}

let isVehicleSceneVisible = Computed(function() {
  let { armyId = null, squadId = null } = selectVehParams.get()
  return armyId != null && squadId != null
})

let itemInArmory = Computed(function() {
  let item = viewItem.get() ?? curSelectedItem.get()
  return item?.itemtype != "vehicle" ? item?.gametemplate : null
})

let itemInArmoryAttachments = Computed(function() {
  let res = []
  let item = (viewItem.get() ?? curSelectedItem.get())
  let guid = item?.guid
  if (guid != null)
    foreach (data in getSoldierItemSlots(guid, campItemsByLink.get())) {
      let tpl = data.item?.basetpl
      if (tpl != null)
        res.append(tpl)
    }
  return res
})

let typeWithNormalCameraAngle = {
  medbox = true
  building_tool = true
}

let needWeaponCameraAngle = Computed(function() {
  let { itemtype = null } = viewItem.get() ?? curSelectedItem.get()
  return itemtype in (itemTypesInSlots.get()?.mainWeapon ?? {})
    && itemtype not in typeWithNormalCameraAngle
})

let currentNewItem = Computed(function() {
  let { itemtype = "", gametemplate = null } = curSelectedItem.get()
  return itemtype == "soldier" || itemtype == "vehicle" ? null : gametemplate
})

let currentNewItemAttachments = Computed(function() {
  let { equipScheme = null, slotTemplates = null } = curSelectedItem.get()
  let res = []
  foreach (slot in equipScheme ?? {})
    foreach (item in (slot?.items ?? [])) {
      if (item != null)
        res.append(item)
    }
  foreach (_, gameTpl in slotTemplates ?? {})
    if (gameTpl != null && gameTpl != "")
      res.append(gameTpl)
  return res
})

let currentNewSoldierGuid = Computed(@() curSelectedItem.get()?.itemtype == "soldier" ? curSelectedItem.get()?.guid : null)

let soldierInSoldiers = Computed(@()
  curCamera.get() == "new_items" ? currentNewSoldierGuid.get()
  : isOutfitPreviewOpen.get() ? null
  : curSoldierGuid.get())

let vehicleInVehiclesScene = Computed(@()
  (curSelectedItem.get()?.itemtype == "vehicle" ? curSelectedItem.get() : null)
  ?? viewVehicle.get()
  ?? curCampItems.get()?[curVehicle.get()])

let vehTplInVehiclesScene = Computed(@() vehicleInVehiclesScene.get()?.gametemplate)

let curSquadCamo = Computed(@()
  getSquadCamoByVehicle(vehicleInVehiclesScene.get(), squadsByArmies.get(),
    armySquadsById.get(), gameProfileLookCfg.get()))

let vehDataInVehiclesScene = Computed(@()
  getCurSkinFromTemplate(vehCamouflages.get(), vehicleInVehiclesScene.get(), curSquadCamo.get()))


function getAircraftInfo(template) {
  if (template == null)
    return { isAircraft = false, isFloating = false, isBike = false }

  let templ = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(template)
  return {
    isAircraft = templ?.getCompValNullable("airplane") != null
    isFloating = templ?.getCompValNullable("floating_aircraft") != null
    isBike = templ?.getCompValNullable("bike") != null
  }
}

let squadCampaignVehicleFilter = Computed(function() {
  let { isAircraft, isFloating, isBike } = getAircraftInfo(vehTplInVehiclesScene.get())
  
  return isBike ? "bike"
    : isFloating ? "plane_floating"
    : isAircraft ? "plane"
    : COMMON_CAMPAIGN
})

let sceneCameraSquadFilter = Computed(function() {
  let prefix = soldiersSquad.get() == null ? "main_menu" : "squad"
  let sceneName = $"{prefix}_{squadCampaignVehicleFilter.get()}"
  
  
  return cameraScenes.get().contains(sceneName) ? sceneName : prefix
})

let scene = Computed(function() {
  let curCameraValue = curCamera.get()
  if (curCameraValue == "vehicles" || curSelectedItem.get()?.itemtype == "vehicle") {
    let aircraftInfo = getAircraftInfo(vehTplInVehiclesScene.get())
    return !aircraftInfo.isAircraft ? "vehicles"
      : aircraftInfo.isFloating ? "aircrafts_floating"
      : "aircrafts"
  }
  let reqViewSquad = (curCameraValue == "soldiers" || curCameraValue == "soldiers_quarters")
    && !curSoldierGuid.get()
  return reqViewSquad || selectedSquadSoldiers.get() ? sceneCameraSquadFilter.get()
    : isCustomizationWndOpened.get() ? "soldier_customization"
    : curCameraValue == "new_items" && currentNewSoldierGuid.get() ? "soldier_in_middle"
    : curCameraValue
})

return {
  currentNewItem
  currentNewItemAttachments
  curHoveredItem
  curSelectedItem
  vehTplInVehiclesScene
  vehDataInVehiclesScene
  itemInArmory
  itemInArmoryAttachments
  needWeaponCameraAngle
  soldierInSoldiers
  scene
  squadCampaignVehicleFilter
  vehicleInVehiclesScene
  isVehicleSceneVisible
  cameraFovDelta
  changeCameraFov
  curSquadCamo
}
