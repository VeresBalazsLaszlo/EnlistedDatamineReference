import "%ui/components/colorize.nut" as colorize
import "%ui/components/mkSquadsList.nut" as mkCurSquadsList
import "%ui/hud/huds/troopers_button.nut" as paratroopersButtonBlock
import "%ui/hud/huds/without_vehicle_spawn_button.nut" as withoutVehicleSpawnButtonBlock
import "%ui/hud/menus/respawn_fuel_selector.ui.nut" as fuelSelector
import "%dngscripts/ecs.nut" as ecs
from "%ui/components/squadsPresentation.nut" import getSquadPresentation
from "%ui/style/fontsStyle.nut" import fontHeading1, fontHeading2, fontBody, fontSub
from "%ui/hud/state/spawn_zones_markers.nut" import spawnZonesState
from "%ui/state/safeArea.nut" import safeAreaVerPadding, safeAreaHorPadding
from "%ui/helpers/time.nut" import secondsToTimeSimpleString
from "%ui/components/textarea.nut" import textarea
from "%ui/helpers/timers.nut" import mkCountdownTimerPerSec
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/state/missionParams.nut" import missionParams
from "%ui/hud/state/respawnState.nut" import isFirstSpawn, spawnCount, spawnSquadId,
  squadIndexForSpawn, doRequestRespawn, squadsList, curSquadData, curVehicle, canSpawnCurrent,
  canSpawnCurrentSoldier, maxSpawnVehiclesOnPointBySquad, nextSpawnOnVehicleInTimeBySquad,
  canUseRespawnbaseByType, respawnBlockedReason, selectedRespawnGroupId,
  paratroopersPointSelectorOn, spawnScore, paratroopersOn, kamikazePenaltyActive,
  spawnWithoutVehicleAvailable, spawnWithoutVehicleForced, freeTankSpawnInfoShow
from "%ui/hud/state/teams.nut" import localPlayerTeamSquadsCanSpawn, localPlayerTeamInfo
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/hud/huds/zombieObjectiveTeamBlock.nut" import zombieObjectivePrechosenUi
from "%ui/hud/respawn_parts.nut" import respawnTimer, forceSpawnButton, panel, headerBlock
from "%ui/components/squadsUiComps.nut" import mkSquadSpawnIcon, mkSquadSpawnDesc
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "%ui/style/designConst.nut" import attentionTxtColor, transpBgColor, defItemBlur,
  strokeStyle, midPadding, smallPadding, blurBgFillColor, slotBaseSize
from "%ui/hud/state/zombie_zones_state.nut" import isZombieObjectiveMode
from "%ui/hud/menus/respawn_squad_info.ui.nut" import normSquadInfo, freeTankSquadInfo
from "%ui/ui_library.nut" import *

const vehicleIconSize = hdpxi(28)

let DB = ecs.g_entity_mgr.getTemplateDB()

let maxSpawnVehiclesOnPoint = Computed(@() maxSpawnVehiclesOnPointBySquad.get()?[squadIndexForSpawn.get()] ?? -1)
let nextSpawnOnVehicleInTime = Computed(@() nextSpawnOnVehicleInTimeBySquad.get()?[squadIndexForSpawn.get()] ?? -1.0)
let timeToCanRespawnOnVehicle = mkCountdownTimerPerSec(nextSpawnOnVehicleInTime)

let bgConfig = {
  rendObj = ROBJ_WORLD_BLUR
  fillColor = transpBgColor
  color = defItemBlur
}

function spawnsLeftText() {
  let maxSpawn = localPlayerTeamInfo.get()?["team__eachSquadMaxSpawns"] ?? 0
  return {
    size = FLEX_H
    watch = [spawnCount, localPlayerTeamInfo]
    children = maxSpawn <= 0 ? null
      : textarea(loc("respawn/leftRespawns", {
          num = colorize(attentionTxtColor, maxSpawn - spawnCount.get())
        }), {
          size = FLEX_H
          halign = ALIGN_CENTER
        }.__update(fontSub))
  }
}

let vehicleIcon = memoize(function(squadType) {
  return freeze({
    rendObj = ROBJ_IMAGE
    size = const [vehicleIconSize, vehicleIconSize]
    image = Picture($"ui/skin#{squadType}_icon.svg:{vehicleIconSize}:{vehicleIconSize}")
  })
})

let vehicleSpawnText = Computed(function() {
    let time = timeToCanRespawnOnVehicle.get()
    let limit = maxSpawnVehiclesOnPoint.get()
    let vehicle = curVehicle.get()
    if (vehicle == null)
      return ""
    if (kamikazePenaltyActive.get() && DB.getTemplateByName(curVehicle.get()?.gametemplate)?.getCompValNullable("airplane") != null)
      return loc("respawn/kamikazePenalty")
    if (time > 0)
      return "{0}{1}".subst(loc("respawn/timeToSpawn"), secondsToTimeSimpleString(time))
    if (limit > 0)
      if (spawnWithoutVehicleAvailable.get() && spawnWithoutVehicleForced.get())
        return loc("respawn/onlySpawnWithoutVehicleAvailable")
      else
        return "{0}/{0}{1}".subst(limit, loc("respawn/vehicleUsed"))
    return ""
})

