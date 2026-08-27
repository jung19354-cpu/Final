-- ==========================================
-- DOORS AUTO-FARM SCRIPT (OHNE BIBLIOTHEKEN)
-- KOMPLETT EIGENSTÄNDIG - KEINE EXTERNEN LOADS
-- ==========================================

print("🚀 Lade Doors Auto-Farm Script (ohne Bibliotheken)...")

-- ==========================================
-- 1. VARIABLEN
-- ==========================================
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")
local lighting = game:GetService("Lighting")

-- Globale Status-Variablen
getgenv().Godmode = false
getgenv().InfiniteJump = false
getgenv().Noclip = false
getgenv().FlyMode = false
getgenv().AutoFarmRooms = false
getgenv().Walkspeed = 16
getgenv().ESPEnabled = false

-- ==========================================
-- 2. GUI ERSTELLEN (OHNE BIBLIOTHEK)
-- ==========================================

-- Haupt-ScreenGui erstellen
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsAutoFarmGUI"
screenGui.Parent = player.PlayerGui

-- Hintergrund-Frame
local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 450)
mainFrame.Position = UDim2.new(0, 10, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BackgroundTransparency = 0.2
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Titel
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.Position = UDim2.new(0, 0, 0, 0)
title.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
title.BackgroundTransparency = 0.5
title.Text = "🔥 DOORS AUTO-FARM"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

-- Close-Button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Parent = mainFrame

-- Scroll-Frame für Buttons
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -45)
scrollFrame.Position = UDim2.new(0, 5, 0, 40)
scrollFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 4
scrollFrame.Parent = mainFrame

-- UIListLayout für Buttons
local uiList = Instance.new("UIListLayout")
uiList.Padding = UDim.new(0, 4)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Parent = scrollFrame

-- ==========================================
-- 3. FUNKTION: BUTTON ERSTELLEN
-- ==========================================
local function createButton(text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 80)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.Parent = scrollFrame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ==========================================
-- 4. FUNKTION: TOGGLE BUTTON ERSTELLEN
-- ==========================================
local function createToggle(text, color, getVal, setVal)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 80)
    btn.Text = text .. " ❌"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.Parent = scrollFrame
    
    btn.MouseButton1Click:Connect(function()
        local newVal = not getVal()
        setVal(newVal)
        if newVal then
            btn.Text = text .. " ✅"
            btn.BackgroundColor3 = Color3.fromRGB(50, 180, 50)
        else
            btn.Text = text .. " ❌"
            btn.BackgroundColor3 = color or Color3.fromRGB(60, 60, 80)
        end
    end)
    return btn
end

-- ==========================================
-- 5. BUTTONS ERSTELLEN
-- ==========================================

-- GODMODE
createToggle("🛡️ Godmode", Color3.fromRGB(80, 60, 120),
    function() return getgenv().Godmode end,
    function(v) 
        getgenv().Godmode = v
        if v then
            spawn(function()
                while getgenv().Godmode do
                    wait(0.1)
                    local char = player.Character
                    if char and char:FindFirstChild("Humanoid") then
                        char.Humanoid.Health = 100
                        char.Humanoid.MaxHealth = 100
                    end
                end
            end)
        end
    end
)

