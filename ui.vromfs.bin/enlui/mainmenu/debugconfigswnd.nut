from "%ui/components/debugWnd.nut" import openDebugWnd
from "%ui/meta/configs.nut" import serverConfigs
from "%ui/ui_library.nut" import *

let overrides = {
  items_templates = { recursionLevel = 1 }
  perks = { recursionLevel = 1 }
  researches = { recursionLevel = 5 }
  squads_config = { recursionLevel = 1 }
}

let getTabs = @() serverConfigs.get()
  .map(@(_, name) { id = name, data = Computed(@() serverConfigs.get()?[name] ?? {}) }.__merge(overrides?[name] ?? {}))
  .values()
  .sort(@(a, b) a.id <=> b.id)

return @() openDebugWnd({
  wndUid = "debug_configs_wnd"
  tabs = getTabs()
})
