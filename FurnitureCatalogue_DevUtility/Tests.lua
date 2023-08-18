-- Tests and benchmark scenarios

local this = FurCDev

-- Helper Functions for Prerequisites

local function disableDebug()
  FurC.SetEnableDebug(false)
end

---@param enabled bool
local function setShowCrowns(enabled)
  FurC.SetHideCrownStoreItems(enabled)
end

---@param enabled bool
local function setShowRumour(enabled)
  FurC.SetHideRumourRecipes(enabled)
end

local function rescanDB()
  -- recreate DB (M3)
  FurC.WipeDatabase()
end

local function rescanData()
  -- rescan Data (M2)
  FurC.ScanRecipes(true, false)
end

local function rescanChar()
  -- rescan char knowledge (M1)
  FurC.ScanRecipes(false, true)
end

local function clearAll()
  -- Source, Version, Char off
  -- TODO: implement turning Source, Version, Char off

  FurC.SetFilterCraftingType(0) -- reset crafting
  FurC.SetFilterQuality(0) -- reset quality

  -- Force NONE instead of default choice to really clear it
  FurC.SetDropdownChoice("Character", "", 0)
  FurC.SetDropdownChoice("Source", "", FurC.Constants.ItemSources.NONE)
  FurC.SetDropdownChoice("Version", "", FurC.Constants.Versioning.NONE)

  setShowCrowns(false)
  setShowRumour(false)
end

local function startProfiler()
  if nil ~= ESO_PROFILER then
    StartScriptProfiler()
  end
end

local function stopProfiler()
  if nil ~= ESO_PROFILER then
    StopScriptProfiler()
    ESO_PROFILER:GenerateReport()
    FurC.SetEnableDebug(true)
    FurC.Logger:Debug("Done profiling, you can export from UI or ESO_PROFILER:Export()")
  end
end

---Tries to emulate user typing into a text field.
---@param uiElement EditControl
---@param inputList table
---@param delay integer
local function emulateTyping(uiElement, inputList, delay)
  -- In case there are onFocus listeners

  uiElement:TakeFocus()

  -- Clear any existing text or selection
  uiElement:ClearSelection()
  uiElement:Clear()

  -- Type with delay between inputs
  local function typeLetter(i)
    if i <= #inputList then
      uiElement:InsertText(inputList[i])
      zo_callLater(function()
        typeLetter(i + 1)
      end, delay)
    end
  end

  typeLetter(1)
end

-- Makes zo_callLater nesting unnecessary (combined with LibAsync)
local function delayTask(task, delay)
  task:Suspend()
  zo_callLater(function()
    task:Resume()
  end, delay)
end

-- Scenario Functions
-- Should interact with UI instead of direct function calls, if possible.

-- Scenario 1: Re-Initialise database
-- Profiling on UI reload crashes on my setup,
--  but we can emulate a Furniture Catalogue boot phase by manually regenerating data.
local function scenario1_init_db()
  local task = LibAsync:Create("scenario1_init_db")
  assert(task)
  -- Prerequisites
  task
    :Call(function()
      --disableDebug()
      delayTask(task, 1000)
    end)
    :Then(function()
      FurnitureCatalogue_Toggle()
      delayTask(task, 1000)
    end)
    :Then(function()
      clearAll()
      delayTask(task, 10000) -- wait before profiling
    end)
    :Then(function()
      startProfiler()
      d("Started profiler")
      rescanDB()
      d("Rescanned DB")
    end)
    :Then(function()
      rescanData()
      d("Rescanned data")
    end)
    :Then(function()
      rescanChar()
      d("Rescanned char")
    end)
    :Then(function()
      FurnitureCatalogue_Toggle()
      d("Toggled Furniture Catalogue again")
    end)
    :Then(function()
      stopProfiler()
      d("Stopped profiler")
    end)
end

