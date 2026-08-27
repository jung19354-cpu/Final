-- ==========================================
-- DOORS AUTO-FARM SCRIPT (OHNE EXTERNE LOADS)
-- KEIN HTTPGET - KEIN LOADSTRING
-- ==========================================

print("🚀 Lade Doors Auto-Farm Script...")

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local userInputService = game:GetService("UserInputService")
local lighting = game:GetService("Lighting")

-- Status-Variablen
getgenv().Godmode = false
getgenv().InfiniteJump = false
getgenv().Noclip = false
getgenv().FlyMode = false
getgenv().AutoFarmRooms = false
getgenv().Walkspeed = 16
getgenv().FullBright = false
getgenv().NoFog = false

-- ==========================================
-- GUI ERSTELLEN
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsFarmGUI"
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 420)
mainFrame.Position = UDim2.new(0, 10, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
title.Text = "🔥 DOORS AUTO-FARM"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Parent = mainFrame

local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -45)
scrollFrame.Position = UDim2.new(0, 5, 0, 40)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 4
scrollFrame.Parent = mainFrame

local uiList = Instance.new("UIListLayout")
uiList.Padding = UDim.new(0, 4)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Parent = scrollFrame

-- ==========================================
-- BUTTON HELFER
-- ==========================================
local function createBtn(text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 70)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.Parent = scrollFrame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

local function createToggle(text, color, getVal, setVal)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = color or Color3.fromRGB(50, 50, 70)
    btn.Text = text .. " ❌"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.Parent = scrollFrame
    btn.MouseButton1Click:Connect(function()
        local newVal = not getVal()
        setVal(newVal)
        btn.Text = text .. (newVal and " ✅" or " ❌")
        btn.BackgroundColor3 = newVal and Color3.fromRGB(40, 160, 40) or (color or Color3.fromRGB(50, 50, 70))
    end)
    return btn
end

-- ==========================================
-- TOGGLES
-- ==========================================
createToggle("🛡️ Godmode", Color3.fromRGB(70, 50, 110),
    function() return getgenv().Godmode end,
    function(v)
        getgenv().Godmode = v
        if v then
            spawn(function()
                while getgenv().Godmode do
                    wait(0.1)
                    local c = player.Character
                    if c and c:FindFirstChild("Humanoid") then
                        c.Humanoid.Health = 100
                        c.Humanoid.MaxHealth = 100
                    end
                end
            end)
        end
    end
)

