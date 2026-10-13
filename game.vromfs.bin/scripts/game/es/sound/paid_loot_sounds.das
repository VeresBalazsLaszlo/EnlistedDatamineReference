require ecs
require sound_utils.modules.sound_player_common
require soundSystem
require common_shooter.events_common_shooter
require game.events_game
require enlisted.events_enlisted
require game.es.events


[es(tag=sound, REQUIRE=watchedByPlr)]
def buy_loot_ammo_sound(evt : CmdUsefulBoxCompleteUse;
                        sound_preset__isLoaded : bool;
                        @shared_comp human_loot_sound__paths : Object;
                        sound_tags : Object)
  if has(evt.box, "paid_loot__ressuplyDefCost") && sound_preset__isLoaded
    sound_player_common::play_path("buyAmmo", human_loot_sound__paths, sound_tags, true/*is_watched_sound*/, get_listener_pos())
