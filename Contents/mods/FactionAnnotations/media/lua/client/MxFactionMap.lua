FactionMap = {
    isToggled = false
}

function FactionMap:isPlayerInAFaction()
    return Faction.getPlayerFaction(getPlayer()) ~= nil
end

function FactionMap:getPlayerFactionName()
    local playerFaction = Faction.getPlayerFaction(getPlayer())
    local playerFactionName = playerFaction and playerFaction:getName() or nil
    return playerFactionName
end

function FactionMap:getPlayerFactionId()
    return self:getPlayerFactionName()
        and "FactionMap_" .. self:getPlayerFactionName()
        or "FactionMap_None"
end

function FactionMap:storeCurrentMap()
    local mapSymbols = self:getCurrentMapSymbols()
    if self.isToggled then
        return ModData.add(self:getPlayerFactionId(), mapSymbols)
    end
    -- Is faction map backup vanilla
    return ModData.add("FactionMap_VanillaBackup", mapSymbols)
end

function FactionMap:getStoredVanillaSymbols()
    return ModData.getOrCreate("FactionMap_VanillaBackup")
end

function FactionMap:getStoredFactionSymbols()
    return ModData.getOrCreate(self:getPlayerFactionId())
end

function FactionMap:setFactionData(symbols)
    return ModData.add(self:getPlayerFactionId(), symbols)
end

function FactionMap:getSymbolsApi()
    return ISWorldMap_instance.javaObject:getAPIv1():getSymbolsAPI()
end

function FactionMap:wipeCurrentMap()
    local symbolApi = self:getSymbolsApi();
    symbolApi:clear();
end

function FactionMap:showFactionMap()
    self:wipeCurrentMap()
    local moddata = self:getStoredFactionSymbols()
    self:injectSymbolsFromTable(moddata)
end

function FactionMap:showVanillaMap()
    self:wipeCurrentMap()
    local moddata = self:getStoredVanillaSymbols()
    self:injectSymbolsFromTable(moddata)
end

function FactionMap:toggleFactionMap()
    self.isToggled = not self.isToggled;
    local mapSymbols = self:getCurrentMapSymbols()
    if self.isToggled then
        ModData.add("FactionMap_VanillaBackup", mapSymbols)
        return self:showFactionMap()
    end
    ModData.add(self:getPlayerFactionId(), mapSymbols)
    return self:showVanillaMap()
end

function FactionMap:getCurrentMapSymbols()
    local payload = {}
    local symAPI = self:getSymbolsApi()
    local cnt = symAPI:getSymbolCount()
    for i = 0, cnt - 1 do
        local sym = symAPI:getSymbolByIndex(i)
        if sym:isVisible() then
            local s = {}
            s.x = sym:getWorldX()
            s.y = sym:getWorldY()
            s.r = sym:getRed()
            s.g = sym:getGreen()
            s.b = sym:getBlue()
            s.a = sym:getAlpha()
            if sym:isTexture() then
                s.type = "texture"
                s.texture = sym:getSymbolID()
            elseif sym:isText() then
                s.type = "text"
                s.text = sym:getTranslatedText() or sym:getUntranslatedText()
            else
                error("unknown symbol type at index " .. i)
            end

            table.insert(payload, s)
        end
    end
    return payload
end

-- I Took this function from BLTAnnotations
function FactionMap:injectSymbolsFromTable(data)
    local symbolApi = self:getSymbolsApi();
    for _, s in ipairs(data) do
        if s.type == "texture" then
            local sym = symbolApi:addTexture(s.texture, s.x, s.y)
            sym:setRGBA(s.r, s.g, s.b, s.a)
            sym:setAnchor(0.5, 0.5)
            sym:setScale(ISMap.SCALE)
        elseif s.type == "text" then
            local sym = symbolApi:addTranslatedText(s.text, UIFont.Handwritten, s.x, s.y)
            sym:setRGBA(s.r, s.g, s.b, s.a)
            sym:setAnchor(0.0, 0.0)
            sym:setScale(ISMap.SCALE)
        else
            error("unknown type found in payload " .. (s.type or "nil"))
        end

        if s.visited then
            local offset = 5
            WorldMapVisited.getInstance():setKnownInSquares(
                s.x - offset, s.y - offset, s.x + offset, s.y + offset
            )
        end
    end
end

-- [[ NETWORKING ]] --

function FactionMap:sendFactionMapData()
    ModData.transmit(self:getPlayerFactionId())
end

function FactionMap:requestFactionMapData()
    ModData.request(self:getPlayerFactionId())
end

local function onReceiveGlobalModData(module, packet)
    if not string.find(module, "FactionMap_")
        or module == "FactionMap_None"
        or not packet then
        return
    end

    local factionName = string.gsub(module, "FactionMap_", "")
    if factionName ~= FactionMap:getPlayerFactionName() then
        return
    end

    FactionMap:setFactionData(packet);

    if not ISWorldMap_instance or not FactionMap.isToggled then
        return
    end

    FactionMap:wipeCurrentMap()
    local moddata = FactionMap:getStoredFactionSymbols()
    FactionMap:injectSymbolsFromTable(moddata)
end

Events.OnReceiveGlobalModData.Add(onReceiveGlobalModData);

local function onLoad()
    FactionMap:requestFactionMapData()
end

Events.OnLoad.Add(onLoad);
