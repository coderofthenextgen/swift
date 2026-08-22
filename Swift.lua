Repo = "https://raw.githubusercontent.com/coderofthenextgen/Swift/main/"
local UniverseId = game.GameId

Library = loadstring(game:HttpGet(Repo .. "Modules/Dependencies.lua"))()

local Success, Script = pcall(function()
    return loadstring(game:HttpGet(Repo .. "Games/" .. UniverseId .. ".lua"))()
end)

if Success and Script then
    Script()
else
    Library:Notify({Title = "Swift", Description = "Script not found for this game! (ID: " .. UniverseId .. ")", Time = 5})
    task.wait(5)
end
