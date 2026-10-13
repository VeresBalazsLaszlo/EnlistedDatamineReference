import "%ui/components/faComp.nut" as faComp
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/components/soldiersUiComps.nut" import kindIcon
from "%ui/components/rankPresentation.nut" import rankIconSize
from "%ui/helpers/remap_nick.nut" import remap_others
from "%ui/style/designConst.nut" import smallPadding, midPadding, bigPadding, defTxtColor, positiveTxtColor
from "%ui/hud/state/travelModePlayersState.nut" import zombieModeTeamEids, zombieModeTeamPrechosen
from "%ui/ui_library.nut" import *

let { zombieModeTeamData } = require("%ui/hud/state/travelModePlayersState.nut")


let imageSize = [hdpxi(64), hdpxi(64)]
let bigImageSize = [hdpxi(82), hdpxi(82)]
let slotSize = [hdpx(220), hdpx(64)]
const bgColor = 0xFF222222
const hpColor = 0xFFFF9595

let downedIcon = {
  size = [rankIconSize, rankIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture("ui/skin#skull.svg:{0}:{1}".subst(rankIconSize, rankIconSize))
  color = hpColor
}

let evacuatingIcon = faComp("check", {
  fontSize = rankIconSize
  color = positiveTxtColor
})

let unselectedKindIcon = {
  size = bigImageSize
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  rendObj = ROBJ_VECTOR_CANVAS
  color = bgColor
  fillColor = 0x99333333
  commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
  children = faComp("question", {
    fontSize = hdpx(50)
    color = defTxtColor
  })
}


let mkText = @(text, override = {}) {
  size = FLEX
  valign = ALIGN_CENTER
  children = {
    rendObj = ROBJ_TEXT
    color = defTxtColor
    text
  }.__update(fontSub, override)
}


let mkKindIcon = @(sKind, isDowned, isEvacuating) {
  pos = [midPadding, 0]
  rendObj = ROBJ_VECTOR_CANVAS
  color = bgColor
  fillColor = bgColor
  commands = [[VECTOR_ELLIPSE, 50, 50, 50, 50]]
  children = isEvacuating ? evacuatingIcon
    : isDowned ? downedIcon
    : kindIcon(sKind, rankIconSize)
}

function mkHpBar(hpCurrent, hpMax) {
  let hpFactor = hpMax <= 0 ? 0 : 100.0 * (min(hpCurrent, hpMax)) / hpMax
  return hpMax <= 0 || hpFactor >= 100 ? null
    : {
        size = const [FLEX, hdpx(8)]
        margin = [0, midPadding, smallPadding, 0]
        padding = hdpx(1)
        rendObj = ROBJ_SOLID
        color = bgColor
        children = {
          size = FLEX
          children = {
            size = [pw(hpFactor), FLEX]
            rendObj = ROBJ_SOLID
            color = hpColor
          }
        }
      }
}

let mkKindBlock = @(sKind, hpCurrent = 0, hpMax = 0, isDowned = false, isEvacuating = false) {
  size = FLEX_H
  halign = ALIGN_RIGHT
  valign = ALIGN_BOTTOM
  children = [
    mkHpBar(hpCurrent, hpMax)
    mkKindIcon(sKind, isDowned, isEvacuating)
  ]
}

let mkPlayerSlotUi = @(playerWatch)
  function() {
    let {
      nickname = "", sKind = "", primaryGunName = "", secondaryGunName = "",
      hpCurrent = 0, hpMax = 0, isDowned = false, isEvacuating = false
    } = playerWatch.get()
    return {
      watch = playerWatch
      size = slotSize
      flow = FLOW_HORIZONTAL
      gap = bigPadding
      children = [
        sKind == "" ? null
          : {
              halign = ALIGN_RIGHT
              valign = ALIGN_BOTTOM
              children = [
                {
                  rendObj = ROBJ_IMAGE
                  size = imageSize
                  image = Picture($"ui/portraits/event/avatar_halloween_{sKind}.avif")
                }
                mkKindBlock(sKind, hpCurrent, hpMax, isDowned, isEvacuating)
              ]
            }
        {
          size = FLEX
          flow = FLOW_VERTICAL
          children = [
            mkText(remap_others(nickname), { color = Color(210,255,220,120) })
            mkText(loc(primaryGunName))
            mkText(loc(secondaryGunName))
          ]
        }
      ]
    }
  }


let zombieObjectiveTeamUi = @() {
  watch = zombieModeTeamEids
  size = FLEX_H
  flow = FLOW_VERTICAL
  gap = midPadding
  children = zombieModeTeamEids.get().map(@(eid)
    eid not in zombieModeTeamData ? null
      : mkPlayerSlotUi(zombieModeTeamData[eid])
  )
}


function mkPlayerPrechosenSlotUi(player) {
  let { nickname = "", sKind = "" } = player
  return {
    flow = FLOW_HORIZONTAL
    gap = bigPadding
    minHeight = bigImageSize[1]
    children = [
      sKind == "" ? unselectedKindIcon
        : {
            size = bigImageSize
            children = {
              halign = ALIGN_RIGHT
              valign = ALIGN_BOTTOM
              children = [
                {
                  rendObj = ROBJ_IMAGE
                  size = bigImageSize
                  image = Picture($"ui/portraits/event/avatar_halloween_{sKind}.avif")
                }
                mkKindBlock(sKind)
              ]
            }
          }
      mkText(remap_others(nickname), { color = Color(210,255,220,120) })
    ]
  }
}


let zombieObjectivePrechosenUi = @() {
  watch = zombieModeTeamPrechosen
  pos = const [-fsh(4), 0]
  flow = FLOW_VERTICAL
  gap = midPadding
  children = zombieModeTeamPrechosen.get().map(mkPlayerPrechosenSlotUi)
}


return {
  zombieObjectiveTeamUi
  zombieObjectivePrechosenUi
}
