import "%dngscripts/ecs.nut" as ecs
from "%ui/state/violenceState.nut" import violenceState
from "gameevents" import EventLevelLoaded

let setViolenceSettingsQuery = ecs.SqQuery("setViolenceSettings", {
  comps_rw = [ ["isBloodEnabled", ecs.TYPE_BOOL], ["isGoreEnabled", ecs.TYPE_BOOL] ]
})

function setOrCreate(isBloodEnabled, isGoreEnabled) {
  local found = false
  setViolenceSettingsQuery(function (_eid, comp) {
    found = true
    comp.isBloodEnabled = isBloodEnabled
    comp.isGoreEnabled = isGoreEnabled
  })
  if (!found)
    ecs.g_entity_mgr.createEntity("violence_settings", {
      "isBloodEnabled": [isBloodEnabled, ecs.TYPE_BOOL]
      "isGoreEnabled": [isGoreEnabled, ecs.TYPE_BOOL]
    })
}

violenceState.subscribe(@(st) setOrCreate(st.isBloodEnabled, st.isGoreEnabled))

ecs.register_es(
  "violence_settings_es",
  {
    [EventLevelLoaded] = @(_evt, _eid, _comp)
      setOrCreate(
        violenceState.get().isBloodEnabled,
        violenceState.get().isGoreEnabled)
  },
  {},
  {tags="gameClient"}
)