import "%dngscripts/ecs.nut" as ecs
from "net" import has_network
from "gameevents" import EventLevelLoaded
from "app" import get_session_id
from "%ui/ui_library.nut" import *

let sessionId = Watched(null)


ecs.register_es(
  "session_id_ui_es",
  {
    [EventLevelLoaded] = function() {
      if (has_network())
        sessionId.set(get_session_id())
    }
  }
)

return sessionId
