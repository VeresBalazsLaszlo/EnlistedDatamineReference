import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *

let canShowReplayHud = Watched(true)
let canShowGameHudInReplay = Watched(true)

const FPS_CAMERA = "FPS_CAMERA"
const TPS_CAMERA = "TPS_CAMERA"
const TPS_FREE_CAMERA = "TPS_FREE_CAMERA"
const OPERATOR_CAMERA = "OPERATOR_CAMERA"

let replayTime = mkEcsComputed({
  comps = [
    ["replay__curTime", ecs.TYPE_FLOAT],
    ["replay__speed", ecs.TYPE_FLOAT],
    ["replay__playTime", ecs.TYPE_FLOAT],
  ]
})

let replayTimeSpeed = Computed(@() replayTime.get()?.replay__speed ?? 0.0)
let replayCurTime = Computed(@() replayTime.get()?.replay__curTime ?? 0.0)
let replayPlayTime = Computed(@() replayTime.get()?.replay__playTime ?? 0.0)



let isTpsFreeCamera = mkEcsComputed({
  comps = [["camera__active", ecs.TYPE_BOOL]]
  comps_rq = [["replay_camera__tpsFree"]]
  defVal = false
  tags = "playingReplay"
})

let isTpsCamera = mkEcsComputed({
  comps = [["camera__active", ecs.TYPE_BOOL]]
  comps_rq = [["replay_camera__tps"]]
  defVal = false
  tags = "playingReplay"
})

let fpsCamera = mkEcsComputed({
  comps = [
    ["camera__active", ecs.TYPE_BOOL],
    ["isHeroCockpitCam", ecs.TYPE_BOOL],
  ]
  comps_rq = [["replay_camera__fps"]]
  tags = "playingReplay"
})

let isFpsCamera = Computed(function() {
  let cam = fpsCamera.get()
  return cam != null && cam.isHeroCockpitCam && cam.camera__active
})

let isOperatorCamera = mkEcsComputed({
  comps = [["camera__active", ecs.TYPE_BOOL]]
  comps_rq = [["replay_camera__operator"]]
  defVal = false
  tags = "playingReplay"
})

let replayCameraTracking = mkEcsComputed({
  comps = [["replay_camera__trackingEnabled", ecs.TYPE_BOOL]]
  comps_rq = ["replayCamera"]
  defVal = true 
  tags = "playingReplay"
})

let isFreeInput = Computed(@() !replayCameraTracking.get())

let replayCameraWeaponEid = mkEcsComputed({
  comps = [["replay_camera__trackWeaponEid", ecs.TYPE_EID]]
  comps_rq = ["replayCamera"]
  defVal = ecs.INVALID_ENTITY_ID
  tags = "playingReplay"
})

let isAttachedToWeapon = Computed(@() replayCameraWeaponEid.get() != ecs.INVALID_ENTITY_ID)

let curSoldierInfo = mkEcsComputed({
  comps = [
    ["name", ecs.TYPE_STRING],
    ["soldier__sClass", ecs.TYPE_STRING],
  ]
  comps_rq = ["watchedByPlr"]
  tags = "playingReplay"
})

let replayAvailableSpeeds = mkEcsComputed({
  comps = [["replay__availableSpeeds", ecs.TYPE_FLOAT_LIST]]
  defVal = freeze([])
  tags = "playingReplay"
})

let isReplayAccelerationTo = Watched(false)

ecs.register_es("ui_replay_acceleration_to", {
  onInit = @(_, _comp) isReplayAccelerationTo.set(true),
  onDestroy = @(_, _comp) isReplayAccelerationTo.set(false)
}, {
  comps_rq = ["replay__accelerationSpeed"]
}, { tags = "playingReplay" })

let activeCameraId = Computed(@() isTpsFreeCamera.get() ? TPS_FREE_CAMERA
  : isOperatorCamera.get() ? OPERATOR_CAMERA
  : isTpsCamera.get() ? TPS_CAMERA
  : isFpsCamera.get() ? FPS_CAMERA
  : null)

return {
  replayCurTime
  replayPlayTime
  replayTimeSpeed
  replayAvailableSpeeds
  isReplayStopped = Computed(@() replayTimeSpeed.get() == 0)
  canShowReplayHud
  canShowGameHudInReplay
  isTpsFreeCamera
  curSoldierInfo
  isFreeInput
  isAttachedToWeapon
  FPS_CAMERA
  TPS_CAMERA
  TPS_FREE_CAMERA
  OPERATOR_CAMERA
  activeCameraId
}
