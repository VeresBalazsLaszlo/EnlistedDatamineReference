import "%ui/steam/steam_awards_wnd.nut" as mkAwardsWindow
import "%ui/steam/steam_event_wnd.nut" as mkEventWindow
import "steam" as steam
from "%ui/steam/steamRateState.nut" import steamURL
from "%ui/ui_library.nut" import *





let eventsConfig = {
  awards = {
    mkWindow = mkAwardsWindow
    checkCb = @() steamURL != null && steam.is_running()
  }

  wargames = {
    mkWindow = mkEventWindow
  }
}

return eventsConfig
