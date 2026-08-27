-- ==========================================
-- DOORS AUTO-PLAY SKRIPT (VOLLAUTOMATIK)
-- KEINE BIBLIOTHEKEN - KEINE EXTERNEN LOADS
-- ==========================================

print("🚀 Lade Doors Auto-Play Script...")

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local userInputService = game:GetService("UserInputService")
local runService = game:GetService("RunService")
local lighting = game:GetService("Lighting")
local tweenService = game:GetService("TweenService")

-- ==========================================
-- STATUS-VARIABLEN
-- ==========================================
getgenv().AutoPlay = false
getgenv().AutoCollect = false
getgenv().AutoOpenDoors = false
getgenv().AutoRooms = false
getgenv().Godmode = false
getgenv().Noclip = false
getgenv().FlyMode = false
getgenv().InfiniteJump = false
getgenv().Walkspeed = 20
getgenv().FullBright = false
getgenv().NoFog = false
getgenv().AutoHeal = false

-- ==========================================
-- HELFER-FUNKTIONEN
-- ==========================================

-- Nächste Tür finden
local function findNearestDoor()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearest = nil
    local nearestDist = math.huge
    for _, obj in pairs(game.Workspace:GetDescendants()) do
        if obj.Name == "Door" and obj:IsA("Model") then
            local handle = obj:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                local dist = (root.Position - handle.Position).Magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = obj
                end
            end
        end
    end
    return nearest
end

-- Nächsten Schlüssel finden
local function findNearestKey()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearest = nil
    local nearestDist = math.huge
    for _, obj in pairs(game.Workspace:GetDescendants()) do
        if obj.Name == "Key" and obj:IsA("BasePart") and obj.Parent ~= char then
            local dist = (root.Position - obj.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = obj
            end
        end
    end
    return nearest
end

-- Nächsten Knob (Geld) finden
local function findNearestKnob()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearest = nil
    local nearestDist = math.huge
    for _, obj in pairs(game.Workspace:GetDescendants()) do
        if obj.Name == "Knob" and obj:IsA("BasePart") and obj.Parent ~= char then
            local dist = (root.Position - obj.Position).Magnitude
            if dist < nearestDist then
                nearestDist = dist
                nearest = obj
            end
        end
    end
    return nearest
end

-- Teleport zu Position
local function teleportTo(position)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root then
        root.CFrame = CFrame.new(position)
    end
end

-- Tür öffnen (Remote-Event)
local function openDoor(door)
    if not door then return end
    local remote = door:FindFirstChild("Open")
    if remote then
        remote:FireServer()
    end
    local handle = door:FindFirstChild("Handle")
    if handle then
        -- ProximityPrompt versuchen
        local prompt = handle:FindFirstChild("ProximityPrompt")
        if prompt then
            prompt:FireServer()
        end
    end
end

-- Gegenstand aufheben
local function collectItem(item)
    if not item then return end
    local prompt = item:FindFirstChild("ProximityPrompt")
    if prompt then
        prompt:FireServer()
    end
    -- Falls es ein Remote-Event ist
    local collect = item:FindFirstChild("Collect")
    if collect then
        collect:FireServer()
    end
end

-- ==========================================
-- AUTO-PLAY HAUPTLOGIK
-- ==========================================
local function startAutoPlay()
    if not getgenv().AutoPlay then return end
    
    spawn(function()
        while getgenv().AutoPlay do
            wait(0.3)
            
            -- GODMODE (falls aktiv)
            if getgenv().Godmode then
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.Health = 100
                    char.Humanoid.MaxHealth = 100
                end
            end
            
            -- AUTO-HEAL
            if getgenv().AutoHeal then
                if char and char:FindFirstChild("Humanoid") then
                    if char.Humanoid.Health < 80 then
                        char.Humanoid.Health = 100
                    end
                end
            end
            
            -- NOCLIP (falls aktiv)
            if getgenv().Noclip then
                if char then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end
            end
            
            -- GESCHWINDIGKEIT
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.WalkSpeed = getgenv().Walkspeed
            end
            
            -- 1. SCHLÜSSEL SAMMELN (Priorität 1)
            if getgenv().AutoCollect then
                local key = findNearestKey()
                if key then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (root.Position - key.Position).Magnitude
                        if dist < 50 then
                            -- Teleport zum Schlüssel
                            root.CFrame = key.CFrame + Vector3.new(0, 1, 0)
                            wait(0.1)
                            collectItem(key)
                            wait(0.2)
                        end
                    end
                end
                
                -- 2. KNOBS SAMMELN
                local knob = findNearestKnob()
                if knob then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local dist = (root.Position - knob.Position).Magnitude
                        if dist < 50 then
                            root.CFrame = knob.CFrame + Vector3.new(0, 1, 0)
                            wait(0.1)
                            collectItem(knob)
                            wait(0.2)
                        end
                    end
                end
            end
            
            -- 3. TÜREN ÖFFNEN
            if getgenv().AutoOpenDoors or getgenv().AutoRooms then
                local door = findNearestDoor()
                if door then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        local handle = door:FindFirstChild("Handle")
                        if handle then
                            local dist = (root.Position - handle.Position).Magnitude
                            -- Wenn Tür in der Nähe, öffnen
                            if dist < 30 then
                                openDoor(door)
                                -- Zur Tür laufen
                                root.CFrame = handle.CFrame + Vector3.new(0, 0, 5)
                                wait(0.2)
                            elseif dist < 200 then
                                -- Zur Tür laufen
                                root.CFrame = handle.CFrame + Vector3.new(0, 0, 5)
                                wait(0.1)
                            end
                        end
                    end
                end
            end
            
            -- 4. AUTO-ROOMS (für A-1000)
            if getgenv().AutoRooms then
                -- Suche nach einem "Rooms"-Teleporter oder nächster Tür
                for _, obj in pairs(game.Workspace:GetDescendants()) do
                    if obj.Name == "Room" and obj:IsA("Model") then
                        local handle = obj:FindFirstChild("Handle")
                        if handle then
                            local root = char:FindFirstChild("HumanoidRootPart")
                            if root then
                                root.CFrame = handle.CFrame + Vector3.new(0, 0, 5)
                                wait(0.1)
                                local remote = obj:FindFirstChild("Open")
                                if remote then remote:FireServer() end
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- ==========================================
-- GUI ERSTELLEN
-- ==========================================

-- Haupt-GUI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsAutoPlayGUI"
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 500)
mainFrame.Position = UDim2.new(0, 10, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Titel
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
title.Text = "🤖 DOORS AUTO-PLAY"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Parent = mainFrame

-- Scroll
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -10, 1, -50)
scrollFrame.Position = UDim2.new(0, 5, 0, 45)
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
-- TOGGLE HELFER
-- ==========================================
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
        -- Wenn AutoPlay aktiviert wird, starte die Logik
        if text == "▶️ Auto-Play" and newVal then
            startAutoPlay()
        end
    end)
    return btn
