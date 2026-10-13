enum Tutorial {
  MAIN = "main"
  RESEARCH = "research"
  EQUIPMENT = "equipment"
  SQUADS = "squads"
  MEMBERS = "members"
  UPGRADES = "upgrades"
  PERKS = "perks"
  VEHICLE = "vehicle"
  OUTFIT = "outfit"
}

let metaTutorialConfig = [
  {
    id = Tutorial.MAIN
    locId = "meta/tutorial/main"
    link = "main"
  },
  {
    id = Tutorial.RESEARCH
    locId = "meta/tutorial/research"
    link = "research"
  },
  {
    id = Tutorial.EQUIPMENT
    locId = "meta/tutorial/equipment"
    link = "equipment"
  },
  {
    id = Tutorial.SQUADS
    locId = "meta/tutorial/squads"
    link = "squads"
  },
  {
    id = Tutorial.MEMBERS
    locId = "meta/tutorial/members"
    link = "members"
  },
  {
    id = Tutorial.UPGRADES
    locId = "meta/tutorial/upgrades"
    link = "upgrades"
  },
  {
    id = Tutorial.PERKS
    locId = "meta/tutorial/perks"
    link = "perks"
  },
  {
    id = Tutorial.VEHICLE
    locId = "meta/tutorial/vehicle"
    link = "vehicle"
  },
  {
    id = Tutorial.OUTFIT
    locId = "meta/tutorial/outfit"
    link = "outfit"
  },
]

let metaTutorialConfigById = {}
metaTutorialConfig.each(function(v) {
  metaTutorialConfigById[v.id] <- v
})

return {
  Tutorial
  metaTutorialConfig
  metaTutorialConfigById
}