let vehicleSpawnInfoBlock = @(squadType) @(){
  watch = vehicleSpawnText
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  gap = midPadding
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = vehicleSpawnText.get().len() > 0
    ? [
        vehicleIcon(squadType)
        textarea(vehicleSpawnText.get(), {
          size = FLEX_H
          halign = ALIGN_CENTER
        }.__update(fontSub))
      ]
    : null
}

let timeToActivateRespawn = Computed(@() respawnBlockedReason.get()?.timeToActivate ?? 0.0)
let timeLeft = mkCountdownTimerPerSec(timeToActivateRespawn)

let availableSpawnZonesCount = Computed(@() spawnZonesState.get()
  .reduce(@(sum, v) canUseRespawnbaseByType.get() == v?.iconType
                    && localPlayerTeam.get() == v?.forTeam ? sum + 1 : sum, 0))

let mkReasonWithTime = @(reasonTxt, timerLocId, timeVal) "{0}\n{1}{2}"
  .subst(reasonTxt, loc(timerLocId),
    colorize(attentionTxtColor, secondsToTimeSimpleString(timeVal)))

function spawnInfoBlock() {
  let { canSpawn = false, readinessPercent = 0, scorePrice = 0,
    isAffordable = true, squadType = null} = curSquadData.get()
  let spawnInfo = [
    @() {
      size = FLEX_H
      watch = [isGamepad, canSpawnCurrentSoldier, spawnScore]
      flow = FLOW_VERTICAL
      gap = midPadding
      halign = ALIGN_CENTER
      children = [
        vehicleSpawnInfoBlock(squadType)
        mkSquadSpawnDesc(canSpawn, readinessPercent, canSpawnCurrentSoldier.get(), isAffordable, scorePrice, spawnScore.get())
      ]
    }
  ]

  let tmVal = timeLeft.get()
  let { reason = null, waitNumber = null } = respawnBlockedReason.get()
  let reasonTxt = waitNumber == null ? loc(reason) : loc(reason, { pos = waitNumber })
  let timerLocId = waitNumber == null ? "respawn/activate_at" : "respawn/nextqueued_at"
  let restrictionsText = tmVal > 0 ? mkReasonWithTime(reasonTxt, timerLocId, tmVal) : reasonTxt
  let restrictionsBlock = reason != null
    ? textarea(restrictionsText, {
        size = FLEX_H
        halign = ALIGN_CENTER
      }.__update(fontSub))
    : null

  let notAffordableBlock = @() textarea(
    loc("respawn/notAffordable", { price = scorePrice, score = spawnScore.get() }), {
      watch = spawnScore
      size = FLEX_H
      halign = ALIGN_CENTER
    }.__update(fontBody))

  let firstSpawnCond = isFirstSpawn.get() && (!paratroopersPointSelectorOn.get() || paratroopersOn.get())
  let hasForceSpawnButton = firstSpawnCond
    || (availableSpawnZonesCount.get() <= 1 && !paratroopersPointSelectorOn.get())
    || (selectedRespawnGroupId.get()?[canUseRespawnbaseByType.get()] ?? -1) >= 0
  let children = !isAffordable ? [ notAffordableBlock ]
    : !canSpawnCurrent.get() ? [ restrictionsBlock ]
    : localPlayerTeamSquadsCanSpawn.get()
      ? [
          respawnTimer(loc("respawn/respawn_squad"), fontSub)
          fuelSelector
          hasForceSpawnButton ? forceSpawnButton()
            : textarea(paratroopersPointSelectorOn.get() ? loc("respawn/landingPoint") : loc("respawn/choose_respawn_point"), {
                size = FLEX_H
                halign = ALIGN_CENTER
              }.__update(fontBody))
          paratroopersButtonBlock
          withoutVehicleSpawnButtonBlock
          spawnsLeftText
        ]
      : [
          textarea(loc("respawn/no_spawn_scores"), {
            size = FLEX_H
            halign = ALIGN_CENTER
          }.__update(fontSub))
        ]

  children.extend(spawnInfo)

  return {
    watch = [curSquadData, localPlayerTeamSquadsCanSpawn, canSpawnCurrent,
             respawnBlockedReason, timeLeft, isFirstSpawn, selectedRespawnGroupId,
             availableSpawnZonesCount, paratroopersPointSelectorOn]
    minHeight = fontH(370) 
    size = FLEX_H
    flow = FLOW_VERTICAL
    valign = ALIGN_BOTTOM
    gap = midPadding
    children
  }
}

let changeSquadParams = Computed(function() {
  let squadId = spawnSquadId.get()
  let idx = squadsList.get().findindex(@(s) s.squadId == squadId) ?? -1
  return {
    idx = idx
    canPrev = idx > 0
    canNext = idx < squadsList.get().len() - 1
  }
})

