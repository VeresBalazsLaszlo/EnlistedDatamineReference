require ecs
require common_shooter.events_common_shooter
require game.es.events
require debug.logerr_once
require DngHuman
require HumanPhys

[es(REQUIRE=gun__bipodMandatory)]
def check_can_operate_gun_mandatory_bipod(evt : CmdWeapPhysUpdate; var gun__canAim : bool&)
  query(evt.owner) <| $ [es] (human_net_phys__isCrawl : bool; bipod__enabled : bool; var human_weap__canShoot : bool&)
    human_weap__canShoot = human_net_phys__isCrawl || bipod__enabled
    gun__canAim = human_weap__canShoot

[es(REQUIRE=gun__bipodMandatoryAds)]
def check_can_aim_gun_mandatory_bipod_ads(evt : CmdWeapPhysUpdate; var gun__canAim : bool&;
                                          gun__bipodMandatory : Tag const? = null)
  if gun__bipodMandatory != null
    logerr_once("gun has both gun__bipodMandatory and gun__bipodMandatoryAds, this is not intended")
  query(evt.owner) <| $ [es] (human_net_phys__isCrawl : bool; bipod__enabled : bool)
    gun__canAim = human_net_phys__isCrawl || bipod__enabled

[es(track=human_weap__currentGunEid)]
def check_can_operate_gun_on_weapon_change(evt : Event; human_weap__currentGunEid : EntityId; var human_weap__canShoot : bool&)
  human_weap__canShoot = !has(human_weap__currentGunEid, "gun__bipodMandatory")
