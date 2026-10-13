import "%ui/components/textFormatters.nut" as formatters
import "%darg/helpers/mkFormatAst.nut" as mkFormatAst
from "%dngscripts/platform.nut" import isPlatformRelevant
from "%sqstd/string.nut" import split
from "%ui/ui_library.nut" import *

let { defStyle } = formatters

let filter = @(object) ("platform" in object) && !isPlatformRelevant(split(object.platform, ","))
let defParams = { formatters, style = defStyle, filter }
let formatText = mkFormatAst(defParams)

function mkFormatText(style, overrides = null) {
  let params = clone defParams
  params.style = params.style.__merge(style)
  if (typeof formatters == "table")
    params.formatters = params.formatters.__merge(overrides ?? {})
  return mkFormatAst(params)
}

return {
  mkFormatText
  formatText
  defStyle
}
