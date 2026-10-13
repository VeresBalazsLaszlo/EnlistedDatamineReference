import "%dngscripts/ecs.nut" as ecs
from "%ui/state/missionParams.nut" import missionParams
from "%ui/hud/state/soldier_class_state.nut" import heroSoldierKind
from "%ui/options/mkOnlineSaveData.nut" import mkOnlineSaveData
from "%ui/hud/chat.ui.nut" import showChatInput
from "%ui/hud/state/briefingState.nut" import showBriefing
from "%ui/hud/state/hero_weapons.nut" import curWeaponIsGrenade
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/hud/state/respawnState.nut" import needSpawnMenu
from "%ui/hud/state/squad_soldiers_menu_state.nut" import showSquadSoldiersMenu
from "%ui/featureFlags.nut" import hasMissionTutorial, hasControlTutorial
from "dasevents" import RqContextCommand
from "ecs.computed" import mkEcsComputed
from "%ui/ui_library.nut" import *


const EMS_STAND = 0
const EMS_SPRINT = 3





let contextOrderIssued = Watched(false)

ecs.register_es("ui_hero_context_order_es",
  { [RqContextCommand] = @(...) contextOrderIssued.set(true) },
  { comps_rq = ["watchedByPlr"] },
  { tags = "gameClient" }
)

let heroControl = mkEcsComputed({
  comps = [
    ["human_net_phys__curMoveState", ecs.TYPE_INT],
    ["human_net_phys__isAiming", ecs.TYPE_BOOL],
    ["human_net_phys__isHctShoot", ecs.TYPE_BOOL],
  ]
  comps_rq = ["watchedByPlr"]
})
let moveState = Computed(@() heroControl.get()?.human_net_phys__curMoveState ?? EMS_STAND)
let isAiming = Computed(@() heroControl.get()?.human_net_phys__isAiming ?? false)
let isShooting = Computed(@() heroControl.get()?.human_net_phys__isHctShoot ?? false)
let isMoving = Computed(@() moveState.get() != EMS_STAND)
let isSprinting = Computed(@() moveState.get() == EMS_SPRINT)




let heroStance = mkEcsComputed({
  comps = [
    ["tutorial_tips__isCrouching", ecs.TYPE_BOOL, false],
    ["tutorial_tips__isCrawling", ecs.TYPE_BOOL, false],
    ["tutorial_tips__isJumping", ecs.TYPE_BOOL, false],
  ]
  comps_rq = ["watchedByPlr"]
})
let isCrouching = Computed(@() heroStance.get()?.tutorial_tips__isCrouching ?? false)
let isCrawling = Computed(@() heroStance.get()?.tutorial_tips__isCrawling ?? false)
let isJumping = Computed(@() heroStance.get()?.tutorial_tips__isJumping ?? false)




let reloadRequested = mkEcsComputed({
  comps = [["gun_reload__isRequesting", ecs.TYPE_BOOL, false]]
  comps_rq = ["gun", "watchedPlayerItem"]
  filter = "opt(gun_reload__isRequesting, false)"
})
let isReloading = Computed(@() reloadRequested.get() ?? false)

const NEW_MISSION_TYPE = "new_mission_type"
const NEW_SOLDIER_CLASS = "new_soldier_class"
const NEW_SQUAD_SELECTION = "new_squad_selection"


let seenMissionHintsStorage = mkOnlineSaveData("seenMissionHints")
let setSeenMissionHints = seenMissionHintsStorage.setValue
let curSeenMissionHints = seenMissionHintsStorage.watch

console_register_command(@() setSeenMissionHints({}), "ui.resetSeenMissionHints")


