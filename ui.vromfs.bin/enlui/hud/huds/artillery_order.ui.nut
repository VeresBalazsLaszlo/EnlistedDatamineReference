import "%dngscripts/ecs.nut" as ecs
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/style.nut" import HUD_TIPS_FAIL_TEXT_COLOR
from "%ui/helpers/time.nut" import secondsToStringLoc
from "%ui/hud/state/artillery.nut" import artilleryIsAvailable, artilleryAvailableTimeLeft, artilleryIsReady, artilleryIsAvailableByLimit
from "%ui/components/controlHudHint.nut" import mkHasBinding
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "dasevents" import CmdShowArtilleryCooldownHint
from "%ui/ui_library.nut" import *

let { playerEvents } = require("%ui/hud/state/eventlog.nut")

const gap = hdpx(5)

function show_artillery_cooldown_hint(){
  let timeLeft = artilleryAvailableTimeLeft.get()
  if (timeLeft <= 0)
    return
  let timeLeftStr = secondsToStringLoc(timeLeft)
  playerEvents.pushEvent({
    text = loc("artillery/cooldown", {timeLeft = timeLeftStr})
    color = HUD_TIPS_FAIL_TEXT_COLOR
  })
}

const artilleryHotkey = "Human.ArtilleryStrike"
let hasArtilleryBinding = mkHasBinding(artilleryHotkey)
function artilleryOrder() {
  let hint = tipCmp({
    text = Computed(@() !artilleryIsAvailableByLimit.get() ? loc("artillery/already_active")
      : artilleryAvailableTimeLeft.get() > 0
        ? loc("artillery/cooldown", { timeLeft = secondsToStringLoc(artilleryAvailableTimeLeft.get()) })
      : loc("squad_orders/artillery_strike"))
    inputId = hasArtilleryBinding.get() ? artilleryHotkey : "HUD.CommandsMenu"
    style = fontSub
  })
  return {
    watch = hasArtilleryBinding
    children = hint
  }
}

let artilleryIconHgt = calc_comp_size(artilleryOrder)[1].tointeger()
let artilleryIcon = Picture("ui/skin#radio.svg:{0}:{0}".subst(artilleryIconHgt))

let artilleryIconComp = @() !artilleryIsReady.get()
  ? { watch = artilleryIsReady }
  : {
      watch = artilleryIsReady
      rendObj = ROBJ_IMAGE
      size = [artilleryIconHgt, artilleryIconHgt]
      image = artilleryIcon
    }

function artillery() {
  let watch = artilleryIsAvailable
  if (!artilleryIsAvailable.get())
    return { watch }

  return {
    watch
    flow = FLOW_HORIZONTAL
    gap
    valign = ALIGN_CENTER
    children = [
      artilleryOrder
      artilleryIconComp
    ]
  }
}

ecs.register_es("artillery_hero_show_cooldown_hint_es",
  {
    [CmdShowArtilleryCooldownHint] = @(_evt, _eid, _comp) show_artillery_cooldown_hint()
  },
  { comps_rq = ["player"] },
  { tags="gameClient" }
)

return artillery
