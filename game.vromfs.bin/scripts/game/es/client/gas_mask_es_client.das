require ecs
require enlisted.events_enlisted
require DngHuman
require DngCamera
require AnimV20
require DagorMath
require math.base
require gameLibs.render_events.render_events


// Create/destroy cockpit on hero switch
[es(tag=gameClient, track=possessedByPlr, REQUIRE_NOT=deadEntity)]
def gas_mask_cockpit_on_hero_change(evt : Event;
                                    eid : EntityId;
                                    possessedByPlr : EntityId;
                                    human_gas_mask__active : bool;
                                    human_gas_mask__cockpitTemplate : string;
                                    var human_gas_mask__cockpitEid : EntityId&)
  if !possessedByPlr && !!human_gas_mask__cockpitEid
    destroyEntity(human_gas_mask__cockpitEid)
    human_gas_mask__cockpitEid = INVALID_ENTITY_ID
  elif !!possessedByPlr && human_gas_mask__active && !human_gas_mask__cockpitEid
    human_gas_mask__cockpitEid = createEntity(human_gas_mask__cockpitTemplate) <| $(var init : ComponentsInitializer)
      set(init, "animchar_attach__attachedTo", eid)
      set(init, "cockpit__isHeroInCockpit", true)


// Cockpit creation/destruction tied to cosmetic face mask visibility
[es(tag=gameClient, track=slot_attach__visible, REQUIRE=gasMaskFace)]
def gas_mask_cockpit_toggle(evt : Event;
                            slot_attach__visible : bool;
                            animchar_attach__attachedTo : EntityId)
  query(animchar_attach__attachedTo) <| $ [es] (animchar_attach__attachedTo : EntityId)
    query(animchar_attach__attachedTo) <| $ [es(REQUIRE=hero)] (human_gas_mask__cockpitTemplate : string;
                                                                var human_gas_mask__cockpitEid : EntityId&)
      if slot_attach__visible && !human_gas_mask__cockpitEid
        human_gas_mask__cockpitEid = createEntity(human_gas_mask__cockpitTemplate) <| $(var init : ComponentsInitializer)
          set(init, "animchar_attach__attachedTo", animchar_attach__attachedTo)
          set(init, "cockpit__isHeroInCockpit", true)
      elif !slot_attach__visible && !!human_gas_mask__cockpitEid
        destroyEntity(human_gas_mask__cockpitEid)
        human_gas_mask__cockpitEid = INVALID_ENTITY_ID


// Destroy cockpit on death
[es(tag=gameClient, on_event=(EventBeforeEntityRecreatedOnDeath, EventEntityDied))]
def gas_mask_cockpit_on_death(evt : Event;
                              var human_gas_mask__cockpitEid : EntityId&)
  if !!human_gas_mask__cockpitEid
    destroyEntity(human_gas_mask__cockpitEid)
    human_gas_mask__cockpitEid = INVALID_ENTITY_ID


[es(tag=render, REQUIRE=hero, after=after_camera_sync)]
def gas_mask_update_cockpit(info : UpdateStageInfoAct;
                            human_gas_mask__cockpitEid : EntityId;
                            human_net_phys : HumanActor)
  query(human_gas_mask__cockpitEid) <| $ [es] (cockpit__offset : float3;
                                               cockpit__scale : float3;
                                               var transform aka cockpit_transform : float3x4&;
                                               var animchar : AnimcharBaseComponent;
                                               var animchar_node_wtm : AnimcharNodesMat44;
                                               var animchar_render__root_pos : vec4f&;
                                               cockpit__leanAngleMult : float = 0.33)
    query(get_cur_cam_entity()) <| $ [es] (transform aka cam_transform : float3x4;
                                           fov : float;
                                           fovSettings : float)
      let fwd = normalize(cam_transform[2])
      let camUp = normalize(cam_transform[1])
      let interpK = get_phys_interpk_clamped(human_net_phys.phys, info.curTime)
      let leanPos = lerp(human_net_phys.phys.previousState.leanPosition, human_net_phys.phys.currentState.leanPosition, interpK)
      let leanAngle = cockpit__leanAngleMult * leanPos * PI / 180.0
      let cosL = cos(leanAngle)
      let sinL = sin(leanAngle)
      let camSide = normalize(cross(fwd, camUp))
      cockpit_transform[2] = fwd
      cockpit_transform[1] = camUp * cosL - camSide * sinL
      cockpit_transform[0] = normalize(cross(fwd, cockpit_transform[1]))

      // Apply base scale and offset first (offset in unscaled space)
      cockpit_transform[0] *= cockpit__scale.x
      cockpit_transform[1] *= cockpit__scale.y
      cockpit_transform[2] *= cockpit__scale.z
      cockpit_transform[3] = cam_transform[3]
      cockpit_transform[3] = cockpit_transform * cockpit__offset

      // Then apply FOV compensation so cockpit keeps same screen-space size
      let fovScale = tan(fov * PI / 360.0) / tan(fovSettings * PI / 360.0)
      cockpit_transform[0] *= fovScale
      cockpit_transform[1] *= fovScale
      cockpit_transform[2] *= fovScale

      animchar_set_tm(animchar, cockpit_transform, true)
      animchar_act(animchar, info.dt, true)
      animchar_copy_nodes(animchar, animchar_node_wtm, animchar_render__root_pos)

[es(tag=render, after=prepare_human_cockpit_es, before=prepare_aim_occlusion_es)]
def gas_mask_cockpit_disable_hero_cockpit_early_prepass_es(info : UpdateStageInfoBeforeRender;
                                                           human_gas_mask__active : bool)
  if human_gas_mask__active
    // todo: it would be better to render only gas mask in prepass and reproject it correctly in occlusion
    query() <| $ [es] (var render_hero_cockpit_into_early_prepass : bool&)
      render_hero_cockpit_into_early_prepass = false
