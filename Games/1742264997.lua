return function()
    loadstring(game:HttpGet(Repo .. "Modules/Loader.lua"))()

    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local UserInputService = game:GetService("UserInputService")
    local RunService = game:GetService("RunService")
    local Camera = workspace.CurrentCamera

    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()

    local Remotes = ReplicatedStorage:WaitForChild("Remotes")
    local ShootRemote = Remotes:WaitForChild("RemoteEvent")

    local Window = Library:CreateWindow({
        Title = "Swift - SCP Roleplay",
        Folder = "Swift_SCP",
        Size = UDim2.fromOffset(550, 460),
        ToggleKey = Enum.KeyCode.RightShift,
    })

    local AimbotTab = Window:NewTab("Aimbot")
    local ESPTab = Window:NewTab("ESP")
    local SettingsTab = Window:NewTab("Settings")

    local Config = {
        SilentAim = false,
        AimPart = "HumanoidRootPart",
        TargetPart = "HumanoidRootPart",
        TeamCheck = false,
        WallCheck = false,
        FOV = 150,
        ShowFOV = false,

        ESPEnabled = false,
        ESPBoxes = false,
        ESPNames = false,
        ESPHealth = false,
        ESPDistance = false,
        ESPTracers = false,
        ESPColor = Color3.fromRGB(255, 255, 255),
        ESPMaxDistance = 1000,

        Whitelist = {},
        PriorityTarget = nil,
    }

    local Connections = {}
    local ESPObjects = {}
    local FOVCircle = Drawing.new("Circle")
    FOVCircle.Thickness = 1
    FOVCircle.NumSides = 60
    FOVCircle.Radius = Config.FOV
    FOVCircle.Filled = false
    FOVCircle.Visible = false
    FOVCircle.Color = Color3.fromRGB(255, 255, 255)
    FOVCircle.Transparency = 0.7

    local function GetCharacter()
        return LocalPlayer.Character
    end

    local function GetHumanoidRootPart()
        local Char = GetCharacter()
        return Char and Char:FindFirstChild("HumanoidRootPart")
    end

    local function IsAlive(Player)
        local Char = Player.Character
        if not Char then return false end
        local Hum = Char:FindFirstChild("Humanoid")
        return Hum and Hum.Health > 0
    end

    local function IsWhitelisted(Player)
        return Config.Whitelist[Player.UserId] == true
    end

    local function GetClosestPlayer()
        local Closest = nil
        local ShortestDist = Config.FOV

        for _, Player in ipairs(Players:GetPlayers()) do
            if Player == LocalPlayer then continue end
            if not IsAlive(Player) then continue end
            if Config.TeamCheck and Player.Team == LocalPlayer.Team then continue end
            if IsWhitelisted(Player) then continue end

            local Char = Player.Character
            local Root = Char:FindFirstChild(Config.TargetPart)
            if not Root then continue end

            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
            if not OnScreen then continue end

            if Config.WallCheck then
                local Origin = Camera.CFrame.Position
                local Direction = (Root.Position - Origin).Unit * 1000
                local RayParams = RaycastParams.new()
                RayParams.FilterType = Enum.RaycastFilterType.Exclude
                RayParams.FilterDescendantsInstances = {GetCharacter()}
                local Result = workspace:Raycast(Origin, Direction, RayParams)
                if Result and not Result.Instance:IsDescendantOf(Char) then
                    continue
                end
            end

            local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
            if Dist < ShortestDist then
                ShortestDist = Dist
                Closest = Player
            end
        end

        return Closest
    end

    local function GetTargetPosition()
        if Config.PriorityTarget and IsAlive(Config.PriorityTarget) then
            local Char = Config.PriorityTarget.Character
            local Part = Char:FindFirstChild(Config.AimPart)
            if Part then return Part.Position end
        end

        local Target = GetClosestPlayer()
        if not Target then return nil end

        local Char = Target.Character
        local Part = Char:FindFirstChild(Config.AimPart)
        return Part and Part.Position
    end

    local function HookRemote()
        local OldNamecall
        OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            local Method = getnamecallmethod()
            local Args = {...}

            if Method == "FireServer" and self == ShootRemote and Config.SilentAim then
                local TargetPos = GetTargetPosition()
                if TargetPos then
                    Args[1] = {
                        {TargetPos.X, TargetPos.Y, TargetPos.Z},
                        Args[1][2]
                    }
                    return OldNamecall(self, unpack(Args))
                end
            end

            return OldNamecall(self, ...)
        end))
    end

    local function CreateESP(Player)
        if ESPObjects[Player] then return end

        local ESP = {}

        ESP.Box = Drawing.new("Square")
        ESP.Box.Thickness = 1
        ESP.Box.Filled = false
        ESP.Box.Visible = false

        ESP.Name = Drawing.new("Text")
        ESP.Name.Size = 14
        ESP.Name.Center = true
        ESP.Name.Outline = true
        ESP.Name.Visible = false

        ESP.Health = Drawing.new("Text")
        ESP.Health.Size = 12
        ESP.Health.Center = true
        ESP.Health.Outline = true
        ESP.Health.Visible = false

        ESP.Distance = Drawing.new("Text")
        ESP.Distance.Size = 12
        ESP.Distance.Center = true
        ESP.Distance.Outline = true
        ESP.Distance.Visible = false

        ESP.Tracer = Drawing.new("Line")
        ESP.Tracer.Thickness = 1
        ESP.Tracer.Visible = false

        ESPObjects[Player] = ESP
    end

    local function RemoveESP(Player)
        if ESPObjects[Player] then
            for _, Obj in pairs(ESPObjects[Player]) do
                pcall(function() Obj:Remove() end)
            end
            ESPObjects[Player] = nil
        end
    end

    local function UpdateESP()
        if not Config.ESPEnabled then
            for _, ESP in pairs(ESPObjects) do
                for _, Obj in pairs(ESP) do
                    pcall(function() Obj.Visible = false end)
                end
            end
            return
        end

        for _, Player in ipairs(Players:GetPlayers()) do
            if Player == LocalPlayer then continue end

            if not ESPObjects[Player] then
                CreateESP(Player)
            end

            local ESP = ESPObjects[Player]
            local Char = Player.Character
            local Root = Char and Char:FindFirstChild("HumanoidRootPart")
            local Hum = Char and Char:FindFirstChild("Humanoid")

            if Root and Hum and Hum.Health > 0 then
                local Pos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
                local MyRoot = GetHumanoidRootPart()

                if OnScreen and MyRoot then
                    local Dist = (Root.Position - MyRoot.Position).Magnitude

                    if Dist <= Config.ESPMaxDistance then
                        local Head = Char:FindFirstChild("Head")
                        local HeadPos = Head and Camera:WorldToViewportPoint(Head.Position + Vector3.new(0, 0.5, 0))
                        local LegPos = Camera:WorldToViewportPoint(Root.Position - Vector3.new(0, 3, 0))

                        if HeadPos and LegPos then
                            local Height = math.abs(HeadPos.Y - LegPos.Y)
                            local Width = Height / 2
                            local BoxPos = Vector2.new(Pos.X - Width / 2, Pos.Y - Height / 2)

                            if Config.ESPBoxes then
                                ESP.Box.Size = Vector2.new(Width, Height)
                                ESP.Box.Position = BoxPos
                                ESP.Box.Color = Config.ESPColor
                                ESP.Box.Visible = true
                            else
                                ESP.Box.Visible = false
                            end

                            if Config.ESPNames then
                                ESP.Name.Text = Player.DisplayName
                                ESP.Name.Position = Vector2.new(Pos.X, BoxPos.Y - 16)
                                ESP.Name.Color = Config.ESPColor
                                ESP.Name.Visible = true
                            else
                                ESP.Name.Visible = false
                            end

                            if Config.ESPHealth then
                                local HealthPct = Hum.Health / Hum.MaxHealth
                                ESP.Health.Text = math.floor(Hum.Health)
                                ESP.Health.Position = Vector2.new(Pos.X, BoxPos.Y + Height + 2)
                                ESP.Health.Color = Color3.fromRGB(255 * (1 - HealthPct), 255 * HealthPct, 0)
                                ESP.Health.Visible = true
                            else
                                ESP.Health.Visible = false
                            end

                            if Config.ESPDistance then
                                ESP.Distance.Text = math.floor(Dist) .. "m"
                                ESP.Distance.Position = Vector2.new(Pos.X, BoxPos.Y + Height + 14)
                                ESP.Distance.Color = Config.ESPColor
                                ESP.Distance.Visible = true
                            else
                                ESP.Distance.Visible = false
                            end

                            if Config.ESPTracers then
                                ESP.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                                ESP.Tracer.To = Vector2.new(Pos.X, Pos.Y)
                                ESP.Tracer.Color = Config.ESPColor
                                ESP.Tracer.Visible = true
                            else
                                ESP.Tracer.Visible = false
                            end
                        else
                            for _, Obj in pairs(ESP) do
                                pcall(function() Obj.Visible = false end)
                            end
                        end
                    else
                        for _, Obj in pairs(ESP) do
                            pcall(function() Obj.Visible = false end)
                        end
                    end
                else
                    for _, Obj in pairs(ESP) do
                        pcall(function() Obj.Visible = false end)
                    end
                end
            else
                for _, Obj in pairs(ESP) do
                    pcall(function() Obj.Visible = false end)
                end
            end
        end
    end

    local function CleanupESP()
        for Player, ESP in pairs(ESPObjects) do
            RemoveESP(Player)
        end
        ESPObjects = {}
    end

    local AimSection = AimbotTab:NewSection("Silent Aim")
    AimSection:NewToggle("Enabled", "Enable silent aim", function(Value)
        Config.SilentAim = Value
    end)
    AimSection:NewDropdown("Aim Part", "Where to aim", {"HumanoidRootPart", "Head", "Torso"}, function(Value)
        Config.AimPart = Value
    end)
    AimSection:NewDropdown("Target Part", "Part to lock onto", {"HumanoidRootPart", "Head", "Torso"}, function(Value)
        Config.TargetPart = Value
    end)
    AimSection:NewSlider("FOV", "Field of view for targeting", 500, 150, function(Value)
        Config.FOV = Value
        FOVCircle.Radius = Value
    end)
    AimSection:NewToggle("Show FOV", "Show FOV circle", function(Value)
        Config.ShowFOV = Value
        FOVCircle.Visible = Value
    end)
    AimSection:NewToggle("Team Check", "Ignore teammates", function(Value)
        Config.TeamCheck = Value
    end)
    AimSection:NewToggle("Wall Check", "Check line of sight", function(Value)
        Config.WallCheck = Value
    end)

    local TargetSection = AimbotTab:NewSection("Custom Targeting")
    TargetSection:NewDropdown("Priority Target", "Target specific player", {}, function(Value)
        for _, Player in ipairs(Players:GetPlayers()) do
            if Player.DisplayName == Value then
                Config.PriorityTarget = Player
                break
            end
        end
    end)
    TargetSection:NewButton("Clear Priority", "Remove priority target", function()
        Config.PriorityTarget = nil
    end)
    TargetSection:NewToggle("Whitelist Mode", "Whitelist players to ignore", function(Value)
        Config.WhitelistMode = Value
    end)
    TargetSection:NewButton("Whitelist Closest", "Whitelist nearest player", function()
        local Target = GetClosestPlayer()
        if Target then
            Config.Whitelist[Target.UserId] = true
            Library:Notify({Title = "Swift", Description = "Whitelisted " .. Target.DisplayName, Time = 2})
        end
    end)
    TargetSection:NewButton("Clear Whitelist", "Remove all whitelisted players", function()
        Config.Whitelist = {}
        Library:Notify({Title = "Swift", Description = "Whitelist cleared!", Time = 2})
    end)

    local ESPSection = ESPTab:NewSection("ESP Settings")
    ESPSection:NewToggle("Enabled", "Enable ESP", function(Value)
        Config.ESPEnabled = Value
        if not Value then
            CleanupESP()
        end
    end)
    ESPSection:NewToggle("Boxes", "Show boxes", function(Value)
        Config.ESPBoxes = Value
    end)
    ESPSection:NewToggle("Names", "Show names", function(Value)
        Config.ESPNames = Value
    end)
    ESPSection:NewToggle("Health", "Show health", function(Value)
        Config.ESPHealth = Value
    end)
    ESPSection:NewToggle("Distance", "Show distance", function(Value)
        Config.ESPDistance = Value
    end)
    ESPSection:NewToggle("Tracers", "Show tracers", function(Value)
        Config.ESPTracers = Value
    end)
    ESPSection:NewSlider("Max Distance", "Maximum ESP distance", 2000, 1000, function(Value)
        Config.ESPMaxDistance = Value
    end)

    local function UpdatePriorityDropdown()
        local Names = {}
        for _, Player in ipairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer then
                table.insert(Names, Player.DisplayName)
            end
        end
        -- refresh dropdown if supported
    end

    local function Init()
        pcall(HookRemote)

        Connections.ESP = RunService.RenderStepped:Connect(UpdateESP)

        Connections.PlayerAdded = Players.PlayerAdded:Connect(function(Player)
            CreateESP(Player)
            UpdatePriorityDropdown()
        end)

        Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(Player)
            RemoveESP(Player)
            Config.Whitelist[Player.UserId] = nil
            if Config.PriorityTarget == Player then
                Config.PriorityTarget = nil
            end
        end)

        for _, Player in ipairs(Players:GetPlayers()) do
            if Player ~= LocalPlayer then
                CreateESP(Player)
            end
        end
    end

    Init()
end
