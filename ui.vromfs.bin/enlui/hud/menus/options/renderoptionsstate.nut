from "%dngscripts/globalState.nut" import nestWatched
from "settings" import get_setting_by_blk_path

let isOptionAvailable = @(option) option?.isAvailable() ?? true

function addOptionVarInfo(option) {
  if (option?.optId == null || !isOptionAvailable(option))
    return option

  let convertFromBlk = "convertFromBlk" in option ? option.convertFromBlk : @(v) v

  let gw = nestWatched(option.optId,
    convertFromBlk(get_setting_by_blk_path(option.blkPath) ?? option.defVal))

  option.var <- gw
  option.setValue <- @(v) gw.set(v)
  return option
}

return {
  addOptionVarInfo
}