import "%ui/soldiers/model/config/sClassesConfig.nut" as sClassesCfg
from "%ui/ui_library.nut" import *

const RETIRE_ORDER = "enlisted_silver"
let retireReturn = Computed(@() sClassesCfg.get().reduce(function(res, cfgClass, sClass) {
  let { retireOrdersReturn = [] } = cfgClass
  if (retireOrdersReturn.len() > 0)
    res[sClass] <- retireOrdersReturn
  return res
}, {}))

return {
  RETIRE_ORDER
  retireReturn
}
