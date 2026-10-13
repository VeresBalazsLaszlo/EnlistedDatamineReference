require ecs
require enlisted.events_enlisted


[es(REQUIRE=watchedByPlr)]
def ui_vehicle_state_update(info : ParallelUpdateFrameDelayed;
                            useActionEid : EntityId;
                            var actionsState__isPlayerCanEnter : bool&;
                            var actionsState__isPlayerCanExit : bool&;
                            var actionsState__isSafeToExit : bool&;
                            var actionsState__isHighSpeedWarningEnabled : bool&)

  query(useActionEid) <| $ [es] (vehicle__isPlayerCanEnter : bool = true;
                                 vehicle__isPlayerCanExit : bool = true;
                                 plane_view__tas : float = 0.f;
                                 vehicle__isHighSpeedWarningEnabled : bool = false)
    actionsState__isPlayerCanEnter = vehicle__isPlayerCanEnter
    actionsState__isPlayerCanExit = vehicle__isPlayerCanExit
    actionsState__isSafeToExit = plane_view__tas < 1.0
    actionsState__isHighSpeedWarningEnabled = vehicle__isHighSpeedWarningEnabled
