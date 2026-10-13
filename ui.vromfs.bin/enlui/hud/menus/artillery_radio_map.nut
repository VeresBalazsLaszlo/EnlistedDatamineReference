import "%ui/control/mouse_buttons.nut" as mouseButtons
import "%ui/control/gui_buttons.nut" as JB
import "%ui/style/cursors.nut" as cursors
import "%dngscripts/ecs.nut" as ecs
from "dagor.math" import Point2, Point3
from "%sqstd/math.nut" import sqrt
from "%ui/hud/minimap_ctors.nut" import mmChildrenCtors
from "%ui/hud/state/interactive_state.nut" import removeInteractiveElement, addInteractiveElement, hudIsInteractive
from "%ui/hud/ct_hud_menus.nut" import closeMenu
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR
from "%ui/hud/state/health_state.nut" import isAlive, isDowned
from "%dngscripts/sound_system.nut" import sound_play
from "%dngscripts/common_queries.nut" import get_controlled_hero
from "%ui/state/safeArea.nut" import safeAreaAmount
from "%ui/hud/menus/mapComps.nut" import hintTextFunc, mkTips
from "dasevents" import CmdClientHumanSpeech, EventArtilleryMapPosSelected, CmdOpenArtilleryMap, CmdCloseArtilleryMap, CmdArtilleryStartSpeeches, EventResetDeviceState
from "%ui/hud/menus/aircraft_request_preview.ui.nut" import aircraftRequestTargetBiases, mkAircraftRequestPreview
from "%ui/hud/menus/art_request_preview.nut" import isArtRequest
from "bhvMinimap" import EventMinimapZoomed
from "%ui/hud/menus/artillery_radio_map_shell_type.nut" import currentShellType, changeShellTips, currentShellTypeIndex
from "%ui/hud/menus/art_request_tips.nut" import isAircraftRequest, artRequestTips
from "%ui/hud/state/artillery.nut" import activeAircraftRequestTimeLeft
from "%ui/ui_library.nut" import *
from "minimap" import MinimapState
from "minimap.behaviors" import Minimap, MinimapInput

let mmContext = require("%ui/hud/huds/minimap/minimap_ctx.nut")
let { mouseNavTips, navGamepadHints } = require("%ui/hud/menus/mapComps.nut")
let showArtilleryMap = mkWatched(persist, "showArtilleryMap", false)
let selectedStartWorldPos = Watched(null)
let currentMouseWorldPos = Watched(Point3())

let mapTransform = const { rotate = 90 }
let markersTransform = const { rotate = -90 }

let artilleryTypeCursor = {
  
  common = "ui/skin#sniper_rifle.svg",
  artillery_he = "ui/skin#artillery_he.svg",
  artillery_smoke = "ui/skin#artillery_smoke.svg",
  artillery_supply = "ui/skin#building_ammo_box.svg",
  rocket_artillery_ussr = "ui/skin#rocket_artillery.svg",
  rocket_artillery_ger = "ui/skin#rocket_artillery.svg",
  rocket_artillery_us = "ui/skin#rocket_artillery.svg",
  rocket_artillery_jp = "ui/skin#rocket_artillery.svg",
  aircraft_request = "ui/skin#aircraft_request.svg",
  artillery_gas = "ui/skin#skull.svg",
}


let mapSize = Computed(@() [safeAreaAmount.get()*fsh(76), safeAreaAmount.get()*fsh(76)])
const title = "map/artillery"
const tipLmb = "map/artilleryStrike"


isAlive.subscribe(function(live) {
  if (!live)
    showArtilleryMap.set(false)
})
isDowned.subscribe(function(downed){
  if (downed)
    showArtilleryMap.set(false)
})


let currentMaxLineLength = Computed(@() currentShellType.get()?.maxLength ?? 0.0)
let isAircraftRequestActive = Computed(@() activeAircraftRequestTimeLeft.get() <= 0.)

currentShellTypeIndex.subscribe(@(...) selectedStartWorldPos.set(null))

function getAllowedLineEndPos(worldPos1, worldPos2, maxLineLength) {
  local dir = Point2(worldPos2.x, worldPos2.z) - Point2(worldPos1.x, worldPos1.z)
  let lineLengthSq = dir.lengthSq()
  local res = worldPos2
  if (lineLengthSq > 0.0 && lineLengthSq > maxLineLength * maxLineLength) {
    dir *= (maxLineLength / sqrt(lineLengthSq))
    res = worldPos1 + Point3(dir.x, 0.0, dir.y)
  }
  return res
}

function onSelect(selectedPos) {
  if (selectedStartWorldPos.get() || !currentShellType.get()?.isLine) {
    let pos = selectedStartWorldPos.get() ?? selectedPos
    let posEnd = getAllowedLineEndPos(pos, selectedPos, currentMaxLineLength.get())
    ecs.g_entity_mgr.sendEvent(get_controlled_hero(),
      EventArtilleryMapPosSelected({pos, typeIndex = currentShellTypeIndex.get(), posEnd}))
    selectedStartWorldPos.set(null)
  } else
    selectedStartWorldPos.set(selectedPos)
}

