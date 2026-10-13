require ecs
require game.events_game

[es(REQUIRE_NOT=freeTankRespawnTag)]
def activate_entity(evt : EventEntityActivate; var active : bool&)
  active = evt.activate
