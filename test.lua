-- ==========================================
-- DOORS AUTO-PLAY V7 (FINAL - AGENT-BASIERT)
-- ==========================================

print("🚀 Lade Doors Auto-Play V7 (Agent-basiert)...")

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local userInputService = game:GetService("UserInputService")
local lighting = game:GetService("Lighting")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")

-- ==========================================
-- STATUS-VARIABLEN
-- ==========================================
getgenv().AutoPlay = false
getgenv().AutoCollect = false
getgenv().AutoOpenDoors = false
getgenv().Godmode = false
getgenv().Noclip = false
getgenv().FlyMode = false
getgenv().InfiniteJump = false
getgenv().Walkspeed = 20
getgenv().FullBright = false
getgenv().NoFog = false
getgenv().AutoHeal = false

-- ==========================================
-- SPIEL-OBJEKTE (aus Agent-Bericht)
-- ==========================================
local gameData = replicatedStorage:FindFirstChild("GameData")
local latestRoom = gameData and gameData:FindFirstChild("LatestRoom")
local currentRooms = workspace:FindFirstChild("CurrentRooms")

if not gameData or not latestRoom or not currentRooms then
    print("❌ Kritische Spiel-Objekte nicht gefunden!")
    print("   GameData:", gameData)
    print("   LatestRoom:", latestRoom)
    print("   CurrentRooms:", currentRooms)
    return
end

print("✅ Spiel-Objekte gefunden!")
print("   LatestRoom:", latestRoom.Value)
print("   CurrentRooms:", currentRooms)

-- ==========================================
-- FORTSCHRITTS-TRACKING
-- ==========================================
local visitedRooms = {}
local currentRoomNumber = 0
local isProcessing = false

-- ==========================================
-- HELFER-FUNKTIONEN (basierend auf Agent-Bericht)
-- ==========================================

-- Aktuelle Raum-Nummer
local function getCurrentRoom()
    if latestRoom then
        return latestRoom.Value
    end
    return nil
end

-- Raum-Container holen
local function getRoomContainer(roomNum)
    if not roomNum then return nil end
    return currentRooms:FindFirstChild(tostring(roomNum))
end

-- Tür im Raum finden (Agent: workspace.CurrentRooms[RoomNumber]:WaitForChild("Door"))
local function findDoorInRoom(room)
    if not room then return nil end
    return room:FindFirstChild("Door")
end

-- Prüfen, ob Tür geöffnet ist
local function isDoorOpen(door)
    if not door then return false end
    -- Versuche verschiedene Attribute
    local opened = door:GetAttribute("Opened")
    if opened == true then return true end
    local isOpen = door:GetAttribute("IsOpen")
    if isOpen == true then return true end
    return false
end

-- Schlüssel im Raum finden (Agent: KeyObtain)
local function findKeysInRoom(room)
    local keys = {}
    if not room then return keys end
    for _, obj in pairs(room:GetDescendants()) do
        if obj.Name == "KeyObtain" or obj.Name == "Key" or obj.Name == "KeyPart" then
            table.insert(keys, obj)
        end
    end
    return keys
end

-- Knobs im Raum finden (Agent: Knob)
local function findKnobsInRoom(room)
    local knobs = {}
    if not room then return knobs end
    for _, obj in pairs(room:GetDescendants()) do
        if obj.Name == "Knob" or obj.Name == "KnobPart" or obj.Name == "Money" then
            table.insert(knobs, obj)
        end
    end
    return knobs
end

-- Teleport zu Position
local function teleportTo(position)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and position then
        root.CFrame = CFrame.new(position)
    end
end

-- ==========================================
-- INTERAKTION (aus Agent-Bericht: ProximityPrompt:FireServer())
-- ==========================================

-- "E" gedrückt halten simulieren
local function holdE(target, duration)
    if not target then return false end
    
    -- ProximityPrompt finden (am Target oder am Handle)
    local prompt = target:FindFirstChild("ProximityPrompt")
    if not prompt then
        local handle = target:FindFirstChild("Handle")
        if handle then
            prompt = handle:FindFirstChild("ProximityPrompt")
        end
    end
    
    if not prompt then
        print("   ❌ Kein ProximityPrompt gefunden!")
        return false
    end
    
    duration = duration or 1.5
    local startTime = tick()
    
    print("   🔑 Halte E für " .. duration .. "s...")
    
    -- Wiederholt feuern, um "gedrückt halten" zu simulieren
    repeat
        prompt:FireServer()
        wait(0.05)
    until tick() - startTime > duration
    
    -- Loslassen
    prompt:FireServer()
    
    print("   ✅ Interaktion abgeschlossen!")
    return true
