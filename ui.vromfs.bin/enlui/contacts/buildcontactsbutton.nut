import "%ui/components/fontIconButton.nut" as fontIconButton
from "%ui/style/colors.nut" import Active, TextActive, TextHighlight, TextDefault
from "%ui/ui_library.nut" import *

function buildContactsButton(selected = Watched(false), onClick = @() null,
    children = null, symbol = "users", enabled = Watched(true)
) {
  if (onClick == null)
    onClick = @() selected.set(!selected.get())
  return function() {
    let iconParams = selected.get() ? { fontFx = FFT_GLOW, fontFxColor = Active } : {}
    let iconColor = @(sf) selected.get() ? Active
      : sf & S_ACTIVE ? TextActive
      : sf & S_HOVER ? TextHighlight
      : TextDefault
    return {
      watch = [selected, enabled]
      size = SIZE_TO_CONTENT
      children = enabled.get()
        ? [
            fontIconButton(symbol, { onClick, fontSize = hdpx(30), iconParams, iconColor })
            { pos = [hdpx(5), 0], size = FLEX, halign = ALIGN_RIGHT, children }
          ]
        : null
    }
  }
}
return kwarg(buildContactsButton)