options no_aot
require ecs
require DagorConsole
require game.es.lut_switcher_common
require DagorSystem

[console_cmd(name="color_grading.enable")]
def enable_color_grading_cmd(uid : string; component : string)
  query() <| $ [es] (eid : EntityId; var color_grading_items : Array)
    if !has(eid, component, ecs_hash(component))
      console_print("No component '{component}' for color grading exists in ({eid})<{getEntityTemplateName(eid)}>")
      return
    let colorGrading = get_ecs_object(eid, component, ecs_hash(component))
    remove_grading(ecs_hash(uid), color_grading_items)
    switch_color_grading(ecs_hash(uid), color_grading_items, *colorGrading, true)

[console_cmd(name="color_grading.disable")]
def disable_color_grading_cmd(uid : string)
  query() <| $ [es] (var color_grading_items : Array)
    remove_grading(ecs_hash(uid), color_grading_items)
