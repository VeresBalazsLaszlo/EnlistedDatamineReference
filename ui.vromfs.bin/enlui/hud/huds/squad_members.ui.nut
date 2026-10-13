import "%ui/hud/huds/context_command_hint.ui.nut" as contextCommandHint
import "%ui/hud/huds/cancel_context_command_hint.ui.nut" as cancelContextCommandHint
from "%enlSqGlob/dasenums.nut" import SquadBehaviour, SquadFormationSpread
from "%ui/style/fontsStyle.nut" import fontSub
from "math" import fabs
from "%ui/hud/state/squad_members.nut" import watchedHeroSquadMembers, selectedBotForOrderEid, isPersonalContextCommandMode, watchedHeroSquadMembersGetWatched, watchedHeroSquadMembersOrderedSet
from "%ui/hud/state/squad_soldiers_menu_state.nut" import isSquadSoldiersMenuAvailable
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/hud/state/vehicle_state.nut" import inVehicle
from "%ui/hud/style.nut" import SUCCESS_TEXT_COLOR, DEFAULT_TEXT_COLOR
from "%ui/hud/state/respawnState.nut" import canChangeRespawnParams, isSpectatorEnabled
from "%ui/hud/components/squad_member.nut" import mkGrenadeIcon, mkMineIcon, mkMemberHealsBlock, mkMemberRepairBlock, mkStatusIcon, mkAiActionIcon
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/state/squad_formation.nut" import squadFormation
from "%ui/hud/state/squad_behaviour.nut" import squadBehaviour
from "%ui/hud/state/hudOptionsState.nut" import showTips
from "%ui/ui_library.nut" import *

const sIconSize = hdpxi(15)
const iconSize = hdpxi(40)
const gap = hdpx(5)
const smallGap = hdpx(2)


local wasKills = {}
function updateKillsAnim() {
  let kills = {}
  foreach (m in watchedHeroSquadMembers.get()) {
    kills[m.eid] <- m.kills
    if (m.kills > (wasKills?[m.eid] ?? 0))
      anim_start($"member_kill_{m.eid}")
  }
  wasKills = kills
}
updateKillsAnim()
watchedHeroSquadMembers.subscribe(@(_) updateKillsAnim())

let blurBack = freeze({
  size = FLEX
  rendObj = ROBJ_WORLD_BLUR
  color = Color(220, 220, 220, 220)
})

function statusIcon(member, isSelf) {
  return {
    size = const [iconSize, iconSize]
    children = [
      blurBack
      mkStatusIcon(member, iconSize, isSelf ? SUCCESS_TEXT_COLOR : DEFAULT_TEXT_COLOR)
      mkAiActionIcon(member, sIconSize)
    ]
  }
}

let splitOnce = memoize(function(name) {
  local idx = name.indexof(" ")
  local found = null
  local minDist = name.len()
  let middle = minDist / 2
  while (idx != null) {
    let dist = fabs(middle - idx)
    if (dist < minDist) {
      found = idx
      minDist = dist
    }
    idx = name.indexof(" ", idx + 1)
  }
  return found == null
    ? [name]
    : [name.slice(0, found), name.slice(found + 1)]
})

let memberNameAnimations = freeze([
  { prop = AnimProp.translate, from = [-hdpx(100), 0], to = [0, 0], duration = 0.2, easing = OutCubic, play = true }
])

let mkNamePart = @(text) {
  rendObj = ROBJ_TEXT
  text
  color = SUCCESS_TEXT_COLOR
  indent = gap
  transform = true
  animations = memberNameAnimations
}.__update(fontSub)

function memberName(name) {
  let nameC = @() {
    watch = name
    flow = FLOW_VERTICAL
    children = splitOnce(name.get()).map(mkNamePart)
  }

  return {
    size = const [SIZE_TO_CONTENT, iconSize]
    valign = ALIGN_CENTER
    clipChildren = true
    children = [
      blurBack
      nameC
    ]
  }
}
let equipmentStatusRow = @(member) {
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  size = const [SIZE_TO_CONTENT, sIconSize]
  gap = smallGap
  children = [
    mkMemberRepairBlock(member, sIconSize)
    mkMemberHealsBlock(member, sIconSize)
    mkGrenadeIcon(member, sIconSize) ?? mkMineIcon(member, sIconSize)
  ]
}

let equipmentStatusRowDummy = { size = const [sIconSize, sIconSize] }
let killsIco = freeze({
  size = const [sIconSize, sIconSize]
  rendObj = ROBJ_IMAGE
  image = Picture("ui/skin#kills_icon.svg:{0}:{0}".subst(sIconSize))
})

let killRow = @(eid, kills) {
  key = eid
  hplace = ALIGN_RIGHT
  flow = FLOW_HORIZONTAL
  gap = smallGap
  children = [
    killsIco
    {
      children = [
        blurBack
        {
          minWidth = sIconSize
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXT
          color = DEFAULT_TEXT_COLOR
          text = kills

          animations = [{ prop = AnimProp.color, from = SUCCESS_TEXT_COLOR, to = DEFAULT_TEXT_COLOR,
            duration = 5, easing = InOutCubic, trigger = $"member_kill_{eid}" }]
        }.__update(fontSub)
      ]
    }
  ]

  transform = true
  animations = [{ prop = AnimProp.scale, from = [1,1], to = [2,2], duration = 0.5, easing = CosineFull, trigger = $"member_kill_{eid}" }]
}

let selectedBotArrowSize = [hdpxi(40), hdpxi(14)]
let selectedBotArrow = {
  size = selectedBotArrowSize
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/skin#squad_member_selected.svg:{selectedBotArrowSize[0]}:{selectedBotArrowSize[1]}")
  color = SUCCESS_TEXT_COLOR
}

