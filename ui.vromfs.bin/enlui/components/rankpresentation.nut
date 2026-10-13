from "%ui/ui_library.nut" import *

let mkGenRank = @(rank, rankName, rankBack) {
  locId = $"rank/{rankName}"
  image = $"ui/skin#ranks/military_rank_{rank}.svg"
  imageBack = $"ui/uiskin/ranks/imageBack/military_rank_{rankBack}_bg.avif"
  imageIcon = $"ui/skin#ranks/imageScore/military_rank_{rank}_lb.svg"
}

const rankIconSize = hdpxi(24)
const rankImageMidSize = hdpxi(50)

let ranks = freeze([
  mkGenRank("01", "noRank", "01")
  mkGenRank("01", "private", "01")
  mkGenRank("02", "corporal", "01")
  mkGenRank("03", "sergeant", "02")
  mkGenRank("04", "staffSergean", "02")
  mkGenRank("05", "sergeantFirstClass", "02")
  mkGenRank("06", "masterSergeant", "02")
  mkGenRank("07", "firstSergeant", "02")
  mkGenRank("08", "sergeantMajor", "02")
  mkGenRank("09", "secondLieutenant", "03")
  mkGenRank("10", "firstLieutenant", "04")
  mkGenRank("11", "captain", "04")
  mkGenRank("12", "major", "05")
  mkGenRank("13", "lieutenantColonel", "05")
  mkGenRank("14", "colonel", "06")
  mkGenRank("15", "brigadierGeneral", "07")
  mkGenRank("16", "majorGeneral", "08")
  mkGenRank("17", "lieutenantGeneral", "09")
  mkGenRank("18", "general", "10")
  mkGenRank("19", "generalArmy", "10")
  mkGenRank("20", "marshal", "11")
])

let getRankConfig = @(rank) ranks?[rank] ?? ranks[0]

function mkRankBack(rank, imgSize = rankImageMidSize) {
  let rankCfg = getRankConfig(rank)
  return {
    rendObj = ROBJ_IMAGE
    size = [imgSize, imgSize]
    image = Picture(rankCfg.imageBack)
  }
}

function mkRankImage(rank, imgSize = rankImageMidSize) {
  let rankCfg = getRankConfig(rank)
  return {
    rendObj = ROBJ_IMAGE
    size = [imgSize, imgSize]
    image = Picture($"{rankCfg.image}:{imgSize}:{imgSize}")
  }
}

function mkRankIcon(rank) {
  let rankCfg = getRankConfig(rank)
  return {
    rendObj = ROBJ_IMAGE
    size = const [rankIconSize, rankIconSize]
    image = Picture($"{rankCfg.imageIcon}:{rankIconSize}:{rankIconSize}")
  }
}

let mkRank = @(rank, imgSize = rankImageMidSize) {
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  children = [
    mkRankBack(rank, imgSize)
    mkRankImage(rank, imgSize)
  ]
}


return {
  mkRankImage
  mkRankIcon
  mkRank
  getRankConfig
  rankIconSize
}