end

local function createButton(text, color, callback)
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

-- ==========================================
-- TOGGLES ERSTELLEN
-- ==========================================

-- AUTO-PLAY (Haupttoggle)
createToggle("▶️ Auto-Play", Color3.fromRGB(200, 100, 50),
    function() return getgenv().AutoPlay end,
    function(v) getgenv().AutoPlay = v end
)

-- AUTO-COLLECT (Schlüssel & Knobs)
createToggle("🔑 Auto-Collect (Schlüssel/Geld)", Color3.fromRGB(60, 120, 60),
    function() return getgenv().AutoCollect end,
    function(v) getgenv().AutoCollect = v end
)

-- AUTO-OPEN-DOORS
createToggle("🚪 Auto-Open-Doors", Color3.fromRGB(60, 80, 140),
    function() return getgenv().AutoOpenDoors end,
    function(v) getgenv().AutoOpenDoors = v end
)

-- AUTO-ROOMS (A-1000 Farm)
createToggle("🏚️ Auto-Rooms (A-1000)", Color3.fromRGB(140, 80, 60),
    function() return getgenv().AutoRooms end,
    function(v) getgenv().AutoRooms = v end
)

-- GODMODE
createToggle("🛡️ Godmode", Color3.fromRGB(80, 50, 130),
    function() return getgenv().Godmode end,
    function(v) getgenv().Godmode = v end
)

-- AUTO-HEAL
createToggle("💚 Auto-Heal", Color3.fromRGB(60, 160, 60),
    function() return getgenv().AutoHeal end,
    function(v) getgenv().AutoHeal = v end
)

-- NOCLIP
createToggle("🌀 Noclip", Color3.fromRGB(50, 70, 150),
    function() return getgenv().Noclip end,
    function(v) getgenv().Noclip = v end
)

-- INFINITE JUMP
createToggle("🦘 Unendlicher Sprung", Color3.fromRGB(60, 130, 80),
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

-- FLY MODE
createToggle("✈️ Flugmodus (F)", Color3.fromRGB(70, 110, 180),
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

-- ==========================================
-- SPEED SLIDER
-- ==========================================
local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(1, -10, 0, 45)
speedFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
speedFrame.Parent = scrollFrame

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0.6, 0, 0, 25)
speedLabel.Position = UDim2.new(0, 5, 0, 0)
speedLabel.Text = "🏃 Speed: 20"
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
-- VISUAL TOGGLES
-- ==========================================
createToggle("💡 Vollhelligkeit", Color3.fromRGB(80, 80, 50),
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
-- BUTTONS
-- ==========================================
createButton("🖱️ Maus anzeigen", Color3.fromRGB(70, 70, 110), function()
    userInputService.MouseIconEnabled = true
end)

createButton("💀 Wiederbeleben", Color3.fromRGB(130, 50, 50), function()
    local c = player.Character
    if c and c:FindFirstChild("Humanoid") then
        c.Humanoid.Health = 100
        c.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end
end)

createButton("🚪 Zur nächsten Tür", Color3.fromRGB(50, 70, 130), function()
    local door = findNearestDoor()
    if door then
        local handle = door:FindFirstChild("Handle")
        if handle then
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                root.CFrame = handle.CFrame + Vector3.new(0, 0, 5)
            end
        end
    end
end)

createButton("📦 Schlüssel suchen", Color3.fromRGB(130, 130, 50), function()
    local key = findNearestKey()
    if key then
        local root = char:FindFirstChild("HumanoidRootPart")
        if root then
            root.CFrame = key.CFrame + Vector3.new(0, 1, 0)
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
    getgenv().AutoPlay = false
end)

-- ==========================================
-- DRAG & DROP
-- ==========================================
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

-- ==========================================
-- START-MELDUNG
-- ==========================================
print("✅ Doors Auto-Play Script geladen!")
print("📌 Aktiviere 'Auto-Play' für Vollautomatik!")
print("📌 Toggles: Auto-Collect, Auto-Open-Doors, Auto-Rooms")
