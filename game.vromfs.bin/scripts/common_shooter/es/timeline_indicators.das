require ecs
require game.es.events
require game.events_game
require inventory
require game.es.inventory_common

[es(tag=gameClient, REQUIRE_NOT=hero)]
def time_line_event_on_death(evt : EventEntityDied;
                             vehicle : Tag const?;
                             isInVehicleHidden : bool = false)
  if has(evt.offender, "hero") || has(evt.offender, "heroVehicle")
    if vehicle != null
      broadcastEvent(EventTimelineEvent(title = "timeline/steam_explosion", desc = "timeline/steam_explosion/desc", icon = "steam_explosion", priority = 2, startTime = 0., clipMode = 1))
    elif !isInVehicleHidden
      broadcastEvent(EventTimelineEvent(title = "timeline/steam_combat", desc = "timeline/steam_combat/desc", icon = "steam_combat", priority = 0, startTime = 0., clipMode = 1))

[es(tag=gameClient, REQUIRE=hero)]
def time_line_event_on_hero_death(evt : EventEntityDied)
  broadcastEvent(EventTimelineEvent(title = "timeline/steam_death", desc = "timeline/steam_death/desc", icon = "steam_death", priority = 2, startTime = 0., clipMode = 1))

[es(tag=gameClient, on_event=(EventZoneIsAboutToBeCaptured, EventZoneCaptured), REQUIRE=capzone)]
def time_line_event_on_zone_cap(evt : Event)
  broadcastEvent(EventTimelineEvent(title = "timeline/steam_flag", desc = "timeline/steam_flag/desc", icon = "steam_flag", priority = 1, startTime = 0., clipMode = 1))