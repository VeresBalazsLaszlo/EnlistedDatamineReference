import "%ui/helpers/locByPlatform.nut" as locByPlatform
from "%dngscripts/platform.nut" import is_ps4
from "%ui/style/designConst.nut" import attentionTxtColor, transpBgColor, bigPadding
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/state/client_version.nut" import isMinimalClient
from "%ui/hud/menus/options/other_options.nut" import isMinimizeWarnings
from "%ui/ui_library.nut" import *

let { isRunningOnPS5 = @() false } = require_optional("sony")


let messagesList = [
  { locId = "ps5_update_request", showFunc = @() is_ps4 && isRunningOnPS5(), maxWidth = hdpx(500) }
  { locId = "low_quality_textures_warning", watch = isMinimizeWarnings,
    showFunc = @() isMinimalClient() && !isMinimizeWarnings.get() }
]

function getMessageBlock(data) {
  let { locId, showFunc, watch = null } = data
  let warningText = {
    watch
    size = SIZE_TO_CONTENT
    rendObj = ROBJ_SOLID
    color = transpBgColor
    padding = bigPadding
    margin = const [bigPadding, 0, 0, 0]
    children = {
      size = SIZE_TO_CONTENT
      maxWidth = data?.maxWidth ?? hdpx(700)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = locByPlatform(locId)
      halign = ALIGN_CENTER
      color = attentionTxtColor
    }.__update(fontBody)
  }

  if (watch == null)
    return showFunc() ? warningText : null

  return @() showFunc() ? warningText : { watch }
}

return freeze({
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  vplace = ALIGN_BOTTOM
  halign = ALIGN_CENTER
  children = messagesList.map(getMessageBlock)
})