end

-- Gegenstand aufheben (kurzer Klick)
local function collectItem(item)
    if not item then return false end
    
    -- Prüfen, ob Item noch existiert
    if not item.Parent then
        print("   ❌ Item existiert nicht mehr!")
        return false
    end
    
    -- Position für Teleport finden
    local pos = item:IsA("BasePart") and item.Position or 
                (item:FindFirstChild("Handle") and item.Handle.Position) or
                (item.PrimaryPart and item.PrimaryPart.Position)
    
    if pos then
        teleportTo(pos + Vector3.new(0, 1, 0))
        wait(0.2)
    end
    
    -- ProximityPrompt finden
    local prompt = item:FindFirstChild("ProximityPrompt")
    if not prompt then
        print("   ❌ Kein Prompt gefunden!")
        return false
    end
    
    -- Kurz klicken
    prompt:FireServer()
    wait(0.2)
    prompt:FireServer()
    
    print("   ✅ Item eingesammelt!")
    return true
end

-- Tür öffnen (mit "E" halten)
local function openDoor(door)
    if not door then return false end
    
    -- Prüfen, ob Tür schon offen ist
    if isDoorOpen(door) then
        print("   🚪 Tür ist schon offen!")
        return true
    end
    
    print("   🚪 Öffne Tür...")
    
    -- Handle für Position finden
    local handle = door:FindFirstChild("Handle")
    if handle then
        -- Zur Tür teleportieren
        teleportTo(handle.Position + Vector3.new(0, 0, 4))
        wait(0.3)
    end
    
    -- "E" gedrückt halten
    local success = holdE(door, 1.5)
    
    if success then
        -- Warten, bis Tür offen ist
        print("   ⏳ Warte auf Tür-Öffnung...")
        local timeout = 15
        local startTime = tick()
        repeat
            wait(0.2)
            if isDoorOpen(door) then
                print("   ✅ Tür geöffnet! (nach " .. math.floor(tick() - startTime) .. "s)")
                return true
            end
            if tick() - startTime > timeout then
                print("   ⏰ Timeout! Tür öffnet nicht.")
                return false
            end
        until false
    end
    
    return false
end

-- ==========================================
-- RAUM VERARBEITEN
-- ==========================================
local function processRoom(roomNum)
    if isProcessing then return end
    if visitedRooms[roomNum] then 
        print("⏭️ Raum " .. roomNum .. " wurde schon bearbeitet.")
        return 
    end
    
    isProcessing = true
    
    print("\n" .. string.rep("=", 50))
    print("🏠 VERARBEITE RAUM " .. roomNum)
    print(string.rep("=", 50))
    
    -- Charakter aktualisieren
    char = player.Character
    if not char then 
        print("   ❌ Kein Charakter! Lade neu...")
        player:LoadCharacter()
        wait(2)
        char = player.Character
        if not char then 
            isProcessing = false
            return 
        end
    end
    
    humanoid = char:FindFirstChild("Humanoid")
    if not humanoid then 
        isProcessing = false
        return 
    end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then 
        isProcessing = false
        return 
    end
    
    -- Godmode
    if getgenv().Godmode then
        humanoid.Health = 100
        humanoid.MaxHealth = 100
    end
    
    -- Auto-Heal
    if getgenv().AutoHeal and humanoid.Health < 80 then
        humanoid.Health = 100
        print("   💚 Auto-Heal aktiviert!")
    end
    
    -- Noclip
    if getgenv().Noclip then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- Geschwindigkeit
    humanoid.WalkSpeed = getgenv().Walkspeed
    
    -- Raum-Container holen
    local room = getRoomContainer(roomNum)
    if not room then
        print("   ❌ Raum-Container nicht gefunden!")
        isProcessing = false
        return
    end
    
    -- ==========================================
    -- 1. AUTO-COLLECT (Schlüssel & Knobs)
    -- ==========================================
    if getgenv().AutoCollect then
        -- Schlüssel finden und einsammeln
        local keys = findKeysInRoom(room)
        for _, key in pairs(keys) do
            print("   🔑 Schlüssel gefunden!")
            if collectItem(key) then
                print("   ✅ Schlüssel eingesammelt!")
                wait(0.3)
                break -- Nur 1 Schlüssel pro Raum
            end
        end
        
        -- Knobs finden und einsammeln
        local knobs = findKnobsInRoom(room)
        for _, knob in pairs(knobs) do
            print("   💰 Knob gefunden!")
            if collectItem(knob) then
                print("   ✅ Knob eingesammelt!")
                wait(0.3)
                break -- Nur 1 Knob pro Raum
            end
        end
    end
    
    -- ==========================================
    -- 2. AUTO-OPEN-DOORS
    -- ==========================================
    if getgenv().AutoOpenDoors then
        local door = findDoorInRoom(room)
        if door then
            -- Tür öffnen
            local opened = openDoor(door)
            
            if opened then
                -- Durch die Tür gehen (vorwärts!)
                local handle = door:FindFirstChild("Handle")
                if handle then
                    -- In Laufrichtung vor die Tür
                    local forward = root.CFrame.LookVector
                    teleportTo(handle.Position + forward * 6)
                    wait(0.3)
                    
                    -- Raum als besucht markieren
                    visitedRooms[roomNum] = true
                    currentRoomNumber = roomNum
                    print("   ✅ Raum " .. roomNum .. " abgeschlossen!")
                end
            end
        else
            print("   ❌ Keine Tür in diesem Raum!")
            -- Trotzdem als besucht markieren, damit wir nicht feststecken
            visitedRooms[roomNum] = true
        end
    else
        -- Wenn Auto-Open-Doors deaktiviert ist, trotzdem markieren
        visitedRooms[roomNum] = true
    end
    
    isProcessing = false
    print(string.rep("=", 50))
