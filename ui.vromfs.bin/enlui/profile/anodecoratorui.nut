from "%ui/style/fontsStyle.nut" import fontBody
from "%ui/components/defcomps.nut" import txt
from "%ui/profile/decoratorPkg.nut" import PORTRAIT_SIZE, mkRatingBlock, mkPortraitIcon
from "%ui/components/decoratorsPresentation.nut" import getPortrait, frameNick
from "%ui/style/designConst.nut" import titleTxtColor, defBgColor, smallPadding
from "%ui/profile/profilePkg.nut" import borderColor
from "%ui/profile/anoProfileState.nut" import anoProfileData
from "%ui/ui_library.nut" import *

let decoratorBlock = @() {
  flow = FLOW_VERTICAL
  size = FLEX_H
  gap = smallPadding
  children = [
    {
      flow = FLOW_VERTICAL
      gap = fsh(2)
      valign = ALIGN_TOP
      children = [
        txt({
          text = frameNick(anoProfileData.get()?.player.name, anoProfileData.get()?.player.nickFrame)
          color = titleTxtColor
        }).__update(fontBody)
      ]
    }
    {
      rendObj = ROBJ_BOX
      borderWidth = hdpx(1)
      size = const [PORTRAIT_SIZE, PORTRAIT_SIZE]
      fillColor = defBgColor
      borderColor = borderColor(0)
      behavior = Behaviors.Button
      children = mkPortraitIcon(getPortrait(anoProfileData.get()?.player.portrait))
    }
  ]
}

return @(){
  size = FLEX_H
  flow = FLOW_HORIZONTAL
  children = [
    decoratorBlock()
    mkRatingBlock(Watched({
      rank = anoProfileData.get().player.rank
      rating = anoProfileData.get().player.rating
    }))
  ]
}
