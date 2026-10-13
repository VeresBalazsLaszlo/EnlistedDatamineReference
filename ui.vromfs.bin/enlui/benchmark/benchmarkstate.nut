from "%dngscripts/globalState.nut" import nestWatched
from "eventbus" import eventbus_subscribe

let gameLauncher = require("%ui/gameLauncher.nut")

let selectedBenchmark = nestWatched("selectedBenchmark", null)
let selectedBenchmarkUpdate = @(v) selectedBenchmark.set(v)
let isBenchmarksListOpened = nestWatched("isBenchmarksListOpened", false)
let isBenchmarksListOpenedUpdate = @(v) isBenchmarksListOpened.set(v)
let benchmarkResult = nestWatched("benchmarkResult", null)

function launchBenchmark(scene) {
  benchmarkResult.set(null)
  selectedBenchmarkUpdate(scene)
  gameLauncher.startGame({
    game = "enlisted",
    scene = scene.path
  })
}

eventbus_subscribe("benchmark.result", function(result) {
  benchmarkResult.set(result.__merge({ location = selectedBenchmark.get().name }))
})

return {
  launchBenchmark
  benchmarkResult
  isBenchmarksListOpened
  openBenchmarksList = @() isBenchmarksListOpenedUpdate(true)
  closeBenchmarksList = @() isBenchmarksListOpenedUpdate(false)
}
