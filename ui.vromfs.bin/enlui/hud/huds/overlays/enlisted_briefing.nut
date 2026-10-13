import "%ui/control/gui_buttons.nut" as JB
from "%ui/hud/components/teamIcon.nut" import mkTeamIcon, getArmyIcon
from "%ui/style/fontsStyle.nut" import fontHeading1, fontBody
from "%ui/state/missionParams.nut" import missionParams
from "%ui/hud/state/briefingState.nut" import showBriefingForTime, showBriefing, briefingState
from "%ui/hud/state/teams.nut" import localPlayerTeamInfo, localPlayerTeamArmyId
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/components/templateControls.nut" import tokenizeTextWithShortcuts, makeHintsRows, controlView
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/textarea.nut" import smallTextarea, textarea
from "%ui/components/text.nut" import dtext
from "%ui/hud/state/health_state.nut" import isAlive
from "%ui/hud/tutorial/state/tutorial_state.nut" import isTutorial
from "%ui/style/designConst.nut" import strokeStyle
from "%dngscripts/globalState.nut" import nestWatched
from "%ui/ui_library.nut" import *
from "types" import String

let playerArmyIcon = Computed(@() getArmyIcon(localPlayerTeamArmyId.get()))

let teamIcon = mkTeamIcon(playerArmyIcon)
let showGoalAuto = nestWatched("showGoalAuto", false)
let showGoal = showBriefing

function hideGoalAfterTime() {
  if ((showBriefingForTime.get() ?? 0) > 0){
    showBriefingForTime.set(null)
    showGoalAuto.set(false)
    showGoal.set(false)
  }
}

showGoal.subscribe(function(v){
  if (v)
    return
  showGoalAuto.set(false)
  showBriefingForTime.set(null)
})

function briefingText(briefing, teamInfo) {
  local team_briefing = teamInfo?["team__briefing"]
  if (team_briefing==null || team_briefing == "")
    team_briefing = briefing?["briefing_common"]
  return team_briefing
}

function isBriefingEmpty(briefing, teamInfo){
  let team_briefing = briefingText(briefing, teamInfo)
  return ((team_briefing==null || team_briefing=="") && (briefing?.common == null || briefing?.common == ""))
}

function setShow() {
  showGoalAuto.set(true)
  showGoal.set(true)
}

let hasGoals = Computed(@() !isBriefingEmpty(briefingState.get(), localPlayerTeamInfo.get()))

showBriefingForTime.subscribe(function(value){
  if (value==null || value <=0)
    return
  if (!hasGoals.get() || !isTutorial.get())
    return
  gui_scene.resetTimeout(0.5, setShow)
  gui_scene.resetTimeout(value + 0.5, hideGoalAfterTime)
})

let showBrief = Computed(@() showGoal.get() || showGoalAuto.get())

isAlive.subscribe(function(live){
  if (live)
    showGoal.set(false)
})
const lightgray = Color(180,180,180,180)

let hintSrcState = Computed(@() loc(briefingState.get()?.hints ?? ""))
let hintsTokensState = Computed(@() tokenizeTextWithShortcuts(hintSrcState.get()))


const kbCloseKey = "Esc"
let gpCloseKey = JB.B
let closeMenuKey ="^{0} | {1}".subst(gpCloseKey, kbCloseKey)

function closeHint() {
  let closeKey = controlView([isGamepad.get() ? gpCloseKey : kbCloseKey])
  return closeKey!=null ? {
    size = FLEX_H
    halign = ALIGN_CENTER
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    gap = hdpx(10)
    children = [
      closeKey
      dtext(loc("briefing/close"))
    ]
  } : null
}

let hintsBlock = @(hintsHeader, hintsTokens) @() {
  watch = isGamepad
  size = FLEX
  color = lightgray
  flow = FLOW_VERTICAL
  gap = hdpx(2)
  children = [
    hintsHeader!=null ? dtext(loc(hintsHeader), { halign = ALIGN_CENTER, margin = const [0, 0, fsh(2), 0] }) : null
    {
      size = FLEX_H
      flow = FLOW_VERTICAL
      gap = hdpx(2)
      children = makeHintsRows(hintsTokens)
    }
  ]
}

let isEmpty = Computed(@() !hasGoals.get() && !hintsTokensState.get().len())

let emptyBriefing = {
  size = FLEX
  flow = FLOW_VERTICAL
  children = { size=FLEX halign=ALIGN_CENTER valign=ALIGN_CENTER children=dtext(loc("No briefing available")) }
}

function goalsBriefing(){
  let briefing = briefingState.get()
  return {
    size = FLEX
    flow = FLOW_VERTICAL
    gap = fsh(2)
    watch = [localPlayerTeamInfo, briefingState]
    children = [
      {
        size = FLEX_H
        flow = FLOW_HORIZONTAL
        valign = ALIGN_CENTER
        gap = fsh(2)
        children = [
          teamIcon
          textarea(loc(briefing?.header))
        ]
      }
      smallTextarea(loc(briefingText(briefing, localPlayerTeamInfo.get())), {
        color = lightgray
      }.__update(fontBody))
      dtext(loc(briefing?.common_header), { halign = ALIGN_CENTER }.__update(fontBody))
      briefing?.common instanceof String
        ? smallTextarea(loc(briefing.common), { color = lightgray })
        : null
    ]
  }
}
let mainBlock = @() {
  watch = [isEmpty, hasGoals]
  size = FLEX
  children = isEmpty.get()
    ? emptyBriefing
    : hasGoals.get()
      ? goalsBriefing
      : null
}

function briefingComp() {
  let briefing = briefingState.get()
  let hints = hintsTokensState.get().len() ? hintsBlock(briefing?.hints_header, hintsTokensState.get()) : null

  return {
    size = [fsh(hasGoals.get() ? 110 : 80), fsh(72)]
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = Color (120,120,120,255)
    flow = FLOW_VERTICAL
    padding = const [fsh(2), fsh(4)]
    gap = fsh(2)
    hotkeys = [[closeMenuKey, @() showGoal.set(false)]]
    watch = [ hintsTokensState, hasGoals, briefingState]
    halign = ALIGN_CENTER
    children = [
      {
        size = FLEX
        flow = FLOW_HORIZONTAL
        gap = fsh(7)
        children = [
          mainBlock
          hints
        ]
      }
      closeHint
    ]
  }
}

let missionTitle = @() {
  watch = missionParams
  rendObj = ROBJ_TEXT
  text = missionParams.get().name
}.__update(fontHeading1, strokeStyle)

let titledBriefing = {
  flow = FLOW_VERTICAL
  gap = fsh(2)
  children = [
    missionTitle
    briefingComp
  ]
}

let animations = [
  { prop = AnimProp.opacity, from = 0, to = 1, duration = 0.3, play = true, easing = OutQuintic }
  { prop = AnimProp.scale, from =[0.5, 0.5], play = true, to = [1, 1], duration = 0.15, easing = OutQuad }
  { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.15, playFadeOut = true, easing = InQuintic }
  { prop = AnimProp.scale, from =[1, 1], playFadeOut = true, to = [1.2, 1.2], duration = 0.15, easing = InQuad }
]

function briefingUi() {
  return {
    key = "briefing"
    size = FLEX
    halign = ALIGN_CENTER
    transform = true
    animations = animations
    valign = ALIGN_CENTER
    children = showBrief.get() ? titledBriefing : null
    watch = [localPlayerTeam, showBrief, briefingState, localPlayerTeamInfo]
    hotkeys = [[closeMenuKey, {
        action = @() showGoal.set(false)
        description =loc("Close")
        inputPassive = true
      }]]
  }
}

return briefingUi
