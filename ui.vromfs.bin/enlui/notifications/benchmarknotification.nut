from "%ui/components/wndManager.nut" import registerWnd, Wnd
from "%ui/components/wndPermissionFlags.nut" import canShowWindows, autoClose
from "%sqstd/timers.nut" import debounce
from "%ui/benchmark/benchmarkWnd.nut" import gpuBenchmarkWnd, benchmarkWindowSeen
from "%dngscripts/platform.nut" import is_pc
from "%ui/ui_library.nut" import *

let needShowBenchmarkWindow = registerWnd({
  dataWatch = Computed(@() is_pc && !benchmarkWindowSeen.get())
  showWatch = canShowWindows
  closeWatch = autoClose
  name = Wnd.BENCHMARK
})

let openBenchmarkWindowDelayed = debounce(function(v) {
  if (v)
    gpuBenchmarkWnd()
}, 0.01)

needShowBenchmarkWindow.subscribe(openBenchmarkWindowDelayed)