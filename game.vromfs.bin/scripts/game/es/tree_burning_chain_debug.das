require ecs
require DagorConsole
options no_aot

[console_cmd(name="tree_burning_chain")]
def tree_burning_chain_debug()
  query() <| $ [es] (var tree_burning_chain_manager__debugOn : bool&)
    tree_burning_chain_manager__debugOn = !tree_burning_chain_manager__debugOn
    console_print("Tree burning chain debug is {tree_burning_chain_manager__debugOn ? "on" : "off"}")
