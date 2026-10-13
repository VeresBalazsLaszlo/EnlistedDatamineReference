from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/options/onlineSettings.nut" import onlineSettingUpdated
from "%ui/ui_library.nut" import *

let { watch, setValue } = mkOnlineSaveData("onlinePersistentFlags", @() {})

let mkOnlinePersistentFlag = @(id) {
  flag = Computed(@() watch.get()?[id] ?? false)
  activate = function() {
    if (onlineSettingUpdated.get())
      setValue(watch.get().__merge({ [id] = true }))
  }
}

console_register_command(@() setValue({}), "ui.resetPersistentFlags")
console_register_command(@()
  console_print("Persistent flags:", watch.get()), "ui.printPersistentFlags")
console_register_command(function(id) {
  let val = !(watch.get()?[id] ?? false)
  console_print($"Persistent flag {id} switched to {val}")
  setValue(watch.get().__merge({ [id] = val }))
}, "ui.togglePersistentFlag")

return {
  mkOnlinePersistentFlag
}
