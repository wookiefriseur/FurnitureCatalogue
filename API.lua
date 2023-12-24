-- Exposes FurC functions to be used by other AddOns in a well defined manner

FurC = FurC or {}

FurC.API = {}
local this = FurC.API

local utils = FurC.Utils

-- TODO: some utility functions for furniture infos

---Get the required achievement for a furnishing
---@param itemLink string
---@return integer achievementId or 0
function this.GetAchievementForFurnishing(itemLink)
  assert(false, "Not Yet Implemented")
  return 0
end

-- TODO: some LibPrice stuff

---Get the furnishing materials
---@param itemLink string
---@return table [{matId = 123, amount = 2}, {...}]
function this.GetMaterialsForFurnishing(itemLink)
  assert(false, "Not Yet Implemented")
  return {}
end
