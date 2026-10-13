from "%dngscripts/globalState.nut" import nestWatched
from "settings" import get_setting_by_blk_path

let soundOutputDevicesList = nestWatched("soundOutputDevicesList", [])
let soundOutputDevicesListUpdate = @(v) soundOutputDevicesList.set(v)
let soundRecordDevicesList = nestWatched("soundRecordDevicesList", [])
let soundRecordDevicesListUpdate = @(v) soundRecordDevicesList.set(v)
let soundOutputDevice = nestWatched("soundOutputDevice", null)
let soundOutputDeviceUpdate = @(v) soundOutputDevice.set(v)
let soundRecordDevice = nestWatched("soundRecordDevice", null)
let soundRecordDeviceUpdate = @(v) soundRecordDevice.set(v)

const SND_OCCLUSION_BLK_PATH = "sound/occlusionGPUInit"
let soundOcclusionState = nestWatched(
  "soundOcclusion", get_setting_by_blk_path(SND_OCCLUSION_BLK_PATH) ?? false
)
let soundOcclusionStateUpdate = @(v) soundOcclusionState.set(v)

return {
  soundOutputDevicesList, soundOutputDevicesListUpdate,
  soundRecordDevicesList, soundRecordDevicesListUpdate,
  soundOutputDevice, soundOutputDeviceUpdate,
  soundRecordDevice, soundRecordDeviceUpdate,
  soundOcclusionState, soundOcclusionStateUpdate, SND_OCCLUSION_BLK_PATH
}
