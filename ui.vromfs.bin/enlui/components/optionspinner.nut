import "%ui/components/spinnerList.nut" as spinnerList
from "%ui/ui_library.nut" import *

let locOn = loc($"option/on")
let locOff = loc($"option/off")
function optionSpinner(opt, group, xmbNode) {
  let stateFlags = Watched(0)
  let available = isObservable(opt?.available)
    ? opt.available
    : Watched(opt?.available)
  let spinnerElem = @(){
    size = FLEX
    watch = available
    children = spinnerList({
      isEqual = opt?.isEqual
      setValue = opt?.setValue
      curValue = opt.var
      valToString = opt?.valToString ?? @(val) val ? locOn : locOff
      allValues = available.get()
      xmbNode
      group
      stateFlags
    })
  }
  return spinnerElem
}

return optionSpinner