local this = FurCDev or {}

local utils = FurC.Utils

FurCDevControl_LinkHandlerBackup_OnLinkMouseUp = nil
this.textbox = this.textbox or FurCDevControlBox
local textbox = this.textbox

---@type LinkStyle
local LINK_STYLE_DEFAULT = LINK_STYLE_DEFAULT

local sFormat = zo_strformat
local sLower = LocaleAwareToLower

local function toLower(str)
  return sLower(sFormat("<<1>>", str))
end

--[[
CachedItems[itemId] =
{
  id = GetItemLinkItemId(itemLink),
  link = itemLink,
  price = 0,
  name = "",
  achievementId = 0,
  achievementName = ""
  currency = GetCurrencyName(CURT_MONEY, false, false), -- assume Gold by default
}
]]
this.CachedItems = {}

local currentItemLink = ""

--- UI FUNCTIONS ---

local function showTextbox()
  this.control:SetHidden(false)
end

function this.clearControl()
  this.textbox:Clear()
  this.CachedItems = {}
end

---Clear cache if textbox is emptied
function this.onTextboxTextChanged()
  if this.control:IsHidden() then
    return
  end

  local text = textbox:GetText() or ""
  if #text > 0 then
    return
  end
  this.clearControl()
end

local achievementTable = {}
local questTable = {}
local zoneTable = {}

-- Inspired by AchievementFinder from Rhyono
local function buildAchievementTable()
  for id = 11, MAX_ACHIEVEMENTS + 11 do
    local achieveName = select(1, GetAchievementInfo(id))
    if achieveName ~= "" then
      -- Save gendered and lowercased achievement name
      achievementTable[id] = toLower(achieveName)
    end
  end
end

local function buildQuestTable()
  local MAX_QUESTS = 10000
  for id = 1, MAX_QUESTS do
    local questName = GetQuestName(id)
    if questName ~= "" then
      questTable[id] = questName
    end
  end
end

local NUM_ZONES = GetNumZones() -- 982 as of version 101041
local MAX_INDEX = NUM_ZONES * 100 -- don't iterate higher than that, man
local STEP_SIZE = NUM_ZONES -- "What are you doing, step size?"
local zoneLock = false
local function buildZoneTable(iFrom)
  if zoneLock then
    return
  end
  zoneLock = true -- protect from call conflicts
  iFrom = iFrom or 1
  local iTo = iFrom + STEP_SIZE - 1

  FurC.Logger:Debug("Building Zone Table: %d/%d [%5d...%5d]", NonContiguousCount(FurCDev.Zones), NUM_ZONES, iFrom, iTo)
  for id = iFrom, iTo do
    -- do NOT use `GetZoneNameByIndex` as it's a contiguous version of *ById, means the indices change
    local zoneName = GetZoneNameById(id)
    if zoneName ~= "" then
      zoneTable[id] = zoneName
    end
    iFrom = id
  end

  -- If we haven't found all zones yet, slowly iterate through the rest
  if NonContiguousCount(FurCDev.Zones) < NUM_ZONES and iFrom <= MAX_INDEX then
    zo_callLater(function()
      zoneLock = false
      buildZoneTable(iFrom + 1)
    end, 2000)
  else
    FurC.Logger:Debug("Zones table done: %d/%d [%d]", NonContiguousCount(FurCDev.Zones), NUM_ZONES, iFrom)
    zoneLock = false
  end
end

local function isInTextbox(itemId)
  local text = textbox:GetText() or ""
  return string.match(text, zo_strformat("%[<<1>>%]", itemId)) ~= nil
end

local function addToCache(item)
  local itemId = item.id or 0
  if itemId == 0 then
    currentItemLink = ""
    return
  end
  -- Save current item link for out of scope access
  currentItemLink = item.link
  if not this.CachedItems[itemId] then
    this.CachedItems[itemId] = {}
    this.CachedItems[itemId] = item
    FurC.Logger:Verbose("Added to cache: [%d] %s", itemId, item.name)
  end
