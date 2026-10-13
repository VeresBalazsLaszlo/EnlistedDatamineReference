options no_aot
require ecs
require ecs.safe
require ecs.ecs_template
require AnimV20
require DagorDebug3D
require GeomNodeTree
require DagorConsole
require danetlibs.render_debug.render.draw_debug_common


[ecs_template]
struct vehicle_effectors_debug_draw
  vehicleEffectorsDebug : Tag

[console_cmd(name="effectors.show_vehicle_nodes", hint="Show vehicle and cockpit IK effector nodes")]
def vehicle_effectors_debug_cmd()
  let exist = find_query() <| $ [es(REQUIRE=vehicleEffectorsDebug)] (eid : EntityId)
    destroyEntity(eid)
    return true
  if !exist
    createEntity("vehicle_effectors_debug_draw")
  console_print("vehicle effectors debug {exist ? "disabled" : "enabled"}")

[es(no_order, REQUIRE=vehicleEffectorsDebug)]
def draw_vehicle_and_cockpit_effectors(info : UpdateStageInfoRenderDebug)
  query() <| $ [es] (animchar : AnimcharBaseComponent;
                     cockpit__effectors : Object)
    for field in cockpit__effectors
      let effectorName = field.key
      let effectorIndex = cockpit__effectors[effectorName] ?? -1
      if effectorIndex < 0
        return

      var wtm : float3x4
      geomtree_getNodeWtmScalar(*animchar.nodeTree, effectorIndex, wtm)
      begin_draw_cached_debug_lines(false, false, false)
      draw_cached_gizmo(wtm, 0.1, 0.05)
      add_debug_text_mark(wtm[3], field.key, -1, 3.5f, E3DCOLOR(0x00000000))
      end_draw_cached_debug_lines()

  query() <| $ [es] (animchar : AnimcharBaseComponent;
                     vehicle_seats__effectors : Array;
                     vehicle_seats__seatEids : EidList)
    if vehicle_seats__effectors.empty
      return

    for seatOwnerNo in iter_range(vehicle_seats__seatEids)
      let effectors = get_ecs_object(vehicle_seats__effectors[seatOwnerNo])
      if effectors == null
        continue
      for field in *effectors
        let effectorName = field.key
        let effectorIndex = *get_int(*effectors, effectorName)

        var wtm : float3x4
        geomtree_getNodeWtmScalar(*animchar.nodeTree, effectorIndex, wtm)
        begin_draw_cached_debug_lines(false, false, false)
        draw_cached_gizmo(wtm, 0.1, 0.05)
        add_debug_text_mark(wtm[3], field.key, -1, 3.5f, E3DCOLOR(0x00000000))
        end_draw_cached_debug_lines()
