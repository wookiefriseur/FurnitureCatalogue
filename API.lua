-- Exposes FurC functions to be used by other AddOns in a well defined manner

FurC = FurC or {}

local this = {}

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

local src = FurC.Constants.ItemSources
--[[
  LibPrice currently accesses internal values like:
local version_data_pvp = FurC.PVP[recipeArray.version]
local version_data_lux = FurC.LuxuryFurnisher[recipe_array.version]
local version_data_misc = FurC.MiscItemSources[recipe_array.version]
local item_id = FurC.GetItemId(item_link)
local blueprint_link = FurC.GetItemLink(recipe_array.blueprint)

local seller_list = { FurC.Rolis, FurC.Faustina }
for _, seller in ipairs(seller_list) do
  version_data = seller[recipe_array.version]
  if version_data and version_data[item_id] then
    break
  end
end

local function costsFromId(id)
  local source = {
    src.CRAFTING,
    src.VENDOR,
    src.WRIT_VENDOR,
    src.PVP,
  }

  local result = {
    price = 123,
    currency = {},
    material = {},
  }

  return result
end
]]

---Furniture Catalogue API for external use. You can treat this as a library.
---<p>You can use it like this:</p><ul>
--- <li>local reference: <code>local libfur = LibFurCat</code> and then <code>libfur.SomeFunction()</code></li>
--- <li>direct use: <code>LibFurCat.SomeFunction()</code></li>
--- <li>specific reference: <code>local someFunction = LibFurCat.SomeFunction()</code> and then <code>someFunction()</code></li>
---</ul>
---<p>There is currently no API-Versioning planned.
--- Functions under development will be marked as WIP and may change frequently.
--- In all other functions any major changes will be mentioned in advance through warnings or deprecation flags.
---</p>
LibFurCat = this
