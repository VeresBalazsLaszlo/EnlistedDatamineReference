require ecs
require app
require human_net_speech.modules.human_net_speech_request_common

[es(track=gun__isOverheat, tag=server, REQUIRE=gunOverheatSpeechEnable)]
def gun_overheat_human_net_speech_es(evt : Event;
                                     gun__isOverheat : bool;
                                     gun__owner : EntityId)
  if gun__isOverheat
    request_net_speech(gun__owner, "gunOverheat")