let closeRequest = @() ecs.g_entity_mgr.sendEvent(get_controlled_hero(), CmdCloseArtilleryMap())

let minimapState = MinimapState({
  ctx = mmContext
  visibleRadius = 350
  shape = "square"
})

let visCone = {
  size = FLEX
  minimapState = minimapState
  rendObj = ROBJ_MINIMAP_VIS_CONE
  behavior = Minimap
}

let mapRootAnims = [
  { prop=AnimProp.opacity, from=0, to=1, duration=0.15, play=true, easing=OutCubic }
  { prop=AnimProp.opacity, from=1, to=0, duration=0.25, playFadeOut=true, easing=OutCubic }
]

function mouseTips() {
  let children = [
    mkTips(["LMB"], tipLmb)
    mouseNavTips
  ]
  return {
    flow = FLOW_HORIZONTAL
    gap = hdpx(10)
    children = children
  }
}
let titleHint = {
  padding = fsh(0.5)
  children = hintTextFunc(loc(title), DEFAULT_TEXT_COLOR)
  rendObj = ROBJ_WORLD_BLUR
  halign = ALIGN_CENTER
}

let tipsBlock = @(){
  size = FLEX_H
  watch = [isGamepad, isAircraftRequest, isAircraftRequestActive]
  rendObj = ROBJ_WORLD_BLUR
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  padding = fsh(1)
  children = [
    isAircraftRequest.get() && !isAircraftRequestActive.get() ? artRequestTips : null
    changeShellTips
    isGamepad.get() ? navGamepadHints : mouseTips
  ]
}

let framedMapBg = {
  rendObj = ROBJ_WORLD_BLUR
  color = Color(140,140,140,255)
  padding = fsh(1)
  behavior = DngBhv.ActivateActionSet
  actionSet = "BigMap"
}

let interactiveFrame = @() {
  rendObj = ROBJ_FRAME
  size = FLEX
  borderWidth = hdpx(2)
  color = Color(180,160,10,130)

  
  behavior = DngBhv.ActivateActionSet
  actionSet = "StopInput"
}

let closeMapDesc = {
  action = @() closeRequest(),
  description = loc("Close"),
  inputPassive = true
}

let mapCoord = @(x) (x * 50) + 50

let mkStartPoint = @(startPoint) {
  size = FLEX
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  color = Color(90,90,90,50)
  fillColor = Color(0,0,0,0)
  rendObj = ROBJ_VECTOR_CANVAS
  lineWidth = hdpx(20)
  behavior = Behaviors.RtPropUpdate
  update = function() {
    let pos = minimapState.worldToMap(startPoint)
    let pos2 = minimapState.worldToMap(
      getAllowedLineEndPos(startPoint, currentMouseWorldPos.get(), currentMaxLineLength.get()))
    return {
      commands = [[VECTOR_LINE, mapCoord(pos.x), mapCoord(-pos.y), mapCoord(pos2.x), mapCoord(-pos2.y)]]
    }
  }
}

let mkArtilleryStartPos = @() { watch = selectedStartWorldPos }
  .__update(selectedStartWorldPos.get() ? mkStartPoint(selectedStartWorldPos.get()) : {})

function mkMapLayer(ctorDesc, paramsWatch) {
  return @() {
    watch = [paramsWatch, ctorDesc.watch]
    size = FLEX
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    clipChildren = true
    eventPassThrough = true
    minimapState = minimapState
    transform = mapTransform
    behavior = Minimap
    children = ctorDesc.ctor(paramsWatch.get())
  }
}

let markersParams = Computed(@() {
  state = minimapState
  size = mapSize.get()
  isCompassMinimap = false
  transform = markersTransform
  isInteractive = true
  showHero = true
})

function getWorldPos(event, state) {
  let elem = event.target
  let elemW = elem.getWidth()
  let elemH = elem.getHeight()
  let relX = ((event?.screenX ?? event.x) - elem.getScreenPosX() - elemW*0.5) * 2 / elemW
  let relY = ((event?.screenY ?? event.y) - elem.getScreenPosY() - elemH*0.5) * 2 / elemH
  return state.mapToWorld(relY, relX)
}

function command(event, state) {
  if (event.button == 1) {
    if (selectedStartWorldPos.get())
      selectedStartWorldPos.set(null)
    else
      closeRequest()
  } else if (event.button == 0 || isGamepad.get())
    onSelect(getWorldPos(event, state))
}
let artilleryMapSpeechInd = Watched(-1)

