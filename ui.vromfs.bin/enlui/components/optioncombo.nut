from "%ui/ui_library.nut" import *


let combobox = require("%ui/components/combobox.nut")

function optionCombo(opt, _group, xmbNode) {
  local ItemWrapper = class{
    item = null
    constructor(item_)   { this.item = item_ }
    function _tostring() { return opt.valToString(this.item) }
    function isCurrent() { return opt.isEqual(this.item, opt.var.get())}
    function value()     { return this.item }
  }
  let { available } = opt
  let items = isObservable(available)
    ? Computed(@() available.get().map(@(v) ItemWrapper(v)))
    : available.map(@(v) ItemWrapper(v))

  return opt?.setValue
    ? combobox({ value = opt.var, update = opt.setValue, changeVarOnListUpdate = opt?.changeVarOnListUpdate ?? true },
               items,
               {useHotkeys = true, xmbNode})
    : combobox({ value = opt.var, _tostring = @() opt.valToString(opt.var.get()), changeVarOnListUpdate = opt?.changeVarOnListUpdate ?? true },
               items,
               {useHotkeys = true, xmbNode})
}


return optionCombo