createToggle("🦘 Unendlicher Sprung", Color3.fromRGB(50, 110, 70),
    function() return getgenv().InfiniteJump end,
    function(v)
        getgenv().InfiniteJump = v
        if v then
            userInputService.JumpRequest:Connect(function()
                if getgenv().InfiniteJump then
                    local c = player.Character
                    if c and c:FindFirstChild("Humanoid") then
                        c.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end
    end
)

createToggle("🌀 Noclip", Color3.fromRGB(50, 70, 130),
    function() return getgenv().Noclip end,
    function(v)
        getgenv().Noclip = v
        if v then
            spawn(function()
                while getgenv().Noclip do
                    wait(0.1)
                    local c = player.Character
                    if c then
                        for _, p in pairs(c:GetDescendants()) do
                            if p:IsA("BasePart") then
                                p.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
    end
)

createToggle("✈️ Flugmodus (F)", Color3.fromRGB(70, 110, 170),
    function() return getgenv().FlyMode end,
    function(v)
        getgenv().FlyMode = v
        local c = player.Character
        if c and c:FindFirstChild("Humanoid") then
            c.Humanoid.PlatformStand = v
        end
        if v then
            userInputService.InputBegan:Connect(function(input)
                if input.KeyCode == Enum.KeyCode.F then
                    getgenv().FlyMode = not getgenv().FlyMode
                    local c = player.Character
                    if c and c:FindFirstChild("Humanoid") then
                        c.Humanoid.PlatformStand = getgenv().FlyMode
                    end
                end
            end)
        end
    end
)

createToggle("🚪 Auto Rooms", Color3.fromRGB(170, 110, 50),
    function() return getgenv().AutoFarmRooms end,
    function(v)
        getgenv().AutoFarmRooms = v
        if v then
            spawn(function()
                while getgenv().AutoFarmRooms do
                    wait(0.3)
                    for _, d in pairs(game.Workspace:GetDescendants()) do
                        if d.Name == "Door" and d:IsA("Model") then
                            local h = d:FindFirstChild("Handle")
                            if h then
                                local r = d:FindFirstChild("Open")
                                if r then r:FireServer() end
                            end
                        end
                        if d.Name == "Button" or d.Name == "Switch" then
                            local p = d:FindFirstChild("ProximityPrompt")
                            if p then p:FireServer() end
                        end
                    end
                end
            end)
        end
    end
)

createToggle("💡 Vollhelligkeit", Color3.fromRGB(70, 70, 50),
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

createToggle("🌫️ Nebel entfernen", Color3.fromRGB(50, 70, 70),
    function() return getgenv().NoFog end,
    function(v)
        getgenv().NoFog = v
        lighting.FogEnd = v and 10000 or 100
    end
)

-- ==========================================
-- SPEED
-- ==========================================
local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(1, -10, 0, 45)
speedFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
speedFrame.Parent = scrollFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.6, 0, 0, 25)
speedLabel.Position = UDim2.new(0, 5, 0, 0)
speedLabel.Text = "🏃 Speed: 16"
speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
speedLabel.TextScaled = true
speedLabel.Font = Enum.Font.SourceSans
speedLabel.Parent = speedFrame

local spUp = Instance.new("TextButton")
spUp.Size = UDim2.new(0, 28, 0, 22)
spUp.Position = UDim2.new(0.7, 0, 0, 0)
spUp.Text = "+"
spUp.TextColor3 = Color3.fromRGB(255, 255, 255)
spUp.TextScaled = true
spUp.Font = Enum.Font.SourceSansBold
spUp.BackgroundColor3 = Color3.fromRGB(50, 130, 50)
spUp.Parent = speedFrame

local spDown = Instance.new("TextButton")
spDown.Size = UDim2.new(0, 28, 0, 22)
spDown.Position = UDim2.new(0.85, 0, 0, 0)
spDown.Text = "-"
spDown.TextColor3 = Color3.fromRGB(255, 255, 255)
spDown.TextScaled = true
spDown.Font = Enum.Font.SourceSansBold
spDown.BackgroundColor3 = Color3.fromRGB(130, 50, 50)
spDown.Parent = speedFrame

spUp.MouseButton1Click:Connect(function()
    getgenv().Walkspeed = math.min(getgenv().Walkspeed + 5, 250)
    speedLabel.Text = "🏃 Speed: " .. getgenv().Walkspeed
    local c = player.Character
    if c and c:FindFirstChild("Humanoid") then
        c.Humanoid.WalkSpeed = getgenv().Walkspeed
    end
end)

spDown.MouseButton1Click:Connect(function()
    getgenv().Walkspeed = math.max(getgenv().Walkspeed - 5, 16)
    speedLabel.Text = "🏃 Speed: " .. getgenv().Walkspeed
    local c = player.Character
    if c and c:FindFirstChild("Humanoid") then
        c.Humanoid.WalkSpeed = getgenv().Walkspeed
    end
end)

-- ==========================================
-- BUTTONS
-- ==========================================
createBtn("🖱️ Maus anzeigen", Color3.fromRGB(70, 70, 110), function()
    userInputService.MouseIconEnabled = true
end)

createBtn("💀 Wiederbeleben", Color3.fromRGB(130, 50, 50), function()
    local c = player.Character
    if c and c:FindFirstChild("Humanoid") then
        c.Humanoid.Health = 100
        c.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end
end)

createBtn("🚪 Zu Tür teleport", Color3.fromRGB(50, 70, 130), function()
    local c = player.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    if not r then return end
    for _, d in pairs(game.Workspace:GetDescendants()) do
        if d.Name == "Door" and d:IsA("Model") then
            local h = d:FindFirstChild("Handle")
            if h and h:IsA("BasePart") then
                r.CFrame = h.CFrame + Vector3.new(0, 2, 3)
                break
            end
        end
    end
end)

-- Canvas aktualisieren
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y + 20)
uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y + 20)
end)

-- Close
closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
end)

-- Drag
local dragging = false
local dsx, dsy, fpx, fpy
mainFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dsx, dsy = inp.Position.X, inp.Position.Y
        fpx, fpy = mainFrame.Position.X.Offset, mainFrame.Position.Y.Offset
    end
end)
mainFrame.InputEnded:Connect(function()
    dragging = false
end)
userInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        mainFrame.Position = UDim2.new(0, fpx + inp.Position.X - dsx, 0, fpy + inp.Position.Y - dsy)
    end
end)

print("✅ Skript geladen! GUI ist sichtbar.")
