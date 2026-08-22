Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Library.lua"))()

if not Library then
    warn("[Swift] Failed to load Obsidian Library")
    return
end

SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/SaveManager.lua"))()
ThemeManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/deividcomsono/Obsidian/main/ThemeManager.lua"))()

if SaveManager then SaveManager:SetLibrary(Library) end
if ThemeManager then ThemeManager:SetLibrary(Library) end

return Library
