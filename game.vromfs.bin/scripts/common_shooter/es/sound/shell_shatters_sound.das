require ecs
require app
require soundEvent
require soundSystem
require common_shooter.events_common_shooter
require sound_utils.modules.sound_physmat_common
require sound_utils.modules.sound_occlusion_common
require DngDm
require dm
require Dacoll
require DagorRandom
require math.base
require DagorMath
require BallisticsProps
require shellSoundProps
require strings
require PhysMat


[es(tag=sound, REQUIRE=msg_sink)]
def shell_shatters_sound(evt : EventOnShellExploded)

  query() <| $ [es] (shell_shatter_sound__maxRadiusMul : float;
                     shell_shatter_sound__countToSoundCount : float4;
                     shell_shatter_sound__relDistToCountMul : float4;
                     shell_shatter_sound__chance : int;
                     var shell_shatter_sound__nextTime : float&;
                     shell_shatter_sound__cooldown : float;
                     shell_shatter_sound__radiusAroundListener : float;
                     shell_shatter_sound__traceStart : float;
                     shell_shatter_sound__hitSoundDistStart : float;
                     shell_shatter_sound__hitPath : string;
                     shell_shatter_sound__wizPath : string)

    assume shatterToSoundCount = shell_shatter_sound__countToSoundCount
    assume relDistToCountMul = shell_shatter_sound__relDistToCountMul

    var hitPath = shell_shatter_sound__hitPath
    var wizPath = shell_shatter_sound__wizPath
    shell_shatter_sound_get_props(int(evt.shellId)) <| $(shellShatterSoundProps : ShellShatterSoundProps)
      hitPath = shellShatterSoundProps.hitPath
      wizPath = shellShatterSoundProps.wizPath
    if empty(hitPath) && empty(wizPath)
      return

    projectile_get_props(int(evt.shellId)) <| $(projectileProps : ProjectileProps)
      using() <| $(var shatterParams : SyntheticShattersParams#)
        shatterParams = calc_synthetic_shatter_params(int(evt.damageId), projectileProps.mass, false)
        let maxRadius = max(shatterParams.radius, get_shell_max_radius(int(evt.shellId), int(evt.damageId), int(evt.ballisticsId))) * shell_shatter_sound__maxRadiusMul
        let listener = get_listener_pos()
        assume radiusAround = shell_shatter_sound__radiusAroundListener

        if length_sq(listener - evt.explPos) >= square(maxRadius + radiusAround)
          return

        let relDist = safediv(distance(listener, evt.explPos), maxRadius)
        var shatterCount = shatterParams.count * cvt(relDist, relDistToCountMul.x, relDistToCountMul.y, relDistToCountMul.z, relDistToCountMul.w)
        shatterCount = cvt(shatterCount, shatterToSoundCount.x, shatterToSoundCount.y, shatterToSoundCount.z, shatterToSoundCount.w)
        if shatterCount <= 0.
          return

        let curTime = get_sync_time()
        if curTime < shell_shatter_sound__nextTime
          return
        shell_shatter_sound__nextTime = curTime + shell_shatter_sound__cooldown

        while --shatterCount >= 0.
          if shell_shatter_sound__chance > rnd_int(0, 99)

            let ptNearListener = listener + float3(rnd_float(-radiusAround, radiusAround), rnd_float(-radiusAround, radiusAround), rnd_float(-radiusAround, radiusAround))
            let traceDir = normalize(ptNearListener - evt.explPos)
            let traceFrom = evt.explPos + traceDir * shell_shatter_sound__traceStart
            let traceDist = maxRadius + radiusAround - shell_shatter_sound__traceStart

            var hitPos = traceFrom + traceDir * traceDist

            var norm : float3
            var pmid = -1
            var riDesc = RendInstDesc()
            var t = traceDist

            if traceray_normalized(traceFrom, traceDir, t, pmid, norm, ETF_LMESH | ETF_HEIGHTMAP | ETF_FRT | ETF_RI | ETF_STRUCTURES, riDesc, -1)
              hitPos = traceFrom + traceDir * t
              if traceray_water_at_time(traceFrom, hitPos, curTime, t)
                hitPos = traceFrom + traceDir * t
                pmid = get_material_id("water3d")

              // hit sound
              if t > shell_shatter_sound__hitSoundDistStart && !empty(hitPath)
                oneshot("[cal={projectileProps.caliber};mat={get_projectile_sound_material_id(pmid)}]{hitPath}", prevent_wall_sound_occlusion(hitPos, norm))

            // wiz sound
            if !empty(wizPath)
              assume dir = traceDir
              assume pos = hitPos
              assume prevPos = evt.explPos
              let wizPos = pos + dir * dot(listener - pos, dir)
              if dot(prevPos - wizPos, dir) <= 0. && dot(pos - wizPos, dir) > 0.
                oneshot("[cal={projectileProps.caliber}]{wizPath}", wizPos)