let tutorialsCfg = [
  { 
    id = "new_mission_type_invasion"
    titleLocId = "missionType/invasion"
    tutorialLocId = "invasion/attackers_goals"
    image = "ui/stalingrad_login_screen_blured.avif"
    isActive = @(pointer, details) pointer == NEW_MISSION_TYPE && details == "invasion"
  }
  { 
    id = "new_mission_type_destruction"
    titleLocId = "missionType/destruction"
    tutorialLocId = "destruction/attackers_goals/short"
    image = "ui/stalingrad_login_screen_blured.avif"
    isActive = @(pointer, details) pointer == NEW_MISSION_TYPE && details == "destruction"
  }
  { 
    id = "new_soldier_class_rifle"
    titleLocId = "soldierClass/rifle"
    tutorialLocId = "squadPromo/rifle/shortDesc"
    image = "ui/soldiers/usa/usa_normandy_rifle_1_image.avif"
    isActive = @(pointer, details) pointer == NEW_SOLDIER_CLASS && details == "rifle"
  }
  {
    id = "new_soldier_class_assault"
    titleLocId = "soldierClass/assault"
    tutorialLocId = "squadPromo/assault/shortDesc"
    image = "ui/shop/usa_normandy_prem_assault_2.avif"
    isActive = @(pointer, details) pointer == NEW_SOLDIER_CLASS && details == "assault"
  }
  {
    id = "new_soldier_class_mgun"
    titleLocId = "soldierClass/mgun"
    tutorialLocId = "squadPromo/mgun/shortDesc"
    image = "ui/shop/usa_normandy_prem_mgun_1.avif"
    isActive = @(pointer, details) pointer == NEW_SOLDIER_CLASS && details == "mgun"
  }
  {
    id = "new_soldier_class_anti_tank"
    titleLocId = "soldierClass/anti_tank"
    tutorialLocId = "squadPromo/anti_tank/shortDesc"
    image = "ui/stalingrad_login_screen_blured.avif"
    isActive = @(pointer, details) pointer == NEW_SOLDIER_CLASS && details == "anti_tank"
  }
  {
    id = "new_soldier_class_sniper"
    titleLocId = "soldierClass/sniper"
    tutorialLocId = "squadPromo/sniper/shortDesc"
    image = "ui/stalingrad_login_screen_blured.avif"
    isActive = @(pointer, details) pointer == NEW_SOLDIER_CLASS && details == "sniper"
  }
  {
    id = "new_soldier_class_engineer"
    titleLocId = "soldierClass/engineer"
    tutorialLocId = "squadPromo/engineer/shortDesc"
    image = "ui/stalingrad_login_screen_blured.avif"
    isActive = @(pointer, details) pointer == NEW_SOLDIER_CLASS && details == "engineer"
  }
  { 
    id = "tutorial_squad_selection"
    titleLocId = "respawn/chooseSquad"
    tutorialLocId = "tutorial/squad_selection"
    image = ""
    isActive = @(pointer, _details) pointer == NEW_SQUAD_SELECTION
  }
]


local heroEid = 0
local heroSpawnedOnce = false
needSpawnMenu.subscribe(function(_v) {
  heroEid = 0
})
controlledHeroEid.subscribe(function(v) {
  if (v != 0)
    heroSpawnedOnce = true
  if (heroEid == 0 && v != 0)
    heroEid = v
})


let curMissionTutorial = Computed(function() {
  if (!hasMissionTutorial.get())
    return null

  let mType = missionParams.get().type
  let sKind = heroSoldierKind.get()
  let spawnMenuOpen = needSpawnMenu.get()
  let seen = curSeenMissionHints.get()
  
  let squadWiped = spawnMenuOpen && heroSpawnedOnce
  let res = tutorialsCfg.findvalue(function(cfg) {
    let { id, isActive } = cfg
    return id not in seen
      && (isActive(NEW_MISSION_TYPE, mType)
          || isActive(NEW_SOLDIER_CLASS, sKind)
          || (squadWiped && isActive(NEW_SQUAD_SELECTION, "")))
  })
  return res
})


function markSeenMissionHint(id) {
  setSeenMissionHints((curSeenMissionHints.get() ?? {}).__merge({ [id] = true }))
}


