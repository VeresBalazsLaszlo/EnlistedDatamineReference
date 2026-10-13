from "%ui/state/appState.nut" import levelIsLoading, dbgLoading
from "%ui/ui_library.nut" import *

let enlisted_loading = require("%ui/loading/enlisted_loading.nut")

let showLoading = Computed(@() levelIsLoading.get() || dbgLoading.get())
let loadingUI = @() {
  watch = showLoading
  size = FLEX
  children = showLoading.get() ? enlisted_loading : null
}

return {loadingUI, showLoading}
