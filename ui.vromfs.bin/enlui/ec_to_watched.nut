from "%ui/scene_update.nut" import frameUpdateCounter
from "%sqstd/frp.nut" import mkLatestByTriggerStream, mkTriggerableLatestWatchedSetAndStorage, MK_COMBINED_STATE
from "%enlSqGlob/library_logs.nut" import *

let mkWatchedSetAndStorage = mkTriggerableLatestWatchedSetAndStorage(frameUpdateCounter)
let mkFrameIncrementObservable = mkLatestByTriggerStream(frameUpdateCounter)

return {
  mkWatchedSetAndStorage
  mkFrameIncrementObservable
  MK_COMBINED_STATE
}