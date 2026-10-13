import "%ui/control/mouse_buttons.nut" as mouseButtons
import "%ui/control/gui_buttons.nut" as JB
import "%ui/hud/huds/overlays/mkTask.nut" as mkTask
import "%ui/hud/huds/minimap/minimap_ctx.nut" as mmContext
from "%ui/style/fontsStyle.nut" import fontHeading1
from "%ui/hud/minimap_ctors.nut" import mmChildrenCtors, mmZombieEventChildrenCtors
from "%ui/hud/menus/bigmap_state.nut" import bigmapDefaultVisibleRadius
from "%ui/components/scrollbar.nut" import makeVertScroll
from "%ui/hud/state/interactive_state.nut" import removeInteractiveElement, hudIsInteractive, switchInteractiveElement
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR
from "%ui/hud/send_minimap_mark.nut" import command
from "%ui/state/safeArea.nut" import safeAreaAmount
from "%ui/hud/state/health_state.nut" import isAlive
from "%ui/hud/state/tasksInBattle.nut" import battleUnlocks, statsInGame, getTasksWithProgress
from "%ui/userstats/unlocksState.nut" import unlockProgress
from "%ui/state/missionParams.nut" import missionParams
from "%ui/hud/state/replay_state.nut" import isReplay
from "%ui/style/designConst.nut" import attentionTxtColor
from "%ui/hud/state/zombie_zones_state.nut" import isZombieObjectiveMode
from "%ui/ui_library.nut" import *
from "minimap" import MinimapState
from "minimap.behaviors" import Minimap, MinimapInput
from "%ui/hud/menus/mapComps.nut" import mouseNavTips, placePointsTipGamepad, navGamepadHints, placePointsTipMouse

let mapTransform = const { rotate = 90 }
let markersTransform = const { rotate = -90 }

let isMapAutonomousInReplay = Watched(true)

let isMapInteractive = Computed(@() hudIsInteractive.get()
  && (!isReplay.get() || !isMapAutonomousInReplay.get()))

const screen_aspect_ratio = sw(100)/sh(100)
local mapSizeForTasks = [fsh(70), fsh(70)]
let leftPadding = Watched(mapSizeForTasks[1]/10)
const mapPadding = fsh(1)

if (screen_aspect_ratio <= 1280.0/1024) {
  mapSizeForTasks = [fsh(50), fsh(50)]
  leftPadding.set(0)
}
else if ( screen_aspect_ratio <= 4.0/3 ) {
  mapSizeForTasks = [fsh(55), fsh(55)]
  leftPadding.set(0)
}

const tasksListWidth = hdpx(450)
const interactiveTipsHeight = hdpx(100)

let statsUpdateTip = {
  rendObj = ROBJ_TEXT
  size = const [tasksListWidth, interactiveTipsHeight]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  text = loc("hud/stats_update_tip")
  color = attentionTxtColor
}

let showBigMap = mkWatched(persist, "showBigMap", false)
let needShowTasks = Computed(@() battleUnlocks.get().len()>0)
let mapSize = Computed(@() needShowTasks.get()
  ? mapSizeForTasks
  : [safeAreaAmount.get()*fsh(70), safeAreaAmount.get()*fsh(70)])

let tasksList = @() {
  watch = [mapSize, battleUnlocks, unlockProgress, statsInGame]
  size = [tasksListWidth, mapSize.get()[0]]
  key = "big_map_tasks"
  children = makeVertScroll({
    size = FLEX_H
    flow = FLOW_VERTICAL
    children = getTasksWithProgress(battleUnlocks.get(), unlockProgress.get(), statsInGame.get())
      .map(@(u) mkTask(u))
  },
  {
    size = FLEX_H
    maxHeight = mapSize.get()[0]
  })
}


isAlive.subscribe(function(live) {
  if (!live)
    showBigMap.set(false)
})

showBigMap.subscribe(@(_) removeInteractiveElement("bigMap"))

let mapRootAnims = [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.15, play=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
]


let minimapState = MinimapState({
  ctx = mmContext
  visibleRadius = bigmapDefaultVisibleRadius.get()
  shape = "square"
})

bigmapDefaultVisibleRadius.subscribe(@(r) minimapState.setVisibleRadius(r))

let visCone = {
  size = FLEX
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP_VIS_CONE
  behavior = Minimap
}

let modeHotkeyTip = tipCmp({
  text = loc("controls/HUD.Interactive")
  inputId = "HUD.Interactive"
  style = { rendObj = null }
  main_params = {
    size = const [SIZE_TO_CONTENT, ph(100)]
  }
  animations = []
})

let mkPlacePointsTip = @(mapSizeW, addChild) @() {
  watch = [mapSizeW, isGamepad]
  size = [mapSizeW.get()[0], SIZE_TO_CONTENT]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  gap = fsh(0.5)
  children = [
    isGamepad.get() ? navGamepadHints : mouseNavTips
    isGamepad.get() ? placePointsTipGamepad : placePointsTipMouse
    addChild
  ]
}
let mkInteractiveTips = @(interactiveTips, notInteractiveTips) @() {
  watch = isMapInteractive
  size = const [FLEX, interactiveTipsHeight]
  valign = ALIGN_CENTER
  flow = FLOW_VERTICAL
  gap = fsh(0.5)
  padding = const [mapPadding, 0]
  halign = ALIGN_CENTER
  children = isMapInteractive.get() ? interactiveTips : notInteractiveTips
}

