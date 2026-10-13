require ecs
require ecs.safe
require PhysMat
require DaWeapons
require ecs.common
require debug.logerr_once
require Dacoll
require BallisticsProps
require DngWeaponRender
require BloodPuddles
require DngWeapon
require AnimV20
require DagorMath
require CollRes
require math.base
require danetlibs.weaponry_hit_fx.main.weaponry_fx_common
require Ballistics
require strings
require daslib/sort_boost
require DngDm
require danetlibs.dm.dm_events
require RendInst
require danetlibs.weaponry_hit_fx.render.weaponry_fx_render_common
require danetlibs.weaponry_hit_fx.main.weaponry_hit_fx_forward_events
require player


[es(tag=render)]
def projectile_hit_scene_es(evt : EventProjectileHitScene;
                            launch_desc : LaunchDesc;
                            dm_projectile_state : ProjectileState;
                            projectile_ballistics : ProjectileBallistics;
                            projectile__hitEffectDescriptor : int;
                            projectile__explEffectDescriptor : int;
                            projectile__isUnderwater : bool;
                            projectile__exploded : bool;
                            projectile__lifeTime : float;
                            projectile_visual_tracer__headColor : float3 = float3(1, 0.431, 0.314);
                            projectile_visual_tracer__startHeadColor : float3 = float3(1, 0.431, 0.314);
                            projectile_visual_tracer__startTime : float = 1.0;
                            projectile_visual_tracer__id : int = -1)
  if int(launch_desc.shellId.shellId) < 0
    return
  let hasTracerVisual = projectile_visual_tracer__id >= 0
  if !evt.sceneIntersectionsExceeded || (evt.shouldStop && evt.allowDetonation)
    let impactResult = (evt.shouldStop ? EffectImpactResult.Stop :
                        evt.ricochetAngle != 0.0 ? EffectImpactResult.Ricochet :
                        EffectImpactResult.Penetration)
    spawn_hit_effect(projectile__hitEffectDescriptor, projectile__explEffectDescriptor,
                 launch_desc, dm_projectile_state, projectile_ballistics, evt.norm, evt.pos, evt.matId, evt.riexHandle,
                 evt.rendinstPool, projectile__isUnderwater, projectile__exploded, impactResult,
                 projectile__lifeTime, projectile_visual_tracer__headColor, projectile_visual_tracer__startHeadColor,
                 projectile_visual_tracer__startTime, hasTracerVisual)
    if impactResult == EffectImpactResult.Ricochet
      let newDir = normalize_default(projectile_ballistics.state.vel, float3(1, 0, 0))
      spawn_hit_effect(projectile__hitEffectDescriptor, projectile__explEffectDescriptor,
                   launch_desc, dm_projectile_state, projectile_ballistics, newDir, evt.pos, evt.matId, evt.riexHandle,
                   evt.rendinstPool, projectile__isUnderwater, projectile__exploded, EffectImpactResult.AwayRicochet,
                   projectile__lifeTime, projectile_visual_tracer__headColor, projectile_visual_tracer__startHeadColor,
                   projectile_visual_tracer__startTime, hasTracerVisual)


[es(tag=render)]
def fx_on_shell_explosion_es(evt : CmdShellExplosionFx;
                             scene_hit_place__matId : int;
                             scene_hit_place__pos : float3;
                             scene_hit_place__norm : float3;
                             launch_desc : LaunchDesc;
                             dm_projectile_state : ProjectileState;
                             projectile_ballistics : ProjectileBallistics;
                             projectile__isUnderwater : bool;
                             projectile__hitEffectDescriptor : int;
                             projectile__explEffectDescriptor : int;
                             projectile__lastDamagedRiexHandle : uint64;
                             projectile__lifeTime : float;
                             projectile_visual_tracer__headColor : float3 = float3(1, 0.431, 0.314);
                             projectile_visual_tracer__startHeadColor : float3 = float3(1, 0.431, 0.314);
                             projectile_visual_tracer__startTime : float = 1.0;
                             projectile_visual_tracer__id : int = -1)
  if int(launch_desc.shellId.shellId) < 0
    return
  let hasTracerVisual = projectile_visual_tracer__id >= 0
  spawn_hit_effect(projectile__hitEffectDescriptor, projectile__explEffectDescriptor,
                             launch_desc, dm_projectile_state, projectile_ballistics, scene_hit_place__norm, scene_hit_place__pos, scene_hit_place__matId,
                             projectile__lastDamagedRiexHandle, -1, projectile__isUnderwater,
                             /*exploded=*/true,
                             EffectImpactResult.Stop,
                             projectile__lifeTime,
                             projectile_visual_tracer__headColor, projectile_visual_tracer__startHeadColor,
                             projectile_visual_tracer__startTime, hasTracerVisual)


