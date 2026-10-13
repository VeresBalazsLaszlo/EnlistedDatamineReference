options no_aot

require app
require ecs
require enlisted.events_enlisted
require DagorConsole
require DagorDebug3D


[es(on_appear, REQUIRE=debugDrawTrajectory)]
def debug_track_trajectory_activated(evt : Event)
  error("Debug track trajectory activated")


[es(on_disappear, REQUIRE=debugDrawTrajectory)]
def debug_track_trajectory_disactivated(evt : Event)
  error("Debug track trajectory disactivated")


[es(tag=gameClient, on_appear, track=draw_trajectory__appearServerPosition)]
def debug_draw_server_appearance(evt : Event; draw_trajectory__appearServerPosition : float3)
  query() <| $ [es(REQUIRE=debugDrawTrajectory)] (frames : int)
    draw_debug_sphere_buffered(draw_trajectory__appearServerPosition, 0.2, E3DCOLOR(0xFF00FF00), 12, frames)


[es(tag=netClient, on_appear)]
def debug_draw_client_appearance(evt : Event;
                                 transform : float3x4;
                                 var draw_trajectory__appearClientPosition : float3&;
                                 var draw_trajectory__currClientPosition : float3&)
  assume appearP = draw_trajectory__appearClientPosition
  assume currP = draw_trajectory__currClientPosition

  query() <| $ [es(REQUIRE=debugDrawTrajectory)] (frames : int)
    appearP = transform[3]
    currP = transform[3]

    draw_debug_sphere_buffered(appearP, 0.3, E3DCOLOR(0xFFFF0000), 12, frames)


[es(tag=gameClient, track=draw_trajectory__prevServerPosition)]
def debug_draw_server_trajectory(evt : Event;
                                 draw_trajectory__currServerPosition : float3;
                                 draw_trajectory__prevServerPosition : float3)
  assume currP = draw_trajectory__currServerPosition
  assume prevP = draw_trajectory__prevServerPosition

  query() <| $ [es(REQUIRE=debugDrawTrajectory)] (frames : int)
    if prevP == currP || prevP == float3(0)
      return

    draw_debug_line_buffered(prevP, currP, E3DCOLOR(0xFF00FF00), frames)
    draw_debug_sphere_buffered(currP, 0.05, E3DCOLOR(0xFF00FF00), 12, frames)


[es(tag=netClient, no_order)]
def debug_draw_client_trajectory(evt : ParallelUpdateFrameDelayed;
                                 transform : float3x4;
                                 var draw_trajectory__currClientPosition : float3&;
                                 var draw_trajectory__prevClientPosition : float3&)
  assume currP = draw_trajectory__currClientPosition
  assume prevP = draw_trajectory__prevClientPosition

  query() <| $ [es(REQUIRE=debugDrawTrajectory)] (frames : int)
    prevP = currP
    currP = transform[3]

    if currP == prevP || prevP == float3(0)
      return

    draw_debug_line_buffered(prevP, currP, E3DCOLOR(0xFFFF0000), frames)
    draw_debug_sphere_buffered(currP, 0.05, E3DCOLOR(0xFF0000FF), 12, frames)
