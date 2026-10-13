from "%ui/meta/sourceServProfile.nut" import sourceProfileData, profileStructure
from "%ui/ui_library.nut" import *

return profileStructure.map(@(_, k) Computed(@() sourceProfileData.get()[k]))
