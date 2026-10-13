from "%ui/components/squadsUiComps.nut" import mkSquadCard
from "%ui/style/designConst.nut" import midPadding
from "%ui/components/scrollbar.nut" import makeVertScroll, thinStyle
from "%ui/ui_library.nut" import *

let mkSquadsList = kwarg(function(
  curSquadsList, curSquadId, setCurSquadId, addedObj = null,
  topElement = null, hasOffset = true, onDoubleClick = null
) {
    let xmbNode = XmbContainer({ wrap = false })
    return function() {
      let squadsList = (curSquadsList.get() ?? []).map(
        function(squad, idx) {
          let {squadId} = squad
          return {
            onClick = @() setCurSquadId(squadId)
            onDoubleClick
            isSelected = Computed(@() curSquadId.get() == squadId)
            idx
          }.__update(squad)
        }
      )
      let children = []
      if (squadsList.len() > 0) {
        let cardsList = {
          flow = FLOW_VERTICAL
          gap = midPadding
          children = squadsList.map(mkSquadCard)
        }
        let maxHeight = hasOffset ? null : calc_comp_size(cardsList)[1]
        children.replace([
          topElement
          makeVertScroll(cardsList, {
            size = FLEX_V
            styling = thinStyle
            maxHeight
          })
          addedObj
        ])
      }
      return {
        watch = curSquadsList
        size = FLEX_V
        flow = FLOW_VERTICAL
        gap = midPadding
        clipChildren = true
        xmbNode
        children
      }
    }
})

return mkSquadsList
