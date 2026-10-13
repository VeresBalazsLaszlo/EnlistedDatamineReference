require ecs
require sound_utils.modules.sound_player_common
require human_sounds.modules.human_sounds_events
require gameLibs.pufd_events.pufd_events
require math.base


[es(tag=sound, track=zombie_aggro_net_sound_state__isAggressive)]
def zombie_aggro_voice(evt : Event;
                       eid : EntityId;
                       zombie_aggro_net_sound_state__isAggressive : bool;
                       zombie_aggro_voice__soundTag : string;
                       zombie_aggro_voice__phrase : string;
                       var sound_flags : Object&;
                       isAlive : bool = true)
  set_sound_tag(zombie_aggro_voice__soundTag, zombie_aggro_net_sound_state__isAggressive, sound_flags)
  if zombie_aggro_net_sound_state__isAggressive && isAlive
    sendEvent(eid, CmdHumanVoiceEffect(phrase = zombie_aggro_voice__phrase))


[es(tag=sound)]
def zombie_cry_near_hero(evt : ParallelUpdateFrameDelayed;
                         eid : EntityId;
                         var zombie_cry_near_hero__isNearHero : bool&;
                         var zombie_cry_near_hero__nextCheckAfter : float&;
                         var zombie_cry_near_hero__nextCryAfter : float&;
                         zombie_cry_near_hero__checkCooldown : float;
                         zombie_cry_near_hero__cryCooldown : float;
                         zombie_cry_near_hero__distThreshold : float;
                         zombie_cry_near_hero__phrase : string;
                         transform aka zombie_transform : float3x4;
                         isAlive : bool = true)

  if evt.curTime >= zombie_cry_near_hero__nextCheckAfter && isAlive
    zombie_cry_near_hero__nextCheckAfter = evt.curTime + zombie_cry_near_hero__checkCooldown

    var isNearHero = false
    query() <| $ [es(REQUIRE=hero)] (transform aka hero_transform : float3x4)
      isNearHero = distance_sq(zombie_transform[3], hero_transform[3]) < square(zombie_cry_near_hero__distThreshold)

    if zombie_cry_near_hero__isNearHero != isNearHero
      zombie_cry_near_hero__isNearHero = isNearHero

      if isNearHero && evt.curTime >= zombie_cry_near_hero__nextCryAfter
        sendEvent(eid, CmdHumanVoiceEffect(phrase = zombie_cry_near_hero__phrase, ignoreDisabledSoundControl = true))
        zombie_cry_near_hero__nextCryAfter = evt.curTime + zombie_cry_near_hero__cryCooldown
