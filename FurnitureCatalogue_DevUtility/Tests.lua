-- Playground for Tests and benchmark scenarios
-- see https://github.com/manavortex/FurnitureCatalogue/blob/master/docs/TESTS.md

local this = FurCDev

local function addTraceMarker(msg)
  RecordScriptProfilerUserEvent(msg)
end

-- Helper Functions for Prerequisites

local function disableDebug()
  FurC.SetEnableDebug(false)
end

---@param isHidden bool
local function setHideCrowns(isHidden)
  FurC.SetHideCrownStoreItems(isHidden)
end

---@param isHidden bool
local function setHideRumour(isHidden)
  FurC.SetHideRumourRecipes(isHidden)
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

local function setDropdownChoice(category, choiceId)
  local ddSrcTxt = FurC.DropdownData["Choices" .. category][choiceId]
  FurC.SetDropdownChoice(category, ddSrcTxt, choiceId)
end

local function clearAll()
  FurC.SetFilterCraftingType(0) -- reset crafting
  FurC.SetFilterQuality(0) -- reset quality

  -- Char, Source, Version off
  setDropdownChoice("Character", 1) -- first entry is "Character filter: off"
  setDropdownChoice("Source", FurC.Constants.ItemSources.NONE)
  setDropdownChoice("Version", FurC.Constants.Versioning.NONE)

  setHideCrowns(true) -- hide crowns, ignoring user default setting
  setHideRumour(true) -- hide rumours, ignoring user default setting
end

local function startProfiler()
  assert(ESO_PROFILER, "EsoProfiler not found")
  StartScriptProfiler()
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
local function emulateUserInput(uiElement, inputList, delay)
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
local function suspendTask(task, delay)
  task:Suspend()
  zo_callLater(function()
    task:Resume()
  end, delay)
end

-- Scenario Functions
-- Should interact with UI instead of direct function calls, if possible.

local delayTyping = 222
local delayProfiler = 10000
local delayUI = 1000
local delaySearch = 5000

