import "%ui/control/gui_buttons.nut" as JB
import "%ui/hud/state/armyData.nut" as armyData
import "%ui/components/colorize.nut" as colorize
from "%ui/hud/components/teamIcon.nut" import mkTeamIcon, getArmyIcon
from "%ui/style/fontsStyle.nut" import fontSub, fontBody
from "%ui/components/textarea.nut" import textarea
from "%ui/components/textButton.nut" import Secondary, Accented
from "%ui/hud/state/respawnState.nut" import timeToRespawn, timeToCanRespawn, respEndTime,
  canRespawnTime, canRespawnWaitNumber, respRequested, doRequestRespawn, doCancelRequestRespawn,
  paratroopersPointSelectorOn
from "%ui/hud/state/teams.nut" import localPlayerTeamArmyId
from "%ui/style/designConst.nut" import midPadding, attentionTxtColor, defItemBlur, transpBgColor,
  slotBaseSize
from "%ui/ui_library.nut" import *

let playerArmyIcon = Computed(@()
  getArmyIcon(armyData.get()?.armyId ?? localPlayerTeamArmyId.get()))

const iconSize = hdpxi(32)
let teamIcon = mkTeamIcon(playerArmyIcon, iconSize)

const wndPadding = fsh(1)

let respAnims = [
  { prop=AnimProp.scale, from=[0,0], to=[1,1], duration=0.25, play=true, easing=InOutCubic }
  { prop=AnimProp.opacity, from=0, to=1, duration=0.25, play=true, easing=InOutCubic }
  { prop=AnimProp.scale, from=[1,1], to=[0,0], duration=0.25, playFadeOut=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
]

let panel = @(content, menuOverride = {}) {
  size = FLEX_V
  valign = ALIGN_CENTER
  children = {
    key = "RespawnBlock"
    size = const [fsh(30), SIZE_TO_CONTENT]
    rendObj = ROBJ_WORLD_BLUR
    color = Color(110,110,110)
    margin = const [fsh(3), fsh(4)]
    padding = wndPadding
    gap = wndPadding
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    children = content
    transform = true
    animations = respAnims
  }.__update(menuOverride)
}

let headerBlock = @(text) {
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = wndPadding
  padding = midPadding
  valign = ALIGN_CENTER
  rendObj = ROBJ_WORLD_BLUR
  fillColor = transpBgColor
  color = defItemBlur
  children = [
    teamIcon
    textarea(text, { size = FLEX_H }.__update(fontSub))
  ]
}

let squadBlock = @(squadName) textarea(squadName,
  {
    size = FLEX_H
    padding = wndPadding
    halign = ALIGN_CENTER
  }.__update(fontSub))

let respawnTimer = @(text, params = {}) @() textarea(
  timeToRespawn.get() ? $"{text}{colorize(attentionTxtColor, timeToRespawn.get())}" : null,
  {
    watch = timeToRespawn
    size = FLEX_H
    halign = ALIGN_CENTER
  }.__update(params))

let forceSpawnStateFlags = Watched(0)
let mtTxtWithTime = @(locId, tLeft) loc(locId, { timer = tLeft ? $"({tLeft})" : "" }).strip()

let spawnButton = @(tLeft) Accented(mtTxtWithTime("Go!", tLeft),
  doRequestRespawn, {
    hotkeys = [["^J:Y | Space | Enter | @Human.Use"]]
    margin = 0
    minWidth = fsh(25)
    stateFlags = forceSpawnStateFlags
    key = "forceSpawnButton"
  })

let cancelSpawnButton = @(tLeft) Secondary(mtTxtWithTime("pressToCancel", tLeft),
  doCancelRequestRespawn, {
    hotkeys = [[$"^{JB.B} | Esc | @Human.Use"]]
    stateFlags = forceSpawnStateFlags
    key = "cancelSpawnButton"
    textParams = {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      maxWidth = slotBaseSize[0] * 0.76
    }.__update(fontBody)
  })

let forceSpawnButton = @(override = {}) @() {
  watch = [timeToCanRespawn, respEndTime, canRespawnTime, canRespawnWaitNumber, respRequested]
  size = FLEX_H
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = canRespawnWaitNumber.get() > 0 ? null
    : respRequested.get() ? cancelSpawnButton(timeToCanRespawn.get())
    : (respEndTime.get() > 0 && respEndTime.get() - canRespawnTime.get() <= 1) && !paratroopersPointSelectorOn.get() ? null
    : spawnButton(timeToCanRespawn.get())
}.__update(override)

return {
  panel
  headerBlock
  squadBlock
  respawnTimer
  forceSpawnButton
}
