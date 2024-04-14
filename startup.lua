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

---DB containing all furniture items
this.DB = {}

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

  filterCraftingType = {},
  filterQuality = {},

  favourites = {},

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
    Character = 1,
    Version = 1,
  },

  -- tooltips
  disableTooltips = false,
  coloredTooltips = true,
  dateFormat = "YYYY-MM-DD",
  hideKnowledge = false,

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
    local function ignore(...) end -- black hole for most property calls, like logger:Debug, because the chat window is unsuited for the amount of text
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
    logger:SetMinLevelOverride(logger.LOG_LEVEL_VERBOSE)
  else
    logger:SetMinLevelOverride(logger.LOG_LEVEL_INFO)
  end

  return logger
end

local function migrateData()
  local data = this.settings.data
  -- Check if old DB is present
  if not data or next(data) == nil then
    return
  end
  this.Logger:Info("Migrating data from old format. Delete the saved variables file if this keeps happening.")
  this.settings.favourites = this.settings.favourites or {}

  local numFound = 0
  local numOldFavs = #this.settings.favourites
  for k, v in pairs(data) do
    if v.favorite then
      numFound = numFound + 1
      FurC.Fave(k)
    end
  end

  local numTotalFavs = NonContiguousCount(this.settings.favourites)
  this.Logger:Info("Found %d favourites, imported %d new ones", numFound, numTotalFavs - numOldFavs)

  this.settings.data = nil
end

local function init(_, addOnName)
  if addOnName ~= this.name then
    return
  end
  EVENT_MANAGER:UnregisterForEvent(this.name, EVENT_ADD_ON_LOADED)

  local timeStart = GetGameTimeMilliseconds()
  local memStart = collectgarbage("count")

  this.settings = ZO_SavedVars:NewAccountWide(this.name .. "_Settings", 2, nil, defaults)
  this.CreateSettings(this.settings, defaults)
  this.Logger = this.getOrCreateLogger()

  this.CharacterName = utils.GetCurrentChar()
  local scanFiles = false
  this.settings.databaseVersion = this.version

  if this.settings.version < this.version then
    -- todo: react to major version changes by cleansing orphaned settings or just nuke from orbit with a full reset (settings = {} + reloadUi)?
    --  check like: (verOld // 1e6)-(verNow // 1e6) < 0
    this.settings.version = this.version
    scanFiles = true
  end

  this.ScanRecipes(scanFiles, not this.GetSkipInitialScan())
  this.SetFilter(true)
  this.CreateTooltips()
  this.InitRightclickMenu()
  this.SetupInventoryRecipeIcons()

  SLASH_COMMANDS["/fur"] = FurnitureCatalogue_Toggle

  local timeEnd = GetGameTimeMilliseconds()
  local memEnd = collectgarbage("count")
  this.Metrics = { -- Some metrics for debugging/profiling
    startup = timeEnd - timeStart,
    memUsage = memEnd - memStart,
    memTotal = memEnd,
  }
  this.Logger:Debug(
    -- Just an indicator, not precise
    "Startup: %03d ms, Memory: ~%0.f KB / %0.f KB",
    this.Metrics.startup,
    this.Metrics.memUsage,
    this.Metrics.memTotal
  )

  migrateData()
end

ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_FURNITURE_CATALOGUE", "Toggle main window")
ZO_CreateStringId("SI_BINDING_NAME_TOGGLE_FURNITURE_CATALOGUE_RECIPE", "Toggle Blueprint on tooltip")
EVENT_MANAGER:RegisterForEvent(this.name, EVENT_ADD_ON_LOADED, init)
