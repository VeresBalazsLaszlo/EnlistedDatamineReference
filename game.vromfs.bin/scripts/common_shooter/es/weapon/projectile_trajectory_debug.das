options no_aot
require ecs
require ecs.common
require ecs.ecs_template
require DagorMath
require DagorDebug3D
require DagorConsole
require Ballistics
require math


[ecs_template]
struct projectile_trajectory_debug
  projectile_trajectory_debug : Tag


[es(tag=(gameClient, dev), no_order, REQUIRE=projectile_trajectory_debug)]
def projectile_trajectory_debug_draw(act : UpdateStageInfoRenderDebug)
  query() <| $ [es] (eid : EntityId;
                     projectile__prevPos : float3;
                     projectile__lifeTime : float;
                     projectile__maxLifeTime : float;
                     projectile_ballistics : ProjectileBallistics)
    let pos = projectile_ballistics.state.pos
    let speed = length(projectile_ballistics.state.vel)
    draw_debug_line_buffered(projectile__prevPos, pos, E3DCOLOR(0xFFFFFF00), 100000)
    draw_debug_sphere_buffered(pos, 0.01, E3DCOLOR(0xFFFFFFFF), 12, 100000)
    add_debug_text_mark(pos, "{eid}:{speed}:{projectile__lifeTime}:{projectile__maxLifeTime}", -1, 0., E3DCOLOR(0xFFFFFFFF))


[console_cmd(name="app.debug_projectile_trajectory")]
def toggle_projectile_trajectory_debug()
  var hadDebug = false
  query() <| $ [es(REQUIRE=projectile_trajectory_debug)] (eid : EntityId)
    destroyEntity(eid)
    hadDebug = true
  if !hadDebug
    createEntity("projectile_trajectory_debug")
