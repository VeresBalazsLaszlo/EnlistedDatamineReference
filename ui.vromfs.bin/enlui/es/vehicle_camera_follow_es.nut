import "%dngscripts/ecs.nut" as ecs
from "settings" import get_setting_by_blk_path
from "%ui/hud/state/vehicleCameraFollowState.nut" import vehicleCameraFollow

let setFollowVehicleRotationQuery = ecs.SqQuery("setFollowVehicleRotationQuery", {
  comps_rw = [["human_input__followVehicleRotationInFirstPerson", ecs.TYPE_BOOL]]
})
vehicleCameraFollow.subscribe(function(follow) {
  setFollowVehicleRotationQuery.perform(function(_eid, comp) {
    comp.human_input__followVehicleRotationInFirstPerson = follow
  })
})

ecs.register_es("init_follow_vehicle_rotation_es",
  { onInit = function(_eid, comp) {
    let follow = get_setting_by_blk_path("gameplay/vehicle_camera_follow") ?? true
    comp.human_input__followVehicleRotationInFirstPerson = (follow == true)
  }},
  { comps_rw = [["human_input__followVehicleRotationInFirstPerson", ecs.TYPE_BOOL]] }
)
