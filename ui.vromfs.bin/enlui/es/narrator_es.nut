import "%dngscripts/ecs.nut" as ecs
from "%ui/state/narratorState.nut" import narratorNativeLang
from "gameevents" import EventLevelLoaded

let setNarratorNativeQuery = ecs.SqQuery("setNarratorNativeQuery", {
  comps_rw = [["narrator_settings__nativeLang", ecs.TYPE_BOOL]]
})

let setNative = @(isNative) setNarratorNativeQuery(@(_eid, comp) comp["narrator_settings__nativeLang"] = isNative)

narratorNativeLang.subscribe(@(val) setNative(val))

ecs.register_es("narrator_settings",
  { [EventLevelLoaded] = @(_evt, _eid, _comp) setNative(narratorNativeLang.get()) },
  {},
  {tags="gameClient"}
)