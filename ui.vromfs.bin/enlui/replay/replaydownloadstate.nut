from "%ui/ui_library.nut" import *

const REPLAY_DOWNLOAD_NONE = 0
const REPLAY_DOWNLOAD_PROGRESS = 1
const REPLAY_DOWNLOAD_FAILED = 2
const REPLAY_DOWNLOAD_SUCCESS = 3

let replayDownload = Watched({
  state = REPLAY_DOWNLOAD_NONE
  stateText  = ""
  filename = ""
  downloadRequestId = ""
  contentLen = -1
})

return {
  REPLAY_DOWNLOAD_NONE
  REPLAY_DOWNLOAD_PROGRESS
  REPLAY_DOWNLOAD_FAILED
  REPLAY_DOWNLOAD_SUCCESS
  replayDownload
}