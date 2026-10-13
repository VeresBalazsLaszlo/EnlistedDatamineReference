options no_aot
require ecs
require ecs.ecs_template
require Gun
require DagorDebug3D
require DagorConsole
require math.base
require DaWeaponProps


[ecs_template]
struct gun_spread_debug_draw
  gunSpreadDebug : Tag


[console_cmd(name="gun.debug_spread", hint="Draw cone for hero's gun where bullets can go")]
def gun_spread_debug()
  var exists = false
  query() <| $ [es(REQUIRE=gunSpreadDebug)] (eid : EntityId)
    destroyEntity(eid)
    exists = true
  if !exists
    createEntity("gun_spread_debug_draw")


[es(tag=(render, dev), no_order, REQUIRE=gunSpreadDebug)]
def draw_gun_spread(evt : UpdateStageInfoRenderDebug)
  query() <| $ [es(REQUIRE=hero)] (human_weap__currentGunEid : EntityId)
    query(human_weap__currentGunEid) <| $ [es] (gun : Gun&; gun__chokeSpread : float = 0.0; gun__curShellId : ShellPropIds)
      let spreadConusLength = 100.0
      var projectileSpread = gun_calcSpread(gun).x // currently in Enlisted x and y spread is the same for all weapons
      let spawnProps = shell_spawn_try_get_props(int(gun__curShellId.shellId))
      if spawnProps != null
        projectileSpread += deg_to_rad(gun__chokeSpread)
      draw_debug_cone_buffered(gun.gunTm[3], gun.gunTm[3] + gun.gunTm[0] * spreadConusLength,
                               projectileSpread, E3DCOLOR(0xFFFFFFFF), 16, 1)