let selectedBotArrowDummy = {size = selectedBotArrowSize}

let personalOrderMarkerSize = [hdpxi(16), hdpxi(16)]
let personalOrderMarker = {
  size = personalOrderMarkerSize
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  image = Picture($"ui/skin#white_circle.svg:{personalOrderMarkerSize[0]}:{personalOrderMarkerSize[1]}")
  color = SUCCESS_TEXT_COLOR
}

let memberUi = memoize(function(eid) {
  let state = watchedHeroSquadMembersGetWatched(eid)
  let isAliveState = Computed(@() state.get()?.isAlive)
  let name = Computed(@() state.get()?.callname ?? state.get()?.name ?? "")
  let nameC = memberName(name)
  let isPersonalOrder = Computed(@() state.get()?.isPersonalOrder)

  function dynamicInf(){
    let member = state.get()
    if (member == null)
      return {watch = state}
    let {isAlive, hasAI, kills} = member
    let isSelf = eid == controlledHeroEid.get()
    let isAliveAI = !isSelf && isAlive && hasAI
    let isSelectedForOrder = (isAliveAI && eid == selectedBotForOrderEid.get())
    return {
      watch = [selectedBotForOrderEid, isPersonalContextCommandMode, state]
      size = const [iconSize, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = smallGap
      children = [
        statusIcon(member, isSelf)
        killRow(eid, kills)
        isAliveAI || isSelf ? equipmentStatusRow(member) : equipmentStatusRowDummy
        !isPersonalContextCommandMode.get()
          ? null
          : isSelectedForOrder
            ? selectedBotArrow
            : selectedBotArrowDummy
      ]
    }
  }
  function child(){
    return {
      flow = FLOW_HORIZONTAL
      watch = [controlledHeroEid, isAliveState]
      children = [
        dynamicInf
        eid==controlledHeroEid.get() && isAliveState.get() ? nameC : null
      ]
    }
  }
  return freeze({
    flow = FLOW_VERTICAL
    vplace = ALIGN_BOTTOM
    gap = smallGap
    children = [
      @() {watch = isPersonalOrder children = isPersonalOrder.get() ? personalOrderMarker : null}
      child
    ]
  })
})

let squadMembersList = @() {
  watch = watchedHeroSquadMembersOrderedSet
  flow = FLOW_HORIZONTAL
  gap
  children = watchedHeroSquadMembersOrderedSet.get().map(memberUi)
}

let squadStatusIconSize = [hdpxi(26), hdpxi(26)]
let mkSquadStatusIcon = memoize(@(icon) {
  hplace = ALIGN_CENTER
  rendObj = ROBJ_IMAGE
  size = squadStatusIconSize
  image = Picture($"{icon}:{squadStatusIconSize[0]}:{squadStatusIconSize[1]}")
})

let squadFormationIcons = {
  [SquadFormationSpread.ESFN_CLOSEST] = mkSquadStatusIcon("ui/skin#squad_formation_closest.svg"),
  [SquadFormationSpread.ESFN_WIDE] = mkSquadStatusIcon("ui/skin#squad_formation_wide.svg")
}

let squadBehaviourIcons = {
  [SquadBehaviour.ESB_PASSIVE] = mkSquadStatusIcon("ui/skin#squad_behaviour_passive.svg")
}

let squadStatus = @() {
  flow = FLOW_HORIZONTAL
  gap = gap
  watch = [squadFormation, squadBehaviour]
  children = [
    squadFormationIcons?[squadFormation.get()]
    squadBehaviourIcons?[squadBehaviour.get()]
  ]
}

let switchBotHint = tipCmp({
  text = loc("squad_orders/switch_bot_for_order"),
  inputId = "Human.SwitchBotForOrders"
  style = fontSub
})

let switchContextHint = tipCmp({
  text = loc("controls/Human.SwitchContextCommandMode"),
  inputId = "Human.SwitchContextCommandMode"
  style = fontSub
})

let squadSoldiersHint = tipCmp({
  text = loc("controls/HUD.SquadSoldiersMenu"),
  inputId = "HUD.SquadSoldiersMenu"
  style = fontSub
})

let squadControlHints = @() {
  minHeight = hdpx(20)
  watch = [isPersonalContextCommandMode, isSquadSoldiersMenuAvailable]
  flow = FLOW_VERTICAL
  children = [
    isPersonalContextCommandMode.get() ? switchBotHint : null
    cancelContextCommandHint
    contextCommandHint
    switchContextHint
    isSquadSoldiersMenuAvailable.get() ? squadSoldiersHint : null
  ]
}
let doNotShowMembers = Computed(@() watchedHeroSquadMembers.get().len() <= 1 || canChangeRespawnParams.get() || inVehicle.get())

function members() {
  if (doNotShowMembers.get())
    return {watch = doNotShowMembers}

  return {
    flow = FLOW_VERTICAL
    gap
    watch = [doNotShowMembers, isSpectatorEnabled, showTips]
    children = [
      squadStatus
      squadMembersList
      !showTips.get() || isSpectatorEnabled.get() ? null : squadControlHints
    ]
  }
}

console_register_command(function(hitr) {
  let trigger = watchedHeroSquadMembers.get()?.top().hitTriggers[hitr]
  if (trigger != null)
    anim_start(trigger)
}, "hud.debugHitMember")

console_register_command(
  function() {
    let member = watchedHeroSquadMembers.get()?.top()
    if (member != null)
      anim_start($"member_kill_{member.eid}")
  }
  "hud.debugMemberKills")

return members
