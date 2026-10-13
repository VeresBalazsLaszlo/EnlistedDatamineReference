import "%ui/components/fontawesome.map.nut" as fa
from "dagor.debug" import logerr
from "debug" import getstackinfos
from "%ui/style/fontsStyle.nut" import fontawesome
from "%ui/ui_library.nut" import *
from "types" import Table

let defParams = {
  rendObj = ROBJ_INSCRIPTION
  validateStaticText = false
}.__update(fontawesome)

function faComp(symbol, params = null) {
  let symType = type(symbol)
  if (symType == "string" && symbol in fa && params == null)
    return {
      text = fa[symbol]
    }.__update(defParams)
  else if (symType == "table")
    return defParams.__merge(symbol)
  else if (symType == "string" && symbol in fa && params instanceof Table)
    return defParams.__merge({text=fa[symbol]}, params)
  log($"faComp, {symbol}", getstackinfos(2))
  logerr("incorrect faComp arguments")
  return null
}

return faComp