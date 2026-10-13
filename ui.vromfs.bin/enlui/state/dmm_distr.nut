from "dagor.fs" import file_exists
from "dagor.system" import get_arg_value_by_name

return !!(file_exists("dmm") || get_arg_value_by_name("dmmdistr"))