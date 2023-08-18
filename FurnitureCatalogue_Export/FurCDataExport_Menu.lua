function FurCEx.makeSettings()
  local LAM = LibAddonMenu2
  local panelData = {
    type = "panel",
    name = FurCEx.name,
    displayName = "FurnitureCatalogue Export",
    author = FurCEx.author,
    version = tostring(FurCEx.version),
    registerForRefresh = true,
    registerForDefaults = true,
  }

  LAM:RegisterAddonPanel("FurnitureCatalogueExport_OptionsPanel", panelData)
  local optionsData = { -- optionsData

    { -- description
      type = "description",
      name = "FurnitureCatalogue Export",
      text = (
        "After an UI reload, FurnitureCatalogue's database can be found in your \n"
        .. "SavedVariables folder inside  FurnitureCatalogue_Export.lua \n"
      ),
    },
    { -- button: Export crafting list
      type = "button",
      name = "Export crafting data",
      warning = "This will reload the UI",
      func = function()
        FurCEx.Export()
      end,
    },
    { -- button: Dump whole database
      type = "button",
      name = "Dump whole Database",
      warning = "This will reload the UI",
      func = function()
        FurCEx.Dump()
      end,
    },
  }

  LAM:RegisterOptionControls("FurnitureCatalogueExport_OptionsPanel", optionsData)
end
