require ecs
require ecs.common
require soundEvent
require soundSystem
require enlisted.events_enlisted
require game.events_game
require game.utils.team
require DagorDataBlock
require DagorSystem
require sound_utils.modules.sound_player_common


[es(tag=sound, on_appear)]
def capzone_capturing_sound_enabled_init(evt : Event; var human__capzoneCapturingSoundEnabled : bool&)
  human__capzoneCapturingSoundEnabled = dgs_get_settings() |> datablock_get_block_by_name("sound") |> datablock_getBool("human_capzone_capturing_sound_enabled", true)


[es(tag=sound)]
def capzone_capturing_sounds_on_captured(evt : EventZoneCaptured;
                                         eid aka capzone_eid : EntityId;
                                         capzone__alwaysHide : bool)
  if evt.zone == capzone_eid && !capzone__alwaysHide
    find_query() <| $ [es(REQUIRE=hero)] (team aka hero_team : int;
                                          capturer__capZonesIn : EidList;
                                          human__capzoneCapturedSoundPath : string)
      if is_teams_friendly(hero_team, evt.team) && find_index(capturer__capZonesIn, capzone_eid) >= 0
        oneshot(human__capzoneCapturedSoundPath)
      return true


// vehicle rule is server side only, zones the hero may not capture are already excluded from capturer__capZonesIn
def is_hero_capturing_something(capturer__capZonesIn : EidList; hero_team : int; is_downed : bool) : bool
  var isCapturing = false
  for zoneEid in capturer__capZonesIn
    query(zoneEid) <| $ [es(REQUIRE_NOT=(trainZone, trainTriggerable))] (capzone__captureStatus : int; capzone__capTeam : int; zone__excludeDowned : ecs::Tag const?)
      isCapturing ||= (capzone__captureStatus != 0 && is_teams_friendly(hero_team, capzone__capTeam) &&
                      (!is_downed || zone__excludeDowned == null))
  return isCapturing


[es(tag=sound, on_appear, track=(capturer__capZonesIn, isDowned, human__capzoneCapturingSoundEnabled, sound_preset__isLoaded), REQUIRE=hero, REQUIRE_NOT=deadEntity)]
def capzone_capturing_sounds_track_hero_zones_in(evt : Event;
                                                 sound_preset__isLoaded : bool;
                                                 capturer__capZonesIn : EidList;
                                                 team aka hero_team : int;
                                                 isDowned : bool;
                                                 human__capzoneCapturingSoundPath : string;
                                                 human__capzoneCapturingSoundEnabled : bool;
                                                 var human__capzoneCapturingSoundEvent : SoundEvent&)
  let isCapturing = human__capzoneCapturingSoundEnabled && is_hero_capturing_something(capturer__capZonesIn, hero_team, isDowned) && sound_preset__isLoaded
  human__capzoneCapturingSoundEvent |> play_or_release(human__capzoneCapturingSoundPath, get_listener_pos(), isCapturing)


[es(tag=sound, on_disappear, REQUIRE=hero, REQUIRE_NOT=deadEntity)]
def capzone_capturing_sounds_on_disappear(evt : Event;
                                          var human__capzoneCapturingSoundEvent : SoundEvent&)
  release_play_or(human__capzoneCapturingSoundEvent)


[es(tag=sound, track=(capzone__captureStatus, capzone__capTeam), REQUIRE=(capzone__captureStatus, capzone__capTeam), REQUIRE_NOT=(trainZone, trainTriggerable))]
def capzone_capturing_sounds_track_capture_status(evt : Event)
  query() <| $ [es(REQUIRE=hero, REQUIRE_NOT=deadEntity)] (sound_preset__isLoaded : bool;
                                                           capturer__capZonesIn : EidList;
                                                           team aka hero_team : int;
                                                           isDowned : bool;
                                                           human__capzoneCapturingSoundPath : string;
                                                           human__capzoneCapturingSoundEnabled : bool;
                                                           var human__capzoneCapturingSoundEvent : SoundEvent&)
    let isCapturing = human__capzoneCapturingSoundEnabled && is_hero_capturing_something(capturer__capZonesIn, hero_team, isDowned) && sound_preset__isLoaded
    human__capzoneCapturingSoundEvent |> play_or_release(human__capzoneCapturingSoundPath, get_listener_pos(), isCapturing)
