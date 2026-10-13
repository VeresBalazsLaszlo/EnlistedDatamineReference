import "%ui/state/extAutoRefreshTimer.nut" as extAutoRefreshTimer
from "%ui/meta/clientApi.nut" import check_purchases
from "%ui/ui_library.nut" import *

const AUTO_REFRESH_DELAY = 30.0 
const CHECK_PURCHASED_PERIOD = 10.0 
const MAX_PURCHASES_CHECK = 6 

let refreshOnWindowActivate = extAutoRefreshTimer(check_purchases, AUTO_REFRESH_DELAY)

let itemsRefresh = @() refreshOnWindowActivate(MAX_PURCHASES_CHECK, CHECK_PURCHASED_PERIOD)

return itemsRefresh