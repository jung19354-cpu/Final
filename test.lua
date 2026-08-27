-- ==========================================
-- DOORS AUTO-PLAY V2 (VERBESSERTE LOGIK)
-- KEINE BIBLIOTHEKEN - KEINE EXTERNEN LOADS
-- ==========================================

print("🚀 Lade Doors Auto-Play V2...")

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local userInputService = game:GetService("UserInputService")
local lighting = game:GetService("Lighting")
local runService = game:GetService("RunService")

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
-- VERBESSERTE SUCH-FUNKTIONEN
-- ==========================================

-- Alle Objekte im Spiel finden
local function getAllObjects()
    local objects = {}
    for _, obj in pairs(game.Workspace:GetDescendants()) do
        table.insert(objects, obj)
    end
    return objects
end

-- Nächste Tür finden (verbessert)
local function findNearestDoor()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearest = nil
    local nearestDist = math.huge
    
    for _, obj in pairs(getAllObjects()) do
        -- Verschiedene mögliche Tür-Namen
        if obj.Name == "Door" or obj.Name == "DoorModel" or obj.Name == "DoorHandle" or obj.Name == "DoorPart" then
            if obj:IsA("Model") or obj:IsA("BasePart") then
                local pos = obj:IsA("Model") and (obj:FindFirstChild("Handle") and obj.Handle.Position or obj.PrimaryPart and obj.PrimaryPart.Position) or obj.Position
                if pos then
                    local dist = (root.Position - pos).Magnitude
                    if dist < nearestDist and dist > 1 then
                        nearestDist = dist
                        nearest = obj
                    end
                end
            end
        end
    end
    return nearest, nearestDist
end

-- Nächsten Schlüssel finden (verbessert)
local function findNearestKey()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearest = nil
    local nearestDist = math.huge
    
    for _, obj in pairs(getAllObjects()) do
        if obj.Name == "Key" or obj.Name == "KeyPart" or obj.Name == "KeyModel" then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local pos = obj:IsA("Model") and (obj:FindFirstChild("Handle") and obj.Handle.Position or obj.PrimaryPart and obj.PrimaryPart.Position) or obj.Position
                if pos and obj.Parent ~= char then
                    local dist = (root.Position - pos).Magnitude
                    if dist < nearestDist and dist > 1 then
                        nearestDist = dist
                        nearest = obj
                    end
                end
            end
        end
    end
    return nearest, nearestDist
end

-- Nächsten Knob finden (verbessert)
local function findNearestKnob()
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return nil end
    local nearest = nil
    local nearestDist = math.huge
    
    for _, obj in pairs(getAllObjects()) do
        if obj.Name == "Knob" or obj.Name == "KnobPart" or obj.Name == "Money" then
            if obj:IsA("BasePart") or obj:IsA("Model") then
                local pos = obj:IsA("Model") and (obj:FindFirstChild("Handle") and obj.Handle.Position or obj.PrimaryPart and obj.PrimaryPart.Position) or obj.Position
                if pos and obj.Parent ~= char then
                    local dist = (root.Position - pos).Magnitude
                    if dist < nearestDist and dist > 1 then
                        nearestDist = dist
                        nearest = obj
                    end
                end
            end
        end
    end
    return nearest, nearestDist
end

-- ==========================================
-- TELEPORT & INTERAKTION
-- ==========================================

-- Teleport zu Position
local function teleportTo(position)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and position then
        root.CFrame = CFrame.new(position)
    end
end

-- Tür öffnen (verbessert)
local function openDoor(door)
    if not door then return end
    
    -- Versuche verschiedene Methoden
    -- 1. Remote-Event "Open"
    local remote = door:FindFirstChild("Open")
    if remote then
        remote:FireServer()
        return
    end
    
    -- 2. Remote-Event "DoorOpen"
    local remote2 = door:FindFirstChild("DoorOpen")
    if remote2 then
        remote2:FireServer()
        return
    end
    
    -- 3. ProximityPrompt an Handle
    local handle = door:FindFirstChild("Handle")
    if handle then
        local prompt = handle:FindFirstChild("ProximityPrompt")
        if prompt then
            prompt:FireServer()
            return
        end
    end
    
    -- 4. Direkt an der Tür (falls BasePart)
    if door:IsA("BasePart") then
        local prompt = door:FindFirstChild("ProximityPrompt")
        if prompt then
            prompt:FireServer()
        end
    end