def spawn_human_binded_fx(fx_tm : float3x4; itm : float3x4; effect_template : string; eid : EntityId; node_coll_id : int; color_mult : E3DCOLOR)
  createEntity(effect_template) <| $(var init)
    init |> set("transform", fx_tm)
    init |> set("effect__colorMult", color_mult)
    init |> set("entity_binded_effect__entity", eid)
    init |> set("entity_binded_effect__collNodeId", node_coll_id)
    init |> set("entity_binded_effect__localEmitter", itm * fx_tm)

def gen_fx_tm(pos : float3; dir : float3; scale : float)
  var tm = IDENT_TM
  tm[1] = normalize(dir)
  tm[2] = normalize(cross(float3(1, 0, 0), dir))
  tm[0] = normalize(cross(dir, tm[2]))
  for i in range(3)
    tm[i] = tm[i] * scale

  tm[3] = pos
  return tm

def is_blood_enabled()
  var isEnabled = true
  find_query <| $ [es] (isBloodEnabled : bool)
    isEnabled = isBloodEnabled
    return true
  return isEnabled

def get_blood_color()
  var bloodColor = E3DCOLOR(0xFFFFFFFF)
  query() <| $ [es] (isBloodEnabled : bool; disabledBloodColor : E3DCOLOR)
    if !isBloodEnabled
      bloodColor = disabledBloodColor
  return bloodColor

