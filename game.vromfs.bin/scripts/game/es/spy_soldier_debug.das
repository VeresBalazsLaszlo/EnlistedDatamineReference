options no_aot
require ecs
require game.es.net_console_macro

[net_console_cmd(name="spy_detection_off")]
def spy_detection_off()
  query() <| $ [es] (var spy_soldier__detected : bool&)
    spy_soldier__detected = false