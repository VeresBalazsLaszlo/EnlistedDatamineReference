require ecs
require human_net_speech.modules.human_net_speech_request_common


[es(tag=server, track=human_melee_charge__isActive, REQUIRE=humanMeleeChargeSpeechEnable)]
def human_melee_charge_net_speech(evt : Event; eid : EntityId;
                                  human_melee_charge__isActive : bool)
  if human_melee_charge__isActive
    request_net_speech(eid, "meleeCharge")