end
--- Generate the Lua text for the textbox
---@param itemId integer
---@return string
local function generateItemText(itemId)
  local item = this.CachedItems[itemId]
  if not item then
    FurC.Logger:Debug("Unable to get %d from cache, please add again", itemId)
    return ""
  end

  local resultText = string.format("\t[%d] = {\t\t-- %s", itemId, item.name)

  item.price = item.price or 0
  if item.price > 0 then
    resultText = resultText .. string.format("\n\t\titemPrice = %d,\t\t-- %s", item.price, item.currency)
  end

  item.achievementId = item.achievementId or 0
  if item.achievementId > 0 then
    resultText = resultText
      .. string.format("\n\t\tachievement = %d,\t\t-- %s", item.achievementId, item.achievementName)
  end

  return resultText .. "\n\t},\n"
end

---@param furnishingLink any
---@return boolean success
local function addItemToTextbox(furnishingLink)
  furnishingLink = furnishingLink or currentItemLink
  local itemId = GetItemLinkItemId(furnishingLink)
  if itemId == 0 then
    FurC.Logger:Debug("Invalid ID for item %s", furnishingLink)
    return false
  end
  if isInTextbox(itemId) then
    FurC.Logger:Verbose("Item already in textbox: %s", furnishingLink)
    return false
  end

  local textSoFar = this.textbox:GetText() or ""
  FurC.Logger:Debug("Adding to textbox: %s", furnishingLink)
  this.textbox:SetText(textSoFar .. generateItemText(itemId))
  showTextbox()

  currentItemLink = ""
  return true
end

