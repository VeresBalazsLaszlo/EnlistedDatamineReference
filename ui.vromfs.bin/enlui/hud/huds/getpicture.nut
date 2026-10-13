from "%ui/ui_library.nut" import *


let getPicture = memoize(function getPicture(name, iconSz) {
  if ((name ?? "") == "")
    return null

  let imagename = name.endswith(".svg")
    ? "{0}:{1}:{1}".subst(name, iconSz.tointeger())
    : name

  return Picture(imagename)
})

return getPicture
