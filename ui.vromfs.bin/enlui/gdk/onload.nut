from "%dngscripts/platform.nut" import is_xbox
from "%ui/ui_library.nut" import *

require("%gdkLib/crossnetwork.nut")

require("%ui/gdk/startup.nut")
require("%ui/gdk/activity.nut")
require("%ui/gdk/crossnetwork.nut")
require("%ui/gdk/presence.nut")
require("%ui/gdk/achievements.nut")
require("%ui/gdk/voice.nut")
require("%ui/gdk/userIds.nut")
require("%ui/gdk/profileCard.nut")
require("%ui/gdk/contactsManager.nut")

if (is_xbox) {
  require("%ui/control/controller.nut")
}