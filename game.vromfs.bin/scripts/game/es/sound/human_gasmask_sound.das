require ecs
require soundEvent
require sound_utils.modules.sound_player_common


[es(tag=sound, on_appear, track=(human_gas_mask__active, is_watched_sound, sound_preset__isLoaded))]
def human_gasmask_sound(evt : Event;
                        human_gas_mask__active : bool;
                        is_watched_sound : bool;
                        sound_preset__isLoaded : bool;
                        human_gasmask_sound__watchedPath : string;
                        human_gasmask_sound__otherFlag : string;
                        var human_gasmask_sound__watchedEvent : SoundEvent&;
                        var sound_flags : Object&;
                        transform : float3x4)

  let shouldPlay = human_gas_mask__active && is_watched_sound && sound_preset__isLoaded
  human_gasmask_sound__watchedEvent |> play_or_abandon(human_gasmask_sound__watchedPath, transform[3], shouldPlay)

  let needFlag = human_gas_mask__active && !is_watched_sound
  set_sound_tag(human_gasmask_sound__otherFlag, needFlag, sound_flags)


[es(tag=sound, track=(human_gas_mask__putonPhase, human_gas_mask__takeoffPhase), REQUIRE=watchedByPlr)]
def human_gasmask_equip_sound(evt : Event;
                              human_gas_mask__putonPhase : int;
                              human_gas_mask__takeoffPhase : int;
                              sound_preset__isLoaded : bool;
                              human_gasmask_sound__putonPath : string;
                              human_gasmask_sound__takeoffPath : string;
                              transform : float3x4)
  if !sound_preset__isLoaded
    return
  if human_gas_mask__putonPhase == 2
    oneshot(human_gasmask_sound__putonPath, transform[3])
  elif human_gas_mask__takeoffPhase == 2
    oneshot(human_gasmask_sound__takeoffPath, transform[3])
