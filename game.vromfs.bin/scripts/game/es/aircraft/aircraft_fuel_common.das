module aircraft_fuel_common shared
require DngPlane
require GamePhys
require math

let MIN_FUEL_LOAD_PCT = 30

def private fuel_load_ratio(fuel_load_pct : int)
  return float(clamp(fuel_load_pct, MIN_FUEL_LOAD_PCT, 100)) / 100.0

def set_plane_fuel_load(var plane_net_phys : PlaneActor&; fuel_load_pct : int)
  let ratio = fuel_load_ratio(fuel_load_pct)
  assume mass = plane_net_phys.phys.M
  for i in range(0, MAX_FUEL_SYSTEMS)
    let maxAmount = getFuelMassMax(mass, i)
    if maxAmount > 0.f
      mass |> setFuel(maxAmount * ratio, i, /*limit*/true)

def refuel_plane_up_to_load(var plane_net_phys : PlaneActor&; fuel_load_pct : int)
  let ratio = fuel_load_ratio(fuel_load_pct)
  assume mass = plane_net_phys.phys.M
  for i in range(0, MAX_FUEL_SYSTEMS)
    let target = getFuelMassMax(mass, i) * ratio
    if target > 0.f && getFuelMassCurrent(mass, i) < target
      mass |> setFuel(target, i, /*limit*/true)
