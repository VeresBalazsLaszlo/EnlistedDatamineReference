from "%sqstd/math.nut" import splitThousands
from "%ui/ui_library.nut" import *
from "types" import Integer

let separator = loc("amount/separator")

function abbreviateAmount(amount) {
  if (!(amount instanceof Integer))
    return amount

  if (amount >= 100_000_000)
    return loc("amount/short/m", { number = splitThousands(amount / 1_000_000, separator) })
  else if (amount >= 100_000)
    return loc("amount/short/k", { number = splitThousands(amount / 1_000, separator) })
  else
    return splitThousands(amount, separator)
}

return {
    abbreviateAmount
}
