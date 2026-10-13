from "settings" import get_setting_by_blk_path
from "dagor.system" import argv, dgs_get_settings

let app_is_offline_mode = @() argv.contains("-devMode")

if (app_is_offline_mode()) {
  let settings = dgs_get_settings()
  if (!get_setting_by_blk_path("disableRemoteNetServices")) {
    settings["disableRemoteNetServices"] <- true
  }
  settings["cryptLogs"] <- false
  if (!get_setting_by_blk_path("disableMenu"))
    settings["disableMenu"] <- true
}

let disableRemoteNetServices = app_is_offline_mode() || (get_setting_by_blk_path("disableRemoteNetServices") ?? false)
let disableMenu = app_is_offline_mode() || (get_setting_by_blk_path("disableMenu") ?? false)
let isSandboxLaunched = app_is_offline_mode()

println($"disableRemoteNetServices: {disableRemoteNetServices}, disableMenu: {disableMenu}, app_is_offline_mode: {app_is_offline_mode()}, isSandboxLaunched: {isSandboxLaunched}")

return freeze({
  app_is_offline_mode
  disableRemoteNetServices
  disableMenu
  isSandboxLaunched
})
