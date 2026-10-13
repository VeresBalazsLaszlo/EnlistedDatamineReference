require ecs
require DngPlane

[es(tag=gameClient, on_appear, REQUIRE=vehicleWithWatched)]
def plane_init_flaps_indices_es(evt : Event;
                                plane_net_phys : PlaneActor;
                                var plane__currFlapsPosIndex : int&;
                                var plane__flapsIndices : IntList&)
  assume phys = plane_net_phys.phys
  if !phys.props.bHasFlapsControl
    return

  plane__flapsIndices |> clear()
  var flapsIndex = 0
  for flapsAxis in phys.props.flapsAxisPositions
    if flapsAxis.presents
      plane__flapsIndices |> push(flapsIndex)
    ++flapsIndex

  for i in iter_range(plane__flapsIndices)
    if phys.input.FlapsControl >= phys.props.flapsAxisPositions[plane__flapsIndices[i]].flaps - 0.05f
      plane__currFlapsPosIndex = i
      break

[es(tag=gameClient, no_order, REQUIRE_NOT=plane_input, REQUIRE=vehicleWithWatched)]
def plane_update_flaps_for_spectator_es(info : UpdateStageInfoAct;
                                        plane__flapsIndices : IntList;
                                        plane_net_phys : PlaneActor;
                                        var flaps_position : int&;
                                        plane__flapsPositionChangePercent : float = 0.5)
  assume phys = plane_net_phys.phys
  flaps_position = 0
  for i in range(length(plane__flapsIndices) - 1)
    let flapIndexLeft = plane__flapsIndices[i]
    let flapIndexRight = plane__flapsIndices[i + 1]
    let leftFlaps = phys.props.flapsAxisPositions[flapIndexLeft].flaps
    let rightFlaps = phys.props.flapsAxisPositions[flapIndexRight].flaps
    if phys.appliedCT.flaps >= leftFlaps && phys.appliedCT.flaps <= rightFlaps
      let flapsProgressPercent = (phys.appliedCT.flaps - leftFlaps) / (rightFlaps - leftFlaps)
      flaps_position = flapsProgressPercent >= plane__flapsPositionChangePercent ? flapIndexRight : flapIndexLeft
      break