function interactiveFrame() {
  let res = { watch = isMapInteractive }
  if (!isMapInteractive.get())
    return res
  return res.__update({
    rendObj = ROBJ_FRAME
    size = FLEX
    borderWidth = hdpx(2)
    color = Color(180,160,10,130)

    behavior = DngBhv.ActivateActionSet
    actionSet = "StopInput"
  })
}

let bigMapEventHandlers = {
  ["HUD.Interactive"] = function(_event) {
    if (isReplay.get())
      isMapAutonomousInReplay.set(!isMapAutonomousInReplay.get())
    switchInteractiveElement("bigMap")
  },
  ["HUD.Interactive:end"] = function (event) {
    if (showBigMap.get() && ((event?.dur ?? 0) > 500 || event?.appActive == false)) {
      if (isReplay.get())
        isMapAutonomousInReplay.set(true)
      removeInteractiveElement("bigMap")
    }
  }
}

let closeMapDesc = {
  action = @() showBigMap.set(false),
  description = loc("Close"),
  inputPassive = true
}

function mkMapLayer(ctorWatch, paramsWatch, map_size) {
  return @() {
    watch = [paramsWatch, ctorWatch?.watch]
    size = map_size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    clipChildren = true
    eventPassThrough = true
    minimapState = minimapState
    transform = mapTransform
    behavior = Minimap
    children = ctorWatch?.ctor(paramsWatch.get())
  }
}

let interactiveTips = mkInteractiveTips(
  mkPlacePointsTip(mapSize, null),
  modeHotkeyTip)

function onClickMap(e){
  if (e.button==1 || (isGamepad.get() && e.button==0))
    command(e, minimapState)
}
function onDoubleClickMap(e) {
  command(e, minimapState)
}

let markersParams = Computed(@() {
  state = minimapState
  size = mapSize.get()
  isCompassMinimap = false
  transform = markersTransform
  isInteractive = isMapInteractive.get()
  showHero = true
})

let baseMap = @() {
  size = mapSize.get()
  watch = [isMapInteractive, mapSize]
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP
  transform = mapTransform
  panMouseButton = mouseButtons.MMB
  behavior = isMapInteractive.get()
    ? [Minimap, Behaviors.Button, MinimapInput]
    : [Minimap]
  color = Color(255, 255, 255, 200)

  halign = ALIGN_CENTER
  valign = ALIGN_CENTER

  clipChildren = true
  eventPassThrough = true
  stickCursor = false
  children = [visCone]

  onClick = onClickMap
  onDoubleClick = onDoubleClickMap
}

let backMap = @() {
  size = mapSize.get()
  watch = [isMapInteractive, mapSize]
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP_BACK
  transform = mapTransform
  behavior = [Minimap]
  color = Color(255, 255, 255, 200)

  halign = ALIGN_CENTER
  valign = ALIGN_CENTER

  clipChildren = true
  eventPassThrough = true
  stickCursor = false
}

function mapLayers() {
  let mmChildren = isZombieObjectiveMode.get() ? mmZombieEventChildrenCtors : mmChildrenCtors
  return {
    behavior = DngBhv.ActivateActionSet
    actionSet = "BigMap"
    watch = [ mapSize, isZombieObjectiveMode ]
    size = mapSize.get()
    children = [ backMap, baseMap ]
      .extend(mmChildren.map(@(c) mkMapLayer(c, markersParams, mapSize.get())))
      .append(interactiveFrame)
  }
}


let mapBlock = {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = const [0, mapPadding]
  children = [
    mapLayers
    interactiveTips
  ]
}

let missionTitle = @(){
  watch = missionParams
  size = FLEX_H
  padding = const [mapPadding, mapPadding]
  children = missionParams.get().name == null ? null : {
    rendObj = ROBJ_TEXT
    text = missionParams.get().name
    fontFxColor = DEFAULT_TEXT_COLOR
  }.__update(fontHeading1)
}


let mapContent = @() {
  watch = [needShowTasks, isReplay]
  flow = FLOW_HORIZONTAL
  children = [
    mapBlock
    needShowTasks.get() && !isReplay.get()
      ? @() {
          watch = isMapInteractive
          size = FLEX_V
          disableInput = !isMapInteractive.get()
          flow = FLOW_VERTICAL
          children = [
            tasksList
            statsUpdateTip
          ]
        }
      : null
  ]
}


function bigMap() {
  return {
    rendObj = ROBJ_SOLID
    color = Color(0,0,0,140)
    key = "big_map"
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    pos = const [0, hdpx(30)]
    padding = const [mapPadding, 0]
    flow = FLOW_VERTICAL
    sound = {
      attach = "ui/map_on"
      detach = "ui/map_off"
    }
    children = [
      missionTitle
      mapContent
    ]


    animations = mapRootAnims
    hotkeys = [
      [ "Esc", closeMapDesc],
      [ $"^{JB.B}", closeMapDesc],
      [ "@HUD.BigMap", closeMapDesc ],
      [$"J:RB | J:LB"] 
    ]
    eventHandlers = bigMapEventHandlers
  }
}

return {
  bigMap
  showBigMap
}
