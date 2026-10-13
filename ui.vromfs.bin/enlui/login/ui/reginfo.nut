import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontHeading2
from "%ui/login/ui/loginUiParams.nut" import registerUrl
from "settings" import get_setting_by_blk_path
from "%ui/style/designConst.nut" import smallPadding, titleTxtColor, accentColor
from "%ui/components/openUrl.nut" import openUrl
from "%ui/ui_library.nut" import *
from "%ui/login/regionalOperator.nut" import isRegionalOperator


if (!(get_setting_by_blk_path("gaijin_net_login") ?? true))
  return null

function text(str) {
  return {
    rendObj = ROBJ_TEXT
    text = str
    color = titleTxtColor
  }.__update(fontHeading2)
}

let normalColor = accentColor
const hoverColor = Color(255, 168, 0)
const activeColor = Color(200, 100, 0)

let login = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    isRegionalOperator ? null : {
      rendObj = ROBJ_IMAGE
      image = Picture("ui/uiskin/gaijin_logo.avif")
      size = hdpx(32)
    }
    text(loc("login/login"))
  ]
}

let color = @(sf) sf & S_ACTIVE ? activeColor
  : sf & S_HOVER ? hoverColor
  : normalColor

let registrationBtn = watchElemState(@(sf){
  flow = FLOW_HORIZONTAL
  behavior = Behaviors.Button
  valign = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  gap = smallPadding
  onClick = @() openUrl(registerUrl)
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("login/registration")
      color = color(sf)
    }.__update(fontHeading2)
    faComp("external-link", {color  = color(sf), fontSize = hdpx(17)})
  ]
})


return {
  size = FLEX_H
  valign = ALIGN_CENTER
  padding = const [hdpx(20), 0]
  children =  [
    login
    registrationBtn
  ]
}