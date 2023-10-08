# HowTo

How to run scenarios:

1. perform UI reload
2. wait for 30-60 seconds in case some AddOns have delayed loading
3. open profiler UI to see progress when it finishes
4. call test from chat window like /script FurCDev.Profiler.s1()
5. it opens FurC GUI, resets any filters and waits for 10 sec (hands off mouse and keyboard, also Game must have focus)
6. after that preparation the profiling begins
7. wait for EsoProfiler to generate the report
8. export tracelog for Perfetto or use the ESOProfiler report viewer ingame
9. or save log for later, like `cp '<SAVED_VARS>/ESOProfiler.lua' '<TARGET_DIR>/2023-01-23_furc_s1.lua'

Running benchmarks and tests is similar, just without the profiler parts.

## Cautions for Profiling and Benchmarks

To rule out most side effects and difficulties in the profiling results:

- try to limit profiling scenarios to 20 seconds
- place your char in a spot with stable FPS in a regular zone
- avoid houses or dungeon instances, which might have unknown side effects
- make sure you're running only essential AddOns
- make sure you are not already logging with another tool
- record multiple sessions, if the numbers look off

# 🚀 Benchmarks

- get some metrics on performance and throughput
- that way you can check if major changes improved or worsened stuff
- do not use with profiler (incompatible with coroutines)
- check [FurCDev/Tests.lua](../FurnitureCatalogue_DevUtility/Tests.lua#L9999) for implementation and call details

# 🔎 Tests

- mainly for regression tests
- check if stuff still works like it should
- check [FurCDev/Tests.lua](../FurnitureCatalogue_DevUtility/Tests.lua#L9999) for implementation and call details


# 🎬 Scenarios for Profiling

- performs certain UI interaction steps always in the same way
- automatically runs profiler
- scenarios are in [FurCDev/Tests.lua](../FurnitureCatalogue_DevUtility/Tests.lua)

## Prerequisites

- ❌clearAll:
  - Source, Version, Char off
  - hide 👑crowns
  - hide 📰rumour
- 👑crowns:
  - showing crown store items
- 📰rumour:
  - showing rumour items
- DB3️⃣:
  - rescan DB (M3)
- DB2️⃣:
  - rescan Data (M2)
- DB1️⃣:
  - rescan char knowledge (M1)

### For all Scenarios

Disable FurC debug output

1. ⚠️ reloadUI
2. ⌛ wait 30+ sec
3. 🤡 place your char in a spot with good FPS
4. ⚙️ open profiler UI to see progress
5. 🔴 start recording
6. 🖥️ open UI
7. 🪜 perform steps
8. 🖥️ close UI
9. ⏹️ stop recording

If you're running automated UI scenarios don't touch keys until it's done.

# Scenarios

## Scenario 1: Re-Initialise database

Profiling on UI reload crashes on my setup,
but we can emulate a Furniture Catalogue boot phase by manually regenerating data.

Prerequisites: ❌clearAll

1. DB3️⃣
2. DB2️⃣
3. DB1️⃣

## Scenario 2: Baseline Search

Search with all filters disabled and no 👑📰 (the default setting), for a baseline.

Prerequisites: ❌clearAll

1. 🔎 search "blessed" (type fast `b`,`l`,`e`,`s`,`s`,`e`,`d`)
   - should return 3+ items
2. 🔎 clear search (`Ctrl+A` then `Backspace`)
   - alternatively `/script d(FurC_SearchBox:Clear())`
   - should return 4746+ items

## Scenario 3: Search all Items (includes 👑📰)

Check if the filters make a difference in search performance.

Prerequisites: ❌clearAll, 👑crowns, 📰rumour

1. 🔎 search "blessed" (type fast `b`,`l`,`e`,`s`,`s`,`e`,`d`)
   - should return 12+ items
2. 🔎 clear search (`Ctrl+A` then `Backspace`)
   - alternatively `/script d(FurC_SearchBox:Clear())`
   - should return 6365+ items

## Scenario 4: Filter Base Items

Check filter performance.

Prerequisites: ❌clearAll, DB3️⃣, DB2️⃣, DB1️⃣

1. 🔎 filter "Source: Purchasable Gold"
2. 🔎 filter "Version: Elsweyr"
4. 🔎 change filter "Source: Craftable: Known"

## Scenario 5: Filter all Items (includes 👑📰)

Check if the filters make a difference in filter performance.

Prerequisites: ❌clearAll, DB3️⃣, DB2️⃣, DB1️⃣

1. 🔎 filter "Source: Purchasable Gold"
2. 🔎 filter "Version: Elsweyr"
3. 🔎 clear filter "Version"
4. 🔎 filter "Source: Craftable: Known"

## Scenario 6: Caching Efficiency Test

Test the performance of switching between filters to check for caching improvements (See [Filter Base Items](#scenario-4-filter-base-items)).

Prerequisites: ❌clearAll

1. 🔎 search "blessed" (type fast `b`,`l`,`e`,`s`,`s`,`e`,`d`)
   - should return 3+ items
2. 🔎 clear search (`Ctrl+A` then `Backspace`)
   - should return 4746+ items
3. 🔎 search "blessed" (type fast `b`,`l`,`e`,`s`,`s`,`e`,`d`)
   - should return 3+ items

