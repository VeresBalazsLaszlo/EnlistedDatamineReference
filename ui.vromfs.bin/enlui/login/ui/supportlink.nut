import "%ui/components/urlText.nut" as urlText
from "%ui/supportUrls.nut" import gaijinSupportUrl, legalsUrl
from "%ui/ui_library.nut" import *

return freeze({
  hplace=ALIGN_LEFT
  vplace=ALIGN_BOTTOM
  flow = FLOW_HORIZONTAL
  margin = hdpx(20)
  gap = hdpx(20)
  children = [
    gaijinSupportUrl == "" ? null : urlText(loc("support"), gaijinSupportUrl, {opacity=0.7})
    urlText(loc("Legals"), legalsUrl, {opacity=0.7})
  ]
})