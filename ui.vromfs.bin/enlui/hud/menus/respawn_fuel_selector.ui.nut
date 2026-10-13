import "%dngscripts/ecs.nut" as ecs
from "%ui/style/designConst.nut" import commonBorderRadius, midPadding, defTxtColor, selectedTxtColor, activeTxtColor, disabledTxtColor
from "%ui/style/fontsStyle.nut" import fontSub
from "%ui/hud/state/respawnState.nut" import curVehicle, fuelLoadPct
from "%ui/ui_library.nut" import *

const FUEL_STEPS = [30, 50, 100]
const lastFuelStep = FUEL_STEPS.len() - 1

const btnSelectorSize = [flex(), hdpxi(24)]
const btnStyleSelected = {
  borderRadius = commonBorderRadius
  fillColor = activeTxtColor
}
const btnStyleHovered = {
  borderRadius = commonBorderRadius
  borderWidth = hdpx(2)
  borderColor = activeTxtColor
}
const btnStyleNormal = {
  borderRadius = commonBorderRadius
  borderWidth = hdpx(2)
  borderColor = disabledTxtColor
}

let DB = ecs.g_entity_mgr.getTemplateDB()

let isAircraftSquad = Computed(function() {
  let vehicle = curVehicle.get()
  if (vehicle == null)
    return false
  return DB.getTemplateByName(vehicle?.gametemplate)?.getCompValNullable("airplane") != null
})

let curFuelIndex = Watched(-1)

function setFuelIndex(idx) {
  let nextIdx = clamp(idx, 0, lastFuelStep)
  curFuelIndex.set(nextIdx)
  fuelLoadPct.set(FUEL_STEPS[nextIdx])
}
setFuelIndex(lastFuelStep)

let cycleFuel = @(dir) setFuelIndex(curFuelIndex.get() + dir)

let fuelLoadLabel = {
  rendObj = ROBJ_TEXT
  text = loc("respawn/fuel_label")
  color = defTxtColor
}.__update(fontSub)

let btnTextColor = @(isSelected, isHovered) isSelected ? selectedTxtColor
  : isHovered ? activeTxtColor
  : defTxtColor

function mkFuelButton(val, idx) {
  let isSelected = Computed(@() curFuelIndex.get() == idx)
  let onClick = @() setFuelIndex(idx)
  let textComp = {
    rendObj = ROBJ_TEXT
    text = $"{val}%"
  }.__update(fontSub)
  return watchElemState(@(sf) {
    watch = isSelected
    rendObj = ROBJ_BOX
    size = btnSelectorSize
    behavior = Behaviors.Button
    onClick
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = textComp.__merge({ color = btnTextColor(isSelected.get(), sf & S_HOVER) })
  }.__update(isSelected.get() ? btnStyleSelected
    : sf & S_HOVER ? btnStyleHovered
    : btnStyleNormal))
}

function fuelSelector() {
  let watch = isAircraftSquad
  if (!isAircraftSquad.get())
    return { watch }

  return {
    watch
    size = FLEX_H
    flow = FLOW_HORIZONTAL
    gap = midPadding
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    children = [ fuelLoadLabel ].extend(FUEL_STEPS.map(mkFuelButton))

    hotkeys = [
      ["^J:LB", { action = @() cycleFuel(-1), description = loc("respawn/fuel_less") }],
      ["^J:RB", { action = @() cycleFuel(1), description = loc("respawn/fuel_more") }]
    ]
  }
}

return fuelSelector
