import "%enlSqGlob/userInfo.nut" as userInfo
import "%ui/helpers/isChineseVersion.nut" as isChineseVersion
from "%dngscripts/platform.nut" import is_gdk, is_sony, is_pc, is_android
from "%sqstd/string.nut" import startsWith, endsWith
from "settings" import get_setting_by_blk_path
from "%ui/state/harmonizationNickState.nut" import harmonizationNickState

let { nicknames } = isChineseVersion
  ? require("%enlSqGlob/data/generated_nicknames_chinese.nut")
  : require("%enlSqGlob/data/generated_nicknames_eng.nut")

let harmonize = @(nickname, withHarmonize = false) is_pc && harmonizationNickState.get()
  && withHarmonize
    ? nicknames[nickname.hash() % nicknames.len()]
    : nickname

let needPlatformMorphemesReplacement = get_setting_by_blk_path("needPlatformMorphemesReplacement") ?? false

const PC_ICON = "⋆"
const TV_ICON = "⋇"
const PSN_ICON = "⋊"
const NBSP = " " 

let namePostfix = {
  ["@live"] = is_gdk? "" : TV_ICON,
  ["@psn"] = is_sony? PSN_ICON : TV_ICON,
  ["@steam"] = is_pc? "" : PC_ICON,
  ["@epic"] = is_pc? "" : PC_ICON,
  ["@googleplay"] = is_android? "" : TV_ICON,
  [" "] = "" 
}

let namePrefix = {
  ["^"] = is_gdk? "" : TV_ICON,
  ["*"] = is_sony? PSN_ICON : TV_ICON
}

let pcAddIcon = is_pc? "" : PC_ICON

let addIcon = needPlatformMorphemesReplacement
  ? (@(name, icon) icon == "" ? name : $"{icon}{NBSP}{name}")
  : @(name, _icon) name

function remap_nick(name, withHarmonize = false) {
  if (typeof name != "string" || name == "")
    return ""

  foreach (morpheme, icon in namePostfix)
    if (endsWith(name, morpheme))
      return addIcon(harmonize(name.slice(0, -morpheme.len()), withHarmonize), icon)

  foreach (morpheme, icon in namePrefix)
    if (startsWith(name, morpheme))
      return addIcon(harmonize(name.slice(morpheme.len()), withHarmonize), icon)

  return addIcon(harmonize(name, withHarmonize), pcAddIcon)
}

function remap_others(plName, withHarmonize = false) {
  let { name = null, nameorig = null } = userInfo.get()
  return plName == name || plName == nameorig ? nameorig : remap_nick(plName, withHarmonize)
}

return {
  remap_nick
  remap_others
}