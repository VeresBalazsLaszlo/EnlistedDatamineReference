import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/menus/artillery_radio_map_shell_type.nut" import currentShellType
from "%ui/ui_library.nut" import *

let isArtRequest = Computed(function() {
  if (!currentShellType.get())
    return false

  let artilleryTemplate = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(currentShellType.get().name)

  if (!artilleryTemplate)
    return false

  return artilleryTemplate.getCompValNullable("artillery_show_map_radius") != null
})

return {
  isArtRequest
}