end

-- Gegenstand aufheben (verbessert)
local function collectItem(item)
    if not item then return end
    
    -- Versuche verschiedene Methoden
    local prompt = item:FindFirstChild("ProximityPrompt")
    if prompt then
        prompt:FireServer()
        return
    end
    
    local collect = item:FindFirstChild("Collect")
    if collect then
        collect:FireServer()
        return
    end
    
    local pickup = item:FindFirstChild("Pickup")
    if pickup then
        pickup:FireServer()
    end
end

-- ==========================================
-- AUTO-PLAY HAUPTLOGIK (VERBESSERT)
-- ==========================================

local function startAutoPlay()
    if not getgenv().AutoPlay then return end
    
    spawn(function()
        print("🔄 Auto-Play gestartet!")
        
        while getgenv().AutoPlay do
            wait(0.5)
            
            -- Aktualisiere Charakter
            char = player.Character
            if not char then 
                wait(1)
                char = player.Character
                if not char then
                    player:LoadCharacter()
                    wait(2)
                    char = player.Character
                end
                if not char then 
                    print("❌ Kein Charakter gefunden!")
                    continue 
                end
            end
            
            humanoid = char:FindFirstChild("Humanoid")
            if not humanoid then continue end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            
            -- ==========================================
            -- 1. GODMODE
            -- ==========================================
            if getgenv().Godmode then
                humanoid.Health = 100
                humanoid.MaxHealth = 100
            end
            
            -- ==========================================
            -- 2. AUTO-HEAL
            -- ==========================================
            if getgenv().AutoHeal and humanoid.Health < 80 then
                humanoid.Health = 100
            end
            
            -- ==========================================
            -- 3. NOCLIP
            -- ==========================================
            if getgenv().Noclip then
                for _, part in pairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
            
            -- ==========================================
            -- 4. GESCHWINDIGKEIT
            -- ==========================================
            humanoid.WalkSpeed = getgenv().Walkspeed
            
            -- ==========================================
            -- 5. AUTO-COLLECT (Schlüssel & Knobs)
            -- ==========================================
            if getgenv().AutoCollect then
                -- Schlüssel suchen
                local key, keyDist = findNearestKey()
                if key and keyDist and keyDist < 60 then
                    teleportTo(key:IsA("Model") and (key:FindFirstChild("Handle") and key.Handle.Position or key.PrimaryPart and key.PrimaryPart.Position) or key.Position)
                    wait(0.15)
                    collectItem(key)
                    wait(0.2)
                    print("🔑 Schlüssel eingesammelt!")
                end
                
                -- Knobs suchen
                local knob, knobDist = findNearestKnob()
                if knob and knobDist and knobDist < 60 then
                    teleportTo(knob:IsA("Model") and (knob:FindFirstChild("Handle") and knob.Handle.Position or knob.PrimaryPart and knob.PrimaryPart.Position) or knob.Position)
                    wait(0.15)
                    collectItem(knob)
                    wait(0.2)
                    print("💰 Knob eingesammelt!")
                end
            end
            
            -- ==========================================
            -- 6. AUTO-OPEN-DOORS
            -- ==========================================
            if getgenv().AutoOpenDoors or getgenv().AutoRooms then
                local door, doorDist = findNearestDoor()
                if door and doorDist then
                    -- Wenn Tür nah, öffnen
                    if doorDist < 20 then
                        openDoor(door)
                        print("🚪 Tür geöffnet!")
                        wait(0.3)
                    end
                    
                    -- Zur Tür laufen (wenn weiter weg)
                    local doorPos = door:IsA("Model") and (door:FindFirstChild("Handle") and door.Handle.Position or door.PrimaryPart and door.PrimaryPart.Position) or door.Position
                    if doorPos then
                        teleportTo(doorPos + Vector3.new(0, 0, 5))
                        wait(0.2)
                    end
                else
                    -- Keine Tür gefunden -> etwas laufen
                    root.CFrame = root.CFrame + root.CFrame.LookVector * 5
                    wait(0.1)
                end
            end
            
            -- ==========================================
            -- 7. AUTO-ROOMS (A-1000 Farm)
            -- ==========================================
            if getgenv().AutoRooms then
                -- Suche nach Rooms-spezifischen Objekten
                for _, obj in pairs(game.Workspace:GetDescendants()) do
                    if obj.Name == "RoomDoor" or obj.Name == "Room" then
                        if obj:IsA("Model") or obj:IsA("BasePart") then
                            local pos = obj:IsA("Model") and (obj:FindFirstChild("Handle") and obj.Handle.Position or obj.PrimaryPart and obj.PrimaryPart.Position) or obj.Position
                            if pos then
                                teleportTo(pos + Vector3.new(0, 0, 3))
                                wait(0.1)
                                openDoor(obj)
                                wait(0.2)
                                break
                            end
                        end
                    end
                end
            end
        end
        
        print("⏹️ Auto-Play gestoppt!")
    end)
