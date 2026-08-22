local Repo = "https://raw.githubusercontent.com/coderofthenextgen/Swift/main/"
local UniverseId = game.GameId

Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()

if not Library then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "Swift",
        Text = "Failed to load Obsidian Library!",
    })
    return
end

SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/SaveManager.lua"))()
ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/ThemeManager.lua"))()

if SaveManager then SaveManager:SetLibrary(Library) end
if ThemeManager then ThemeManager:SetLibrary(Library) end

local Success, Script = pcall(function()
    return loadstring(game:HttpGet(Repo .. "Games/" .. UniverseId .. ".lua"))()
end)

if Success and Script then
    Script()
else
    Library:Notify({Title = "Swift", Description = "Script not found for this game! (ID: " .. UniverseId .. ")", Time = 5})
    task.wait(5)
end
