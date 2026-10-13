require ecs.ecs_quirrel
require daslib/quirrel_boost
require replay

[quirrel_bind(module_name="das.replay")]
def replay_rewind(time : float)
  find_query() <| $ [es(REQUIRE=replay__accelerationTime)] (eid : EntityId)
    destroyEntity(eid)
    return true

  createEntity("replay_acceleration_to") <| $(var init)
    init |> set("replay__accelerationTime", time)

// app_profile-based, true for the whole replay session (unlike the replayIsPlaying
// entity which appears only after EventLevelLoaded, i.e. after net events replay)
[quirrel_bind(module_name="das.replay")]
def is_playing_replay() : bool
  return is_replay_playing()