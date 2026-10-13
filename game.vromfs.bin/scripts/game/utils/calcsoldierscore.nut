let { getScore } = require("%scripts/game/expScoringValues.nut")

let calcScore = @(stats, scoreMode) (getScore(scoreMode))
  .reduce(@(sum, score, key) sum + score * (stats?[key] ?? 0), 0).tointeger()

return calcScore