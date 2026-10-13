from "%dngscripts/localizations.nut" import loc
from "%dngscripts/platform.nut" import platformId
from "dagor.localize" import doesLocTextExist
from "types" import String, Table

function locByPlatform(locId, ...) {
  local params = null
  local defLocId = locId
  foreach (v in vargv)
    if (v instanceof String)
      defLocId = v
    else if (v instanceof Table)
      params = v

  let locPlatformId = $"{locId}/{platformId}"
  if (doesLocTextExist(locPlatformId))
    return loc(locPlatformId, params)
  return loc(locId, params, defLocId)
}

return locByPlatform