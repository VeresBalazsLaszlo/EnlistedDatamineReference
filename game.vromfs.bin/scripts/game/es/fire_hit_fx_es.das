require ecs
require common_shooter.events_common_shooter
require danetlibs.weaponry_hit_fx.main.physmat_fx_common
require DagorRandom
require math.base
require game.events_game
require RendInst

def create_fire_fx(pos : float3;
                   norm : float3;
                   mat_id : int;
                   fire_hit_fx__templateName : string;
                   fire_hit_fx__probability : float;
                   fire_hit_fx__minCosNormToVertical : float;
                   projectile__isUnderwater : bool;
                   attached_riexHandle : uint64)
  if projectile__isUnderwater || is_physmat_in_group(mat_id, "water") || dot(norm, float3(0, 1, 0)) < fire_hit_fx__minCosNormToVertical || rnd_float(0.0, 1.0) > fire_hit_fx__probability
    return

  createEntity(fire_hit_fx__templateName) <| $(init)
    var tm = IDENT_TM
    tm[3] = pos
    init |> set("transform", tm)
    init |> set("attached_riexHandle", attached_riexHandle)
    init |> set("fire_effect__norm", float3(0, 1, 0))


[es(tag=server)]
def projectile_create_fire_fx_on_explode(evt : CmdShellExplosionFx;
                                         scene_hit_place__pos : float3;
                                         scene_hit_place__norm : float3;
                                         scene_hit_place__matId : int;
                                         fire_hit_fx__templateName : string;
                                         fire_hit_fx__probability : float;
                                         fire_hit_fx__minCosNormToVertical : float;
                                         projectile__isUnderwater : bool)
  create_fire_fx(scene_hit_place__pos, scene_hit_place__norm, scene_hit_place__matId, fire_hit_fx__templateName, fire_hit_fx__probability, fire_hit_fx__minCosNormToVertical, projectile__isUnderwater, uint64(-1))


[es(tag=server)]
def projectile_create_fire_fx_on_hit(evt : EventProjectileHitScene;
                                     fire_hit_fx__templateName : string;
                                     fire_hit_fx__probability : float;
                                     fire_hit_fx__minCosNormToVertical : float;
                                     projectile__isUnderwater : bool)
  create_fire_fx(evt.pos, evt.norm, evt.matId, fire_hit_fx__templateName, fire_hit_fx__probability, fire_hit_fx__minCosNormToVertical, projectile__isUnderwater, evt.riexHandle)

[es(tag=server, REQUIRE_NOT=phys_obj_net_phys)]
def destroy_fire_effect_on_rendinst_destroy(evt : EventRendinstDestroyed;
                                            eid : EntityId;
                                            attached_riexHandle : riex_handle_t)
  if attached_riexHandle != RIEX_HANDLE_NULL && evt.riexHandle == attached_riexHandle
    destroyEntity(eid)