require ecs
require game.utils.sound_utils


[es(tag=server, on_event=EventBombSiteExplosion, REQUIRE_NOT=bomb_site__disableDestoy, before=bomb_site_destroy_on_detonation)]
def zombie_crater_explosion_net_sound(evt : Event;
                                      zombie_crater_explosion_net_sound__desc : string;
                                      transform : float3x4)
  broadcast_scene_net_sound(zombie_crater_explosion_net_sound__desc, transform[3])
