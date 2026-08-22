local Repo = "https://raw.githubusercontent.com/coderofthenextgen/Swift/main/"
local UniverseId = game.GameId

local function SafeLoad(Url)
    local Success, Result = pcall(function()
        local Code = game:HttpGet(Url)
        if Code and Code ~= "" then
            return loadstring(Code)()
        end
        return nil
    end)
    return Success and Result or nil
end

Library = SafeLoad("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua")

if not Library then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Swift",
        Text = "Failed to load Library!",
    })
    return
end

SaveManager = SafeLoad("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/SaveManager.lua")
ThemeManager = SafeLoad("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/ThemeManager.lua")

pcall(function() if SaveManager then SaveManager:SetLibrary(Library) end end)
pcall(function() if ThemeManager then ThemeManager:SetLibrary(Library) end end)

local Success, Script = pcall(function()
    local Code = game:HttpGet(Repo .. "Games/" .. UniverseId .. ".lua")
    if Code and Code ~= "" then
        return loadstring(Code)()
    end
    return nil
end)

if Success and Script then
    Script()
else
    Library:Notify({Title = "Swift", Description = "Script not found! (ID: " .. UniverseId .. ")", Time = 5})
    task.wait(5)
end
