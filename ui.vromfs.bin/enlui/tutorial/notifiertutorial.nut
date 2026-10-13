import "%ui/components/faComp.nut" as faComp
import "%ui/style/tooltipCtor.nut" as tooltipCtor
from "%ui/components/soldiersUiComps.nut" import PERK_ALERT_SIGN, ITEM_ALERT_SIGN, UPGRADE_ALERT_SIGN
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/soldiers/model/soldierPerks.nut" import notChosenPerkSquads, clearPerkNotifiersArmy
from "%ui/vehicles/unseenVehicles.nut" import unseenArmiesVehicle, markArmyVehiclesSeen
from "%ui/options/onlineSettings.nut" import settings
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/components/blinkingIcon.nut" import blinkingIcon
from "%ui/style/designConst.nut" import smallPadding, bigPadding, defTxtColor, titleTxtColor
from "%ui/soldiers/model/unseenWeaponry.nut" import markInventorySlotsSeen, armyUpgradeAlerts
from "%ui/components/textButton.nut" import soundActive
from "%ui/style/cursors.nut" import withTooltip
from "%ui/ui_library.nut" import *

const SEEN_ID = "seen/notifierTutorials"
let seenData = Computed(@() settings.get()?[SEEN_ID] ?? {})

function resetSeen() {
  if (SEEN_ID not in settings.get())
    return

  settings.mutate(@(v) v.$rawdelete(SEEN_ID))
}

enum Notifiers {
  PERK
  VEHICLE
  WEAPON
}

let notifierConfig = {
  [Notifiers.PERK] = {
    icon = PERK_ALERT_SIGN
    order = 1
    locId = "hint/perkNotifier"
    removeFn = clearPerkNotifiersArmy
  },
  [Notifiers.VEHICLE] = {
    icon = ITEM_ALERT_SIGN
    order = 2
    locId = "hint/newVehicleNotifier"
    removeFn = markArmyVehiclesSeen
  },
  [Notifiers.WEAPON] = {
    icon = UPGRADE_ALERT_SIGN
    order = 3
    locId = "hint/newWeaponNotifier"
    removeFn = markInventorySlotsSeen
  }
}

let order = @(notifierId) notifierConfig?[notifierId].order ?? -1

let needShowAlert = Computed(function() {
  let activeNotifiers = []
  if ((notChosenPerkSquads.get()?[curArmy.get()].len() ?? 0) > 0)
    activeNotifiers.append(Notifiers.PERK)
  if ((unseenArmiesVehicle.get()?[curArmy.get()] ?? 0) > 0)
    activeNotifiers.append(Notifiers.VEHICLE)
  if (armyUpgradeAlerts.get()?[curArmy.get()] ?? false)
    activeNotifiers.append(Notifiers.WEAPON)

  let seen = seenData.get()
  activeNotifiers.sort(@(a, b) a in seen <=> b in seen || order(a) <=> order(b))
  return activeNotifiers?[0]
})

let animatedParams = {
  transform = true
  animations = [
    {
      prop = AnimProp.opacity, from = 0.5, to = 1, duration = 1.5,
      play = true, loop = true, easing = Blink
    }
    {
      prop = AnimProp.opacity, from = 1, to = 1, delay = 6,
      play = true, loop = true, easing = Blink
    }
  ]
}

let disableCmp = watchElemState(@(sf) {
  behavior = Behaviors.Button
  sound = soundActive
  gap = smallPadding
  onClick = @(_) notifierConfig?[needShowAlert.get()].removeFn?(curArmy.get())
  children = withTooltip(
    faComp("times-rectangle", {
        color = sf & S_HOVER ? titleTxtColor : defTxtColor
      }),
    @() tooltipCtor({
      flow = FLOW_VERTICAL
      gap = bigPadding
      padding = bigPadding
      halign = ALIGN_LEFT
      children = [
        {
          rendObj = ROBJ_TEXT
          text = loc("btn/removeNotifiers")
        }.__update(fontSub, { color = titleTxtColor })
        {
          rendObj = ROBJ_TEXT
          text = loc("btn/removeNotifiersDetails")
        }.__update(fontSub)
      ]
    })
  )
})

function notifierHint() {
  if (needShowAlert.get() == null)
    return { watch = needShowAlert }
  let notifierId = needShowAlert.get()
  let params = notifierId not in seenData.get() ? animatedParams : {}
  let { icon, locId } = notifierConfig[notifierId]
  return {
    watch = [needShowAlert, seenData]
    halign = ALIGN_CENTER
    gap = smallPadding
    flow = FLOW_HORIZONTAL
    children = [
      {
        flow = FLOW_HORIZONTAL
        children = [
          blinkingIcon(icon).__update({ animations = null })
          {
            rendObj = ROBJ_TEXTAREA
            behavior = Behaviors.TextArea
            text = loc(locId)
          }.__update(fontSub)
        ]
      }.__update(params)
      {
        vplace = ALIGN_TOP
        children = disableCmp
      }
    ]
  }
}

console_register_command(resetSeen, "meta.resetSeenNotifiers")

return {
  notifierHint
}
