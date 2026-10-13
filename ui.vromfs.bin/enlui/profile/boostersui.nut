from "%ui/style/fontsStyle.nut" import fontHeading2, fontBody, fontSub
from "%ui/components/defcomps.nut" import txt
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/soldiers/model/boosters.nut" import allBoosters, battleLeftCount,
  setActivateBooster, setDeactivateBooster, curExpBonus
from "%ui/style/designConst.nut" import unitSize, smallPadding, largePadding, defSlotBgColor,
  hoverSlotBgColor, defBdColor, attentionTxtColor, disabledTxtColor, listCtors, commonBorderRadius,
  fullTransparentBgColor, blurBgFillColor, bigPadding
from "%ui/profile/profilePkg.nut" import PROFILE_WIDTH
from "%ui/helpers/gradients.nut" import mkDiagonalColoredGradient
from "%ui/components/mkXpBooster.nut" import mkXpBooster, mkBoosterInfo, mkBoosterLeftBattles,
  mkBoosterExpireInfo
from "%ui/components/msgbox.nut" import showMsgbox
from "%ui/soldiers/model/config/gameProfile.nut" import gameProfile
from "%ui/ui_library.nut" import *


let { txtColor } = listCtors


const activeBoosterColor = Color(184, 109, 11)
let boosterItemSize = [(3.4 * unitSize).tointeger(), (2.5 * unitSize).tointeger()]

let emptyBoostersText = txt({
  text = loc("profile/boostersIsEmpty")
  hplace = ALIGN_CENTER
  color = disabledTxtColor
}).__update(fontHeading2)


let boosterContainer = {
  size = const [ph(90), ph(105)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
}

let boostersTxt = {
  rendObj = ROBJ_TEXT
  text = loc("booster/get")
  hplace = ALIGN_CENTER
}.__update(fontBody)

function activateBooster(boosterGuid, boosterCfg) {
  let { maxBoostersBonus = 1.0 } = gameProfile.get()
  let curBoostersBonus = curExpBonus(allBoosters.get()) + boosterCfg.expMul
  if (curBoostersBonus > maxBoostersBonus) {
    showMsgbox(loc("booster/limitExceeded", {
      current = (curBoostersBonus * 100).tointeger()
      limit = (maxBoostersBonus * 100).tointeger()
    }))
    return
  }

  setActivateBooster(boosterGuid)
}

let gradient = {
  size = boosterItemSize
  rendObj = ROBJ_IMAGE
  image = mkDiagonalColoredGradient({
    cTop = Color(0, 0, 0, 0)
    cBottom = activeBoosterColor
    width = boosterItemSize[0]
    height = boosterItemSize[1]
  })
}

function mkBooster(boosterObj) {
  let { booster, template } = boosterObj
  let { activeTs = 0 } = booster
  let { expMul = 0 } = template
  let leftBattles = battleLeftCount(boosterObj)

  let isActive = activeTs > 0
  return watchElemState(function(sf) {
    let txtStyle = { color = txtColor(sf) }.__update(fontSub)
    return {
      xmbNode = XmbNode({
        canFocus = true
        wrap = false
        isGridLine = true
        scrollToEdge = [false, true]
      })
      rendObj = ROBJ_BOX
      fillColor = sf & S_HOVER ? defSlotBgColor : fullTransparentBgColor
      borderRadius = commonBorderRadius
      borderWidth = hdpx(1)
      borderColor = !isActive ? defBdColor : activeBoosterColor
      flow = FLOW_VERTICAL
      gap = smallPadding
      padding = smallPadding
      halign = ALIGN_CENTER
      behavior = Behaviors.Button
      onClick = @() isActive
        ? setDeactivateBooster(booster.guid)
        : activateBooster(booster.guid, template)
      sound = {
        hover = "ui/enlist/button_highlight"
        click = "ui/enlist/button_click"
        active = "ui/enlist/button_action"
      }
      children = [
        isActive
          ? txt({
              text = loc("active")
              color = attentionTxtColor
            }).__update(fontSub)
          : txt({
              text = loc("notActive")
              color = disabledTxtColor
            }).__update(fontSub)
        {
          rendObj = ROBJ_BOX
          fillColor = sf & S_HOVER ? hoverSlotBgColor : defSlotBgColor
          size = boosterItemSize
          children = [
            isActive ? gradient : null
            mkXpBooster(boosterContainer, expMul < 0.0)
            {
              size = FLEX
              padding = smallPadding
              children = [
                leftBattles <= 0 ? null : mkBoosterLeftBattles(leftBattles)
                mkBoosterInfo(template, txtStyle)
              ]
            }
          ]
        }
        mkBoosterExpireInfo(booster)
      ]
    }
  })
}

function mkBoostersListUi() {
  let boosters = Computed(@() allBoosters.get().values()
    .filter(@(b) b.template.expMul > 0.0)
    .sort(@(a, b) b.template.expMul <=> a.template.expMul
      || a.booster.expireTs <=> b.booster.expireTs))

  return function() {
    let boostersVal = boosters.get()
    if (boostersVal.len() == 0)
      return {
        watch = boosters
        size = FLEX
        flow = FLOW_VERTICAL
        gap = smallPadding
        children = [
          {
            size = FLEX
            valign = ALIGN_CENTER
            children = emptyBoostersText
          }
          boostersTxt
        ]
      }

    let components = boostersVal.map(mkBooster)
    let { maxBoostersBonus = 1.0 } = gameProfile.get()
    let boostersList = wrap(components, {
      width = PROFILE_WIDTH
      vGap = largePadding
      hGap = largePadding
    })
    let scrollBoostersList = makeVertScroll({
        size = const [PROFILE_WIDTH, SIZE_TO_CONTENT]
        hplace = ALIGN_CENTER
        children = boostersList
      },
      { styling = thinStyle }
    )
    return {
      size = FLEX
      flow = FLOW_VERTICAL
      gap = smallPadding
      watch = [boosters, gameProfile]
      children = [
        {
          size = FLEX_H
          halign = ALIGN_CENTER
          padding = bigPadding
          rendObj = ROBJ_SOLID
          color = blurBgFillColor
          flow = FLOW_HORIZONTAL
          gap = largePadding * 2
          children = [
            {
              rendObj = ROBJ_TEXT
              text = loc("profile/totalBonus", {
                value = (curExpBonus(boostersVal) * 100).tointeger()
                max = (maxBoostersBonus * 100).tointeger()
              })
            }.__update(fontBody)
          ]
        }
        {
          xmbNode = XmbContainer({
            canFocus = false
            isGridLine = true
            scrollSpeed = [0, 2.0]
            scrollToEdge = [false, true]
          })
          size = FLEX
          valign = ALIGN_TOP
          padding = [0, bigPadding]
          children = scrollBoostersList
        }
        boostersTxt
      ]
    }
  }
}

return @() {
  size = FLEX
  children = mkBoostersListUi()
}
