import "%ui/helpers/texNameConvertor.nut" as texNameConvertor
import "%ui/hud/components/wallposter_menu_item_ctor.nut" as mkPieItemCtor
import "%dngscripts/ecs.nut" as ecs
from "%ui/hud/state/pie_menu_state.nut" import pieMenuItems
from "%ui/hud/state/wallposter.nut" import wallPosters
from "%ui/hud/state/local_player.nut" import localPlayerEid
from "dasevents" import CmdWallposterPreview
from "%ui/ui_library.nut" import *

let wallPosterPreview = @(index)
  ecs.g_entity_mgr.sendEvent(localPlayerEid.get(), CmdWallposterPreview({enable=true, wallPosterId=index}))

wallPosters.subscribe(function(posters) {
  pieMenuItems.mutate(@(arr) arr[0] = posters.map(function(poster, index) {
    let template = ecs.g_entity_mgr.getTemplateDB().getTemplateByName(poster)
    let text = template?.getCompValNullable?("wallposter_menu__text") ?? ""
    local imageName = template?.getCompValNullable?("wallposter_menu__image")
    if (imageName != null)
      imageName = texNameConvertor(imageName)
    let hintText = loc(text)
    return {
      action = @() wallPosterPreview(index)
      text = hintText
      ctor = mkPieItemCtor(index, imageName, hintText)
    }
  }))
})
