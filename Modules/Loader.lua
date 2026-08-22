local Loading = Library:CreateLoading({
    Title = "Swift",
    Icon = 155217770,
    TotalSteps = 5,
})

Loading:SetMessage("Initializing Swift...")
Loading:SetDescription("Preparing modules...")
task.wait(0.5)

Loading:SetCurrentStep(1)
Loading:SetDescription("Loading configuration...")
task.wait(0.5)

Loading:SetCurrentStep(2)
Loading:SetDescription("Setting up theme...")
task.wait(0.5)

Loading:SetCurrentStep(3)
Loading:ShowSidebarPage(true)
Loading.Sidebar:AddLabel("User: " .. game.Players.LocalPlayer.Name)
Loading.Sidebar:AddLabel("Version: v1.0.0")
Loading.Sidebar:AddLabel("Place: " .. game.PlaceId)
task.wait(0.5)

Loading:SetCurrentStep(4)
Loading:SetDescription("Loading modules...")
task.wait(0.5)

Loading:SetCurrentStep(5)
Loading:SetDescription("Ready!")
task.wait(0.3)

Loading:Continue()
