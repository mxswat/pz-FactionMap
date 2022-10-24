local function onServerReceiveGlobalModData(module, packet)
    if not string.find(module, "FactionMap_") or module == "FactionMap_None" then
        return
    end

    if not packet then
        return
    end

    ModData.add(module, packet)

    if not isServer() then
        return
    end

    ModData.transmit(module)
end

Events.OnReceiveGlobalModData.Add(onServerReceiveGlobalModData);
