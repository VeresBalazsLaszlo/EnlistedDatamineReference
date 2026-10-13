import "%dngscripts/ecs.nut" as ecs
from "dagor.math" import Point2
from "%ui/components/itemTexReplace.nut" import getTexReplaceString, getTexSetString, getCamouflageString
from "%ui/components/itemAttachmentParams.nut" import getAttachmentParams
from "%ui/ui_library.nut" import *

const ANIMCHAR_STR = @"a{animchar:t={animchar};slot:t={slot};shading:t=same;attachType:t={attachType};
  {objTexReplaceRules}{objTexSetRules}{paintColorParam}{blendFactor}{camouflage}}"

const RENDER_STR = @"ui/photo#render{
  animchar:t={animchar};offset:p2={offsetX},{offsetY};scale:r={scale};animation:t={animation};
  brightness:r={brightness};autocrop:b=false;zenith:r={zenith};azimuth:r={azimuth};{attachments}
  w:i={width};h:i={height};shading:t=full;}.render"

let smallIconsCache = {}
let largeIconsCache = {}
function getSoldierParamsByTemplate(template, isLarge) {
  let cache = isLarge ? largeIconsCache : smallIconsCache
  if (template in cache)
    return cache[template]

  let db = ecs.g_entity_mgr.getTemplateDB()
  let sTpl = db.getTemplateByName(template)
  let offset = sTpl?.getCompValNullable("human_icon__offset") ?? Point2(0.0, -0.47)
  let res = {
    animchar = sTpl?.getCompValNullable("animchar__res")
    width = hdpxi(sTpl?.getCompValNullable(isLarge ? "human_icon__widthLarge" : "human_icon__width") ?? 128)
    height = hdpxi(sTpl?.getCompValNullable(isLarge ? "human_icon__heightLarge" : "human_icon__height") ?? 190)
    offsetX = offset.x
    offsetY = offset.y
    scale = sTpl?.getCompValNullable("human_icon__scale") ?? 2.2
    zenith = sTpl?.getCompValNullable("human_icon__zenith") ?? 65.0
    azimuth = sTpl?.getCompValNullable("human_icon__azimuth") ?? -40.0
    brightness = sTpl?.getCompValNullable("human_icon__brightness") ?? 4.0
  }

  if (db.size() > 0)
    cache[template] <- res
  return res
}

function mkSoldierPhotoName(soldierTemplate, equipment_, animation, isLarge = false) {
  
  let equipment = [].extend(equipment_).sort(@(a, b) a.slot <=> b.slot)
  animation = "enlisted_idle_01" 
  soldierTemplate = soldierTemplate ?? "usa_base_soldier"

  let attachments = [];
  let hides = {};
  foreach (equip in equipment)
    foreach (h in getAttachmentParams(equip.tpl).hides)
      hides[h] <- true

  foreach (equip in equipment) {
    let aParams = getAttachmentParams(equip.tpl)
    if (!aParams.isVisibleOnPhoto)
      continue
    if (aParams.hideFlags.findvalue(@(h) h in hides) != null)
      continue
    let paintColor = aParams?.paintColor
    let headgenReplace = aParams?.headgenTex0 && aParams?.headgenTex1 ?
      @"from:t=head_european_01_tex_d*;to:t={tex0}_d*;
      from:t=head_european_02_tex_d*;to:t={tex1}_d*;
      from:t=head_european_01_tex_n*;to:t={tex0}_n*;
      from:t=head_european_02_tex_n*;to:t={tex1}_n*;".subst({tex0 = aParams?.headgenTex0, tex1 = aParams?.headgenTex1}) : ""

    let objTexReplace = getTexReplaceString(aParams)
    let objTexSet = getTexSetString(aParams)

    let camouflage = getCamouflageString(aParams?.camouflage)

    attachments.append(ANIMCHAR_STR.subst({
      animchar = aParams.animchar
      slot = aParams.slotName ?? equip.slot
      attachType = aParams.needAttach ? "skeleton" : "slot"
      objTexReplaceRules = "objTexReplaceRules{{0} r1{{1}}}".subst(objTexReplace, headgenReplace)
      objTexSetRules = "objTexSetRules{{0}} ".subst(objTexSet)
      paintColorParam = paintColor ? $"paintColor:p4={paintColor.x}, {paintColor.y}, {paintColor.z}, {paintColor.w};" : ""
      blendFactor = aParams?.blendFactor ? $"blendfactor:r={aParams?.blendFactor}" : ""
      camouflage = camouflage ? "camouflage_override{{0}}".subst(camouflage) : ""
    }))
  }

  let tplParams = getSoldierParamsByTemplate(soldierTemplate, isLarge)
  let tbl = tplParams.__merge({
    attachments = attachments.len() > 0 ? "attachments{{0}}".subst("".join(attachments)) : "",
    animation
  })
  return RENDER_STR.subst(tbl)
}

function mkSoldierPhoto(photoName, size, inner = null, style = {}) {
  if (photoName == null)
    return {
      size
      rendObj = ROBJ_IMAGE
      image = Picture("ui/soldiers/soldier_default.avif")
      clipChildren = true
      children = inner
    }.__update(style)

  return {
    children = {
        size
        rendObj = ROBJ_IMAGE
        image = Picture(photoName)
        clipChildren = true
        children = inner
      }.__update(style)
  }
}

return {
  mkSoldierPhotoName
  mkSoldierPhoto
}
