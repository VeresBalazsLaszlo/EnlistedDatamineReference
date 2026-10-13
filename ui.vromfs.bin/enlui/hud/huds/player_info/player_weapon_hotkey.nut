from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/control/formatInputBinding.nut" import textListFromAction, buildElems
from "%ui/control/active_controls.nut" import isGamepad
from "%ui/components/controlHudHint.nut" import mkShortHudHintFromList
from "%ui/hud/style.nut" import DEFAULT_TEXT_COLOR
from "%ui/ui_library.nut" import *

const disabledColor = Color(128,128,128,128)

function isHotkeysEmpty(textList){
  textList = textList ?? [""]
  if (textList.len()==1 && textList?[0] == "")
    return true
  return false
}

const eventTypeToText = false
function makeControlTip(hotkey, active) {
  return function() {
    let textFunc = @(text) {
      rendObj = ROBJ_TEXT,
      color = active ? DEFAULT_TEXT_COLOR : disabledColor,
      padding = hdpx(4),
      text
    }.__update(fontSub)
    local textList = textListFromAction(hotkey, isGamepad.get() ? 1 : 0, eventTypeToText)
    if (isHotkeysEmpty(textList) && (["Human.Weapon1", "Human.Weapon2"].contains(hotkey))){
      textList = textListFromAction("Human.WeaponNextMain", isGamepad.get() ? 1 : 0, eventTypeToText)
    }
    if (isHotkeysEmpty(textList) && ["Human.Weapon1", "Human.Weapon2", "Human.Weapon3", "Human.Weapon4"].contains(hotkey))
      textList = textListFromAction("Human.WeaponNext", isGamepad.get() ? 1 : 0, eventTypeToText)
    if (isHotkeysEmpty(textList) && ["Human.Weapon1", "Human.Weapon2", "Human.Weapon3", "Human.Weapon4"].contains(hotkey))
      textList = textListFromAction("Human.WeaponPrev", isGamepad.get() ? 1 : 0, eventTypeToText)
    let controlElems = buildElems(textList, {textFunc = textFunc, compact = true})
    return mkShortHudHintFromList(controlElems)
  }
}

let weaponHotkeysActive = {}
let weaponHotkeysInactive = {}
let weaponKeys = [
  "Human.Weapon1",
  "Human.Weapon2",
  "Human.Weapon3",
  "Human.Weapon4",
  "Human.Throw",
  "Human.SpecialItemSlot",
  "Inventory.UseMedkit",
  "Human.Melee",
  "Human.WeaponNextMain",
  "Human.GrenadeNext",
  "Human.FiringMode",
  "Inventory.UseFlask",
  "Human.UseBinocular"
]

foreach (key in weaponKeys) {
  weaponHotkeysActive[key] <- makeControlTip(key, true)
  weaponHotkeysInactive[key] <- makeControlTip(key, false)
}

function getWeaponHotkeyWidget(key, active) {
  return (active ? weaponHotkeysActive : weaponHotkeysInactive)[key]
}

return getWeaponHotkeyWidget