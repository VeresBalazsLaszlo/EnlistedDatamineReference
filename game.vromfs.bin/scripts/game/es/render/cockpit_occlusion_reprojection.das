require ecs
require WorldRenderer


[es(tag=gameClient, no_order, REQUIRE=watchedByPlr)]
def hero_set_cockpit_reprojection_mode_es(info : UpdateStageInfoAct;
                                          human_weap__currentGunEid : EntityId)
  var isReload = false;
  query(human_weap__currentGunEid) <| $ [es] (gun_anim__reloadProgress : float)
    isReload = gun_anim__reloadProgress > 0.0 && gun_anim__reloadProgress < 1.0

  let disableCockpitCulling = isReload;

  // Discard cockpit pixels during complex / fast animations, because cockpit reprojection only uses single matrix
  worldRenderer_setCockpitReprojectionMode(disableCockpitCulling ?
    CockpitReprojectionMode.COCKPIT_REPROJECT_OUT_OF_SCREEN : CockpitReprojectionMode.COCKPIT_REPROJECT_ANIMATED)
