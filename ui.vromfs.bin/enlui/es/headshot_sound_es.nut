import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/sound_options_state.nut" import headshotSoundEnabled

let setHeadshotSoundEnabledQuery = ecs.SqQuery("setHeadshotSoundEnabledQuery", {
  comps_rw = [["human_hit_sound__headshotSoundEnabled", ecs.TYPE_BOOL]]
})

headshotSoundEnabled.subscribe(function(enabled) {
  setHeadshotSoundEnabledQuery(function(_eid, comp) {
    comp.human_hit_sound__headshotSoundEnabled = enabled
  })
})
