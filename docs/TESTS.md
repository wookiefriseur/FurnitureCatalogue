# Scenarios for Profiling

Tests in [FurCDev-Tests](../FurnitureCatalogue_DevUtility/Tests.lua)

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

Prerequisites: ❌clearAll,👑crowns,📰rumour

1. 🔎 search "blessed" (type fast `b`,`l`,`e`,`s`,`s`,`e`,`d`)
   - should return 12+ items
2. 🔎 clear search (`Ctrl+A` then `Backspace`)
   - alternatively `/script d(FurC_SearchBox:Clear())`
   - should return 6365+ items

## Scenario 4: Filter Base Items

Check filter performance.

Prerequisites: ❌clearAll,DB3️⃣,DB2️⃣,DB1️⃣

1. 🔎 filter "Source: Purchasable Gold"
2. 🔎 filter "Version: Elsweyr"
3. 🔎 clear filter "Version"
4. 🔎 filter "Source: Craftable: Known"

## Scenario 5: Filter all Items (includes 👑📰)

Check if the filters make a difference in filter performance.

Prerequisites: ❌clearAll,DB3️⃣,DB2️⃣,DB1️⃣

1. 🔎 filter "Source: Purchasable Gold"
2. 🔎 filter "Version: Elsweyr"
3. 🔎 clear filter "Version"
4. 🔎 filter "Source: Craftable: Known"

## Scenario 6: Caching Efficiency Test

Test the performance of searching for the same item multiple times to check for caching improvements (See [Baseline Search Scenario](#scenario-2-baseline-search)).

Prerequisites: ❌clearAll

1. 🔎 search "blessed" (type fast `b`,`l`,`e`,`s`,`s`,`e`,`d`)
   - should return 3+ items
2. 🔎 clear search (`Ctrl+A` then `Backspace`)
   - should return 4746+ items
3. 🔎 search "blessed" (type fast `b`,`l`,`e`,`s`,`s`,`e`,`d`)
   - should return 3+ items
