from "settings" import get_setting_by_blk_path
from "%ui/ui_library.nut" import *
from "app" import get_circuit_conf

let { get_distr = null } = require("auth")
let circuitConf = get_circuit_conf()

local registerUrl = circuitConf?.registerUrl
  ?? get_setting_by_blk_path("registerUrl")
  ?? "https://login.gaijin.net/en/profile/register"

function addQueryParam(url, name, value) {
  let delimiter = url.contains("?") ? "&" : "?"
  return "".concat(url,delimiter, name, "=", value)
}

let distrStr = get_distr?() ?? ""
if (distrStr != "") {
  registerUrl = addQueryParam(registerUrl, "distr", distrStr)
}

return {
  loginBlockOverride = Watched({
    size = const [fsh(40), SIZE_TO_CONTENT]
    minHeight = fsh(45)
    hplace = ALIGN_RIGHT
    vplace = ALIGN_CENTER
  })
  registerUrl
}