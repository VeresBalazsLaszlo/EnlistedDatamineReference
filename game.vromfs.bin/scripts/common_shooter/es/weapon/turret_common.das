module turret_common shared
require ecs
require DagorMathUtils

let AIM_DISTANCE = 1000.0

let
  TRIGGER_MAIN = 0
  TRIGGER_SECONDARY = 1
  TRIGGER_MG = 2
  TRIGGER_GRENADE_LAUNCHER = 3

def turret_calc_shoot_angles(vehicle_pos : float3&;
                             aim_pos : float3&)
  let shootFromPos = vehicle_pos + float3(0.0, 2.0, 0.0)
  let shootDir = normalize(aim_pos - shootFromPos)
  return dir_to_angles(shootDir)