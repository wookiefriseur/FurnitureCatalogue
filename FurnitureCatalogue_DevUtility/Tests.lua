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
local function scenario_init_db()
  local task = LibAsync:Create("scenario_init_db")
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
local function scenario_baseline_search()
  local task = LibAsync:Create("scenario_baseline_search")
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
local function scenario_search_all_items()
  local task = LibAsync:Create("scenario_search_all_items")
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
local function scenario_filter_base_items()
  local task = LibAsync:Create("scenario_filter_base_items")
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
local function scenario_filter_all_items()
  local task = LibAsync:Create("scenario_filter_all_items")
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
local function scenario_caching_test()
  local task = LibAsync:Create("scenario_caching_test")
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

-- Benchmarks

local function benchmarkReport(metrics)
  return string.format(
    "Min Time: %s\nMax Time: %s\nAverage Time: %s\nQueries per Second:",
    metrics.timeMin,
    metrics.timeMax,
    metrics.timeAvg,
    metrics.queriesPerSecond
  )
end

---Benchmark a given function
---  (Do not use in combination with the tracer as it seems to be incompatible with coroutines)
---@param calledFn function benchmarked function
---@param iterations number how often to repeat the function call
---@param batchSize number yields after each batch
---@return thread  process returning {timeMin,timeMax,timeAvg,timeMedian,queriesPerSecond,queryTimes}
local function benchmarkFunctions(calledFn, iterations, batchSize)
  local co = coroutine.create(function()
    local queryTimes = {}
    local timeMin = math.huge
    local timeMax = 0
    local totalTime = 0
    local batches = math.ceil(iterations / batchSize)
    for b = 1, batches do
      local batchStartTime = GetGameTimeMilliseconds()
      for i = 1, batchSize do
        calledFn()
      end
      local batchEndTime = GetGameTimeMilliseconds()
      local batchTime = batchEndTime - batchStartTime
      local avgQueryTime = batchTime / batchSize
      totalTime = totalTime + batchTime
      timeMin = math.min(timeMin, avgQueryTime)
      timeMax = math.max(timeMax, avgQueryTime)
      for i = 1, batchSize do
        table.insert(queryTimes, avgQueryTime)
      end
      d(string.format("Current progress: %.2f%%", b / (iterations / batchSize) * 100))
      coroutine.yield()
    end

    -- Calculate stats
    local timeAvg = totalTime / iterations
    table.sort(queryTimes)
    local queriesPerSecond = iterations / (totalTime / 1000)
    local timeMedian
    if iterations % 2 == 1 then
      timeMedian = queryTimes[math.ceil(iterations / 2)]
    else
      timeMedian = (queryTimes[iterations / 2] + queryTimes[iterations / 2 + 1]) / 2
    end

    return {
      timeMin = timeMin,
      timeMax = timeMax,
      timeAvg = timeAvg,
      timeMedian = timeMedian,
      queriesPerSecond = queriesPerSecond,
      batchSize = batchSize,
      iterations = iterations,
      queryTimes = queryTimes,
    }
  end)

  return co
end

local function benchmark_init_db()
  local function mockRescan()
    local sum = 0
    for i = 1, 10000 do
      sum = sum + i
    end
  end
  benchmarkFunctions(mockRescan, 10, 1)
end
local function benchmark_ui_search() end
local function benchmark_ui_filter() end
local function benchmark_query() end
local function benchmark_get_material() end

-- TESTS

local function testsuite_utils_table()
  local function test_MergeTable()
    local mergeTable = FurC.Utils.MergeTable
    -- Test case 1: Merging two tables with some overlapping keys
    local t1 = { a = "1", b = "3" }
    local t2 = { b = "2" }
    local result = mergeTable(t1, t2)
    assert(result.a == "1", "Test case 1: Key 'a' should have value '1'")
    assert(result.b == "2", "Test case 1: Key 'b' should have value '2'")

    -- Test case 2: Merging with an empty table
    local t3 = { a = "1", b = "3" }
    local t4 = {}
    local result2 = mergeTable(t3, t4)
    assert(result2.a == "1", "Test case 2: Key 'a' should have value '1'")
    assert(result2.b == "3", "Test case 2: Key 'b' should have value '3'")

    -- Test case 3: Merging two empty tables
    local t5 = {}
    local t6 = {}
    local result3 = mergeTable(t5, t6)
    assert(next(result3) == nil, "Test case 3: Result should be an empty table")
  end

  test_MergeTable()
end

local function testsuite_utils_string() end

local function testsuite_utils_furniture()
  local furniture = {
    { id = 126559, link = "|H0:item:126559:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" },
    { id = 147647, link = "|H0:item:147647:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" },
    { id = 118206, link = "|H0:item:118206:5:1:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" },
  }
  local recipes = {
    { id = 166834, itemid = 165687, link = "|H1:item:166834:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0:0|h|h" },
  }

  local function test_isFurniture()
    local isFurniture = FurC.Utils.IsFurniture

    for _, item in pairs(furniture) do
      assert(isFurniture(item.link), item.id .. " is furniture")
    end
  end

  test_isFurniture()
end

local function run_test_suites()
  local tests = {
    testsuite_utils_table,
    testsuite_utils_string,
    testsuite_utils_furniture,
  }

  for i = 1, #tests do
    local success, message = pcall(tests[i])
    if success then
      FurC.Logger:Info("Testsuite #" .. i .. " passed")
    else
      FurC.Logger:Info("Testsuite #" .. i .. " failed: " .. message)
    end
  end
end

this.Profiler = {
  -- Scenarios (uses profiler)
  s1 = scenario_init_db,
  s2 = scenario_baseline_search,
  s3 = scenario_search_all_items,
  s4 = scenario_filter_base_items,
  s5 = scenario_filter_all_items,
  s6 = scenario_caching_test,

  -- ToDo: Benchmarks (do not use with profiler)
  b1 = benchmark_init_db,
  b2 = benchmark_ui_search,
  b3 = benchmark_ui_filter,
  b4 = benchmark_query,
  b5 = benchmark_get_material,

  -- ToDo: Tests
  tests = run_test_suites,

  -- Utility
  info = function()
    local memCurrent = collectgarbage("count")
    return string.format(
      "Startup: %03d ms, Memory: ~%0.f KB / %0.f KB\nCurrent total: %0.f KB (change: %0.f KB)",
      FurC.Metrics.startup,
      FurC.Metrics.memUsage,
      FurC.Metrics.memTotal,
      memCurrent,
      memCurrent - FurC.Metrics.memTotal
    )
  end,
}
