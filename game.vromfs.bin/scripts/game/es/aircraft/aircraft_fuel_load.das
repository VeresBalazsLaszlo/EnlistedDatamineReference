require ecs
require DngPlane
require game.es.aircraft.aircraft_fuel_common

[es(tag=server, on_appear, REQUIRE=airplane)]
def aircraft_apply_fuel_load_on_spawn(evt : Event;
                                      ownedByPlayer : EntityId;
                                      var plane__fuelLoadPct : int&;
                                      var plane_net_phys : PlaneActor&)
  if !ownedByPlayer
    return
  var fuelPct = 100
  query(ownedByPlayer) <| $ [es] (respawner__fuelLoadPct : int)
    fuelPct = respawner__fuelLoadPct
  plane__fuelLoadPct = fuelPct
  if fuelPct >= 100
    return
  plane_net_phys |> set_plane_fuel_load(fuelPct)
