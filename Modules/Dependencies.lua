local function SafeLoad(Name, Url)
    local Success, Result = pcall(function()
        return loadstring(game:HttpGet(Url))()
    end)
    if Success and Result then
        return Result
    else
        warn("[Swift] Failed to load " .. Name .. ": " .. tostring(Result))
        return nil
    end
end

Library = SafeLoad("Library", "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua")
SaveManager = SafeLoad("SaveManager", "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/SaveManager.lua")
ThemeManager = SafeLoad("ThemeManager", "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/ThemeManager.lua")

if SaveManager then SaveManager:SetLibrary(Library) end
if ThemeManager then ThemeManager:SetLibrary(Library) end