end

-- ==========================================
-- GUI ERSTELLEN
-- ==========================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsAutoPlayV2"
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 520)
mainFrame.Position = UDim2.new(0, 10, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
title.Text = "🤖 AUTO-PLAY V2"
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
-- TOGGLES
-- ==========================================

createToggle("▶️ Auto-Play", Color3.fromRGB(200, 100, 50),
    function() return getgenv().AutoPlay end,
    function(v) getgenv().AutoPlay = v end
)

createToggle("🔑 Auto-Collect", Color3.fromRGB(60, 120, 60),
    function() return getgenv().AutoCollect end,
    function(v) getgenv().AutoCollect = v end
)

createToggle("🚪 Auto-Open-Doors", Color3.fromRGB(60, 80, 140),
    function() return getgenv().AutoOpenDoors end,
    function(v) getgenv().AutoOpenDoors = v end
)

createToggle("🏚️ Auto-Rooms (A-1000)", Color3.fromRGB(140, 80, 60),
    function() return getgenv().AutoRooms end,
    function(v) getgenv().AutoRooms = v end
)

createToggle("🛡️ Godmode", Color3.fromRGB(80, 50, 130),
    function() return getgenv().Godmode end,
    function(v) getgenv().Godmode = v end
)

createToggle("💚 Auto-Heal", Color3.fromRGB(60, 160, 60),
    function() return getgenv().AutoHeal end,
    function(v) getgenv().AutoHeal = v end
)

createToggle("🌀 Noclip", Color3.fromRGB(50, 70, 150),
    function() return getgenv().Noclip end,
    function(v) getgenv().Noclip = v end
)

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
-- SPEED
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
-- VISUAL
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
    local door, dist = findNearestDoor()
    if door then
        local pos = door:IsA("Model") and (door:FindFirstChild("Handle") and door.Handle.Position or door.PrimaryPart and door.PrimaryPart.Position) or door.Position
        if pos then
            teleportTo(pos + Vector3.new(0, 0, 5))
        end
    end
end)

createButton("📦 Schlüssel suchen", Color3.fromRGB(130, 130, 50), function()
    local key, dist = findNearestKey()
    if key then
        local pos = key:IsA("Model") and (key:FindFirstChild("Handle") and key.Handle.Position or key.PrimaryPart and key.PrimaryPart.Position) or key.Position
        if pos then
            teleportTo(pos + Vector3.new(0, 1, 0))
        end
    end
end)

-- Canvas
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y + 20)
uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y + 20)
end)

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

print("✅ Auto-Play V2 geladen!")
print("📌 Aktiviere 'Auto-Play' für Vollautomatik!")
