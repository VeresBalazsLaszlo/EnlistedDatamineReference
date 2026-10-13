import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%sqstd/frp.nut" import watchedTable2TableOfWatched
from "%ui/ec_to_watched.nut" import mkFrameIncrementObservable
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "%ui/ui_library.nut" import *





let inVehicleDefValue = freeze({
  inTank = false
  requireCrosshair = false
  inPlane = false
  inShip = false
  isPassengerInMobileRespawn = false
  isOwnerInMobileRespawn = false
  inGroundVehicle = false
  isVehicleAlive = false
  isVehicleCanBeRessuplied = false
  isPlaneOnCarrier = false
  vehicleResupplyType = ""
  controlledVehicleEid = ecs.INVALID_ENTITY_ID
})

let { inVehicleState, inVehicleStateSetValue } = mkFrameIncrementObservable(inVehicleDefValue, "inVehicleState")
let {
  inTank, requireCrosshair, inPlane, inShip, isPassengerInMobileRespawn, isOwnerInMobileRespawn, inGroundVehicle, isVehicleAlive, isVehicleCanBeRessuplied, isPlaneOnCarrier, vehicleResupplyType, controlledVehicleEid
} = watchedTable2TableOfWatched(inVehicleState)

let heroSeat = mkEcsComputed({
  comps = [
    ["isInVehicle", ecs.TYPE_BOOL, false],
    ["isDriver", ecs.TYPE_BOOL, false],
    ["isGunner", ecs.TYPE_BOOL, false],
    ["isPassenger", ecs.TYPE_BOOL, false]
  ]
  comps_rq = ["watchedByPlr"]
})

let mkVehicleRole = @(role) Computed(@() (heroSeat.get()?.isInVehicle ?? false) && (heroSeat.get()?[role] ?? false))
let rolesExport = {
  isDriver = mkVehicleRole("isDriver")
  isGunner = mkVehicleRole("isGunner")
  isPassenger = mkVehicleRole("isPassenger")
}

let vehicleActions = mkEcsComputed({
  comps = [
    ["actionsState__isPlayerCanEnter", ecs.TYPE_BOOL],
    ["actionsState__isPlayerCanExit", ecs.TYPE_BOOL],
    ["actionsState__isSafeToExit", ecs.TYPE_BOOL],
    ["actionsState__isHighSpeedWarningEnabled", ecs.TYPE_BOOL]
  ]
  comps_rq = ["watchedByPlr"]
})

let actionsExport = {
  isPlayerCanEnter = Computed(@() vehicleActions.get()?.actionsState__isPlayerCanEnter ?? true)
  isPlayerCanExit = Computed(@() vehicleActions.get()?.actionsState__isPlayerCanExit ?? true)
  isSafeToExit = Computed(@() vehicleActions.get()?.actionsState__isSafeToExit ?? true)
  isHighSpeedWarningEnabled = Computed(@() vehicleActions.get()?.actionsState__isHighSpeedWarningEnabled ?? false)
}

let planeCritical = mkEcsComputed({
  comps = [
    ["plane__flapsCritical", ecs.TYPE_BOOL, false],
    ["plane__overloadCritical", ecs.TYPE_BOOL, false],
  ]
  comps_rq = ["vehicleWithWatched"]
})
let planeStateExport = {
  isFlapsCritical = Computed(@() planeCritical.get()?.plane__flapsCritical ?? false)
  isOverloadCritical = Computed(@() planeCritical.get()?.plane__overloadCritical ?? false)
}

local lastInitedStateEid = ecs.INVALID_ENTITY_ID

ecs.register_es("ui_in_vehicle_eid_es",
  {
    [["onChange", "onInit"]] = function (eid, comp) {
      let inPlaneC = comp["airplane"] != null
      let inTankC = comp["isTank"] != null
      let requireCrosshairC = comp["requireCrosshair"] != null
      let inShipC = comp["ship"] != null
      let isOwnerInMobileRespawnC = comp["mobileRespawnTag"] != null && comp["ownedByPlayer"] == localPlayerEid.get()
      let isPassengerInMobileRespawnC = comp["mobileRespawnTag"] != null && !isOwnerInMobileRespawnC
      let canBeRessuplied = comp.resupplyAtTime != null && comp.disableVehicleResupply == null
      inVehicleStateSetValue({
        inPlane=inPlaneC, inTank = inTankC, requireCrosshair = requireCrosshairC, inShip=inShipC, isOwnerInMobileRespawn = isOwnerInMobileRespawnC,
        isPassengerInMobileRespawn = isPassengerInMobileRespawnC, inGroundVehicle=!inPlaneC,
        vehicleResupplyType = comp.vehicle_resupply__type
        isVehicleAlive = comp["isAlive"]
        isVehicleCanBeRessuplied = canBeRessuplied
        controlledVehicleEid = eid
        isPlaneOnCarrier = comp.plane_carrier_assist__isOnCarrier
      })
      lastInitedStateEid = eid
    },
    function onDestroy(eid, _){
      if (lastInitedStateEid == eid)
        inVehicleStateSetValue(inVehicleDefValue)
    }
  },
  {
    comps_track = [
      ["isAlive", ecs.TYPE_BOOL, false],
      ["plane_carrier_assist__isOnCarrier", ecs.TYPE_BOOL, false],
    ],
    comps_ro = [
      ["airplane", ecs.TYPE_TAG, null],
      ["isTank", ecs.TYPE_TAG, null],
      ["requireCrosshair", ecs.TYPE_TAG, null],
      ["ship", ecs.TYPE_TAG, null],
      ["mobileRespawnTag", ecs.TYPE_TAG, null],
      ["ownedByPlayer", ecs.TYPE_EID, ecs.INVALID_ENTITY_ID],
      ["vehicle_resupply__type", ecs.TYPE_STRING, ""],
      ["resupplyAtTime", ecs.TYPE_FLOAT, null],
      ["disableVehicleResupply", ecs.TYPE_TAG, null],
    ],
    comps_rq=["vehicleWithWatched"]
  }
)

return rolesExport.__merge(actionsExport, planeStateExport, {
  inTank, requireCrosshair, inPlane, inShip, isOwnerInMobileRespawn, isPassengerInMobileRespawn, inGroundVehicle, isVehicleAlive, isVehicleCanBeRessuplied, isPlaneOnCarrier, controlledVehicleEid,
  vehicleResupplyType,
  inVehicle = Computed(@() inGroundVehicle.get() || inPlane.get())
})