-- INFINITE JUMP
createToggle("🦘 Unendlicher Sprung", Color3.fromRGB(60, 120, 80),
    function() return getgenv().InfiniteJump end,
    function(v)
        getgenv().InfiniteJump = v
        if v then
            userInputService.JumpRequest:Connect(function()
                if getgenv().InfiniteJump then
                    local char = player.Character
                    if char and char:FindFirstChild("Humanoid") then
                        char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end
    end
)

-- NOCLIP
createToggle("🌀 Noclip", Color3.fromRGB(60, 80, 140),
    function() return getgenv().Noclip end,
    function(v)
        getgenv().Noclip = v
        if v then
            spawn(function()
                while getgenv().Noclip do
                    wait(0.1)
                    local char = player.Character
                    if char then
                        for _, part in pairs(char:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
    end
)

-- FLY MODE
createToggle("✈️ Flugmodus (F)", Color3.fromRGB(80, 120, 180),
    function() return getgenv().FlyMode end,
    function(v)
        getgenv().FlyMode = v
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.PlatformStand = v
        end
        if v then
            userInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.KeyCode == Enum.KeyCode.F then
                    getgenv().FlyMode = not getgenv().FlyMode
                    local char = player.Character
                    if char and char:FindFirstChild("Humanoid") then
                        char.Humanoid.PlatformStand = getgenv().FlyMode
                    end
                end
            end)
        end
    end
)

-- AUTO ROOMS
createToggle("🚪 Auto Rooms", Color3.fromRGB(180, 120, 60),
    function() return getgenv().AutoFarmRooms end,
    function(v)
        getgenv().AutoFarmRooms = v
        if v then
            spawn(function()
                while getgenv().AutoFarmRooms do
                    wait(0.3)
                    -- Türen öffnen
                    for _, door in pairs(game.Workspace:GetDescendants()) do
                        if door.Name == "Door" and door:IsA("Model") then
                            local handle = door:FindFirstChild("Handle")
                            if handle and handle:IsA("BasePart") then
                                local remote = door:FindFirstChild("Open")
                                if remote then
                                    remote:FireServer()
                                end
                            end
                        end
                        if door.Name == "Button" or door.Name == "Switch" then
                            local prompt = door:FindFirstChild("ProximityPrompt")
                            if prompt then
                                prompt:FireServer()
                            end
                        end
                    end
                end
            end)
        end
    end
)

-- ==========================================
-- 6. SPEED SLIDER (MANUELL)
-- ==========================================
local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(1, -10, 0, 50)
speedFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
speedFrame.BackgroundTransparency = 0.5
speedFrame.Parent = scrollFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.7, 0, 0, 25)
speedLabel.Position = UDim2.new(0, 5, 0, 0)
speedLabel.Text = "🏃 Speed: 16"
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.SourceSans
speedLabel.Parent = speedFrame

local speedBtnUp = Instance.new("TextButton")
speedBtnUp.Size = UDim2.new(0, 30, 0, 25)
speedBtnUp.Position = UDim2.new(0.75, 0, 0, 0)
speedBtnUp.Text = "+"
speedBtnUp.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBtnUp.TextScaled = true
speedBtnUp.Font = Enum.Font.SourceSansBold
speedBtnUp.BackgroundColor3 = Color3.fromRGB(60, 120, 60)
speedBtnUp.Parent = speedFrame

local speedBtnDown = Instance.new("TextButton")
speedBtnDown.Size = UDim2.new(0, 30, 0, 25)
speedBtnDown.Position = UDim2.new(0.88, 0, 0, 0)
speedBtnDown.Text = "-"
speedBtnDown.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBtnDown.TextScaled = true
speedBtnDown.Font = Enum.Font.SourceSansBold
speedBtnDown.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
speedBtnDown.Parent = speedFrame

speedBtnUp.MouseButton1Click:Connect(function()
    getgenv().Walkspeed = math.min(getgenv().Walkspeed + 5, 250)
    speedLabel.Text = "🏃 Speed: " .. getgenv().Walkspeed
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = getgenv().Walkspeed
    end
end)

speedBtnDown.MouseButton1Click:Connect(function()
    getgenv().Walkspeed = math.max(getgenv().Walkspeed - 5, 16)
    speedLabel.Text = "🏃 Speed: " .. getgenv().Walkspeed
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.WalkSpeed = getgenv().Walkspeed
    end
end)

-- ==========================================
-- 7. WEITERE BUTTONS
-- ==========================================

-- VOLLHELLIGKEIT
createToggle("💡 Vollhelligkeit", Color3.fromRGB(80, 80, 60),
    function() return getgenv().FullBright end,
    function(v)
        getgenv().FullBright = v
        if v then
            lighting.Brightness = 10
            lighting.Ambient = Color3.fromRGB(255, 255, 255)
            lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        else
            lighting.Brightness = 2
            lighting.Ambient = Color3.fromRGB(0, 0, 0)
            lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
        end
    end
)

-- NEBEL ENTFERNEN
createToggle("🌫️ Nebel entfernen", Color3.fromRGB(60, 80, 80),
    function() return getgenv().NoFog end,
    function(v)
        getgenv().NoFog = v
        if v then
            lighting.FogEnd = 10000
        else
            lighting.FogEnd = 100
        end
    end
)

-- MAUS ANZEIGEN
createButton("🖱️ Maus anzeigen", Color3.fromRGB(80, 80, 120), function()
    userInputService.MouseIconEnabled = true
end)

-- WIEDERBELEBEN
createButton("💀 Wiederbeleben", Color3.fromRGB(120, 60, 60), function()
    local char = player.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Health = 100
        char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end
end)

-- TELEPORT ZU TÜR
createButton("🚪 Zu Tür teleport", Color3.fromRGB(60, 80, 120), function()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    for _, door in pairs(game.Workspace:GetDescendants()) do
        if door.Name == "Door" and door:IsA("Model") then
            local handle = door:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                root.CFrame = handle.CFrame + Vector3.new(0, 2, 3)
                break
            end
        end
    end
end)

-- CANVAS GRÖSSE AKTUALISIEREN
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y + 20)
uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y + 20)
end)

-- ==========================================
-- 8. CLOSE BUTTON
-- ==========================================
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- ==========================================
-- 9. DRAG & DROP (Verschieben)
-- ==========================================
local dragging = false
local dragStartX, dragStartY
local framePosX, framePosY

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStartX = input.Position.X
        dragStartY = input.Position.Y
        framePosX = mainFrame.Position.X.Offset
        framePosY = mainFrame.Position.Y.Offset
    end
end)

mainFrame.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

userInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local deltaX = input.Position.X - dragStartX
        local deltaY = input.Position.Y - dragStartY
        mainFrame.Position = UDim2.new(0, framePosX + deltaX, 0, framePosY + deltaY)
    end
end)

-- ==========================================
-- 10. START-MELDUNG
-- ==========================================
print("✅ Doors Auto-Farm Script geladen!")
print("📌 GUI ist jetzt sichtbar!")
