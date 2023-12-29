FurC = FurC or {}

local this = FurC
local utils = FurC.Utils

this.name = "FurnitureCatalogue"
this.author = "manavortex"
this.tag = "FurC"

this.version = 4086000 -- will be AUTOREPLACED with AddonVersion
this.CharacterName = nil
this.website = "https://www.esoui.com/downloads/fileinfo.php?id=1617"
this.settings = {}

local src = this.Constants.ItemSources
local ver = this.Constants.Versioning

this.AchievementVendors = {}
this.LuxuryFurnisher = {}
this.Recipes = {}
this.Rolis = {}
this.Faustina = {}
this.RolisRecipes = {}
this.FaustinaRecipes = {}
this.Books = {}
this.EventItems = {}
this.PVP = {}
this.MiscItemSources = {}
this.RumourRecipes = {}

local defaults = {
  hideMats = true,
  dontScanTradingHouse = false,
  enableDebug = false,

  data = {},
  filterCraftingType = {},
  filterQuality = {},

  resetDropdownChoice = false,
  useTinyUi = true,
  useInventoryIcons = true,
  fontSize = 18,

  gui = {
    lastX = 100,
    lastY = 100,
    width = 650,
    height = 550,
  },

  dropdownDefaults = {
    Source = 1,
    Version = 1,
  },

  -- tooltips
  disableTooltips = false,
  coloredTooltips = true,
  dateFormat = "YYYY-MM-DD",
  hideKnowledge = false,

  ---@type boolean Accountwide character knowledge
  accountwide = true,

  hideBooks = true,
  hideDoubtfuls = true,
  hideCrownstore = true,
  hideRumourEntry = false,
  hideCrownStoreEntry = false,
  wipeDatabase = false,

  hideUiButtons = {
    FURC_RUMOUR = false,
    FURC_CROWN = false,
  },
}

local logger
--- Gets the current logger or creates it if it doesn't exist yet
--- @return Logger logger instance
function this.getOrCreateLogger()
  if logger then
    return logger
  end -- return existing reference

  if not LibDebugLogger then
    local function ignore(...) end -- black hole for most property calls, like logger:Debug
    local function info(self, ...)
      local prefix = string.format("[%s]: ", this.tag)
      if tostring(...):find("%%") then
        d(prefix .. string.format(...))
      else
        d(prefix .. tostring(...))
      end
    end
    logger = {}
    logger.Verbose = ignore
    logger.Debug = ignore
    logger.Info = info
    logger.Warn = ignore
    logger.Error = ignore
    logger.Log = ignore
    logger.LOG_LEVEL_VERBOSE = "V"
    logger.LOG_LEVEL_DEBUG = "D"
    logger.LOG_LEVEL_INFO = "I"
    logger.LOG_LEVEL_WARNING = "W"
    logger.LOG_LEVEL_ERROR = "E"
    logger.SetMinLevelOverride = ignore

    return logger
  end

  -- use logger from library
  logger = LibDebugLogger(this.tag)
  logger.LOG_LEVEL_VERBOSE = LibDebugLogger.LOG_LEVEL_VERBOSE
  logger.LOG_LEVEL_DEBUG = LibDebugLogger.LOG_LEVEL_DEBUG
  logger.LOG_LEVEL_INFO = LibDebugLogger.LOG_LEVEL_INFO
  logger.LOG_LEVEL_WARNING = LibDebugLogger.LOG_LEVEL_WARNING
  logger.LOG_LEVEL_ERROR = LibDebugLogger.LOG_LEVEL_ERROR

  -- set initial log level
  if this.settings.enableDebug then
    logger:SetMinLevelOverride(logger.LOG_LEVEL_DEBUG)
  else
    logger:SetMinLevelOverride(logger.LOG_LEVEL_INFO)
  end

  return logger
end

local function init(_, addOnName)
  if addOnName ~= this.name then
    return
  end

  local timeStart = GetGameTimeMilliseconds()
  local memStart = collectgarbage("count")

  this.settings = ZO_SavedVars:NewAccountWide(this.name .. "_Settings", 2, nil, defaults)

  this.CreateSettings(this.settings, defaults)
  this.Logger = this.getOrCreateLogger()

  this.CharacterName = utils.GetCurrentChar()

  this.InitGui()

  this.CreateTooltips()
  this.InitRightclickMenu()

  this.SetupInventoryRecipeIcons()

  local scanFiles = false
  if this.settings.version < this.version then
    this.settings.version = this.version
    scanFiles = true
  end

  this.ScanRecipes(scanFiles, not this.GetSkipInitialScan())
  this.settings.databaseVersion = this.version
  SLASH_COMMANDS["/fur"] = FurnitureCatalogue_Toggle

  this.SetFilter(true)

  EVENT_MANAGER:UnregisterForEvent(this.name, EVENT_ADD_ON_LOADED)
  local timeEnd = GetGameTimeMilliseconds()
  local memEnd = collectgarbage("count")
  this.Metrics = { -- Some metrics for debugging/profiling
    startup = timeEnd - timeStart,
    memUsage = memEnd - memStart,
    memTotal = memEnd,
  }
  this.Logger:Debug(
    "Startup: %03d ms, Memory: ~%0.f KB / %0.f KB",
    this.Metrics.startup,
    this.Metrics.memUsage,
    this.Metrics.memTotal
  )
end

ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_FURNITURE_CATALOGUE", "Toggle main window")
ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_FURNITURE_CATALOGUE_RECIPE", "Toggle Blueprint on tooltip")
EVENT_MANAGER:RegisterForEvent(this.name, EVENT_ADD_ON_LOADED, init)
