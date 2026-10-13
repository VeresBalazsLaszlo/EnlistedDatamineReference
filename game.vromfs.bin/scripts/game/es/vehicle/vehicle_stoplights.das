require ecs
require vehicle

[es(no_order, tag=render)]
def vehicle_stoplights(info : UpdateStageInfoAct; vehicle_net_phys : VehiclePhysActor;
                       var vehicle__stopLightsState : bool&; var dynamic_material_channels_arr : Array;
                       vehicle__stopLightsChannel : int;
                       vehicle__stopLightsActiveColor, vehicle__stopLightsPassiveColor : float4)
  assume phys = vehicle_net_phys.phys
  assume state = phys.currentState
  let isBraking = state.leftSteeringBrake > 0f || state.rightSteeringBrake > 0f
  if isBraking != vehicle__stopLightsState
    vehicle__stopLightsState = isBraking
    var matParams = getRW_ecs_object(dynamic_material_channels_arr[vehicle__stopLightsChannel])
    if matParams != null
      let color = isBraking ? vehicle__stopLightsActiveColor : vehicle__stopLightsPassiveColor
      set(*matParams, "dynmat_param__emissive_color", color)
