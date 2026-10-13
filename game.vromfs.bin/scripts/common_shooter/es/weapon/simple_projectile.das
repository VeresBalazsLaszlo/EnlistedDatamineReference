require ecs
require app
require DaWeapons
require DaWeaponProps
require Dacoll
require Ballistics
require BallisticsProps
require DagorMath
require DagorSystem
require DngDm
require DngWeapon
require AnimV20
require GeomNodeTree
require GamePhys
require enlisted.events_enlisted
require ecs.safe
require PhysMat


[es(no_order)]
def update_simple_projectile(info : ParallelUpdateFrameDelayed;
                             eid : EntityId;
                             simple_projectile__spawnTime : float;
                             simple_projectile__destroyAtTime : float;
                             simple_projectile__deltaTime : float;
                             simple_projectile__traceRayMatId : int;
                             simple_projectile__acceleration : float3;
                             var simple_projectile__position : float3&;
                             var simple_projectile__velocity : float3&;
                             var simple_projectile__lastTick : int&)
  if info.curTime > simple_projectile__destroyAtTime
    destroyEntity(eid)
    return

  assume p = simple_projectile__position
  assume v = simple_projectile__velocity
  assume a = simple_projectile__acceleration
  assume dt = simple_projectile__deltaTime

  let curTick = floori((info.curTime - simple_projectile__spawnTime) / dt)
  let tickCount = curTick - simple_projectile__lastTick
  simple_projectile__lastTick = curTick

  for _i in range(tickCount)
    v += a * dt
    let dp = v * dt
    var traceLen = length(dp)
    if traceLen < 0.001
      destroyEntity(eid)
      return
    let dir = dp / traceLen
    var pmid = -1
    var norm = float3()
    var hit = false
    var hitWater = false
    using() <| $(var riDesc : RendInstDesc#)
      hit = traceray_normalized(p, dir, traceLen, pmid, norm, ETF_ALL, riDesc, simple_projectile__traceRayMatId)
      let traceEnd = p + dir * traceLen
      if traceray_water_at_time(p, traceEnd, info.curTime, traceLen)
        pmid = get_material_id("water3d")
        norm = float3(0.0, 1.0, 0.0)
        hit = true
        hitWater = true
    if hit
      p += dir * traceLen
      sendEvent(eid, SimpleProjectileHitScene(pos = p, norm = norm, pmid = pmid, hitWater = hitWater))
      sendEvent(eid, CmdDestoyProjectileEntity()) // destroy entity via event to properly handle sent events before actual destruction
      return
    p += dp


[es(on_appear)]
def init_simple_projectile(evt : Event;
                           simple_projectile__maxLifeTime : float;
                           var simple_projectile__spawnTime : float&;
                           var simple_projectile__destroyAtTime : float&)
  simple_projectile__spawnTime = get_sync_time()
  simple_projectile__destroyAtTime = simple_projectile__spawnTime + simple_projectile__maxLifeTime
