-- Exposes FurC functions to be used by other AddOns in a well defined manner

FurC = FurC or {}

local this = {}

local utils = FurC.Utils

---Get the required achievement for a furnishing
---@param item string|number itemlink or ID
---@return table achievementTable default values, if not found: {id=0, name="", link=""}
function this.GetAchievementForFurnishing(item)
  local achievement = { id = 0, name = "", link = "" }
  item = utils.GetItemLink(item)

  if item == "" then
    return achievement
  end

  local itemId = utils.GetItemId(item)
  local achStr = FurC.getAchievementVendorSource(itemId, nil, false)
  achievement.link = string.match(achStr, "(|H0:achievement:%d+:%d+:%d+|h|h)") or ""
  achievement.id = GetAchievementIdFromLink(achievement.link)
  achievement.name = zo_strformat("<<1>>", GetAchievementName(achievement.id))

  return achievement
end

-- TODO #API: some LibPrice stuff

---Get the furnishing materials
---@param item string|number itemlink or ID
---@return table { link = "some itemlink", qty = 123} or {}
function this.GetMaterialsForFurnishing(item)
  item = utils.GetItemLink(item)
  local mats = {}

  local itemId = utils.GetItemId(item)
  for matLink, qty in pairs(FurC.GetIngredients(itemId)) do
    table.insert(mats, {
      link = matLink,
      qty = qty,
      id = GetItemLinkItemId(matLink),
    })
  end
  return mats
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

---Furniture Catalogue API for external use. You can treat this like a library.
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
