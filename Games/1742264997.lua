return function()
    loadstring(game:HttpGet(Repo .. "Modules/Loader.lua"))()

    local Window = Library:CreateWindow({
        Title = "Swift - SCP Roleplay",
        Folder = "Swift",
        Size = UDim2.fromOffset(550, 460),
        ToggleKey = Enum.KeyCode.RightShift,
    })

    local MainTab = Window:NewTab("Main")
    local FarmGroup = MainTab:NewSection("Farm")

    FarmGroup:NewToggle("AutoFarm", "Automatically farm resources", function(Value)
        getgenv().SwiftAutoFarm = Value
    end)

    FarmGroup:NewButton("Teleport to SCP", "Teleport to nearest SCP", function()
        -- teleport logic
    end)

    local PlayerTab = Window:NewTab("Player")
    local PlayerGroup = PlayerTab:NewSection("Player")

    PlayerGroup:NewSlider("WalkSpeed", "Change walk speed", 500, 16, function(Value)
        game.Players.LocalPlayer.Character.Humanoid.WalkSpeed = Value
    end)

    PlayerGroup:NewSlider("JumpPower", "Change jump power", 500, 50, function(Value)
        game.Players.LocalPlayer.Character.Humanoid.JumpPower = Value
    end)

    PlayerGroup:NewToggle("Noclip", "Walk through walls", function(Value)
        getgenv().SwiftNoclip = Value
    end)

    local SettingsTab = Window:NewTab("Settings")
    Window:NewSection("Settings")
end
