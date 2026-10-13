options no_aot

require app
require ecs
require game.es.net_console_macro
require enlisted.events_enlisted


/*

  USAGE: Add following components to an entity you want to draw trajectory of
         then use command 'debug.draw_trajectory' with 'server.cmd debug.draw_trajectory'
         so to create debug entity both on client and server

  _group{
    draw_trajectory__appearServerPosition:p3=0,0,0
    draw_trajectory__currServerPosition:p3=0,0,0
    draw_trajectory__prevServerPosition:p3=0,0,0

    draw_trajectory__appearClientPosition:p3=0,0,0
    draw_trajectory__currClientPosition:p3=0,0,0
    draw_trajectory__prevClientPosition:p3=0,0,0

    _track:b=yes
    _replicate:b=yes
  }

*/


[console_cmd(name="debug.draw_trajectory")]
def debug_draw_trajectory_cmd(frame_count : int = 20000)
  let found = find_query() <| $ [es(REQUIRE=debugDrawTrajectory)] (eid : EntityId)
    destroyEntity(eid)
    return true
  if !found
    createEntity("debug_draw_trajectory") <| $(init)
      init |> set("frames", frame_count)


[es(tag=server, on_appear)]
def debug_track_server_appearance(evt : Event;
                                  transform : float3x4;
                                  var draw_trajectory__appearServerPosition : float3&;
                                  var draw_trajectory__currServerPosition : float3&)
  query() <| $ [es(REQUIRE=debugDrawTrajectory)] ()
    draw_trajectory__appearServerPosition = transform[3]
    draw_trajectory__currServerPosition = transform[3]


[es(tag=server, no_order)]
def debug_track_server_trajectory(evt : ParallelUpdateFrameDelayed;
                                  transform : float3x4;
                                  var draw_trajectory__prevServerPosition : float3&;
                                  var draw_trajectory__currServerPosition : float3&)
  assume currP = draw_trajectory__currServerPosition
  assume prevP = draw_trajectory__prevServerPosition

  query() <| $ [es(REQUIRE=debugDrawTrajectory)] ()
    if transform[3] == currP
      return

    prevP = currP
    currP = transform[3]

