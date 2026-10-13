require ecs
require gameLibs.render_events.render_events

[es(before=prepare_human_cockpit_es, tag=render)]
def update_hero_cockpit_render_mode(info : UpdateStageInfoBeforeRender;
                                    var hero_cockpit__drawAboveGeometry : bool&)
  var lensRenderEnabled = false
  var isHeroCockpitCamera = false
  find_query() <| $ [es] (camera__active : bool;
                          isHeroCockpitCam : bool;
                          aim_data__lensRenderEnabled : bool = false;
                          aim_data__lensNodeId : int = -1)
    if camera__active
      isHeroCockpitCamera = isHeroCockpitCam
      lensRenderEnabled = aim_data__lensRenderEnabled && aim_data__lensNodeId >= 0
      return true
    return false
  if !isHeroCockpitCamera || lensRenderEnabled
    hero_cockpit__drawAboveGeometry = false
    return

  var isHeroInVehicle = false
  var isInHatchAndHoldingGun = false
  query() <| $ [es(REQUIRE=(cockpitEntity, watchedByPlr))] (isInVehicle : bool;
                                                            human_vehicle__isInHatch : bool = false;
                                                            human_vehicle__isHoldingGunPassenger : bool = false)
    isHeroInVehicle = isInVehicle
    isInHatchAndHoldingGun = human_vehicle__isInHatch && human_vehicle__isHoldingGunPassenger

  hero_cockpit__drawAboveGeometry = isInHatchAndHoldingGun || !isHeroInVehicle
