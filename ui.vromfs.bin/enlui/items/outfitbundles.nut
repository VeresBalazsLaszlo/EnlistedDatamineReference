from "%ui/meta/configs.nut" import mkComputedConfigGet


let outfitBundles = mkComputedConfigGet("outfit_bundles", {})

const bundlesPresentation = {
  outfit_bundle_usa_normandy_1 = {
    image = "ui/shop/outfit_bundle_usa_normandy_1.avif"
    locId = "shop/outfit_bundle_usa_normandy_1"
  }
  outfit_bundle_usa_ardennes_1 = {
    image = "ui/shop/outfit_bundle_usa_ardennes_1.avif"
    locId = "shop/outfit_bundle_usa_ardennes_1"
  }
  outfit_bundle_usa_tunisia_1 = {
    image = "ui/shop/outfit_bundle_usa_tunisia_1.avif"
    locId = "shop/outfit_bundle_usa_tunisia_1"
  }
  outfit_bundle_usa_pacific_1 = {
    image = "ui/shop/outfit_bundle_usa_pacific_1.avif"
    locId = "shop/outfit_bundle_usa_pacific_1"
  }
}

return {
  bundlesPresentation
  outfitBundles
}
