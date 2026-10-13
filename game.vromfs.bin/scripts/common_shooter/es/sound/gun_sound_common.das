module gun_sound_common shared
require ecs
require DagorMath
require sound_utils.modules.sound_player_common
require strings
require soundEvent
require soundHash


def get_gun_sound_pos(animchar_bbox : bbox3f)
  return (animchar_bbox.bmin.xyz + animchar_bbox.bmax.xyz) * 0.5


def add_gun_sound_to_owner_sound_group(var handle : SoundEventHandle&; world_pos : float3; gun__owner : EntityId)
  var shouldAbandon = true
  query(gun__owner) <| $ [es] (var sound_event_group : SoundEventGroup&; transform : float3x4)
    shouldAbandon = false
    let localPos = inverse(transform) * world_pos
    add_sound(sound_event_group, sound_hash(""), localPos, handle, 4)
  if shouldAbandon
    abandon(handle)


def make_gun_shot_sound_path_str(shot_path, tags : Object; is_watched, is_single_shot : bool) : string
  return make_final_path_str(shot_path, tags, is_watched, is_single_shot ? "shot_single" : "shot_loop")


def make_gun_shot_sound_path_str(shot_path : Object; path_id : int; is_watched, is_single_shot : bool) : string
  return make_final_path_str(shot_path, path_id, is_watched, is_single_shot ? "shot_single" : "shot_loop")


def is_watched_gun_sound(gun__owner : EntityId) : bool
  var isWatched = false
  query(gun__owner) <| $ [es] (is_watched_sound : bool; human_anim__vehicleSelected = INVALID_ENTITY_ID)
    isWatched = is_watched_sound
    query(human_anim__vehicleSelected) <| $ [es] (is_watched_sound : bool)
      isWatched ||= is_watched_sound
  return isWatched

/*
[es(tag=sound, on_appear, track=gun__owner)]
def gun_sound_watched_track(evt : Event
                            gun__owner : EntityId
                            var gun_sound__isWatched : bool&)
  gun_sound__isWatched = is_watched_gun_sound(gun__owner)

[es(tag=sound, track=is_watched_sound, REQUIRE=is_watched_sound)]
def is_watched_sound_track_gun_sound_watched(evt : Event)
  query() <| $ [es] (gun__owner : EntityId; var gun_sound__isWatched : bool&)
    gun_sound__isWatched = is_watched_gun_sound(gun__owner)

[es(tag=sound, track=human_anim__vehicleSelected, REQUIRE=human_anim__vehicleSelected)]
def human_anim_vehicle_selected_track_gun_sound_watched(evt : Event)
  query() <| $ [es] (gun__owner : EntityId; var gun_sound__isWatched : bool&)
    gun_sound__isWatched = is_watched_gun_sound(gun__owner)
*/
