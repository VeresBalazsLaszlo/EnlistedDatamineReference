require ecs
require ecs.safe
require math
require player
require math.base
require DagorMath
require Dacoll
require DngNet
require game.es.events
require game.utils.team
require DagorSystem
require enlisted.game.es.artillery_radio_common
require enlisted.events_enlisted
require game.events_game
require game.es.paratroopers_common
require app
require ecs.common
require strings

[es(tag=server, track=(artillery__templates, respawner__squad), REQUIRE=artillery__templates)]
def artillery_menu_names_init(evt : Event;
                              respawner__squad : EntityId;
                              artillery_menu__namesBase : StringList;
                              army : string;
                              armies : Object;
                              var artillery_menu__names : StringList)
  clear(artillery_menu__names)
  var hasRocketArtillery = false
  var isRadomanSquad = false
  if !!respawner__squad
    let squadId = get_int(respawner__squad, "squad__id") ?? -1
    if squadId != -1
      assume squads = (armies[army] ?as Object)?.squads ?as Array
      if squads == null
        return
      let squadObj = (*squads)[squadId] as Object
      if squadObj == null
        return

      let hasAllArtillery = squadObj?.hasAllArtillery ?? false
      hasRocketArtillery = (squadObj?.hasRocketArtillery ?? false) || hasAllArtillery
      isRadomanSquad = ((squadObj?.squadType ?? "") == "radioman") || hasAllArtillery

  for artilleryName in artillery_menu__namesBase
    let artilleryTemplate = getTemplateByName(string(artilleryName))
    if (!hasRocketArtillery && templateHasComponent(*artilleryTemplate, "rocketArtillery") ||
        !isRadomanSquad && templateHasComponent(*artilleryTemplate, "aircraft_request"))
      continue
    push(artillery_menu__names, artilleryName)

[es(tag=gameClient, track=(artillery_menu__names, artillery__templates))]
def artillery_menu_items_init_es(evt : Event;
                                 eid : EntityId;
                                 artillery_menu__names : StringList;
                                 artillery__templates : StringList;
                                 artillery__interval : float;
                                 respawner__squad : EntityId;
                                 var artillery_menu__cooldown : FloatList;
                                 var artillery_menu__active : bool&;
                                 var artillery_menu__index : IntList)
  clear(artillery_menu__index)
  clear(artillery_menu__cooldown)
  resize(artillery_menu__index, length(artillery_menu__names))
  resize(artillery_menu__cooldown, length(artillery_menu__names))

  // training ground overrides all artillery cooldowns at runtime; show those instead of baked template defaults
  var trainingArtInterval = -1.
  var trainingAircraftInterval = -1.
  var trainingSupplyCooldown = -1.
  find_query() <| $ [es] (training_artillery__baseInterval : float;
                          training_artillery__teamAircraftInterval : float;
                          training_artillery__supplyBaseCooldown : float)
    trainingArtInterval = training_artillery__baseInterval
    trainingAircraftInterval = training_artillery__teamAircraftInterval
    trainingSupplyCooldown = training_artillery__supplyBaseCooldown
    return true

  var activeShellTypes = 0
  for artilleryMenuName, menuNum in artillery_menu__names, range(length(artillery_menu__names))
    var index = -1
    for artilleryTemplate, templateNum in artillery__templates, range(length(artillery__templates))
      if find(string(artilleryTemplate), string(artilleryMenuName)) >= 0
        index = templateNum
        break

    artillery_menu__index[menuNum] = index
    if index == -1
      continue

    activeShellTypes++

    let artilleryTemplate = getTemplateByName(string(artillery__templates[index]))
    if templateHasComponent(*artilleryTemplate, "aircraft_request")
      if trainingAircraftInterval >= 0.
        artillery_menu__cooldown[menuNum] = trainingAircraftInterval
      else
        let artilleryMulUnlock = get_float(respawner__squad, "squad__artilleryTimersMulUnlock") ?? 1.
        let reqInterval = getTemplateComponent(*artilleryTemplate, "aircraft_request__interval") ?? artillery__interval
        artillery_menu__cooldown[menuNum] = reqInterval * artilleryMulUnlock
    elif templateHasComponent(*artilleryTemplate, "supplyArtillery")
      artillery_menu__cooldown[menuNum] = trainingSupplyCooldown >= 0. ? trainingSupplyCooldown : (getTemplateComponent(*artilleryTemplate, "artillery__baseCooldown") ?? artillery__interval)
    else
      artillery_menu__cooldown[menuNum] = trainingArtInterval >= 0. ? trainingArtInterval : artillery__interval

  sendEvent(eid, CmdUpdateArtilleryMenu())
  artillery_menu__active = activeShellTypes > 1