function changeSquad(dir) {
  let size = squadsList.get().len()
  let idx = (changeSquadParams.get().idx + dir + size) % size
  let { squadId = null } = squadsList.get()[idx]
  if (squadId != null)
    spawnSquadId.set(squadId)
}

let squadShortcuts = @() {
  watch = [isGamepad, changeSquadParams]
  flow = FLOW_HORIZONTAL
  hplace = ALIGN_CENTER
  children = !isGamepad.get() ? null
    : [
        mkHotkey("^J:LB", @() changeSquad(-1), { opacity = changeSquadParams.get().canPrev ? 1.0 : 0.5 })
        mkHotkey("^J:RB", @() changeSquad(1), { opacity = changeSquadParams.get().canNext ? 1.0 : 0.5 })
      ]
}

let squadsListUI = mkCurSquadsList({
  curSquadsList = Computed(@() squadsList.get()
    .map(@(s) s.__merge({ addedRightObj = s.canSpawn ? null : mkSquadSpawnIcon })))
  curSquadId = spawnSquadId
  setCurSquadId = @(squadId) spawnSquadId.set(squadId)
  addedObj = squadShortcuts
  hasOffset = false
  onDoubleClick = doRequestRespawn
})

let squadSpawnList = @() {
  size = FLEX_V
  flow = FLOW_HORIZONTAL
  gap = midPadding
  padding = midPadding
  rendObj = ROBJ_SOLID
  children = [
    squadsListUI
    @() {
      size = FLEX_V
      flow = FLOW_VERTICAL
      gap = midPadding
      watch = [ freeTankSpawnInfoShow ]
      children = [
        freeTankSpawnInfoShow.get() ? freeTankSquadInfo : normSquadInfo
        spawnInfoBlock
      ]
    }
  ]
}.__update(bgConfig)


let squadHintText = Computed(function() {
  let squadId = spawnSquadId.get()
  return isZombieObjectiveMode.get()
    ? loc($"spawn_squad_description/{squadId}")
    : ""
})

function squadHintTextUi() {
  let watch = squadHintText
  if ((squadHintText.get() ?? "") == "")
    return { watch }

  return {
    watch
    pos = [0, slotBaseSize[1] + midPadding]
    size = 0
    padding = smallPadding
    children = {
      padding = smallPadding
      rendObj = ROBJ_WORLD_BLUR_PANEL
      fillColor = blurBgFillColor
      color = 0xFFBBBBBB
      children = {
        size = const [hdpx(400), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = squadHintText.get()
      }
    }
  }
}


let squadRespawn = panel(function() {
  let locId = isFirstSpawn.get()
    ? "respawn/chooseSquad"
    : getSquadPresentation(spawnSquadId.get())?.nameLocId ?? "unknown"

  return {
    watch = [isFirstSpawn, spawnSquadId]
    size = FLEX_V
    flow = FLOW_VERTICAL
    gap = smallPadding
    children = [
      headerBlock(loc(locId)).__update(bgConfig)
      {
        size = FLEX_V
        flow = FLOW_HORIZONTAL
        children = [
          squadSpawnList
          squadHintTextUi
        ]
      }
    ]
  }
},
{
  rendObj = null
  size = FLEX_V
  flow = FLOW_HORIZONTAL
  gap = smallPadding
})

const titlePadding = fsh(4)
let missionNameUI = @() {
  rendObj = ROBJ_TEXT
  text = missionParams.get().name
  margin = [safeAreaVerPadding.get() + titlePadding, safeAreaHorPadding.get() + titlePadding]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  watch = [safeAreaVerPadding, missionParams]
}.__update(fontHeading1, strokeStyle)


let selectSpawnTitle = @() {
  watch = [ paratroopersPointSelectorOn ]
  rendObj = ROBJ_TEXT
  text = paratroopersPointSelectorOn.get() ? loc("respawn/selectLandingPoint") : loc("select_spawn")
}.__update(fontHeading2, strokeStyle)
let showSpawnHint = Computed(@() !isFirstSpawn.get() && availableSpawnZonesCount.get() > 0)

let selectSpawnHint = @(){
  watch = [showSpawnHint, safeAreaVerPadding]
  hplace = ALIGN_CENTER
  pos = [0, safeAreaVerPadding.get() + fsh(10)]
  children = showSpawnHint.get() || paratroopersPointSelectorOn.get() ? selectSpawnTitle : null
}


let zombieObjectivePrechosenTeam = @() {
  watch = isZombieObjectiveMode
  margin = const [fsh(4), 0]
  vplace = ALIGN_BOTTOM
  children = isZombieObjectiveMode.get() ? zombieObjectivePrechosenUi : null
}


return freeze({
  size = FLEX
  children = [
    {
      size = FLEX
      flow = FLOW_HORIZONTAL
      children = [
        squadRespawn
        zombieObjectivePrechosenTeam
      ]
    }
    selectSpawnHint
    missionNameUI
  ]
})
