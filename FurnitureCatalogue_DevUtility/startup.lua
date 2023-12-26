FurCDev = {}

local this = FurCDev

local control = FurCDevControl

this.name = "FurnitureCatalogue_DevUtility"
this.control = control
this.textbox = FurCDevControlBox

function this.ToggleEditBox()
  control:SetHidden(not control:IsHidden())
end

local function init(_, addonName)
  if addonName ~= this.name then
    return
  end

  SLASH_COMMANDS["/furcdev"] = function()
    this.ToggleEditBox()
  end

  if sidTools then
    SLASH_COMMANDS["/dumpfurniture"] = FurCDev.DumpFurniture
  end

  this.textbox = FurCDevControlBox
  this.textbox:SetMaxInputChars(3000)
  this.InitRightclickMenu()

  EVENT_MANAGER:UnregisterForEvent(FurCDev.name, EVENT_ADD_ON_LOADED)
end

function FurnitureCatalogueDevUtility_AddToTextbox()
  FurCDevControl_HandleInventoryContextMenu(moc())
end

ZO_CreateStringId("SI_BINDING_NAME_FURCDEV_TOGGLE_TEXTBOX", "Toggle |cFF3333FurCDev|r text box")
EVENT_MANAGER:RegisterForEvent(this.name, EVENT_ADD_ON_LOADED, init)
