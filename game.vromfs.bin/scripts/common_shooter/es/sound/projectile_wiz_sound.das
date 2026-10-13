require ecs
require soundEvent
require soundSystem
require Ballistics
require BallisticsProps
require math.base
require DagorMath
require DaWeapons
require DaWeaponProps
require strings
require game.es.camera_common
require weapon_sounds.modules.weapon_sounds_events
require enlisted.events_enlisted


[es(tag=sound, after=(sound_begin_update_es, trace_scene_after_update_projectile_es), before=sound_end_update_es)]
def projectile_wiz_sound(evt : ParallelUpdateFrameDelayed)

  query() <| $ [es, unused_argument(projectile_wiz_sound__dirThresholds)] (projectile_wiz_sound__caliberToDist : float4;
                                                                           projectile_wiz_sound__dirThresholds : float2;

                                                                           projectile_wiz_sound__shellCaliberThreshold : float;
                                                                           projectile_wiz_sound__largeCaliberThreshold : float;
                                                                           projectile_wiz_sound__supersonicThreshold : float;

                                                                           projectile_wiz_sound__shellPath : string;
                                                                           projectile_wiz_sound__largeCaliberPath : string;
                                                                           projectile_wiz_sound__supersonicBulletPath : string;
                                                                           projectile_wiz_sound__subsonicBulletPath : string;

                                                                           projectile_wiz_sound__cooldown : float;
                                                                           var projectile_wiz_sound__nextSoundAt : float&)

    if evt.curTime < projectile_wiz_sound__nextSoundAt
      return

    let listener = get_listener_pos()
    find_query() <| $ [es(REQUIRE_NOT=projectile__inactive)] (ownerEid : EntityId;
                                                              launch_desc : LaunchDesc;
                                                              projectile__prevPos : float3;

                                                              projectile_trace_info__len : float;
                                                              projectile_trace_info__dir : float3;
                                                              projectile_trace_info__sceneIntersected : bool;

                                                              projectile_ballistics : ProjectileBallistics;
                                                              projectile_ballistics_props : ProjectileProps;
                                                              projectile_wiz_sound__path : das_string const?)

      if has(ownerEid, "watchedByPlr")
        return false

      let start = projectile__prevPos
      let end = projectile_trace_info__sceneIntersected ? projectile__prevPos + projectile_trace_info__dir * projectile_trace_info__len : projectile_ballistics.state.pos
      let len = distance(start, end)
      if len < FLT_EPSILON
        return false

      let dir = (end - start) / len
      let t = dot(listener - start, dir)
      if t < 0. || t >= len
        return false

      let pt = start + dir * t

      if length_sq(pt - listener) >= square(cvt(projectile_ballistics_props.caliber, projectile_wiz_sound__caliberToDist.x, projectile_wiz_sound__caliberToDist.y, projectile_wiz_sound__caliberToDist.z, projectile_wiz_sound__caliberToDist.w))
        return false

      // !((launchPos is in front) && (fly dir is perpendicular to view))
      let launchDir = normalize(launch_desc.tm[3] - listener)
      let viewDir = get_cam_itm()[2]
      if dot(launchDir, viewDir) > 0.0
        return false

      projectile_wiz_sound__nextSoundAt = evt.curTime + projectile_wiz_sound__cooldown

      if projectile_wiz_sound__path != null
        if !empty(*projectile_wiz_sound__path)
          oneshot(string(*projectile_wiz_sound__path), pt)
          sendEvent(ownerEid, EventOnWizSound(pos = pt))
      else
        var path : string
        if projectile_ballistics_props.caliber >= projectile_wiz_sound__shellCaliberThreshold
          path = projectile_wiz_sound__shellPath
        elif projectile_ballistics_props.caliber >= projectile_wiz_sound__largeCaliberThreshold
          path = projectile_wiz_sound__largeCaliberPath
        else
          path = projectile_wiz_sound__supersonicBulletPath
          shell_start_get_props(int(launch_desc.shellId.shellId)) <| $(shellStartProps : ShellStartProps)
            if shellStartProps.speed < projectile_wiz_sound__supersonicThreshold
              path = projectile_wiz_sound__subsonicBulletPath
        oneshot(path, pt)
        sendEvent(ownerEid, EventOnWizSound(pos = pt))

      return true
