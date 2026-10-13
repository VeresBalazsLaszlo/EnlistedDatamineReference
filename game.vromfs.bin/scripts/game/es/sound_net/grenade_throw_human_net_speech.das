require ecs
require common_shooter.events_common_shooter
require human_net_speech.modules.human_net_speech_request_common
require soundNetProps
require strings


[es(tag=server)]
def grenade_throw_human_net_speech(evt : EventOnGrenadeThrow; eid : EntityId)
  let shellSoundNetProps = shell_sound_net_try_get_props(evt.gun_props_id)
  if shellSoundNetProps != null
    let phrase : string = (*shellSoundNetProps).throwPhrase
    if !empty(phrase)
      request_net_speech(eid, phrase)
