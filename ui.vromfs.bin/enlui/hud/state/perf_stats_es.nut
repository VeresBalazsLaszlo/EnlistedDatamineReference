import "%dngscripts/ecs.nut" as ecs
from "ecs.computed" import mkEcsComputed

let warningsCompsTrack = [
  ["ui_perf_stats__server_tick_warn", 0],
  ["ui_perf_stats__low_fps_warn", 0],
  ["ui_perf_stats__latency_warn", 0],
  ["ui_perf_stats__latency_variation_warn", 0],
  ["ui_perf_stats__packet_loss_warn", 0],
  ["ui_perf_stats__low_tickrate_warn", 0],
]


let warnings = mkEcsComputed({
  comps = warningsCompsTrack.map(@(v) [v[0], ecs.TYPE_INT])
  defVal = warningsCompsTrack.totable()
})

return {
  warnings
}
