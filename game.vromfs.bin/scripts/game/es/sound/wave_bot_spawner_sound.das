require ecs
require soundEvent
require enlisted.events_enlisted
require game.utils.team
require gameLibs.pufd_events.pufd_events
require net_narrator.modules.net_narrator_events
require app
require game.events_game
require DngNet

[es(tag=sound)]
def wave_bot_spawner_sound_event(evt : EventWaveBotSpawned;
                                 team : int;
                                 var wave_bot_spawner_sound__playOnTime : float&;
                                 var wave_bot_spawner_sound__narratorPlayOnTime : float&;
                                 wave_bot_spawner_sound__narratorTimeAfterWaveStart : float;
                                 wave_bot_spawner_sound__timeAfterWaveStart : float)
  let text = get_local_player_team() == team ? "your_wave_started" : "enemy_wave_started"
  send_net_event(get_local_player_eid(), CmdHeroLogEvent(event = "ww1_event", text = "ww1_event/{text}", ttl = 30))
  if get_local_player_team() == team
    wave_bot_spawner_sound__playOnTime = get_sync_time() + wave_bot_spawner_sound__timeAfterWaveStart
  else
    wave_bot_spawner_sound__narratorPlayOnTime = wave_bot_spawner_sound__narratorTimeAfterWaveStart + get_sync_time()

[es(tag=sound)]
def wave_bot_spawner_sound_update(info : ParallelUpdateFrameDelayed;
                                  var wave_bot_spawner_sound__playOnTime : float&;
                                  var wave_bot_spawner_sound__narratorPlayOnTime : float&;
                                  wave_bot_spawner_sound__path : string)
  if wave_bot_spawner_sound__playOnTime > 0. && wave_bot_spawner_sound__playOnTime < info.curTime
    wave_bot_spawner_sound__playOnTime = -1.
    find_query() <| $ [es(REQUIRE=hero)] (transform : float3x4)
      oneshot(wave_bot_spawner_sound__path, transform[3])
      return true
  if wave_bot_spawner_sound__narratorPlayOnTime > 0. && wave_bot_spawner_sound__narratorPlayOnTime < info.curTime
    wave_bot_spawner_sound__narratorPlayOnTime = -1.
    broadcastEvent(CmdNarratorAboutLocalTeam(phrase = "defence", replace = false))