ecs.register_es("artilleryCallSpeech",
{
  [CmdArtilleryStartSpeeches] = function(evt, eid,_comp) {
    if (evt.ind != artilleryMapSpeechInd.get())
      ecs.g_entity_mgr.sendEvent(eid, CmdClientHumanSpeech({phrase=currentShellType.get()?.requestPhrase ?? "artStrikeRequest"}))
    ecs.g_entity_mgr.sendEvent(eid, CmdClientHumanSpeech({phrase=currentShellType.get()?.responsePhrase ?? "artStrikeRespond"}))
    artilleryMapSpeechInd.set(-1)
  }
},
{
  comps_rq=["hero"],
},
{tags="gameClient"}
)

showArtilleryMap.subscribe(function(show) {
  if (show) {
    closeMenu("BigMap")
    closeMenu("Scores")
    addInteractiveElement("artilleryMap")
    selectedStartWorldPos.set(null)

    sound_play("ui/radio_artillery")
    ecs.g_entity_mgr.sendEvent(get_controlled_hero(), CmdClientHumanSpeech({phrase=currentShellType.get()?.requestPhrase ?? "artStrikeRequest"}))
    artilleryMapSpeechInd.set(currentShellTypeIndex.get())
  } else {
    removeInteractiveElement("artilleryMap")
    closeRequest()
  }
})

let currentMinimapVisibleRadius = Watched(minimapState.getVisibleRadius())

const artilleryInactiveColor = Color(10, 10, 10, 100)
const artilleryActiveColor   = Color(84, 24, 24, 5)

let baseMap = @() {
  size = FLEX
  watch = [currentShellType,
           currentMouseWorldPos,
           currentMinimapVisibleRadius,
           aircraftRequestTargetBiases,
           isArtRequest,
           isAircraftRequestActive]

  minimapState = minimapState
  rendObj = ROBJ_MINIMAP
  transform = mapTransform
  panMouseButton = mouseButtons.MMB
  behavior = hudIsInteractive.get()
    ? [Minimap, Behaviors.Button, Behaviors.ProcessPointingInput, MinimapInput]
    : [Minimap]
  color = Color(255, 255, 255, 200)

  halign = ALIGN_CENTER
  valign = ALIGN_CENTER

  clipChildren = true
  eventPassThrough = true
  stickCursor = false
  children = [visCone]
    .append(mkArtilleryStartPos)
    .append(isArtRequest.get() ?
      mkAircraftRequestPreview(
        currentMouseWorldPos.get(),
        currentShellType.get().radius,
        currentMinimapVisibleRadius.get()
      ) : null)
    .extend(aircraftRequestTargetBiases.get()
      .map(@(targetBias)
        mkAircraftRequestPreview(
          currentMouseWorldPos.get() + targetBias,
          currentShellType.get().radius,
          currentMinimapVisibleRadius.get(),
          isAircraftRequestActive.get() ? artilleryActiveColor : artilleryInactiveColor
        )))

  function onClick(e) {
    command(e, minimapState)
  }

  function onPointerMove(e) {
    if (e.devId == DEVID_MOUSE || e.devId == DEVID_JOYSTICK) {
      currentMouseWorldPos.set(getWorldPos(e, minimapState))
    }
  }
}

let framedMap = @() framedMapBg.__merge({
  watch = [mapSize]
  size = mapSize.get()
  children = [
    baseMap
  ]
    .extend(mmChildrenCtors.map(@(c) mkMapLayer(c, markersParams)))
    .append(interactiveFrame)
})

let mapBlock = @(){
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    titleHint
    framedMap
    tipsBlock
  ]
}

function artilleryMap() {
  let typeCursor = artilleryTypeCursor?[currentShellType.get()?.name]
    ?? artilleryTypeCursor.common
  return {
    watch = [mapSize, currentShellType]
    size = SIZE_TO_CONTENT
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    cursor = cursors.mkCustom(typeCursor)
    sound = {
      attach = "ui/map_on"
      detach = "ui/map_off"
    }

    children = mapBlock

    animations = mapRootAnims
    hotkeys = [
      [ "Esc", closeMapDesc],
      [ $"^{JB.B}", closeMapDesc],
      [ "@HUD.BigMap", closeMapDesc ],
    ]
  }
}

ecs.register_es("artilllery_map_ui_es",
  {
    [CmdOpenArtilleryMap] = @(...) showArtilleryMap.set(true),
    [CmdCloseArtilleryMap] = @(...) showArtilleryMap.set(false),
    [EventResetDeviceState] = @(...) showArtilleryMap.set(false)
  },
  {
    comps_rq = [
      ["human_weap__radioMode", ecs.TYPE_BOOL],
      ["squad_member__squad", ecs.TYPE_EID],
    ]
  },
  {tags = "gameClient"}
)

ecs.register_es("minimap_zoomed_es",
  {
    [EventMinimapZoomed] = @(...) currentMinimapVisibleRadius.set(minimapState.getVisibleRadius())
  },
  {
  },
  {tags = "gameClient"}
)

return {
  artilleryMap
  showArtilleryMap
}