def human_spawn_blood_fx(victim_eid : EntityId; coll_node_id : int; blood_splash : HitBloodType;
                         pos : float3; dir : float3; scale : float; norm : float3; shellId : int; projectile__fleshEffectCaliberGroup : float = -1.)
  var success = false
  if !is_blood_enabled()
    return true

  let heroEid = get_Eid(get_local_player_eid(), "possessed") ?? INVALID_ENTITY_ID
  if victim_eid != heroEid
    let blood_on_screen_eid = getSingletonEntity("blood_on_screen")
    if !!blood_on_screen_eid
      sendEvent(blood_on_screen_eid, AmbientBloodOnScreenRender(source_pos = pos, source_norm = norm))

  query(victim_eid) <| $ [es] (transform : float3x4;
                               animchar : AnimcharBaseComponent;
                               collres : CollisionResource;
                               human__overrideBloodFx : string = "";
                               human__caliberFleshEffects : float = 0.01f)

    find_query() <| $ [es] (global_hit_fx__fleshEffects : Object)
      var hitCaliber = human__caliberFleshEffects
      if projectile__fleshEffectCaliberGroup < 0.
        let ballProjProps = projectile_try_get_props(shellId)
        hitCaliber = (ballProjProps?.caliber ?? hitCaliber) * 1000.0 //magic const to convert m to mm
      else
        hitCaliber = projectile__fleshEffectCaliberGroup
      var minFound = FLT_MAX
      var hitEntryFx = ""
      var hitSideFx = ""
      var hitExitFx = ""

      var maxFound = 0.f
      var maxHitEntryFx = ""
      var maxHitSideFx = ""
      var maxHitExitFx = ""

      for it in global_hit_fx__fleshEffects
        let currentCaliber = float(it.key)
        if hitCaliber < currentCaliber && minFound > currentCaliber
          minFound = currentCaliber
          let caliberFleshEffects = get_ecs_object(it.value)
          hitEntryFx = get_string(caliberFleshEffects, "hitEntryFx", "")
          hitSideFx = get_string(caliberFleshEffects, "hitSideFx", "")
          hitExitFx = get_string(caliberFleshEffects, "hitExitFx", "")
        elif hitEntryFx == "" && maxFound < currentCaliber
          let caliberFleshEffects = get_ecs_object(it.value)
          maxHitEntryFx = get_string(caliberFleshEffects, "hitEntryFx", "")
          maxHitSideFx = get_string(caliberFleshEffects, "hitSideFx", "")
          maxHitExitFx = get_string(caliberFleshEffects, "hitExitFx", "")
          maxFound = currentCaliber

      hitEntryFx = hitEntryFx == "" ? maxHitEntryFx : hitEntryFx
      if hitEntryFx == ""
        if length(global_hit_fx__fleshEffects) > 0
          logerr("human_spawn_blood_fx: Couldn't find effect hit in global_hit_fx__fleshEffects")
        return true
      success = true

      hitSideFx = hitSideFx == "" ? maxHitSideFx : hitSideFx
      hitSideFx = empty(human__overrideBloodFx) ? hitSideFx : human__overrideBloodFx

      hitExitFx = hitExitFx == "" ? maxHitExitFx : hitExitFx
      hitExitFx = empty(human__overrideBloodFx) ? hitExitFx : human__overrideBloodFx

      let bloodColor = get_blood_color()
      var nodeTm : float3x4
      collres_get_collision_node_tm(collres, coll_node_id, transform, animchar.nodeTree, nodeTm)
      let itm = inverse(nodeTm)
      spawn_human_binded_fx(gen_fx_tm(pos, -dir, scale), itm, hitEntryFx, victim_eid, coll_node_id, bloodColor)
      let reflectedDir = dir - 2. * dot(norm, dir) * norm
      if hitSideFx != "" && length_sq(reflectedDir) > 1e-5f
        spawn_human_binded_fx(gen_fx_tm(pos, ((normalize(reflectedDir) + norm) * 0.5f), scale), itm, hitSideFx, victim_eid, coll_node_id, bloodColor)

      if blood_splash != HitBloodType.TWO_SIDE || hitExitFx == "" || length_sq(dir) < FLT_EPSILON
        return true
      let t = 2.
      let tracePos = pos + 2. * dir
      let invDir = -dir
      collres_traceray(collres, transform, animchar.nodeTree, tracePos, invDir, t, true, uint8(BehaviorFlag.TRACEABLE)) <| $(find : bool; isects : CollResIntersectionsType#)
        if find
          let exitNodeId = int(isects[length(isects) - 1].collisionNodeId)
          spawn_human_binded_fx(gen_fx_tm(pos + (2.0f - t) * dir, dir, scale), itm, hitExitFx, victim_eid, exitNodeId, bloodColor)
      return true

  return success

//This is for vehicles only!
//Hit effects for other surfaces are taken care of in projectile_hit_scene_es
[es(tag=render)]
def on_shell_hit_entity_fx_es(evt : EventOnHitByProjectile; transform : float3x4)
  let pos = transform * evt.localHitPos
  let norm = rotate(transform, evt.localNormal)
  let pmid = get_material_id("steel")
  query(evt.projectileEid) <| $ [es] (launch_desc : LaunchDesc;
                                      dm_projectile_state : ProjectileState;
                                      projectile_ballistics : ProjectileBallistics;
                                      projectile__hitEffectDescriptor : int;
                                      projectile__explEffectDescriptor : int;
                                      projectile__isUnderwater : bool;
                                      projectile__exploded : bool;
                                      projectile__lifeTime : float;
                                      projectile_visual_tracer__headColor : float3 = float3(1, 0.431, 0.314);
                                      projectile_visual_tracer__startHeadColor : float3 = float3(1, 0.431, 0.314);
                                      projectile_visual_tracer__startTime : float = 1.0;
                                      projectile_visual_tracer__id : int = -1)
    let hasTracerVisual = projectile_visual_tracer__id >= 0
    spawn_hit_effect(projectile__hitEffectDescriptor, projectile__explEffectDescriptor,
                               launch_desc, dm_projectile_state, projectile_ballistics, norm, pos, pmid,
                               RIEX_HANDLE_NULL, /*rendinstPool*/ -1, projectile__isUnderwater, projectile__exploded, EffectImpactResult.Stop,
                               projectile__lifeTime, projectile_visual_tracer__headColor, projectile_visual_tracer__startHeadColor,
                                 projectile_visual_tracer__startTime, hasTracerVisual)
    if evt.pierced
      spawn_hit_effect(projectile__hitEffectDescriptor, projectile__explEffectDescriptor,
                   launch_desc, dm_projectile_state, projectile_ballistics, norm, pos, pmid,
                   RIEX_HANDLE_NULL, /*rendinstPool*/ -1, projectile__isUnderwater, projectile__exploded, EffectImpactResult.VehicleDamage,
                   projectile__lifeTime, projectile_visual_tracer__headColor, projectile_visual_tracer__startHeadColor,
                                 projectile_visual_tracer__startTime, hasTracerVisual)

[es(tag=render)]
def on_shell_hit_entity_blood_fx_es(evt : EventOnHitBloodFx; eid : EntityId)
  if (evt.blood_splash == HitBloodType.NONE)
    return
  query(evt.projectile_eid) <| $ [es] (projectile__fleshEffectCaliberGroup : float = -1.)
    human_spawn_blood_fx(eid, evt.coll_node, evt.blood_splash, evt.pos, evt.hit_dir, /*scale*/ 1., evt.norm, evt.shell_id, projectile__fleshEffectCaliberGroup)

  if evt.blood_splash == HitBloodType.TWO_SIDE
    create_blood_puddle_emitter(eid, evt.coll_node)
  elif evt.blood_splash == HitBloodType.ONE_SIDE
    add_hit_blood_effect(evt.pos, evt.hit_dir)

//This is for ricochetting off vehicles only!
//Ricochetting off other surfaces is taken care of in projectile_hit_scene_es
[es(tag=render)]
def on_ricochet_vehicle_fx_es(evt : EventOnRicochet; transform : float3x4)
  let pos = transform * evt.localHitPos
  let norm = rotate(transform, evt.localNormal)

  query(evt.projectileEid) <| $ [es] (launch_desc : LaunchDesc;
                                      dm_projectile_state : ProjectileState;
                                      projectile_ballistics : ProjectileBallistics;
                                      projectile__hitEffectDescriptor : int;
                                      projectile__explEffectDescriptor : int;
                                      projectile__isUnderwater : bool;
                                      projectile__exploded : bool;
                                      projectile__lifeTime : float;
                                      projectile_visual_tracer__headColor : float3 = float3(1, 0.431, 0.314);
                                      projectile_visual_tracer__startHeadColor : float3 = float3(1, 0.431, 0.314);
                                      projectile_visual_tracer__startTime : float = 1.0;
                                      projectile_visual_tracer__id : int = -1)
    let hasTracerVisual = projectile_visual_tracer__id >= 0
    let newDir = normalize_default(projectile_ballistics.state.vel, float3(1, 0, 0))
    spawn_hit_effect(projectile__hitEffectDescriptor, projectile__explEffectDescriptor,
                 launch_desc, dm_projectile_state, projectile_ballistics, norm, pos, get_material_id("steel"),
                 RIEX_HANDLE_NULL, /*rendinstPool*/ -1, projectile__isUnderwater, projectile__exploded, EffectImpactResult.Ricochet,
                 projectile__lifeTime, projectile_visual_tracer__headColor, projectile_visual_tracer__startHeadColor,
                 projectile_visual_tracer__startTime, hasTracerVisual)
    spawn_hit_effect(projectile__hitEffectDescriptor, projectile__explEffectDescriptor,
                 launch_desc, dm_projectile_state, projectile_ballistics, newDir, pos, get_material_id("steel"),
                 RIEX_HANDLE_NULL, /*rendinstPool*/ -1, projectile__isUnderwater, projectile__exploded, EffectImpactResult.AwayRicochet,
                 projectile__lifeTime, projectile_visual_tracer__headColor, projectile_visual_tracer__startHeadColor,
                 projectile_visual_tracer__startTime, hasTracerVisual)

def find_effect_group(effect_groups : Array;
                      effect_group_name : string)
  var resObj : Object const?
  for elem in effect_groups
    let effectGroup = elem as Object
    let val = get_string(*effectGroup, "name", "")
    if val == effect_group_name
      resObj = effectGroup
      break
  return resObj

[es(tag=render)]
def on_shell_hit_scene_client_es(evt : EventShellOnSceneHit;
                                 global_hit_fx__effectGroups : Array)
  let effectGroup = find_effect_group(global_hit_fx__effectGroups, evt.shellEffectGroupName)
  let fxName = get_projectile_fx_name_from_effect_group(*effectGroup, evt.pmid)
  let isPaintFxOnHit = riex_isRiGenExtraValid(evt.riexHandle) ? riex_isPaintFxOnHit(evt.riexHandle) : true
  spawn_hit_effect(evt.norm, evt.pos, fxName, isPaintFxOnHit)

[es(tag=render)]
def on_shell_hit_human_blood_effect_es(evt : EventShellOnHumanCreateBlood;
                                       eid : EntityId)
  human_spawn_blood_fx(eid, evt.nodeId, HitBloodType.TWO_SIDE, evt.pos, evt.dir, /*scale*/ 1., evt.norm, -1)
