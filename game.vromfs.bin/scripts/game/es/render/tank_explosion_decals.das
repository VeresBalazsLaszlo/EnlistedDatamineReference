require ecs
require math.base
require math.random
require DagorMath
require CollRes
require enlisted.events_enlisted


[es(no_order, track=isExploded)]
def create_decal_on_tank_explosion(evt : Event;
                                   isExploded : bool;
                                   transform : float3x4;
                                   collres : CollisionResource;
                                   tank_explosion_decal__height : float;
                                   tank_explosion_decal__sideScale : float;
                                   tank_explosion_decal__riTemplate : string)
  if isExploded && !empty(tank_explosion_decal__riTemplate)
    let quat = quat_from_euler(rnd_float(0f, TWOPI), 0f, 0f)
    let pos = transform[3]
    let bbox = BBox3(collres.vFullBBox)
    let sideSize = min(bbox.width.x, bbox.width.z)
    let scale = sideSize * tank_explosion_decal__sideScale
    let decalTm = float3x4(compose(pos, quat, float3(scale, tank_explosion_decal__height, scale)))
    createEntity(tank_explosion_decal__riTemplate) <| $(init)
      init |> set("transform", decalTm)

