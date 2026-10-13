import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/sqevents.nut" import EventSetCamTmAndFov, mkEventSetCamTmAndFov
from "dagor.system" import DBGLEVEL
from "dagor.math" import Point2, Point3, TMatrix
from "%ui/showState.nut" import vehTplInVehiclesScene, vehDataInVehiclesScene, cameraFovDelta,
  itemInArmory, itemInArmoryAttachments, needWeaponCameraAngle, soldierInSoldiers, currentNewItem,
  currentNewItemAttachments, scene, squadCampaignVehicleFilter, isVehicleSceneVisible,
  curSquadCamo
from "%dngscripts/globalState.nut" import nestWatched
from "%sqstd/frp.nut" import subscribeList
from "%ui/soldiers/squadOutfitPreview.nut" import isOutfitPreviewOpen, previewSoldiersLook
from "%ui/soldiers/model/state.nut" import curSquad
from "%ui/meta/profile.nut" import curCampSoldiers, curCampItems
from "%ui/soldiers/model/readySoldiers.nut" import curSquadSoldiersReady
from "%ui/soldiers/model/chooseSquadsState.nut" import selectedSquadSoldiers, selSquadVehicleGameTpl
from "gameevents" import EventLevelLoaded
from "%ui/scene/soldier_tools.nut" import soldierViewGen, createSoldier, appearanceToRender
from "%ui/scene/vehicle_tools.nut" import createVehicle
from "%ui/fadeToBlack.nut" import doFadeBlack, registerFadeBlackActions
from "%ui/scene/transformItem.nut" import transformItem, transformItemRelative
from "%ui/vehicles/dmViewer.nut" import setDmViewerTarget
from "%ui/vehicles/decorViewer.nut" import setDecalTarget
from "%ui/vehicles/customizeState.nut" import curVehCustomization, notPurchased, viewVehDecorByType
from "%ui/vehicles/vehiclesListState.nut" import selectVehParams
from "%ui/meta/servProfile.nut" import soldiersLook
from "%ui/soldiers/model/config/outfitConfig.nut" import equippedOutfitsForArmy
from "%ui/items/itemCollageState.nut" import viewTemplates
from "%ui/meta/curCampaign.nut" import COMMON_CAMPAIGN
from "%ui/scene/machinegun_tools.nut" import enginObjectToPlace
from "%ui/scene/item_tools.nut" import setItemTransformFunc
from "%ui/meta/configs.nut" import serverConfigs
from "%ui/helpers/metalink.nut" import getItemIndex
from "%ui/ui_library.nut" import *











let setCameraQuery = ecs.SqQuery("setCameraQuery", {
  comps_rw = [
    ["menu_cam__target", ecs.TYPE_EID],
    ["menu_cam__dirInited", ecs.TYPE_BOOL],
    ["menu_cam__initialDir", ecs.TYPE_POINT3],
    ["menu_cam__offset", ecs.TYPE_POINT3],
    ["menu_cam__offsetMult", ecs.TYPE_POINT3],
    ["menu_cam__limitYaw", ecs.TYPE_POINT2],
    ["menu_cam__limitPitch", ecs.TYPE_POINT2],
    ["menu_cam__shouldRotateTarget", ecs.TYPE_BOOL],
  ],
  comps_rq = ["camera__active", ["transform", ecs.TYPE_MATRIX], ["fov", ecs.TYPE_FLOAT]], comps_no=["scene"]})
