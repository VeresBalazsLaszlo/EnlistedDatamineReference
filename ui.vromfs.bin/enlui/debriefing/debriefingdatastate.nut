from "%ui/debriefing/debriefingDbgState.nut" import dbgData, dbgShow
from "%ui/debriefing/debriefingState.nut" import debriefingData
from "%ui/ui_library.nut" import *

let dataToShow = Computed(@() dbgShow.get() ? dbgData.get() : debriefingData.get())

return {
  dataToShow
}
