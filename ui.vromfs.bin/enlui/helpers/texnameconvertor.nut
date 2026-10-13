from "game_load" import check_tex_exists
from "%ui/state/harmonizationState.nut" import isHarmonizationEnabled

let texNameConvertor = isHarmonizationEnabled.get()
  ? function(name) {
      let idx = name.indexof("*")
      if (idx == null)
        return name
      let newName = $"{name.slice(0, idx)}_tomoe*"
      return check_tex_exists(newName) ? newName : name
    }
  : @(name) name

return texNameConvertor