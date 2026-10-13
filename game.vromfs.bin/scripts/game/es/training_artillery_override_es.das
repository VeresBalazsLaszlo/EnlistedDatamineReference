require ecs

// patch team aircraft intervals when team appears
[es(tag=server, on_appear)]
def training_artillery_team_es(evt : Event;
                               var team__aircraftRequestInterval : float&;
                               var team__aircraftRequestFromBoxInterval : float&)
  find_query() <| $ [es] (training_artillery__teamAircraftInterval : float)
    team__aircraftRequestInterval = training_artillery__teamAircraftInterval
    team__aircraftRequestFromBoxInterval = training_artillery__teamAircraftInterval
    return true

// patch player artillery timers when player appears
[es(tag=server, on_appear, after=artillery_player_init_es)]
def training_artillery_player_es(evt : Event;
                                 var artillery__baseInterval : float&;
                                 var artillery__interval : float&;
                                 var artillery__baseSpawnDelay : float&;
                                 var artillery__spawnDelay : float&;
                                 var artillery__missionStartDelay : float&)
  find_query() <| $ [es] (training_artillery__baseInterval : float;
                          training_artillery__baseSpawnDelay : float;
                          training_artillery__missionStartDelay : float)
    artillery__baseInterval = training_artillery__baseInterval
    artillery__interval = training_artillery__baseInterval
    artillery__baseSpawnDelay = training_artillery__baseSpawnDelay
    artillery__spawnDelay = training_artillery__baseSpawnDelay
    artillery__missionStartDelay = training_artillery__missionStartDelay
    return true

// patch aircraft_request__interval before it's used to set player cooldown
[es(tag=server, on_appear, before=aircraft_request_started_es)]
def training_artillery_aircraft_request_es(evt : Event;
                                           var aircraft_request__interval : float&)
  find_query() <| $ [es] (training_artillery__teamAircraftInterval : float)
    aircraft_request__interval = training_artillery__teamAircraftInterval
    return true

// patch supply cooldown before it's applied to player availability
[es(tag=server, on_appear, REQUIRE=supplyArtillery, before=create_supply_aircraft)]
def training_artillery_supply_es(evt : Event;
                                 var artillery__baseCooldown : float&)
  find_query() <| $ [es] (training_artillery__supplyBaseCooldown : float)
    artillery__baseCooldown = training_artillery__supplyBaseCooldown
    return true