let controlTutorialsCfg = [
  {
    id = "tutorial_move"
    details = [{ inputId = "Human.Move", locId = "controls/Human.Move" }]
    completeTrigger = isMoving
    isComplete = @(v) v ?? false
  }
  {
    id = "tutorial_sprint"
    details = [{ inputId = "Human.Sprint", locId = "controls/Human.Sprint" }]
    completeTrigger = isSprinting
    isComplete = @(v) v ?? false
  }
  {
    id = "tutorial_crouch"
    details = [{ inputId = "Human.Crouch", locId = "controls/Human.Crouch" }]
    completeTrigger = isCrouching
    isComplete = @(v) v ?? false
  }
  {
    id = "tutorial_crawl"
    details = [{ inputId = "Human.Crawl", locId = "controls/Human.Crawl" }]
    completeTrigger = isCrawling
    isComplete = @(v) v ?? false
  }
  {
    id = "tutorial_jump"
    details = [{ inputId = "Human.Jump", locId = "controls/Human.Jump" }]
    completeTrigger = isJumping
    isComplete = @(v) v ?? false
  }
  {
    id = "tutorial_shoot"
    details = [{ inputId = "Human.Shoot", locId = "controls/Human.Shoot" }]
    completeTrigger = isShooting
    isComplete = @(v) v ?? false
  }
  {
    id = "tutorial_aim"
    details = [{ inputId = "Human.Aim1", locId = "controls/Human.Aim1" }]
    completeTrigger = isAiming
    isComplete = @(v) v ?? false
  }
  {
    id = "tutorial_reload"
    details = [{ inputId = "Human.Reload", locId = "controls/Human.Reload" }]
    completeTrigger = isReloading
    isComplete = @(v) v ?? false
  }
  {
    id = "tutorial_select_grenade"
    details = [{ inputId = "Human.GrenadeNext", locId = "controls/Human.GrenadeNext" }]
    completeTrigger = curWeaponIsGrenade
    isComplete = @(v) v ?? false
  }
  {
    id = "tutorial_change_soldier"
    details = [{ inputId = "Human.SquadNext", locId = "controls/Human.SquadNext" }]
    completeTrigger = controlledHeroEid
    isComplete = @(v) heroEid != 0 && v != heroEid
  }
  {
    id = "tutorial_squad_soldiers_menu"
    details = [{ inputId = "HUD.SquadSoldiersMenu", locId = "controls/HUD.SquadSoldiersMenu" }]
    completeTrigger = showSquadSoldiersMenu
    isComplete = @(v) v ?? false
  }
  {
    id = "tutorial_context_order"
    details = [{ inputId = "Human.ContextCommand", locId = "controls/Human.ContextCommand" }]
    completeTrigger = contextOrderIssued
    isComplete = @(v) v ?? false
  }
  {
    id = "tutorial_open_briefing"
    details = [{ inputId = "HUD.Briefing", locId = "loading/controlsHelpTip" }]
    completeTrigger = showBriefing
    isComplete = @(v) v ?? false
  }
]



const CONTROL_TUTORIAL_DEFAULT_SHOW_TIME = 10.0
let disableControlTutorial = @() hasControlTutorial.set(false)
local controlTutorialShowTime = CONTROL_TUTORIAL_DEFAULT_SHOW_TIME

function allHintsDone(seen) {
  foreach (cfg in controlTutorialsCfg)
    if (!(seen?[cfg.id] ?? false))
      return false
  return true
}

function scheduleControlTutorialClose() {
  gui_scene.clearTimer(disableControlTutorial)
  if (controlTutorialShowTime > 0)
    gui_scene.resetTimeout(controlTutorialShowTime, disableControlTutorial)
  else
    disableControlTutorial()
}

ecs.register_es("enable_control_tutorial_es",
  {
    function onInit(_evt, _eid, comp) {
      controlTutorialShowTime = comp["controlTutorial__showTime"]
      gui_scene.clearTimer(disableControlTutorial)
      
      
      
      contextOrderIssued.set(false)
      hasControlTutorial.set(true)
      
      
      if (allHintsDone(curSeenMissionHints.get()))
        scheduleControlTutorialClose()
    }
    onDestroy = function(...) {
      gui_scene.clearTimer(disableControlTutorial)
      hasControlTutorial.set(false)
    }
  },
  {
    comps_rq = ["enableControlTutorial"]
    comps_ro = [["controlTutorial__showTime", ecs.TYPE_FLOAT, CONTROL_TUTORIAL_DEFAULT_SHOW_TIME]]
  }
)


ecs.register_es("enable_mission_tutorial_es",
  {
    onInit    = @(...) hasMissionTutorial.set(true)
    onDestroy = @(...) hasMissionTutorial.set(false)
  },
  { comps_rq = ["enableMissionTutorial"] }
)


let isControlTutorialVisible = Computed(function() {
  if (!hasControlTutorial.get() || needSpawnMenu.get()
    || showChatInput.get() || curMissionTutorial.get() != null
  )
    return false

  let seen = curSeenMissionHints.get()
  foreach (cfg in controlTutorialsCfg)
    if (!(seen?[cfg.id] ?? false))
      return true

  
  return true
})


foreach (cfg in controlTutorialsCfg) {
  let curCfg = cfg
  curCfg.completeTrigger.subscribe(function(v) {
    
    
    if (!hasControlTutorial.get())
      return
    if (curSeenMissionHints.get()?[curCfg.id] ?? false)
      return
    if (curCfg.isComplete(v))
      markSeenMissionHint(curCfg.id)
  })
}


curSeenMissionHints.subscribe(function(seen) {
  if (!hasControlTutorial.get())
    return
  if (allHintsDone(seen))
    scheduleControlTutorialClose()
})


return {
  curMissionTutorial
  markSeenMissionHint
  controlTutorialsCfg
  curSeenMissionHints
  isControlTutorialVisible
}
