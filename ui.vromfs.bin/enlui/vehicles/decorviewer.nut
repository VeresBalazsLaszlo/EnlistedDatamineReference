import "%dngscripts/ecs.nut" as ecs
from "dagor.math" import Point2
from "vehicle_decals" import RequestToSaveVehicleDecals, LoadVehicleDecals
from "dasevents" import SaveVehicleDecor, ClearVehicleDecor, SetVehicleDecor
from "%ui/ui_library.nut" import *

const MIN_SIZE = 0.2
const MAX_SIZE_MUL = 0.08
const SIZE_STEP = 0.05
const ROTATION_STEP = 0.0872664626

let vehTargetEid = Watched(0)
let decalSize = Watched(1)
let decalRotation = Watched(0)

let setDecalTargetQuery = ecs.SqQuery("setDecalTargetQuery",
  { comps_rw = [[ "decals_manager__target", ecs.TYPE_EID ]]})

function setDecalTarget(targetEid) {
  vehTargetEid.set(targetEid)
  setDecalTargetQuery.perform(function(_eid, comp) {
    comp["decals_manager__target"] = targetEid
  })
}


let setDecalSlotQuery = ecs.SqQuery("setDecalSlotQuery",
  { comps_rw = [ ["decals_manager__active_slot", ecs.TYPE_INT ] ]})

function setDecalSlot(slot) {
  setDecalSlotQuery.perform(function(_eid, comp) {
    comp["decals_manager__active_slot"] = slot
  })
}


let setDecalInfoQuery = ecs.SqQuery("setDecorInfoQuery",
  { comps_rw = [
    [ "current_decal__name", ecs.TYPE_STRING ],
    [ "current_decor__type", ecs.TYPE_STRING ]
  ]})

function setDecorInfo(dName, dType) {
  setDecalInfoQuery.perform(function(_eid, comp) {
    comp["current_decal__name"] = dName
    comp["current_decor__type"] = dType
  })
}


let setDecalMirroredQuery = ecs.SqQuery("setDecalMirroredQuery",
  { comps_rw = [[ "current_decal__mirrored", ecs.TYPE_BOOL ]] })

function setDecalMirrored(isMirrored) {
  setDecalMirroredQuery.perform(function(_eid, comp) {
    comp["current_decal__mirrored"] = isMirrored
  })
}


let setDecalTwoSideQuery = ecs.SqQuery("setDecalTwoSideQuery",
  { comps_rw = [
    [ "current_decal__twoSided", ecs.TYPE_BOOL ],
    [ "current_decal__oppositeMirrored", ecs.TYPE_BOOL ]
  ] })

function setDecalTwoSide(isTwoSided, isMirrored) {
  setDecalTwoSideQuery.perform(function(_eid, comp) {
    comp["current_decal__twoSided"] = isTwoSided
    comp["current_decal__oppositeMirrored"] = isMirrored
  })
}


let setDecalScreenPosQuery = ecs.SqQuery("setDecalScreenPosQuery",
  { comps_rw = [
    [ "decals_manager__screenPos", ecs.TYPE_POINT2 ]
  ] })

function onDecalMouseMove(pointerEvent) {
  setDecalScreenPosQuery.perform(function(_eid, comp) {
    let x = pointerEvent?.screenX ?? pointerEvent.x
    let y = pointerEvent?.screenY ?? pointerEvent.y
    comp["decals_manager__screenPos"] = Point2(x, y)
  })
}


let setDecalMouseWheelQuery = ecs.SqQuery("setDecalMouseWheelQuery", {
  comps_rw = [
    [ "current_decal__size", ecs.TYPE_FLOAT ],
    [ "current_decal__vehicleSize", ecs.TYPE_FLOAT ],
    [ "current_decal__rotation", ecs.TYPE_FLOAT ]
  ]
})

function onDecalMouseWheel(mouseEvent) {
  setDecalMouseWheelQuery.perform(function(_eid, comp) {
    local maxSize = max(MIN_SIZE, MAX_SIZE_MUL*comp["current_decal__vehicleSize"])
    local size = decalSize.get()
    local rotation = decalRotation.get()
    local hasChange = false
    if ((mouseEvent?.shiftKey ?? false) && !(mouseEvent?.altKey ?? false)) {
      size = clamp(size + mouseEvent.button * SIZE_STEP, MIN_SIZE, maxSize)
      decalSize.set(size)
      hasChange = true
    }
    else if ((mouseEvent?.altKey ?? false) && !(mouseEvent?.shiftKey ?? false)) {
      rotation += mouseEvent.button * ROTATION_STEP
      decalRotation.set(rotation)
      hasChange = true
    }
    if (hasChange) {
      comp["current_decal__size"] = size
      comp["current_decal__rotation"] = rotation
    }
  })
}

function applyUsingDecal() {
  ecs.g_entity_mgr.sendEvent(vehTargetEid.get(), RequestToSaveVehicleDecals())
}

function applyUsingDecor() {
  ecs.g_entity_mgr.broadcastEvent(SaveVehicleDecor())
}

function applyDecalsToVehicle(decal) {
  let { targetEid, decalCompArray } = decal
  ecs.g_entity_mgr.sendEvent(targetEid, LoadVehicleDecals(decalCompArray))
}

function applyDecorToVehicle(decor_info) {
  let { targetEid, decorArray } = decor_info
  ecs.g_entity_mgr.sendEvent(targetEid, ClearVehicleDecor())
  foreach(decor in decorArray)
    ecs.g_entity_mgr.sendEvent(targetEid, SetVehicleDecor({
      relativeTm = decor.relativeTm,
      slotId = decor.slot,
      nodeName = decor.nodeName
      templateName = decor.textureName
    }))
}


let setSkinParameters = ecs.SqQuery("setSkinParameters", {
  comps_rw = [
    [ "vehicle_camo_condition", ecs.TYPE_FLOAT ],
    [ "vehicle_camo_scale", ecs.TYPE_FLOAT ],
    [ "vehicle_camo_rotation", ecs.TYPE_FLOAT ]
  ]
})

function setSkinCondition(val) {
  setSkinParameters.perform(function(_eid, comp) {
    comp["vehicle_camo_condition"] = val
  })
}

function setSkinScale(val) {
  setSkinParameters.perform(function(_eid, comp) {
    comp["vehicle_camo_scale"] = val
  })
}

function setSkinRotation(val) {
  setSkinParameters.perform(function(_eid, comp) {
    comp["vehicle_camo_rotation"] = val
  })
}


return {
  setDecalTarget
  setDecalSlot
  setDecorInfo
  setDecalMirrored
  setDecalTwoSide
  onDecalMouseMove
  onDecalMouseWheel
  vehTargetEid
  applyUsingDecal
  applyUsingDecor
  applyDecalsToVehicle
  applyDecorToVehicle
  setSkinCondition
  setSkinScale
  setSkinRotation
}
