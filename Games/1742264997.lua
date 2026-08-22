return function()
    local Players = game:GetService("Players")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local Camera = workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()
    local Remotes = ReplicatedStorage:WaitForChild("Remotes")

    local Window = Library:CreateWindow({
        Title = "Swift - SCP Roleplay",
        Folder = "Swift_SCP",
        Size = UDim2.fromOffset(700, 500),
        ToggleKeybind = Enum.KeyCode.RightShift,
    })

    local AimbotTab = Window:AddTab("Aimbot", "crosshair")
    local PlayerTab = Window:AddTab("Player", "user")
    local ESPTab = Window:AddTab("ESP", "eye")
    local SettingsTab = Window:AddTab("Settings", "settings")

    local AimGroup = AimbotTab:AddGroupbox({Name = "Silent Aim"})
    local TargetGroup = AimbotTab:AddGroupbox({Name = "Custom Targeting"})
    local PlayerGroup = PlayerTab:AddGroupbox({Name = "Movement"})
    local ESPGroup = ESPTab:AddGroupbox({Name = "ESP"})
    local SettingsGroup = SettingsTab:AddGroupbox({Name = "General"})

    local Config = {
        SilentAim = false,
        AimPart = "HumanoidRootPart",
        TargetPart = "HumanoidRootPart",
        TeamCheck = false,
        WallCheck = false,
        FOV = 300,
        ShowFOV = false,
        ESPEnabled = false,
        ESPBoxes = false,
        ESPNames = false,
        ESPHealth = false,
        ESPDistance = false,
        ESPTracers = false,
        ESPColor = Color3.fromRGB(255, 255, 255),
        ESPMaxDistance = 1000,
        ESPTeamColor = false,
        SpeedEnabled = false,
        SpeedValue = 16,
        JumpEnabled = false,
        JumpValue = 50,
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

    local function IsAlive(Plr)
        local Char = Plr.Character
        if not Char then return false end
        local Hum = Char:FindFirstChild("Humanoid")
        return Hum and Hum.Health > 0
    end

    local function IsWhitelisted(Plr)
        return Config.Whitelist[Plr.UserId] == true
    end

    local function IsVisible(Part, Origin)
        local Char = GetCharacter()
        if not (Char and Part) then return false, nil end
        local RayParams = RaycastParams.new()
        RayParams.FilterType = Enum.RaycastFilterType.Exclude
        RayParams.FilterDescendantsInstances = {Char}
        RayParams.IgnoreWater = true
        local Dir = Part.Position - Origin
        local Result = workspace:Raycast(Origin, Dir, RayParams)
        if not Result then return true, nil end
        if Result.Instance:IsDescendantOf(Part.Parent) then
            return true, Result.Instance
        end
        return false, Result.Instance
    end

    local function IsSameTeam(Plr)
        if not Config.TeamCheck then return false end
        return LocalPlayer.Team and Plr.Team and LocalPlayer.Team == Plr.Team
    end

    local function GetTarget(Origin)
        if not Config.SilentAim then return nil end
        local ClosestPart = nil
        local ClosestDist = Config.FOV

        for _, Plr in ipairs(Players:GetPlayers()) do
            if Plr == LocalPlayer then continue end
            if IsSameTeam(Plr) then continue end
            if IsWhitelisted(Plr) then continue end

            local Char = Plr.Character
            if not Char then continue end
            if Char:FindFirstChildOfClass("ForceField") then continue end
            local Hum = Char:FindFirstChild("Humanoid")
            if not Hum or Hum.Health <= 0 then continue end

            local TargetRoot = Char:FindFirstChild(Config.TargetPart) or Char.PrimaryPart
            if not TargetRoot then continue end

            local Pos, OnScreen = Camera:WorldToViewportPoint(TargetRoot.Position)
            if not OnScreen then continue end

            if Config.WallCheck then
                local Visible, HitPart = IsVisible(TargetRoot, Origin)
                if not Visible then
                    local HRP = Char:FindFirstChild("HumanoidRootPart")
                    if HRP then
                        Visible, HitPart = IsVisible(HRP, Origin)
                    end
                    if not Visible then continue end
                end
                if HitPart then TargetRoot = HitPart end
            end

            local Dist = (Vector2.new(Pos.X, Pos.Y) - UserInputService:GetMouseLocation()).Magnitude
            if Dist < ClosestDist then
                ClosestPart = TargetRoot
                ClosestDist = Dist
            end
        end

        return ClosestPart
    end

    local Controller = LocalPlayer.PlayerScripts:FindFirstChild("Controller")
    if not Controller then
        Library:Notify({Title = "Swift", Description = "Controller not found!", Time = 5})
        return
    end

    local ControllerEnv = getsenv(Controller)
    if not ControllerEnv or not ControllerEnv.BulletHit then
        Library:Notify({Title = "Swift", Description = "BulletHit not found!", Time = 5})
        return
    end

    local OldBulletHit
    OldBulletHit = hookfunction(ControllerEnv.BulletHit, newcclosure(function(Args1, Args2, ...)
        local Origin = Camera.CFrame.Position
        local Target = GetTarget(Origin)
        if Target then
            return OldBulletHit(Args1, {
                ["Instance"] = Target,
                ["Position"] = Target.Position,
                ["Normal"] = Vector3.new(0, 1, 0),
                ["Material"] = Target.Material,
            }, ...)
        end
        return OldBulletHit(Args1, Args2, ...)
    end))

    local function UpdateVelocity()
        local Char = GetCharacter()
        if not Char then return end
        local HRP = Char:FindFirstChild("HumanoidRootPart")
        local Hum = Char:FindFirstChild("Humanoid")
        if not HRP or not Hum then return end

        if Config.SpeedEnabled then
            local MoveDir = Hum.MoveDirection
            if MoveDir.Magnitude > 0 then
                HRP.Velocity = Vector3.new(MoveDir.X * Config.SpeedValue, HRP.Velocity.Y, MoveDir.Z * Config.SpeedValue)
            end
        end

        if Config.JumpEnabled then
            if Hum:GetState() == Enum.HumanoidStateType.Jumping or Hum:GetState() == Enum.HumanoidStateType.Freefall then
                if HRP.Velocity.Y < Config.JumpValue and HRP.Velocity.Y > 0 then
                    HRP.Velocity = Vector3.new(HRP.Velocity.X, Config.JumpValue, HRP.Velocity.Z)
                end
            end
        end
    end

    local function GetClosestPlayer()
        local Closest = nil
        local ShortestDist = Config.FOV
        for _, Plr in ipairs(Players:GetPlayers()) do
            if Plr == LocalPlayer then continue end
            if IsSameTeam(Plr) then continue end
            if IsWhitelisted(Plr) then continue end
            if not IsAlive(Plr) then continue end
            local Char = Plr.Character
            local Root = Char and Char:FindFirstChild(Config.TargetPart)
            if not Root then continue end
            local ScreenPos, OnScreen = Camera:WorldToViewportPoint(Root.Position)
            if not OnScreen then continue end
            local Dist = (Vector2.new(ScreenPos.X, ScreenPos.Y) - UserInputService:GetMouseLocation()).Magnitude
            if Dist < ShortestDist then
                ShortestDist = Dist
                Closest = Plr
            end
        end
        return Closest
    end

    local function CreateESP(Plr)
        if ESPObjects[Plr] then return end
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
        ESPObjects[Plr] = ESP
    end

    local function RemoveESP(Plr)
        if ESPObjects[Plr] then
            for _, Obj in pairs(ESPObjects[Plr]) do
                pcall(function() Obj:Remove() end)
            end
            ESPObjects[Plr] = nil
        end
    end

    local function UpdateESP()
        FOVCircle.Position = UserInputService:GetMouseLocation()
        FOVCircle.Radius = Config.FOV
        if not Config.ESPEnabled then
            for _, ESP in pairs(ESPObjects) do
                for _, Obj in pairs(ESP) do
                    pcall(function() Obj.Visible = false end)
                end
            end
            return
        end
        for _, Plr in ipairs(Players:GetPlayers()) do
            if Plr == LocalPlayer then continue end
            if not ESPObjects[Plr] then
                CreateESP(Plr)
            end
            local ESP = ESPObjects[Plr]
            local Char = Plr.Character
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
                            local ESPColor = Config.ESPColor
                            if Config.ESPTeamColor and Plr.Team and Plr.Team.TeamColor then
                                ESPColor = Plr.Team.TeamColor.Color
                            end
                            if Config.ESPBoxes then
                                ESP.Box.Size = Vector2.new(Width, Height)
                                ESP.Box.Position = BoxPos
                                ESP.Box.Color = ESPColor
                                ESP.Box.Visible = true
                            else
                                ESP.Box.Visible = false
                            end
                            if Config.ESPNames then
                                ESP.Name.Text = Plr.DisplayName
                                ESP.Name.Position = Vector2.new(Pos.X, BoxPos.Y - 16)
                                ESP.Name.Color = ESPColor
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
                                ESP.Tracer.Color = ESPColor
                                ESP.Tracer.Visible = true
                            else
                                ESP.Tracer.Visible = false
                            end
                        else
                            for _, Obj in pairs(ESP) do pcall(function() Obj.Visible = false end) end
                        end
                    else
                        for _, Obj in pairs(ESP) do pcall(function() Obj.Visible = false end) end
                    end
                else
                    for _, Obj in pairs(ESP) do pcall(function() Obj.Visible = false end) end
                end
            else
                for _, Obj in pairs(ESP) do pcall(function() Obj.Visible = false end) end
            end
        end
    end

    local function CleanupESP()
        for Plr, _ in pairs(ESPObjects) do
            RemoveESP(Plr)
        end
        ESPObjects = {}
    end

    AimGroup:AddToggle("SilentAim", {
        Text = "Silent Aim",
        Default = false,
        Callback = function(Value) Config.SilentAim = Value end,
    })

    AimGroup:AddDropdown("AimPart", {
        Text = "Aim Part",
        Values = {"HumanoidRootPart", "Head", "Torso"},
        Default = "HumanoidRootPart",
        Callback = function(Value) Config.AimPart = Value end,
    })

    AimGroup:AddSlider("FOVSlider", {
        Text = "FOV Size",
        Default = 300,
        Min = 50,
        Max = 800,
        Rounding = 0,
        Callback = function(Value) Config.FOV = Value FOVCircle.Radius = Value end,
    })

    AimGroup:AddToggle("ShowFOV", {
        Text = "Show FOV Circle",
        Default = false,
        Callback = function(Value) Config.ShowFOV = Value FOVCircle.Visible = Value end,
    })

    AimGroup:AddToggle("TeamCheck", {
        Text = "Team Check",
        Default = false,
        Callback = function(Value) Config.TeamCheck = Value end,
    })

    AimGroup:AddToggle("WallCheck", {
        Text = "Wall Check",
        Default = true,
        Callback = function(Value) Config.WallCheck = Value end,
    })

    TargetGroup:AddDropdown("TargetPart", {
        Text = "Lock Part",
        Values = {"HumanoidRootPart", "Head", "Torso"},
        Default = "HumanoidRootPart",
        Callback = function(Value) Config.TargetPart = Value end,
    })

    TargetGroup:AddDropdown("PriorityTarget", {
        Text = "Priority Target",
        Values = (function()
            local Names = {}
            for _, P in ipairs(Players:GetPlayers()) do
                if P ~= LocalPlayer then table.insert(Names, P.DisplayName) end
            end
            return Names
        end)(),
        Default = "",
        Callback = function(Value)
            for _, P in ipairs(Players:GetPlayers()) do
                if P.DisplayName == Value then
                    Config.PriorityTarget = P
                    break
                end
            end
        end,
    })

    TargetGroup:AddButton({Text = "Clear Priority", Func = function() Config.PriorityTarget = nil end})

    TargetGroup:AddButton({
        Text = "Whitelist Closest",
        Func = function()
            local Target = GetClosestPlayer()
            if Target then
                Config.Whitelist[Target.UserId] = true
                Library:Notify({Title = "Swift", Description = "Whitelisted " .. Target.DisplayName, Time = 2})
            end
        end,
    })

    TargetGroup:AddButton({
        Text = "Clear Whitelist",
        Func = function()
            Config.Whitelist = {}
            Library:Notify({Title = "Swift", Description = "Whitelist cleared!", Time = 2})
        end,
    })

    ESPGroup:AddToggle("ESPEnabled", {
        Text = "Enable ESP",
        Default = false,
        Callback = function(Value) Config.ESPEnabled = Value if not Value then CleanupESP() end end,
    })

    ESPGroup:AddToggle("ESPBoxes", {
        Text = "Boxes",
        Default = false,
        Callback = function(Value) Config.ESPBoxes = Value end,
    })

    ESPGroup:AddToggle("ESPNames", {
        Text = "Names",
        Default = false,
        Callback = function(Value) Config.ESPNames = Value end,
    })

    ESPGroup:AddToggle("ESPHealth", {
        Text = "Health",
        Default = false,
        Callback = function(Value) Config.ESPHealth = Value end,
    })

    ESPGroup:AddToggle("ESPDistance", {
        Text = "Distance",
        Default = false,
        Callback = function(Value) Config.ESPDistance = Value end,
    })

    ESPGroup:AddToggle("ESPTracers", {
        Text = "Tracers",
        Default = false,
        Callback = function(Value) Config.ESPTracers = Value end,
    })

    ESPGroup:AddSlider("ESPMaxDist", {
        Text = "Max Distance",
        Default = 1000,
        Min = 100,
        Max = 2000,
        Rounding = 0,
        Callback = function(Value) Config.ESPMaxDistance = Value end,
    })

    ESPGroup:AddToggle("ESPTeamColor", {
        Text = "Team Color",
        Default = false,
        Callback = function(Value) Config.ESPTeamColor = Value end,
    })

    PlayerGroup:AddToggle("SpeedEnabled", {
        Text = "Velocity Speed",
        Default = false,
        Callback = function(Value) Config.SpeedEnabled = Value end,
    })

    PlayerGroup:AddSlider("SpeedValue", {
        Text = "Speed",
        Default = 16,
        Min = 16,
        Max = 200,
        Rounding = 0,
        Callback = function(Value) Config.SpeedValue = Value end,
    })

    PlayerGroup:AddToggle("JumpEnabled", {
        Text = "Velocity Jump",
        Default = false,
        Callback = function(Value) Config.JumpEnabled = Value end,
    })

    PlayerGroup:AddSlider("JumpValue", {
        Text = "Jump Power",
        Default = 50,
        Min = 50,
        Max = 200,
        Rounding = 0,
        Callback = function(Value) Config.JumpValue = Value end,
    })

    SettingsGroup:AddButton({
        Text = "Destroy UI",
        Func = function()
            CleanupESP()
            Library:Unload()
        end,
    })

    Connections.ESP = RunService.RenderStepped:Connect(function()
        UpdateESP()
        UpdateVelocity()
    end)

    Connections.PlayerAdded = Players.PlayerAdded:Connect(function(Plr)
        CreateESP(Plr)
    end)

    Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(Plr)
        RemoveESP(Plr)
        Config.Whitelist[Plr.UserId] = nil
        if Config.PriorityTarget == Plr then
            Config.PriorityTarget = nil
        end
    end)

    for _, Plr in ipairs(Players:GetPlayers()) do
        if Plr ~= LocalPlayer then
            CreateESP(Plr)
        end
    end
end
