module weaponry_fx_render_common shared

require ecs
require ecs.safe
require danetlibs.weaponry_hit_fx.main.weaponry_fx_common
require danetlibs.weaponry_hit_fx.render.ricocheted_fx_common
require fx
require DngDm
require Dacoll
require DaWeapons
require Ballistics


def spawn_hit_effect(norm : float3;
                     pos : float3;
                     fx_name : string;
                     allow_paint_from_biome : bool = false;
                     rendinst_pool : int = -1;
                     desired_biome : string = "")
  if empty(fx_name) || fx_name == "-"
    return

  let tm = calc_effect_tm(pos, norm)
  let fxTemplate = getTemplateByName(fx_name)
  if fxTemplate == null
    return

  let lowestFxQuality = getTemplateComponent(*fxTemplate, "effect__lowestFxQuality") ?? 0
  if int(get_fx_target()) < (1 << lowestFxQuality)
    return

  if allow_paint_from_biome && (getTemplateComponent(*fxTemplate, "paint_from_biome") ?? false)
    createEntity("biome_fx_readback_info") <| $(init)
      init |> set("transform", tm)
      init |> set("fx_name_to_spawn", fx_name)
      if !empty(desired_biome)
        init |> set("biome_query__desiredBiomeName", desired_biome)
  else
    createEntity(fx_name) <| $(init)
      init |> set("transform", tm)
      init |> set("effect__riPoolUsedForColoring", rendinst_pool)


def spawn_hit_effect(hit_effect_descriptor : int;
                     expl_effect_descriptor : int;
                     launch_desc : LaunchDesc;
                     dm_projectile_state : ProjectileState;
                     projectile_ballistics : ProjectileBallistics;
                     norm : float3;
                     pos : float3;
                     mat_id : int;
                     riexHandle : riex_handle_t;
                     rendinstPool : int;
                     is_under_water : bool;
                     exploded : bool;
                     impact_result : EffectImpactResult;
                     projectile__lifeTime : float;
                     headColor : float3;
                     startHeadColor : float3;
                     startTime : float;
                     has_tracer_visual : bool)
  let fxInfo = get_projectile_fx_info(hit_effect_descriptor, expl_effect_descriptor,
                                      launch_desc, dm_projectile_state, projectile_ballistics, mat_id, is_under_water,
                                      exploded, impact_result)
  let fxName = fxInfo.fxName
  if fxInfo.effectGroup != null
    spawn_ricocheted_fx(pos, norm, *fxInfo.effectGroup, fxInfo.matId, impact_result, projectile__lifeTime, headColor, startHeadColor, startTime, has_tracer_visual)

  if empty(fxName)
    return

  var posAdjusted : float3
  var normAdjusted : float3

  if is_under_water
    var waterLevel = 0.0
    traceht_water(pos, waterLevel)
    posAdjusted = float3(pos.x, waterLevel, pos.z)
    normAdjusted = float3(0, 1, 0)
  else
    posAdjusted = pos
    normAdjusted = norm
  let isPaintFxOnHit = riex_isRiGenExtraValid(riexHandle) ? riex_isPaintFxOnHit(riexHandle) : true
  spawn_hit_effect(normAdjusted, posAdjusted, fxName, isPaintFxOnHit, rendinstPool)
  return