let setDofQuery = ecs.SqQuery("setDofQuery", {
  comps_rw = [
    ["dof__on", ecs.TYPE_BOOL],
    ["dof__nearDofStart", ecs.TYPE_FLOAT],
    ["dof__nearDofEnd", ecs.TYPE_FLOAT],
    ["dof__nearDofAmountPercent", ecs.TYPE_FLOAT],
    ["dof__farDofStart", ecs.TYPE_FLOAT],
    ["dof__farDofEnd", ecs.TYPE_FLOAT],
    ["dof__farDofAmountPercent", ecs.TYPE_FLOAT],
    ["dof__bokehShape_kernelSize", ecs.TYPE_FLOAT],
    ["dof__bokehShape_bladesCount", ecs.TYPE_FLOAT],
    ["dof__minCheckDistance", ecs.TYPE_FLOAT],
    ["dof__is_filmic", ecs.TYPE_BOOL],
    ["dof__focusDistance", ecs.TYPE_FLOAT],
    ["dof__sensorHeight_mm", ecs.TYPE_FLOAT],
    ["dof__focalLength_mm", ecs.TYPE_FLOAT],
    ["dof__fStop", ecs.TYPE_FLOAT],
  ]
  comps_rq=[["is_dof", ecs.TYPE_TAG]]
})
let findScenicCamQuery = ecs.SqQuery("findScenicCamQuery", {
  comps_ro = [
    ["transform", ecs.TYPE_MATRIX],
    ["fov", ecs.TYPE_FLOAT],
    ["menu_cam__target", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
    ["menu_cam__offset", ecs.TYPE_POINT3, Point3(0.0, 0.0, 0.0)],
    ["menu_cam__offsetMult", ecs.TYPE_POINT3, Point3(0.0, 0.0, 0.0)],
    ["menu_cam__limitYaw", ecs.TYPE_POINT2, Point2(0.0, 0.0)],
    ["menu_cam__limitPitch", ecs.TYPE_POINT2, Point2(0.0, 0.0)],
    ["menu_cam__shouldRotateTarget", ecs.TYPE_BOOL, false],
    ["scene", ecs.TYPE_STRING]
  ]})
let findScenicDofDistQuery = ecs.SqQuery("findScenicDofDistQuery", {comps_ro = [
    ["dof__on", ecs.TYPE_BOOL],
    ["scene", ecs.TYPE_STRING],
    ["dof__nearDofStart", ecs.TYPE_FLOAT],
    ["dof__nearDofEnd", ecs.TYPE_FLOAT],
    ["dof__nearDofAmountPercent", ecs.TYPE_FLOAT],
    ["dof__farDofStart", ecs.TYPE_FLOAT],
    ["dof__farDofEnd", ecs.TYPE_FLOAT],
    ["dof__farDofAmountPercent", ecs.TYPE_FLOAT],
    ["dof__bokehShape_kernelSize", ecs.TYPE_FLOAT],
    ["dof__bokehShape_bladesCount", ecs.TYPE_FLOAT],
    ["dof__minCheckDistance", ecs.TYPE_FLOAT],
    ["dof__is_filmic", ecs.TYPE_BOOL],
    ["dof__focusDistance", ecs.TYPE_FLOAT],
    ["dof__sensorHeight_mm", ecs.TYPE_FLOAT],
    ["dof__focalLength_mm", ecs.TYPE_FLOAT],
    ["dof__fStop", ecs.TYPE_FLOAT],
  ]})

function setDofDist(dof_comp){
  setDofQuery.perform(function(_eid, post_fx_comp){
    post_fx_comp.dof__on = dof_comp["dof__on"]
    post_fx_comp.dof__nearDofStart = dof_comp["dof__nearDofStart"]
    post_fx_comp.dof__nearDofEnd = dof_comp["dof__nearDofEnd"]
    post_fx_comp.dof__nearDofAmountPercent = dof_comp["dof__nearDofAmountPercent"]
    post_fx_comp.dof__farDofStart = dof_comp["dof__farDofStart"]
    post_fx_comp.dof__farDofEnd = dof_comp["dof__farDofEnd"]
    post_fx_comp.dof__farDofAmountPercent = dof_comp["dof__farDofAmountPercent"]
    post_fx_comp.dof__bokehShape_kernelSize = dof_comp["dof__bokehShape_kernelSize"]
    post_fx_comp.dof__bokehShape_bladesCount = dof_comp["dof__bokehShape_bladesCount"]
    post_fx_comp.dof__minCheckDistance = dof_comp["dof__minCheckDistance"]
    post_fx_comp.dof__is_filmic = dof_comp["dof__is_filmic"]
    post_fx_comp.dof__focusDistance = dof_comp["dof__focusDistance"]
    post_fx_comp.dof__sensorHeight_mm = dof_comp["dof__sensorHeight_mm"]
    post_fx_comp.dof__focalLength_mm = dof_comp["dof__focalLength_mm"]
    post_fx_comp.dof__fStop = dof_comp["dof__fStop"]
  })
}

let cameraOffset = Watched([0, 0, 0])
console_register_command(function(x, y, z) {
  cameraOffset.set([x, y, z])
}, "setCameraOffset")


function mkOffsetTMatrix(tm, offset) {
  local newTm = TMatrix(tm)
  newTm[3] = Point3(
    tm[3].x + offset[0],
    tm[3].y + offset[1],
    tm[3].z + offset[2]
  )
  return newTm
}

let setMenuItemFovProportion = ecs.SqQuery("setMenuItemFovProportion", {
  comps_rw = [
    ["menu_item__cameraCenterOffsetProportion", ecs.TYPE_FLOAT],
  ]
})

local curCameraFov = 0

function setCamera(cameraComps) {
  local tm = null
  local cam_eid = ecs.INVALID_ENTITY_ID
  setCameraQuery.perform(function(eid, comp){
    foreach (k, v in cameraComps)
      if (k == "transform") {
        tm = mkOffsetTMatrix(v, cameraOffset.get())
        cam_eid = eid
      }
      else if (k == "fov") {
        cam_eid = eid
        let fovProportion = 1.0 + (cameraFovDelta.get() / curCameraFov)
        setMenuItemFovProportion(@(_eid, comps) comps.menu_item__cameraCenterOffsetProportion = fovProportion)
      }
      else if (k in comp) {
        comp[k] = v
      }
  })
  if (cam_eid != ecs.INVALID_ENTITY_ID)
    ecs.g_entity_mgr.sendEvent(cam_eid, mkEventSetCamTmAndFov({ tm = tm, fov = (curCameraFov + cameraFovDelta.get()) }))
}


ecs.register_es("set_cam_ofs_and_fov_es", {
      [EventSetCamTmAndFov] = function(evt, _eid, comp) {
        if (comp.camera__active) {
          let tm = evt.data?.tm
          if (tm != null)
            comp.transform = tm
          comp.fov = evt.data.fov
        }
      }
    }, {
    comps_rw = [["transform", ecs.TYPE_MATRIX], ["fov", ecs.TYPE_FLOAT]],
    comps_ro = [["camera__active", ecs.TYPE_BOOL]],
    comps_rq = ["camera_view"],
    comps_no = ["scene"]
})



function createEntity(template, transform, callback = null, extraTemplates=[], attachTemplates=[]){
  if (template) {
    template = "+".join([template].extend(extraTemplates))
    let eid = ecs.g_entity_mgr.createEntity(template, { transform = transform }, callback)
    local attachesEids = ecs.CompEidList()
    foreach(attach in attachTemplates) {
      let attachEid = ecs.g_entity_mgr.createEntity(attach, {
        ["animchar_attach__attachedTo"] = ecs.EntityId(eid),
        ["slot_attach__visible"] = true
      }, null)
      attachesEids.append(ecs.EntityId(attachEid))
    }
    return {eid, attachesEids}
  }
  return {eid = ecs.INVALID_ENTITY_ID}
}

let logg = DBGLEVEL !=0 ? log_for_user : log
function makeWeaponTemplate(template){
  if (template == null || template == "")
    return null

  let templ = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(template)
  local itemTemplate = templ?.getCompValNullable("item__template")
    ?? templ?.getCompValNullable("ammo_holder__templateName")
  if (itemTemplate==null){
    if (templ?.getCompValNullable("animchar__res") != null)
      itemTemplate = template
    else {
      logg("Incorrect template found for weapon meta-template:", template)
      return null
    }
  }
  return ecs.makeTemplate({
    baseTemplate = itemTemplate ?? template, addTemplates = ["item_in_world", "menu_item"]
  })
}

function setCameraTargetInScene(targetEid){
  setCamera({["menu_cam__target"] = targetEid})
}

function setDmViewerInScene(targetEid){
  setDmViewerTarget(targetEid)
}

function setDecalTargetInScene(targetEid){
  setDecalTarget(targetEid)
}

function resetCameraDirection(){
  setCamera({["menu_cam__dirInited"] = false})
}

cameraFovDelta.subscribe(@(v) setCamera({ ["fov"] = v }))

let cameraTarget = mkWatched(persist, "cameraTarget", ecs.INVALID_ENTITY_ID)
let isFadeDone = mkWatched(persist, "isFadeDone", false)

let visibleScene = Watched(scene.get())

function recreateStubFunc(...){
  logg("Incorrect recreate cb function")
}

let transformDefault =  @(transform, ...) transform

function makeShowScene(sceneDesc, name){
  let {
    compName, data, transformItemFunc = transformDefault,
    createEntityFunc = createEntity, reInitEntityFunc = recreateStubFunc,
    recreateSoldier = false
  } = sceneDesc
  let query = ecs.SqQuery($"query{compName}", {
    comps_ro = [["transform", ecs.TYPE_MATRIX]]
    comps_rw = [
      [ compName, ecs.TYPE_EID ],
      [ "item_attaches", ecs.TYPE_EID_LIST, null ]
    ]
  })

  function onCreateEntity(createdEid) {
    cameraTarget.set(createdEid)
    let { shouldResetCameraDirection = false } = data.get()
    if (shouldResetCameraDirection)
      resetCameraDirection()
  }

  let visibleWatch = Computed(@() visibleScene.get() == name ? data.get().currentObj : null)

  function update(_baseEid, comp) {
    let mainObj = visibleWatch.get()
    if (visibleScene.get() != name) {
      ecs.g_entity_mgr.destroyEntity(comp[compName])
      comp[compName] = ecs.INVALID_ENTITY_ID
      if (comp.item_attaches != null) {
        foreach (attach in comp.item_attaches)
          ecs.g_entity_mgr.destroyEntity(attach)
        comp.item_attaches = ecs.CompEidList()
      }
      return
    }

    if (!recreateSoldier || comp[compName] == ecs.INVALID_ENTITY_ID) {
      let {eid, attachesEids = ecs.CompEidList()} =
        createEntityFunc(mainObj, transformItemFunc(comp["transform"], mainObj), onCreateEntity)
      ecs.g_entity_mgr.destroyEntity(comp[compName])
      comp[compName] = eid
      if (comp.item_attaches != null) {
        foreach (attach in comp.item_attaches)
          ecs.g_entity_mgr.destroyEntity(attach)
        comp.item_attaches = attachesEids
      }
    }
    else {
      let newSoldierEid = reInitEntityFunc(mainObj,
        transformItemFunc(comp["transform"], mainObj), onCreateEntity, comp[compName])
      if (newSoldierEid != ecs.INVALID_ENTITY_ID)
        comp[compName] = newSoldierEid
    }
  }

  let updateEntity = @(...) query.perform(update)
  let showScene = sceneDesc.__merge({
    visibleWatch
    query
    updateEntity
  })
  showScene.data.subscribe(function(_) {
    if (visibleScene.get() == name)
      updateEntity()
  })
  return showScene
}

let transformByItemtype = @(transform, template) needWeaponCameraAngle.get()
  ? transformItem(transform, template)
  : transformItemRelative(transform, template)

let mainMenuSceneData = {
  compName = "menu_char_to_control"
  createEntityFunc = @(guid, transform, callback = null) {
    eid = createSoldier({
      guid
      transform
      callback
      soldiersLookVal = soldiersLook.get()
      premiumItems = equippedOutfitsForArmy.get()
  })}
  data = Computed(@() {
    currentObj = soldierInSoldiers.get()
    curCampItems = curCampItems.get()
    soldierViewGen = soldierViewGen.get()
    soldiersLook = soldiersLook.get()
    equippedOutfitsForArmy = equippedOutfitsForArmy.get()
    curCampSoldiers = curCampSoldiers.get()
    serverConfigs = serverConfigs.get()
  })
}

let objectsToObserve = {
  main_menu = mainMenuSceneData
  soldiers = mainMenuSceneData
  soldiers_quarters = mainMenuSceneData
  soldier_customization = {
    compName = "menu_char_to_control"
    recreateSoldier = true
    createEntityFunc = @(guid, transform, callback = null) {
      eid = createSoldier({
        guid
        transform
        callback
        soldiersLookVal = soldiersLook.get()
        premiumItems = equippedOutfitsForArmy.get()
        customizationOvr = appearanceToRender.get()
    })}
    reInitEntityFunc = @(guid, transform, callback = null, reInitEid = ecs.INVALID_ENTITY_ID)
      createSoldier({
        guid
        transform
        callback
        soldiersLookVal = soldiersLook.get()
        premiumItems = equippedOutfitsForArmy.get()
        customizationOvr = appearanceToRender.get()
        reInitEid
      })
    data = Computed(@() {
      currentObj = soldierInSoldiers.get()
      curCampItems = curCampItems.get()
      soldierViewGen = soldierViewGen.get()
      soldiersLook = soldiersLook.get()
      equippedOutfitsForArmy = equippedOutfitsForArmy.get()
      curCampSoldiers = curCampSoldiers.get()
      serverConfigs = serverConfigs.get()
      appearanceToRender = appearanceToRender.get()
    })
  },
  soldier_in_middle = {
    compName = "menu_char_to_control"
    createEntityFunc = @(guid, transform, callback = null) {
      eid = createSoldier({
        guid
        transform
        callback
        soldiersLookVal = soldiersLook.get()
        premiumItems = equippedOutfitsForArmy.get()
        isDisarmed = true
    })}
    data = Computed(@() {
      currentObj = soldierInSoldiers.get()
      curCampItems = curCampItems.get()
      soldierViewGen = soldierViewGen.get()
      soldiersLook = soldiersLook.get()
      equippedOutfitsForArmy = equippedOutfitsForArmy.get()
      curCampSoldiers = curCampSoldiers.get()
      serverConfigs = serverConfigs.get()
    })
  },
  vehicles = {
    compName = "menu_vehicle_to_control"
    createEntityFunc = @(template, transform, callback = null) {
      eid = createVehicle({
        template,
        transform,
        callback,
        customization = curVehCustomization.get(),
        extraTemplates = ["menu_vehicle"]
    })}
    data = Computed(@() {
      shouldResetCameraDirection = !(selectVehParams.get()?.isCustomMode ?? false)
      recreateVersionNo = selectVehParams.get()?.recreateVersionNo
      currentObj = vehTplInVehiclesScene.get()
      notPurchased = notPurchased.get()
      viewVehDecorByType = viewVehDecorByType.get()
      curVehCustomization = curVehCustomization.get()
    })
  },
  aircrafts = {
    compName = "menu_aircraft_to_control"
    data = Computed(@() {
      shouldResetCameraDirection = !(selectVehParams.get()?.isCustomMode ?? false)
      currentObj = vehTplInVehiclesScene.get()
    })
  },
  aircrafts_floating = {
    compName = "menu_aircraft_floating_to_control"
    data = Computed(@() {
      shouldResetCameraDirection = !(selectVehParams.get()?.isCustomMode ?? false)
      currentObj = vehTplInVehiclesScene.get()
    })
  },
  armory = {
    compName = "menu_weapon_to_control",
    transformItemFunc = transformByItemtype
    createEntityFunc = @(template, transform, callback=null)
      createEntity(makeWeaponTemplate(template), transform, callback, [], itemInArmoryAttachments.get())
    data = Computed(@() {
      shouldResetCameraDirection = true
      currentObj = itemInArmory.get()
      itemInArmoryAttachments = itemInArmoryAttachments.get()
      needWeaponCameraAngle = needWeaponCameraAngle.get()
    })
  },
  items_inventory = {
    compName = "menu_shop_items_to_control"
    transformItemFunc = setItemTransformFunc
    createEntityFunc = @(template, transform, callback=null)
      createEntity(makeWeaponTemplate(template), transform, callback, [], itemInArmoryAttachments.get())
    data = Computed(@() {
      shouldResetCameraDirection = true
      currentObj = itemInArmory.get()
      itemInArmoryAttachments = itemInArmoryAttachments.get()
    })
  },
  inv_items = {
    compName = "menu_inv_items_to_control"
    data = WatchedRo({
      shouldResetCameraDirection = true
    })
  },
  new_items = {
    compName = "menu_new_items_to_control"
    transformItemFunc = transformItemRelative
    createEntityFunc = @(template, transform, callback=null)
      createEntity(makeWeaponTemplate(template), transform, callback, [], currentNewItemAttachments.get())
    data = Computed(@() {
      shouldResetCameraDirection = true
      currentObj = currentNewItem.get()
    })
  },
  shop_items = {
    compName = "menu_shop_items_to_control"
    transformItemFunc = transformByItemtype
    createEntityFunc = @(template, transform, callback=null)
      createEntity(makeWeaponTemplate(template), transform, callback, [], currentNewItemAttachments.get())
    data = Computed(@() {
      shouldResetCameraDirection = true
      currentObj = currentNewItem.get()
      needWeaponCameraAngle = needWeaponCameraAngle.get()
    })
  },
  battle_pass = {
    compName = "menu_battle_pass_to_control"
    transformItemFunc = transformItem
    createEntityFunc = @(template, transform, callback=null)
      createEntity(makeWeaponTemplate(template), transform, callback, [], currentNewItemAttachments.get())
    data = Computed(@() {
      shouldResetCameraDirection = true
      currentObj = currentNewItem.get()
    })
  }
}.map(makeShowScene)

function updateSceneObjects(...) {
  if (!isFadeDone.get())
    return

  setCameraTargetInScene(cameraTarget.get())
  setDmViewerInScene(cameraTarget.get())
  setDecalTargetInScene(cameraTarget.get())
}

cameraTarget.subscribe(updateSceneObjects)

registerFadeBlackActions({
  change_camera = kwarg(function(cameraComps, curScene) {
    curCameraFov = cameraComps?["fov"] ?? 0
    cameraFovDelta.set(0)

    setCamera(cameraComps)
    let sceneToClear = visibleScene.get()
    visibleScene.set(curScene)
    objectsToObserve?[sceneToClear].updateEntity()
    objectsToObserve?[curScene].updateEntity()
    updateSceneObjects()
    findScenicDofDistQuery.perform(@(_dof_eid, dof_comp) dof_comp.scene == curScene ? setDofDist(dof_comp) : null)
    isFadeDone.set(true)
  })
})

function processScene(...) {
  let curScene = scene.get()
  if (!curScene)
    return
  isFadeDone.set(false)
  local cameraNotFound = true
  findScenicCamQuery.perform(function(_eid,comp) {
    if (comp.scene != curScene)
      return
    cameraNotFound = false
    let cameraComps = {
      ["menu_cam__dirInited"] = false,
      ["menu_cam__initialDir"] = comp.transform.getcol(2),
    }
    foreach (k, v in comp)
      cameraComps[k] <- v
    doFadeBlack({ fadein = 0.33, fadeout = 0.4, action = "change_camera",
      params = { cameraComps, curScene } })
  })
  if (cameraNotFound)
    isFadeDone.set(true)
}
subscribeList(processScene, scene, cameraOffset)

function posComparator(a, b) {
  if (a.filter == b.filter)
    return a.order <=> b.order
  if (a.filter.len() < b.filter.len())
    return 1
  return -1
}

let gettransforms = @(query, posFilter) ecs.query_map(query, @(_eid, comp) {
    transform = comp["transform"]
    order = comp["priority_order"]
    isSiting = comp?.isSiting ?? false
    filter = comp?.menuPosFilter ?? ""
  })
  .filter(@(pos) pos.filter == "" || pos.filter == posFilter)
  .sort(posComparator)

let destroyEntityByQuery = @(query) query.perform(function(eid, _comp) {
  ecs.g_entity_mgr.destroyEntity(eid)
})







local lastShownSquadToPlace = []
let currentSquadToPlace = Computed(function() {
  local newSquad = selectedSquadSoldiers.get()
  if (!newSquad && soldierInSoldiers.get() && !isOutfitPreviewOpen.get())
    return null

  newSquad = newSquad ?? curSquadSoldiersReady.get()
  if (newSquad.len() != 0 && !isEqual(lastShownSquadToPlace, newSquad))
    lastShownSquadToPlace = newSquad
  return lastShownSquadToPlace
})

let vehicleToPlace = Computed(function() {
  log($"[scene_control] vehicleToPlace {selectedSquadSoldiers.get()} {selSquadVehicleGameTpl.get()} {vehTplInVehiclesScene.get()}")
  let vehicle = selectedSquadSoldiers.get()
    ? selSquadVehicleGameTpl.get()
    : vehTplInVehiclesScene.get()
  return vehicle ? [vehicle] : null
})

let createdSoldiers = nestWatched("createdSoldiers", [])

let squadPlacesQuery = ecs.SqQuery("squadPlaces", {
  comps_ro = [
    ["transform", ecs.TYPE_MATRIX],
    ["priority_order", ecs.TYPE_INT, 0],
    ["menuPosFilter", ecs.TYPE_STRING],
    ["isSiting", ecs.TYPE_BOOL],
  ]
  comps_rq = ["menu_soldier_respawnbase"]
})
let menuBackgroundSoldiersQuery = ecs.SqQuery("menuBackgroundSoldiersQuery", {
  comps_rq = ["background_menu_soldier"]
})

let createdVehicles = nestWatched("createdVehicles", [])
let vehiclesPlacesQuery = ecs.SqQuery("vehiclePlaces", {
  comps_ro = [
    ["transform", ecs.TYPE_MATRIX],
    ["priority_order", ecs.TYPE_INT, 0],
    ["menuPosFilter", ecs.TYPE_STRING]
  ]
  comps_rq = ["menu_vehicle_respawnbase"]
})
let menuBackgroundVehiclesQuery = ecs.SqQuery("menuBackgroundVehiclesQuery", {
  comps_rq = ["background_menu_vehicle"]
})

let createdEnginObjects = nestWatched("createdEnginObjects", [])
let enginObjectsPlacesQuery = ecs.SqQuery("enginObjectPlaces", {
  comps_ro = [
    ["transform", ecs.TYPE_MATRIX],
    ["priority_order", ecs.TYPE_INT, 0],
    ["menuPosFilter", ecs.TYPE_STRING]
  ]
  comps_rq = ["menu_machinegun_respawnbase"]
})


let createdItems = nestWatched("createdItems", [])
let itemsPlacesQuery = ecs.SqQuery("itemPlaces", {
  comps_ro = [
    ["transform", ecs.TYPE_MATRIX],
    ["priority_order", ecs.TYPE_INT, 0]
  ]
  comps_rq = ["menu_item_respawnbase"]
})
let menuBackgroundItemsQuery = ecs.SqQuery("menuBackgroundItemsQuery", {
  comps_rq = ["background_menu_item"]
})




let mkReplaceObjectsFunc = @(name, placesQuery, objectsQuery, createFunc, createdList, placesFilter = null)
  function replaceObjects(objects) {
    createdList.get().each(@(eid) ecs.g_entity_mgr.destroyEntity(eid))
    destroyEntityByQuery(objectsQuery)
    log($"[scene_control] replacingObjects {name} prev_count={createdList.get().len()} new_count={objects?.len()}")
    let oldTemplateName = ecs.g_entity_mgr.getEntityTemplateName(createdList.get()?[0] ?? ecs.INVALID_ENTITY_ID)
    log($"[scene_control] createdList[0]={oldTemplateName} objects[0]={objects?[0]}")
    if (objects == null) {
      createdList.set([])
      return
    }
    let places = gettransforms(placesQuery, placesFilter?.get() ?? "")
    createdList.set(objects
      .slice(0, min(places.len(), objects.len()))
      .map(@(obj, i) createFunc(obj, places[i])))
  }


let poseUniqueFactors = [13, 17, 19, 23, 29, 31, 37]

function getObjectPoseIndex(object) {
  if ("links" not in object)
    return null

  let { squadId = null } = curSquad.get()
  if (squadId == null)
    return null

  let squadHash = squadId.hash()
  let uniqueFactor = poseUniqueFactors[squadHash % poseUniqueFactors.len()]
  return uniqueFactor * (getItemIndex(object) + 1)
}

let hasPreviewLook = Computed(@() previewSoldiersLook.get().len() > 0)
let squadSoldiersLook = Computed(@()
  hasPreviewLook.get() ? previewSoldiersLook.get() : soldiersLook.get())
let equippedOutfits = Computed(@() hasPreviewLook.get() ? {} : equippedOutfitsForArmy.get())

let replaceSoldiers = mkReplaceObjectsFunc("soldiers",
  squadPlacesQuery,
  menuBackgroundSoldiersQuery,
  @(object, place) createSoldier({
    guid = object?.guid
    transform = mkOffsetTMatrix(place.transform, cameraOffset.get())
    isSiting = place.isSiting
    soldiersLookVal = squadSoldiersLook.get()
    premiumItems = equippedOutfits.get()
    extraTemplates = ["background_menu_soldier"]
    poseIndex = getObjectPoseIndex(object)
  }),
  createdSoldiers,
  squadCampaignVehicleFilter
)

let replaceVehicles = mkReplaceObjectsFunc("vehicles",
  vehiclesPlacesQuery,
  menuBackgroundVehiclesQuery,
  function(object, place) {
    let entityId = createVehicle({
      template = object
      transform = mkOffsetTMatrix(place.transform, cameraOffset.get())
      customization = vehDataInVehiclesScene.get()
      extraTemplates = ["background_menu_vehicle"]
    })
    setDecalTargetInScene(entityId)
    return entityId
  },
  createdVehicles,
  squadCampaignVehicleFilter
)

let replaceEnginObject = mkReplaceObjectsFunc("enginObject",
  enginObjectsPlacesQuery,
  menuBackgroundVehiclesQuery,
  @(object, place) createVehicle({
    template = object
    transform = mkOffsetTMatrix(place.transform, cameraOffset.get())
  }),
  createdEnginObjects,
  COMMON_CAMPAIGN
)

let replaceInvItems = mkReplaceObjectsFunc("items",
  itemsPlacesQuery,
  menuBackgroundItemsQuery,
  function(template, place) {
    if (template == "")
      return ecs.INVALID_ENTITY_ID
    let { eid = ecs.INVALID_ENTITY_ID } = createEntity(makeWeaponTemplate(template), place.transform)
    return eid
  },
  createdItems)

registerFadeBlackActions({
  replace_soldiers     = @() replaceSoldiers(currentSquadToPlace.get())
  replace_vehicles     = @() replaceVehicles(vehicleToPlace.get())
  replace_engin_object = @() replaceEnginObject(enginObjectToPlace.get())
  replace_inv_items    = @() replaceInvItems(viewTemplates.get())
})


let currentSquadToPlaceReplace = @(...)
  doFadeBlack({ fadein = 0.2, fadeout = 0.6, action = "replace_soldiers" })
let vehicleToPlaceReplace = @(...)
  doFadeBlack({ fadein = 0.2, fadeout = 0.3, action = "replace_vehicles" })
let itemsToPlaceReplace = @(...)
  doFadeBlack({ fadein = 0.2, fadeout = 0.3, action = "replace_inv_items" })
let enginObjectToPlaceReplace = @(...)
  doFadeBlack({ fadein = 0.2, fadeout = 0.3, action = "replace_engin_object" })


subscribeList(currentSquadToPlaceReplace, currentSquadToPlace, squadCampaignVehicleFilter, cameraOffset, soldiersLook)

subscribeList(vehicleToPlaceReplace, vehicleToPlace, squadCampaignVehicleFilter, cameraOffset, isVehicleSceneVisible,
    curSquadCamo)

subscribeList(enginObjectToPlaceReplace, enginObjectToPlace, cameraOffset)


viewTemplates.subscribe(itemsToPlaceReplace)


ecs.register_es("setscene_es", {
    [EventLevelLoaded] = function(_evt, _eid, _comp) {
      processScene()
      objectsToObserve.each(@(v) v.updateEntity())
      currentSquadToPlaceReplace()
      vehicleToPlaceReplace()
      enginObjectToPlaceReplace()
   }
})
