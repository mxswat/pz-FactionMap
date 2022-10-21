local old_ISWorldMapSymbols_createChildren = ISWorldMapSymbols.createChildren
function ISWorldMapSymbols:createChildren()
    local result = old_ISWorldMapSymbols_createChildren(self)

    local FONT_HGT_SMALL = getTextManager():getFontHeight(UIFont.Small)
    local btnWid = self.width - 20 * 2
    local btnHgt = FONT_HGT_SMALL + 2 * 2
    local btnPad = 10

    local y = self.removeBtn:getBottom() + btnPad

    self.toggleFactionMapButton = ISButton:new(20, y, btnWid, btnHgt, "title", self, self.onFactionTickBoxClick)
    self.toggleFactionMapButton:initialise()
    self.toggleFactionMapButton:instantiate()
    self.toggleFactionMapButton.borderColor.a = 0.0
    self.toggleFactionMapButton.enable = false

    self:addChild(self.toggleFactionMapButton)
    self:setHeight(self.toggleFactionMapButton:getBottom() + 20)
    self:checkInventory()

    -- Patch for 2701170568\mods\ExtraMapSymbolsUI\media\lua\client\ExtraMapSymbolsUI.lua
    if self.extraUI_Refresh then
        local old_extraUI_Refresh = self.extraUI_Refresh
        self.extraUI_Refresh = function(...)
            local ret = { old_extraUI_Refresh(self, ...) }

            local y = self.removeBtn:getBottom() + btnPad
            self.toggleFactionMapButton:setY(y)
            self.toggleFactionMapButton:setX(self.removeBtn:getX())
            self.toggleFactionMapButton:setWidth(self.removeBtn:getWidth())
            self:setHeight(self.toggleFactionMapButton:getBottom() + 20)

            return unpack(ret)
        end
    end

    return result
end

local old_ISWorldMapSymbols_checkInventory = ISWorldMapSymbols.checkInventory
function ISWorldMapSymbols:checkInventory()
    local result = old_ISWorldMapSymbols_checkInventory(self)
    if not self.toggleFactionMapButton then
        return result
    end

    self.toggleFactionMapButton.enable = FactionMap:isPlayerInAFaction()

    if not FactionMap:isPlayerInAFaction() then
        local title = 'You Are Not In A Faction'
        self.toggleFactionMapButton:setTitle(title)
        return result
    end

    local playerFactionName = FactionMap:getPlayerFactionName()
    local showTitle = '"' .. playerFactionName .. '" map is [DISABLED]'
    local hideTitle = '"' .. playerFactionName .. '" map is [ENABLED]'
    self.toggleFactionMapButton:setTitle(FactionMap.isToggled and hideTitle or showTitle)

    return result
end

function ISWorldMapSymbols:onFactionTickBoxClick(index, selected)
    FactionMap:toggleFactionMap();
    self:checkInventory()
end

local old_ISWorldMap_close = ISWorldMap.close
function ISWorldMap:close()
    local result = old_ISWorldMap_close(self)

    FactionMap:storeCurrentMap()
    if FactionMap:isPlayerInAFaction() then
        -- HaloTextHelper.addTextWithArrow(self.character, 'Sending Faction Map...', true, HaloTextHelper.getColorGreen())
        FactionMap:sendFactionMapData()
        return result
    end

    return result
end

local old_ISWorldMap_ShowWorldMap = ISWorldMap.ShowWorldMap
function ISWorldMap.ShowWorldMap(playerNum)
    local result = old_ISWorldMap_ShowWorldMap(playerNum)
    local isInFaction = FactionMap:isPlayerInAFaction()

    if not ISWorldMap_instance then
        return result
    end

    local vanillaSymbols = FactionMap:getStoredVanillaSymbols()
    if not vanillaSymbols or #vanillaSymbols == 0 then
        -- If someone has installed the mod on an existing save
        -- Backup their data before doing anything
        FactionMap:storeCurrentMap();
    end

    if not FactionMap.isToggled or not isInFaction then
        FactionMap:showVanillaMap()
        return result
    end

    FactionMap:showFactionMap()
    return result
end

local old_ISWorldMap_ToggleWorldMap = ISWorldMap.ToggleWorldMap
function ISWorldMap.ToggleWorldMap(playerNum)
    local result = old_ISWorldMap_ToggleWorldMap(playerNum)
    FactionMap:requestFactionMapData()
    return result
end

local function defaultSendFactionCheck()
    FactionMap:storeCurrentMap()
    if FactionMap:isPlayerInAFaction() and FactionMap.isToggled then
        FactionMap:sendFactionMapData()
    end
end

local old_ISWorldMapSymbolTool_AddSymbol_addSymbol = ISWorldMapSymbolTool_AddSymbol.addSymbol
function ISWorldMapSymbolTool_AddSymbol:addSymbol(x, y)
    local result = old_ISWorldMapSymbolTool_AddSymbol_addSymbol(self, x, y)
    defaultSendFactionCheck()
    return result
end

local old_ISWorldMapSymbolTool_AddNote_onAddNote = ISWorldMapSymbolTool_AddNote.onAddNote
function ISWorldMapSymbolTool_AddNote:onAddNote(button, playerNum)
    local result = old_ISWorldMapSymbolTool_AddNote_onAddNote(self, button, playerNum)
    defaultSendFactionCheck()
    return result
end

local old_ISWorldMapSymbolTool_EditNote_onEditNote = ISWorldMapSymbolTool_EditNote.onEditNote
function ISWorldMapSymbolTool_EditNote:onEditNote(button, symbol)
    local result = old_ISWorldMapSymbolTool_EditNote_onEditNote(self, button, symbol)
    defaultSendFactionCheck()
    return result
end

local old_ISWorldMapSymbolTool_RemoveAnnotation_removeAnnotation = ISWorldMapSymbolTool_RemoveAnnotation.removeAnnotation
function ISWorldMapSymbolTool_RemoveAnnotation:removeAnnotation()
    local result = old_ISWorldMapSymbolTool_RemoveAnnotation_removeAnnotation(self)
    defaultSendFactionCheck()
    return result
end

local old_ISWorldMapSymbolTool_MoveAnnotation_onMouseUp = ISWorldMapSymbolTool_MoveAnnotation.onMouseUp
function ISWorldMapSymbolTool_MoveAnnotation:onMouseUp(x, y)
    local result = old_ISWorldMapSymbolTool_MoveAnnotation_onMouseUp(self, x, y)
    if result then
        defaultSendFactionCheck()
    end
    return result
end