-- Scenario 1: Re-Initialise database
-- Profiling on UI reload crashes on my setup,
--  but we can emulate a Furniture Catalogue boot phase by manually regenerating data.
local function scenario1_init_db()
  local task = LibAsync:Create("scenario1_init_db")
  assert(task)
  task
    :Call(function()
      FurnitureCatalogue_Toggle()
      suspendTask(task, delayUI) -- wait for the UI to catch up
    end)
    :Then(function()
      clearAll()
      suspendTask(task, delayProfiler) -- wait before starting the profiler
    end)
    :Then(function() -- ~00:00
      disableDebug()
      startProfiler()
      addTraceMarker(task.name .. ",warmup")
      suspendTask(task, 3 * delayUI) -- let the profiler warm up
    end)
    :Then(function() -- ~00:03
      addTraceMarker(task.name .. ",rescanDB")
      rescanDB()
      suspendTask(task, delaySearch) -- wait for result list to catch up
    end)
    :Then(function() -- ~00:08
      addTraceMarker(task.name .. ",rescanData")
      rescanData()
      suspendTask(task, delaySearch) -- wait for result list to catch up
    end)
    :Then(function() -- ~00:13
      addTraceMarker(task.name .. ",rescanChar")
      rescanChar()
      suspendTask(task, 3 * delayUI) -- wait for char knowledge scan
    end)
    :Then(function() -- ~00:16
      FurnitureCatalogue_Toggle()
      stopProfiler()
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
      suspendTask(task, delayUI) -- wait for the UI to catch up
    end)
    :Then(function()
      clearAll()
      suspendTask(task, delayProfiler) -- wait before starting the profiler
    end)
    :Then(function() -- ~00:00
      disableDebug()
      startProfiler()
      addTraceMarker(task.name .. ",warmup")
      suspendTask(task, 3 * delayUI) -- let the profiler warm up
    end)
    :Then(function() -- ~00:03
      local searchTerm = { "b", "l", "e", "s", "s", "e", "d" }
      addTraceMarker(task.name .. ",search")
      emulateUserInput(FurC_SearchBox, searchTerm, delayTyping)
      suspendTask(task, delaySearch + (#searchTerm * delayTyping)) -- wait for the searches to catch up
    end)
    :Then(function() -- ~00:09.5
      addTraceMarker(task.name .. ",clear")
      FurC_SearchBox:Clear()
      suspendTask(task, delaySearch) -- wait for the cleared search to catch up
    end)
    :Then(function() -- ~00:14.5
      addTraceMarker(task.name .. ",unfocus")
      FurC_SearchBox:LoseFocus()
      suspendTask(task, delayUI) -- wait for any UI actions related to focus loss
    end)
    :Then(function() -- ~00:15.5
      FurnitureCatalogue_Toggle()
      stopProfiler()
    end)
end

-- Scenario 3: Search all Items (includes crown+rumour)
-- Check if the filters make a difference in search performance.
local function scenario3_search_all_items()
  local task = LibAsync:Create("scenario3_search_all_items")
  assert(task)
  task
    :Call(function()
      FurnitureCatalogue_Toggle()
      suspendTask(task, delayUI) -- wait for the UI to catch up
    end)
    :Then(function()
      disableDebug()
      clearAll()
      suspendTask(task, 3 * delayUI) -- wait for the UI to catch up
    end)
    :Then(function()
      setHideCrowns(false)
      setHideRumour(false)
      suspendTask(task, delayProfiler) -- wait before starting the profiler
    end)
    :Then(function() -- ~00:00
      startProfiler()
      addTraceMarker(task.name .. ",warmup")
      suspendTask(task, 3 * delayUI) -- let the profiler warm up
    end)
    :Then(function() -- ~00:03
      local searchTerm = { "b", "l", "e", "s", "s", "e", "d" }
      addTraceMarker(task.name .. ",search")
      emulateUserInput(FurC_SearchBox, searchTerm, delayTyping)
      suspendTask(task, delaySearch + (#searchTerm * delayTyping))
    end)
    :Then(function() -- ~00:09.5
      addTraceMarker(task.name .. ",clear")
      FurC_SearchBox:Clear()
      suspendTask(task, delaySearch) -- Wait again for the search to finish
    end)
    :Then(function() -- ~00:14.5
      addTraceMarker(task.name .. ",unfocus")
      FurC_SearchBox:LoseFocus()
      suspendTask(task, delayUI) -- wait for any UI actions related to focus loss
    end)
    :Then(function() -- ~00:15.5
      FurnitureCatalogue_Toggle()
      stopProfiler()
    end)
end

-- Scenario 4: Filter Base Items
-- Check filter performance.
local function scenario4_filter_base_items()
  local task = LibAsync:Create("scenario4_filter_base_items")
  assert(task)
  task
    :Call(function()
      FurnitureCatalogue_Toggle()
      suspendTask(task, delayUI) -- wait for the UI to catch up
    end)
    :Then(function()
      clearAll()
      suspendTask(task, delayProfiler) -- wait before starting the profiler
    end)
    :Then(function() -- ~00:00
      disableDebug()
      startProfiler()
      addTraceMarker(task.name .. ",warmup")
      suspendTask(task, 3 * delayUI) -- let the profiler warm up
    end)
    :Then(function() -- ~00:03
      addTraceMarker(task.name .. ",filter1")
      setDropdownChoice("Source", FurC.Constants.ItemSources.VENDOR)
      suspendTask(task, 3 * delayUI) -- wait for the 1. filter to take effect
    end)
    :Then(function() -- ~00:06
      addTraceMarker(task.name .. ",filter2")
      setDropdownChoice("Version", FurC.Constants.Versioning.KITTY)
      suspendTask(task, 3 * delayUI) -- wait for the 2. filter to take effect
    end)
    :Then(function() -- ~00:09
      addTraceMarker(task.name .. ",filter2Change")
      setDropdownChoice("Source", FurC.Constants.Versioning.CRAFTING_KNOWN)
      suspendTask(task, 3 * delayUI) -- wait for the changed 2. filter to take effect
    end)
    :Then(function() -- ~00:12
      addTraceMarker(task.name .. ",unfocus")
      FurC_SearchBox:LoseFocus()
      suspendTask(task, delayUI) -- wait for any UI actions related to focus loss
    end)
    :Then(function() -- ~00:15.5
      FurnitureCatalogue_Toggle()
      stopProfiler()
    end)
end

-- Scenario 5: Filter all Items (includes crown+rumour)
-- Check if the filters make a difference in filter performance.
local function scenario5_filter_all_items()
  local task = LibAsync:Create("scenario5_filter_all_items")
  assert(task)
  task
    :Call(function()
      FurnitureCatalogue_Toggle()
      suspendTask(task, delayUI) -- wait for the UI to catch up
    end)
    :Then(function()
      clearAll()
      suspendTask(task, 3 * delayUI) -- wait for the UI to catch up
    end)
    :Then(function()
      setHideCrowns(false)
      setHideRumour(false)
      suspendTask(task, delayProfiler) -- wait before starting the profiler
    end)
    :Then(function() -- ~00:00
      disableDebug()
      startProfiler()
      addTraceMarker(task.name .. ",warmup")
      suspendTask(task, 3 * delayUI) -- let the profiler warm up
    end)
    :Then(function() -- ~00:03
      addTraceMarker(task.name .. ",filter1")
      setDropdownChoice("Source", FurC.Constants.ItemSources.VENDOR)
      suspendTask(task, 3 * delayUI) -- wait for the 1. filter to take effect
    end)
    :Then(function() -- ~00:06
      addTraceMarker(task.name .. ",filter2")
      setDropdownChoice("Version", FurC.Constants.Versioning.KITTY)
      suspendTask(task, 3 * delayUI) -- wait for the 2. filter to take effect
    end)
    :Then(function() -- ~00:09
      addTraceMarker(task.name .. ",filter2Change")
      setDropdownChoice("Source", FurC.Constants.Versioning.CRAFTING_KNOWN)
      suspendTask(task, 3 * delayUI) -- wait for the changed 2. filter to take effect
    end)
    :Then(function() -- ~00:12
      addTraceMarker(task.name .. ",unfocus")
      FurC_SearchBox:LoseFocus()
      suspendTask(task, delayUI) -- wait for any UI actions related to focus loss
    end)
    :Then(function() -- ~00:15.5
      FurnitureCatalogue_Toggle()
      stopProfiler()
    end)
end

-- Scenario 6: Caching Efficiency Test
-- Test the performance of switching between filters to check for caching improvements
local function scenario6_caching_test()
  local task = LibAsync:Create("scenario6_caching_test")
  assert(task)
  task
    :Call(function()
      FurnitureCatalogue_Toggle()
      suspendTask(task, delayUI) -- wait for the UI to catch up
    end)
    :Then(function()
      clearAll()
      suspendTask(task, delayProfiler) -- wait before starting the profiler
    end)
    :Then(function() -- ~00:00
      disableDebug()
      startProfiler()
      addTraceMarker(task.name .. ",warmup")
      suspendTask(task, 3 * delayUI) -- let the profiler warm up
    end)
    :Then(function() -- ~00:03
      addTraceMarker(task.name .. ",filter")
      setDropdownChoice("Version", FurC.Constants.Versioning.KITTY)
      suspendTask(task, 3 * delayUI) -- wait for the 1. filter to take effect
    end)
    :Then(function() -- ~00:06
      addTraceMarker(task.name .. ",filterChange1")
      setDropdownChoice("Version", FurC.Constants.Versioning.NECROM)
      suspendTask(task, 3 * delayUI) -- wait for the changed filter to take effect
    end)
    :Then(function() -- ~00:09
      addTraceMarker(task.name .. ",filterChange2")
      setDropdownChoice("Version", FurC.Constants.Versioning.KITTY)
      suspendTask(task, 3 * delayUI) -- wait for the changed filter to take effect
    end)
    :Then(function() -- ~00:12
      addTraceMarker(task.name .. ",clear")
      setDropdownChoice("Version", FurC.Constants.Versioning.NONE)
      suspendTask(task, 3 * delayUI) -- wait for the cleared filter to take effect
    end)
    :Then(function() -- ~00:15
      addTraceMarker(task.name .. ",unfocus")
      FurC_SearchBox:LoseFocus()
      suspendTask(task, delayUI) -- wait for any UI actions related to focus loss
    end)
    :Then(function() -- ~00:16
      FurnitureCatalogue_Toggle()
      stopProfiler()
    end)
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
