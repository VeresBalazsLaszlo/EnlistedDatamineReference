module sandbox_config_common shared
require app
require DagorSystem
require DagorDataBlock
require enlisted.game.utils.sandbox_state

let SETTING_EDITOR = "daEditor"
let SETTING_PLAYCONFIG = "sandboxPlayConfig_"

def sandbox_config_get_int(name : string; defval : int) : int
  if !is_sandbox_enabled()
    return defval
  var res = defval
  dgs_get_settings() |> datablock_get_block(SETTING_EDITOR) <| $(daEditorBlock)
    res = daEditorBlock |> datablock_getInt("{SETTING_PLAYCONFIG}{name}", defval)
  return res

def sandbox_config_get_string(name : string; defval : string) : string
  if !is_sandbox_enabled()
    return defval
  var res = defval
  dgs_get_settings() |> datablock_get_block(SETTING_EDITOR) <| $(daEditorBlock)
    res = daEditorBlock |> datablock_getStr("{SETTING_PLAYCONFIG}{name}", defval)
  return res