-- Scenario 2: Baseline Search
-- Search with all filters disabled and no crown+rumour (the default setting), for a baseline.
local function scenario2_baseline_search()
  local task = LibAsync:Create("scenario2_baseline_search")
  assert(task)
  task
    :Call(function()
      FurnitureCatalogue_Toggle()
      disableDebug()
      clearAll()
      delayTask(task, 10000) -- wait before profiling
    end)
    :Then(function()
      startProfiler()
      local searchBox = FurC_SearchBox
      emulateTyping(searchBox, { "b", "l", "e", "s", "s", "e", "d" }, 85)
      delayTask(task, 5000) -- Wait for the search to catch up, before clearing it
    end)
    :Then(function()
      FurC_SearchBox:Clear()
      delayTask(task, 5000) -- Wait again for the search to finish
    end)
    :Then(function()
      FurC_SearchBox:LoseFocus()
      delayTask(task, 1000)
    end)
    :Then(function()
      FurnitureCatalogue_Toggle()
      stopProfiler()
    end)
end

-- Scenario 3: Search all Items (includes crown+rumour)
-- Check if the filters make a difference in search performance.
local function scenario3_search_all_items()
  FurnitureCatalogue_Toggle()
  disableDebug()
  clearAll()
  setShowCrowns(true)
  setShowRumour(true)

  zo_callLater(function()
    startProfiler()
    local searchBox = FurC_SearchBox
    emulateTyping(searchBox, { "b", "l", "e", "s", "s", "e", "d" }, 85)
    -- Wait for the search to catch up, before clearing it
    zo_callLater(function()
      searchBox:Clear()
      -- Wait again for the search to finish
      zo_callLater(function()
        -- emulate user unfocussing search
        searchBox:LoseFocus()
        zo_callLater(function()
          FurnitureCatalogue_Toggle()
          stopProfiler()
        end, 1000)
      end, 5000)
    end, 5000)
  end, 10000) -- wait before profiling
end

-- Scenario 4: Filter Base Items
-- Check filter performance.
local function scenario4_filter_base_items()
  FurnitureCatalogue_Toggle()
  disableDebug()
  clearAll()
  rescanDB()
  rescanData()
  rescanChar()

  zo_callLater(function()
    startProfiler()
    local searchBox = FurC_SearchBox
    emulateTyping(searchBox, { "b", "l", "e", "s", "s", "e", "d" }, 85)
    -- Wait for the search to catch up, before clearing it
    zo_callLater(function()
      searchBox:Clear()
      -- Wait again for the search to finish
      zo_callLater(function()
        -- emulate user unfocussing search
        searchBox:LoseFocus()
        zo_callLater(function()
          FurnitureCatalogue_Toggle()
          stopProfiler()
        end, 1000)
      end, 5000)
    end, 5000)
  end, 10000) -- wait before profiling

  startProfiler()
  FurnitureCatalogue_Toggle()
  -- TODO: Implement the filter operations
  FurnitureCatalogue_Toggle()
  stopProfiler()
end

local function scenario5_filter_all_items()
  disableDebug()
  clearAll()
  setShowCrowns(true)
  setShowRumour(true)
  rescanDB()
  rescanData()
  rescanChar()

  startProfiler()
  FurnitureCatalogue_Toggle()
  -- TODO: Implement the filter operations
  FurnitureCatalogue_Toggle()
  stopProfiler()
end

local function scenario6_caching_test()
  disableDebug()
  clearAll()
  startProfiler()
  FurnitureCatalogue_Toggle()
  -- TODO: Implement the search, clear, search operations to test caching
  FurnitureCatalogue_Toggle()
  stopProfiler()
end

-- Structuring the Tests

this.Profiler = {
  s1 = scenario1_init_db,
  s2 = scenario2_baseline_search,
  s3 = scenario3_search_all_items,
  s4 = scenario4_filter_base_items,
  s5 = scenario5_filter_all_items,
  s6 = scenario6_caching_test,
}

-- How to run scenarios:
-- 1. perform UI reload
-- 2. place your char in a spot with good FPS
-- 3. open profiler UI to see progress
-- 4. call test from chat window like /script FurCDev.Profiler.s1()
-- 5. it opens FurC GUI, resets any filters and waits for 10 sec
-- 6. after that the profiling starts
-- 7. wait for EsoProfiler to generate the report
-- 8. export tracelog
-- 9. check file in Perfetto Trace Log Viewer
-- 10. or save log for later, like `cp '<SAVED_VARS>/ESOProfiler.lua' '<TARGET_DIR>/2023-01-25_furc_s1.lua'