function this.AddAllFromTrader()
  local furnishings = this.GetFurnishingsFromStore()

  local numNewItems = 0
  for i, item in ipairs(furnishings) do
    local itemLink = item.link
    local wasAdded = addItemToTextbox(itemLink)
    numNewItems = numNewItems + (wasAdded and 1 or 0)
  end
  if #furnishings > 0 then
    FurC.Logger:Info("Added %d of %d items", numNewItems, #furnishings)
  end
end

--- HELPER FUNCTIONS ---

---Get single achievementId from achievementName, no partial matches
---@param achievementName string Exact localised Name (from tooltip)
---@return integer achievementId or 0
local function getAchievementId(achievementName)
  if not achievementName or achievementName == "" then
    return 0
  end

  ---Generate Lookup table for Achievements, only called on demand
  --- (Inspired by AchievementFinder from Rhyono)
  if NonContiguousCount(achievementTable) == 0 then
    local MIN_ACHIEVEMENT_ID = 11
    for id = MIN_ACHIEVEMENT_ID, MAX_ACHIEVEMENTS + MIN_ACHIEVEMENT_ID do
      local achieveName = select(1, GetAchievementInfo(id))
      if achieveName ~= "" then
        -- Save localised and lowercased achievement name
        achievementTable[id] = toLower(achieveName)
      end
    end
  end

  -- making sure that the achievement name is the same like in the lookup table
  achievementName = toLower(achievementName)
  for id, name in pairs(achievementTable) do
    if name == achievementName then
      return id
    end
  end

  return 0
end
FurCDev.GetAchievementId = getAchievementId

---@param achievementName string part of the achievement name
---@return table results list of achievements that match the given name
local function findAchievement(achievementName)
  local results = {}
  if not achievementName or achievementName == "" then
    return results
  end

  if #achievementTable < 1 then
    buildAchievementTable()
  end

  achievementName = toLower(achievementName)
  for id, name in pairs(achievementTable) do
    if string.find(name, achievementName) then
      table.insert(results, zo_strformat("<<1>>: <<2>>", id, name))
    end
  end
  return results
end
FurCDev.FindAchievement = findAchievement

---@param questName string part of the quest name
---@return table results list of quests that match the given name
local function findQuest(questName)
  local results = {}
  if not questName or questName == "" then
    return results
  end

  if NonContiguousCount(questTable) < 1 then
    FurC.Logger:Debug("Have to build quest table, search again")
    buildQuestTable()
    return results
  end

  questName = toLower(questName)
  for id, name in pairs(questTable) do
    if string.find(LocaleAwareToLower(name), questName) then
      results[id] = name
    end
  end
  return results
end
FurCDev.FindQuest = findQuest

---@param zoneName string part of the zone name
---@return table results list of zones that match the given name (unformatted)
local function findZone(zoneName)
  local results = {}
  if not zoneName or zoneName == "" then
    return results
  end

  if NonContiguousCount(zoneTable) < 1 then
    FurC.Logger:Debug("Have to build zone table, search again when it's done")
    buildZoneTable()
    return results
  end

  zoneName = toLower(zoneName)
  for id, name in pairs(zoneTable) do
    if string.find(LocaleAwareToLower(name), zoneName) then
      results[id] = name
    end
  end
  return results
end
FurCDev.FindZone = findZone

---Get all furnishings and blueprints detected from the trader
---Example: /script d(FurCDev.GetFurnishingsFromStore())
---@return table {{link,id,price,name,...},...} or empty table
function this.GetFurnishingsFromStore()
  if IsStoreEmpty() then
    FurC.Logger:Info("No store opened or trader has no items.")
    return {}
  end

  local furnishings = {}
  local numItems = GetNumStoreItems()
  ---@type luaindex i
  for i = 1, numItems do
    local item = this.GetStoreFurnishingInfo(i)
    if item and item.id ~= nil then
      table.insert(furnishings, item)
    end
  end

  FurC.Logger:Info("Trader has %d furnishings (total items: %d)", #furnishings, numItems)
  return furnishings
end

---Get relevant information about a furnishing from the store
---Example: /script d(FurCDev.GetStoreFurnishingInfo(33))
---@param storeIndex luaindex
---@return table {link,id,price,name,achievementId,currency,...}
function this.GetStoreFurnishingInfo(storeIndex)
  local itemLink = GetStoreItemLink(storeIndex, LINK_STYLE_DEFAULT)
  if not utils.IsFurniture(itemLink) then
    return {}
  end

  local itemId = GetItemLinkItemId(itemLink)
  if itemId == 0 then
    return {}
  end
  if this.CachedItems[itemId] then
    return this.CachedItems[itemId]
  end

  local item = {
    id = itemId,
    link = itemLink,
    price = 0,
    name = "",
    achievementId = 0,
    achievementName = "",
    currency = GetCurrencyName(CURT_MONEY, false, false), -- assume Gold by default
  }

  local _, name, _, price, _, _, _, _, _, currencyType1, currencyQuantity1, _, _, _, _, buyErrorStringId =
    GetStoreEntryInfo(storeIndex)

  item.name = sFormat("<<1>>", name)

  if price == 0 then
    price = 0 + currencyQuantity1
    item.currency = GetCurrencyName(currencyType1, false, false)
  end
  item.price = price

  local success, achievement = pcall(GetErrorString, buyErrorStringId)
  if success and achievement ~= "" then
    -- Different tooltip formatting depending on locale
    -- DE: Benötigt die Errungenschaft „Sieger von Bal Sunnar“.
    -- EN: Requires Bal Sunnar Vanquisher to purchase.
    local matchWithoutQuotes = string.match(achievement, "Requires (.+) Achievement to purchase%.")
    achievement = matchWithoutQuotes or string.match(achievement, ".+ %„(.+)%“.+")
    item.achievementId = this.GetAchievementId(achievement)
    item.achievementName = achievement
  end

  addToCache(item)
  return item
end

--- EVENTS AND INIT ---

local function addMenuItems()
  local S_ADD_TO_BOX = "Add data to textbox"
  local S_DIVIDER = "-"
  AddCustomMenuItem(S_DIVIDER, nil, MENU_ADD_OPTION_LABEL)
  AddCustomMenuItem(S_ADD_TO_BOX, addItemToTextbox, MENU_ADD_OPTION_LABEL)
end

function FurCDevControl_HandleClickEvent(itemLink, mButton, ctrl)
  if mButton ~= MOUSE_BUTTON_INDEX_RIGHT then
    return
  end
  currentItemLink = itemLink -- let the textbox know what item we clicked on
  if not utils.IsFurniture(itemLink) then
    return
  end
end

-- thanks Randactyl for helping me with the handler :)
function FurCDevControl_HandleInventoryContextMenu(control)
  control = control or moc()
  local st = ZO_InventorySlot_GetType(control)

  local item = {
    link = "",
    id = 0,
    name = "",
  }

  -- TODO #REFACTOR: put this in utils, as GetFurnitureDataFromControl(control)
  if
    st == SLOT_TYPE_ITEM
    or st == SLOT_TYPE_BANK_ITEM
    or st == SLOT_TYPE_GUILD_BANK_ITEM
    or st == SLOT_TYPE_TRADING_HOUSE_POST_ITEM
    or st == SLOT_TYPE_LAUNDER
  then
    local bagId, slotId = ZO_Inventory_GetBagAndIndex(control)
    ---@type string itemLink
    item.link = GetItemLink(bagId, slotId, LINK_STYLE_DEFAULT)

    if not utils.IsFurniture(item.link) then
      return
    end

    item.id = GetItemLinkItemId(item.link)
    item.name = zo_strformat("<<1>>", GetItemLinkName(item.link))
  elseif st == SLOT_TYPE_STORE_BUY then
    local storeEntryIndex = control.index or 0
    local itemLink = GetStoreItemLink(storeEntryIndex, LINK_STYLE_DEFAULT)
    if not utils.IsFurniture(itemLink) then
      return
    end
    utils.MergeTable(item, this.GetStoreFurnishingInfo(storeEntryIndex))
  elseif st == SLOT_TYPE_LOOT then
    if not control.lootEntry or not control.lootEntry.lootId then
      return
    end
    local lootId = control.lootEntry.lootId
    item.link = GetLootItemLink(lootId, LINK_STYLE_DEFAULT)

    if not utils.IsFurniture(item.link) then
      return
    end

    item.id = GetItemLinkItemId(item.link)
    item.name = zo_strformat("<<1>>", GetItemLinkName(item.link))
  elseif st == SLOT_TYPE_MAIL_QUEUED_ATTACHMENT then
    -- ZO_MailSendAttachmentsSlot1
    local slotId = control.id or 1
    item.link = GetMailQueuedAttachmentLink(slotId, LINK_STYLE_DEFAULT)

    if not utils.IsFurniture(item.link) then
      return
    end

    item.id = GetItemLinkItemId(item.link)
    item.name = zo_strformat("<<1>>", GetItemLinkName(item.link))
  elseif st == SLOT_TYPE_MAIL_ATTACHMENT then
    -- ZO_MailInboxMessageAttachmentsSlot4
    local mailid = MAIL_INBOX:GetOpenMailId()
    local slotIndex = control.slotIndex or 1
    item.link = GetAttachedItemLink(mailid, slotIndex, LINK_STYLE_DEFAULT)

    if not utils.IsFurniture(item.link) then
      return
    end

    item.id = GetItemLinkItemId(item.link)
    item.name = zo_strformat("<<1>>", GetItemLinkName(item.link))
  else
    return
  end

  addToCache(item)

  zo_callLater(function()
    addMenuItems()
    ShowMenu()
  end, 80)
end

function this.InitRightclickMenu()
  LINK_HANDLER:RegisterCallback(LINK_HANDLER.LINK_MOUSE_UP_EVENT, FurCDevControl_HandleClickEvent)
  ZO_PreHook("ZO_InventorySlot_ShowContextMenu", FurCDevControl_HandleInventoryContextMenu)
end
