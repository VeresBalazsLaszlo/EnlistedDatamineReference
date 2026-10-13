require ecs
require human_sounds.modules.human_voice_effect_common


[es(tag=sound, on_appear, before=human_voice_effect_on_change, track=human_inventory__entityToUse)]
def human_voice_effect_drinking(evt : Event;
                                human_inventory__entityToUse : EntityId;
                                var human_voice_effect__activeEffects : Object&)
  var isDrinking = false
  query(human_inventory__entityToUse) <| $ [es(REQUIRE=humanVoiceEffectDrinking)] ()
    isDrinking = true
  set_human_voice_effect("drink", isDrinking, human_voice_effect__activeEffects)
