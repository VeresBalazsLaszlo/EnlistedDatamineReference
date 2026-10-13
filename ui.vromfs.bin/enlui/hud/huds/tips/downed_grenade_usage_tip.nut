from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/state/controlled_hero.nut" import controlledHeroEid
from "%ui/hud/state/health_state.nut" import isDowned
from "%ui/hud/state/hero_weapons.nut" import hasAnyGrenade
from "%ui/hud/huds/tips/tipComponent.nut" import tipCmp
from "%ui/control/formatInputBinding.nut" import mkHasBinding
from "%ui/ui_library.nut" import *

const color0 = Color(200,40,40,110)
const color1 = Color(200,200,40,180)

let hasGrenadeBind = mkHasBinding("Human.ThrowDowned")

let needShowGrenadeTip = Computed(@() isDowned.get() && controlledHeroEid.get()
  && hasGrenadeBind.get() && hasAnyGrenade.get())

let tipDefaults = {
  textColor = Color(200,40,40,110)
  transform = {pivot=[0,0.5]}
  animations = [{prop=AnimProp.translate, from=[sw(50),0], to=[0,0],
    duration=0.5, play=true, easing=InBack}]
  textAnims = [
    {prop=AnimProp.color, from=color0, to=color1, duration=1.0,
      play=true, loop=true, easing=CosineFull}
    {prop=AnimProp.scale, from=[1,1], to=[1.0, 1.1], duration=3.0,
      play=true, loop=true, easing=CosineFull}
  ]
  style = fontSub
}

let grenadeUsageTip = tipCmp(tipDefaults.__merge({
  text = loc("tips/useGrenade")
  inputId = "Human.ThrowDowned"
}))


let downed_grenade_usage_tip = @() {
  watch = needShowGrenadeTip
  children = needShowGrenadeTip.get() ? grenadeUsageTip : null
}

return downed_grenade_usage_tip