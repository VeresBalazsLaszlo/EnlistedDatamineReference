require ecs
require human_net_speech.modules.human_net_speech_request_common

[es(tag=sound, on_event=EventEntityDowned, REQUIRE=humanCovermeSpeechEnable)]
def human_coverme_speech_downed(evt : Event; eid : EntityId)
  request_net_speech(eid, "coverme")
