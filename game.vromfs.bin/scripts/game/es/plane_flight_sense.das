require ecs
require DagorSystem
require DagorDataBlock

[es(tag=gameClient, on_appear)]
def flight_sense_settings_ui(evt : Event; var plane_inertial_cam__flightSense : float&)
  dgs_get_settings() |> datablock_get_block("gameplay") <| $(daEditorBlock)
    let exist = daEditorBlock |> datablock_param_exists("plane_flight_sense", -1)
    if exist
      let optionValue = daEditorBlock |> datablock_getReal("plane_flight_sense", 0.f)
      plane_inertial_cam__flightSense = optionValue / 100.f
