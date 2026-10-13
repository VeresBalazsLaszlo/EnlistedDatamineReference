require ecs
require app
require AnimV20
require soundEvent
require soundSystem
require sound_utils.modules.sound_player_common
require human_sounds.modules.human_voice_effect_common
require human_sounds.modules.human_sound_geomtree_nodes_common


[es(tag=sound, on_event=EventEntityDied)]
def human_death_sound(evt : Event;
                      eid : EntityId;
                      @shared_comp human_voice_sound__path : Object;
                      @shared_comp human_voice_sound__descs : Object;
                      var human_death_sound__event : SoundEvent&;
                      human_speech__locale = "";
                      is_watched_sound : bool = false;
                      human_sound_geomtree_nodes__headNodeId = -1;
                      animchar : AnimcharBaseComponent const? = null;
                      transform : float3x4;
                      sound_tags : Object;
                      sound_preset__isLoaded : bool)

  release(human_death_sound__event)

  if sound_preset__isLoaded
    let descId = "death"
    if get_desc(human_voice_sound__descs, descId) == null
      sound_debug("no desc '{descId}' in {eid} '{getEntityTemplateName(eid)}'")
      return

    let voicePos = get_human_voice_3d_pos(is_watched_sound, transform, human_sound_geomtree_nodes__headNodeId, animchar)
    human_death_sound__event |> reset(play_voice(descId, human_voice_sound__path, human_voice_sound__descs, sound_tags, is_watched_sound, voicePos, human_speech__locale, false))
    human_death_sound__event.abandonOnReset = true


[es(tag=sound, on_event=ParallelUpdateFrameDelayed, REQUIRE=deadEntity)]
def human_death_sound_update(evt : Event;
                             var human_death_sound__event : SoundEvent&;
                             is_watched_sound : bool = false;
                             human_sound_geomtree_nodes__headNodeId = -1;
                             animchar : AnimcharBaseComponent const? = null;
                             transform : float3x4)
  if is_valid_handle_value(human_death_sound__event)
    if is_playing(human_death_sound__event)
      let voicePos = get_human_voice_3d_pos(is_watched_sound, transform, human_sound_geomtree_nodes__headNodeId, animchar)
      set_pos(human_death_sound__event, voicePos)
    else
      release(human_death_sound__event)
