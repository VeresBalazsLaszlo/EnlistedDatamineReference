import "%enlSqGlob/is_teams_friendly.nut" as is_teams_friendly
import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/local_player.nut" import localPlayerTeam
from "%ui/ui_library.nut" import *

let usefulBoxHintFull = Watched(null)
let usefulBoxHintCost = Watched(null)
let usefulBoxHintEmpty = Watched(null)
let isUsefulBoxEmpty = Watched(false)
let usefulBoxPrice = Watched(0)
let selectedUsefulBox = Watched(ecs.INVALID_ENTITY_ID)

let usefulBoxQuery = ecs.SqQuery("usefulBoxQuery", {
  comps_ro = [
    ["useful_box__hintEmpty", ecs.TYPE_STRING],
    ["useful_box__hintFull", ecs.TYPE_STRING],
    ["useful_box__hintCost", ecs.TYPE_STRING],
    ["useful_box__useCount", ecs.TYPE_INT],
    ["useful_box__anyTeam", ecs.TYPE_TAG, null],
    ["team", ecs.TYPE_INT],
    ["useful_box__uiPrice", ecs.TYPE_INT, 0]
  ]
})

ecs.register_es("ui_useful_box_hint_es",
  {
    [["onChange", "onInit"]] = function (_eid, comp) {
      let selectedObject = comp["human_use_object__selectedObject"]
      local hintFull = null
      local hintEmpty = null
      local hintCost = null
      local isBoxEmpty = false
      local usefulBox = ecs.INVALID_ENTITY_ID
      local price = 0
      usefulBoxQuery(selectedObject, function(eid, boxComp) {
        if (!boxComp.useful_box__anyTeam && !is_teams_friendly(localPlayerTeam.get(), boxComp.team))
          return

        usefulBox = eid
        hintFull = boxComp["useful_box__hintFull"]
        hintEmpty = boxComp["useful_box__hintEmpty"]
        hintCost = boxComp["useful_box__hintCost"]
        isBoxEmpty = (boxComp["useful_box__useCount"] == 0)
        price = boxComp["useful_box__uiPrice"]
      })
      usefulBoxHintFull.set(hintFull)
      usefulBoxHintEmpty.set(hintEmpty)
      usefulBoxHintCost.set(hintCost)
      isUsefulBoxEmpty.set(isBoxEmpty)
      selectedUsefulBox.set(usefulBox)
      usefulBoxPrice.set(price)
    },
  },
  {
    comps_track = [["human_use_object__selectedObject", ecs.TYPE_EID]],
    comps_rq = ["hero"]
  },
  { before="ui_useful_box_ammo_count_changed_es" }
)

ecs.register_es("ui_useful_box_ammo_count_changed_es",
  {
    [["onChange", "onInit"]] = function (eid, comp) {
      if (selectedUsefulBox.get() == eid) {
        isUsefulBoxEmpty.set(comp["useful_box__useCount"] == 0)
        usefulBoxPrice.set(comp["useful_box__uiPrice"])
      }
    },
  },
  {
    comps_track = [
      ["useful_box__useCount", ecs.TYPE_INT],
      ["useful_box__uiPrice", ecs.TYPE_INT, 0]
    ]
  }
)

return {
  usefulBoxHintFull
  usefulBoxHintEmpty
  usefulBoxHintCost
  isUsefulBoxEmpty
  usefulBoxPrice
}