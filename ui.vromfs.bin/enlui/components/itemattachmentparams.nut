import "%dngscripts/ecs.nut" as ecs
from "%ui/ui_library.nut" import *

let attachCache = {}
function getAttachmentParams(template) {
  if (template in attachCache)
    return attachCache[template]

  let db = ecs.g_entity_mgr.getTemplateDB()
  let tpl = db.getTemplateByName(template)

  let res = {
    isVisibleOnPhoto     = tpl != null && (tpl.getCompValNullable("isVisibleOnPhoto") ?? true)
    hideFlags            = tpl?.getCompValNullable("hideFlags").getAll() ?? []
    hides                = tpl?.getCompValNullable("hides").getAll() ?? []
    animchar             = tpl?.getCompValNullable("animchar__res")
    slotName             = tpl?.getCompValNullable("slot_attach__slotName")
    needAttach   = tpl?.hasComponent("skeleton_attach__attached") ?? false
    paintColor = tpl?.getCompValNullable("paintColor")
    headgenTex0 = tpl?.getCompValNullable("headgen__tex0")
    headgenTex1 = tpl?.getCompValNullable("headgen__tex1")
    blendFactor = tpl?.getCompValNullable("headgen__blendFactor")
    objTexReplace = [tpl?.getCompValNullable("animchar__objTexReplace")?.getAll() ?? {}]
    objTexSet = [tpl?.getCompValNullable("animchar__objTexSet")?.getAll() ?? {}]
    camouflage = tpl?.getCompValNullable("camouflage_override").getAll() ?? []
  }

  if (db.size() > 0)
    attachCache[template] <- res
  return res
}

return {
  getAttachmentParams
}
