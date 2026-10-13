import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/pie_menu_state.nut" import pieMenuLayer, showPieMenu
from "%ui/hud/state/wallposters_use_state.nut" import canUseWallposter
from "%ui/components/uiHotkeysHint.nut" import mkHotkey
from "dasevents" import CmdWallposterPreview, RequestArtillery
from "%dngscripts/common_queries.nut" import get_controlled_hero
from "%ui/hud/state/wallposter.nut" import wallPostersMaxCount, wallPostersCurCount, wallPosters
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/style/colors.nut" import TextActive
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/hud/state/health_state.nut" import isDowned
from "%ui/hud/state/artillery.nut" import artilleryIsReady, artilleryIsAvailable, isHeroRadioman
from "%ui/hud/state/squad_members.nut" import localPlayerSquadMembers
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/hud/menus/artillery_menu.nut" import artilleryMenuAvaialable
from "%ui/ui_library.nut" import *

let hasActive = Computed(@() localPlayerSquadMembers.get()
  .findvalue(@(m) m.eid != controlledHeroEid.get() && m.isAlive) != null)

let canRequestArtillery = Computed(@() !isDowned.get()
  && artilleryIsReady.get() && artilleryIsAvailable.get()
  && (isHeroRadioman.get() || hasActive.get()))

let noWallposterAvailable = Computed(@() !canUseWallposter.get()
  || wallPostersMaxCount.get() == 0
  || wallPostersCurCount.get() >= wallPostersMaxCount.get())

function wallposterNavClick() {
  if (pieMenuLayer.get() == 0) {
    pieMenuLayer.set(1)
    return
  }
  if (noWallposterAvailable.get())
    return

  if (wallPosters.get().len() == 1) {
    ecs.g_entity_mgr.sendEvent(
      localPlayerEid.get(), CmdWallposterPreview({enable=true, wallPosterId=0}))
    showPieMenu.set(false)
  }
  else
    pieMenuLayer.set(0)
}

let wallposterNavText = Computed(@() pieMenuLayer.get() == 0 ? loc("piemenu/squad_commands")
  : !canUseWallposter.get() ? loc("wallposter/cant_use")
  : wallPostersMaxCount.get() == 0
    || wallPostersCurCount.get() >= wallPostersMaxCount.get() ? loc("wallposter/nomore")
  : wallPostersMaxCount.get() == 1 ? loc("wallposter/place")
  : loc("piemenu/wallposters"))


let wallposterNavigationHint = [
  mkHotkey("J:X | Q", wallposterNavClick)
  @() {
    rendObj = ROBJ_TEXT
    watch = wallposterNavText
    text = wallposterNavText.get()
    color = TextActive
  }.__update(fontBody)
]


let quickchatNavClick = @() pieMenuLayer.modify(@(v) v == 2 ? 1 : 2)

let quickchatNavigationHint = [
  mkHotkey("J:Y | E", quickchatNavClick)
  @() {
    rendObj = ROBJ_TEXT
    watch = pieMenuLayer
    text = pieMenuLayer.get() == 2 ? loc("piemenu/squad_commands") : loc("piemenu/quick_chat")
    color = TextActive
  }.__update(fontBody)
]


let artilleryNavText = Computed(function(){
  if (pieMenuLayer.get() == 3)
    return loc("piemenu/squad_commands")
  if (canRequestArtillery.get())
    return loc("squad_orders/artillery_strike")
  return loc("squad_orders/artillery_strike_unavailable")
})

function artilleryNavClick() {
  if (pieMenuLayer.get() == 3) {
    pieMenuLayer.set(1)
    return
  }
  if (canRequestArtillery.get())
    if (artilleryMenuAvaialable.get())
      pieMenuLayer.set(3)
    else{
      showPieMenu.set(false)
      ecs.g_entity_mgr.sendEvent(get_controlled_hero(), RequestArtillery())
    }
}

let artilleryNavigationHint = [
  mkHotkey("J:A | Z", artilleryNavClick)
  @() {
    rendObj = ROBJ_TEXT
    watch = artilleryNavText
    text = artilleryNavText.get()
    color = TextActive
  }.__update(fontBody)
]

let mkPieMenuNavigationTip = @(action, children, isInactive = Watched(false)) watchElemState(@(sf) {
  watch = [isInactive, isGamepad]
  behavior = isGamepad.get() ? null : Behaviors.Button
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(6)
  padding = const [hdpx(3), hdpx(9)]
  color = (sf & S_HOVER) && !isInactive.get() ? Color(220,220,220) : Color(240,240,240)
  onClick = action
  stopMouse = true
  children
})


let pieMenuNavigation = @(){
  pos = const [0, hdpx(100)]
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  watch = [isHeroRadioman, hasActive]
  children = [
    mkPieMenuNavigationTip(wallposterNavClick, wallposterNavigationHint, noWallposterAvailable),
    mkPieMenuNavigationTip(quickchatNavClick, quickchatNavigationHint),
    (isHeroRadioman.get() || hasActive.get()) ? mkPieMenuNavigationTip(artilleryNavClick, artilleryNavigationHint, canRequestArtillery) : null
  ]
}

return {
  pieMenuNavigation
}