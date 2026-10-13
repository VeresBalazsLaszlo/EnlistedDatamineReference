from "app" import exit_game
from "eventbus" import eventbus_subscribe


eventbus_subscribe("wegame.quit", @(_) exit_game())