end

-- ==========================================
-- RAUM-LISTENER (Agent: LatestRoom.Changed)
-- ==========================================
local autoPlayRunning = false

local function startAutoPlay()
    if autoPlayRunning then return end
    if not getgenv().AutoPlay then return end
    
    autoPlayRunning = true
    print("🔄 Auto-Play V7 gestartet!")
    print("📌 Warte auf Raum-Änderungen...")
    
    local connection
    connection = latestRoom:GetPropertyChangedSignal("Value"):Connect(function()
        if not getgenv().AutoPlay then 
            if connection then connection:Disconnect() end
            autoPlayRunning = false
            return 
        end
        
        local roomNum = getCurrentRoom()
        if not roomNum then return end
        
        -- Nur verarbeiten, wenn nicht schon bearbeitet
        if not visitedRooms[roomNum] and not isProcessing then
            processRoom(roomNum)
        end
    end)
    
    -- Aktuellen Raum sofort verarbeiten
    wait(1)
    local roomNum = getCurrentRoom()
    if roomNum and not visitedRooms[roomNum] then
        processRoom(roomNum)
    end
end

-- ==========================================
-- GUI ERSTELLEN
-- ==========================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsAutoPlayV7"
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 500)
mainFrame.Position = UDim2.new(0, 10, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.BackgroundTransparency = 0.15
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
title.Text = "🤖 AUTO-PLAY V7 (FINAL)"
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

createButton("📊 Fortschritt anzeigen", Color3.fromRGB(130, 130, 50), function()
    print("\n📊 FORTSCHRITT:")
    local sorted = {}
    for k in pairs(visitedRooms) do
        table.insert(sorted, k)
    end
    table.sort(sorted)
    print("   Abgeschlossene Räume:", #sorted)
    if #sorted > 0 then
        print("   Letzter Raum:", sorted[#sorted])
        print("   Nächster Raum:", sorted[#sorted] + 1)
    else
        print("   Noch keine Räume besucht.")
    end
    print("   Aktueller Raum:", getCurrentRoom())
end)

createButton("🔄 Fortschritt zurücksetzen", Color3.fromRGB(130, 50, 50), function()
    visitedRooms = {}
    currentRoomNumber = 0
    print("🔄 Fortschritt zurückgesetzt!")
end)

-- Canvas
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y + 20)
uiList:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, uiList.AbsoluteContentSize.Y + 20)
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    getgenv().AutoPlay = false
    autoPlayRunning = false
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

print("✅ Doors Auto-Play V7 geladen!")
print("📌 Agent-basiert - verwendet korrekte Objektnamen!")
print("📌 Tür-Öffnung mit 'E' halten Simulation!")
print("📌 Raum-Fortschritt wird verfolgt!")
print("📌 Aktiviere Auto-Play für Vollautomatik!")
