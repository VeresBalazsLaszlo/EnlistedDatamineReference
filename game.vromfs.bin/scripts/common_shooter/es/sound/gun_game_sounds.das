require ecs
require soundEvent
require soundSystem
require common_shooter.events_common_shooter
require net_narrator.modules.net_narrator_events
require enlisted.events_enlisted
require game.events_game
require game.es.events
require game.utils.team
require player
require math.base

def play_spawn_sound(sound : string; is_hero : bool; pos : float3)
  oneshot_far(is_hero ? "events/2504/sp/{sound}" : "events/2504/se/{sound}", pos)

[es(tag=sound)]
def spawn_voice_es(evt : CharsGungameLevelUpSound;
                   transform : float3x4)
  play_spawn_sound(evt.sound, evt.isHero, transform[3] + float3(0., 1.5, 0.))

[es(tag=sound)]
def gun_game_end_sound(evt : EventTeamRoundResult; chars_gun_game__matchEndSound : string)
  if evt.team == get_local_player_team()
    oneshot(chars_gun_game__matchEndSound, get_listener_pos())


// -------- narrator --------

[es(tag=sound, REQUIRE=localPlayer)]
def gun_game_narrator_on_new_leader(evt : EventGunGameNewLeader;
                                    eid aka local_player_eid : EntityId)
  if evt.newLeaderPlayerEid == local_player_eid
    broadcastEvent(CmdNarratorAboutLocalTeam(phrase = "youLeader", replace = false))
  else
    broadcastEvent(CmdNarratorAboutLocalTeam(phrase = "newLeader", replace = false))


[es(tag=sound, track=gun_game__currentLevel)]
def gun_game_narrator_on_enemy_almost_won(evt : Event;
                                          eid aka enemy_player_eid : EntityId;
                                          gun_game__currentLevel : int)
  if enemy_player_eid != get_local_player_eid()
    query() <| $ [es] (gun_game__levelsCount : int)
      if gun_game__currentLevel + 1 == gun_game__levelsCount
        broadcastEvent(CmdNarratorAboutLocalTeam(phrase = "enemyAlmostWon", replace = true))


// -------- tomahawk_throwable --------

[es(tag=sound, REQUIRE=human)]
def tomahawk_kill_human_sound(evt : EventEntityDied;
                              transform aka victim_transform : float3x4;
                              is_watched_sound : bool)

  find_query() <| $ [es] (shell__gun_props_id : int;
                          tomahawk_kill_human_sound__watched : string;
                          tomahawk_kill_human_sound__other : string)

    if evt.gunPropsId == shell__gun_props_id // create and use CharsGungameTomahawkKillHumanSound(server->client) if this is wrong

      query() <| $ [es] (var phys_obj_collision_sound__time : float&;
                         var phys_obj_collision_sound__event : SoundEvent&;
                         transform : float3x4)
        if distance_sq(transform[3], victim_transform[3]) < square(5.)
          phys_obj_collision_sound__time = -0.4
          release_immediate(phys_obj_collision_sound__event)
          phys_obj_collision_sound__event.enabled = false

      oneshot(is_watched_sound ? tomahawk_kill_human_sound__watched : tomahawk_kill_human_sound__other, victim_transform[3] + float3(0., 1., 0.))
      return true

    return false
