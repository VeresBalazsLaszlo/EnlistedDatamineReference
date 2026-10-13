import "%ui/soldiers/model/armyEffects.nut" as armyEffects
from "%ui/soldiers/model/state.nut" import curArmy
from "%ui/ui_library.nut" import *

let maxTrainByClass = Computed(@() armyEffects.get()?[curArmy.get()].class_training ?? {})

return {
  maxTrainByClass
}
