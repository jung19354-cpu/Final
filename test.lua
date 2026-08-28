-- =============================================================
-- ||   DOORS AUTO-PLAY - MIT EXAKTEN PFADEN                 ||
-- ||   BASIERT AUF RAUM-SCANNER                             ||
-- =============================================================

print("🚀 Lade DOORS Auto-Play mit exakten Pfaden...")

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =============================================================
-- SPIEL-OBJEKTE
-- =============================================================
local GameData = ReplicatedStorage:FindFirstChild("GameData")
local LatestRoom = GameData and GameData:FindFirstChild("LatestRoom")
local CurrentRooms = Workspace:FindFirstChild("CurrentRooms")

if not LatestRoom or not CurrentRooms then
    print("❌ Kritische Objekte nicht gefunden!")
    return
end

print("✅ LatestRoom: " .. tostring(LatestRoom.Value))
print("✅ CurrentRooms: " .. tostring(CurrentRooms))

-- =============================================================
-- STATUS
-- =============================================================
getgenv().AutoPlay = false
getgenv().AutoCollect = false
getgenv().AutoOpenDoors = false
getgenv().Godmode = false
getgenv().Noclip = false
getgenv().Walkspeed = 20

local visitedRooms = {}
local isProcessing = false

-- =============================================================
-- CHARAKTER
-- =============================================================
local function getChar()
    local c = player.Character
    if not c then
        pcall(function() player:LoadCharacter() end)
        task.wait(1)
        c = player.Character
    end
    return c
end

local function getHumanoid(c)
    if not c then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end

local function getRoot(c)
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

local function getCharSafe()
    local c = getChar()
    if not c then return nil, nil, nil end
    return c, getHumanoid(c), getRoot(c)
end

-- =============================================================
-- TELEPORT
-- =============================================================
local function teleportTo(pos)
    if not pos then return false end
    local c, h, root = getCharSafe()
    if not root then return false end
    pcall(function()
        root.CFrame = CFrame.new(pos)
    end)
    return true
end

-- =============================================================
-- RAUM-FUNKTIONEN
-- =============================================================
local function getRoom()
    return LatestRoom and LatestRoom.Value
end

local function getRoomContainer(num)
    if not num then return nil end
    return CurrentRooms:FindFirstChild(tostring(num))
end

-- =============================================================
-- OBJEKTE FINDEN (MIT EXAKTEN PFADEN)
-- =============================================================

-- Tür finden: CurrentRooms.[Raum].Door
local function findDoor(room)
    if not room then return nil end
    return room:FindFirstChild("Door")
end

-- Schlüssel finden: CurrentRooms.[Raum].Assets.KeyObtain
local function findKey(room)
    if not room then return nil end
    local assets = room:FindFirstChild("Assets")
    if not assets then return nil end
    return assets:FindFirstChild("KeyObtain")
end

-- Knobs finden: CurrentRooms.[Raum].Assets.Dresser.DrawerContainer.Knobs
local function findKnobs(room)
    if not room then return nil end
    local assets = room:FindFirstChild("Assets")
    if not assets then return nil end
    local dresser = assets:FindFirstChild("Dresser")
    if not dresser then return nil end
    local drawerContainer = dresser:FindFirstChild("DrawerContainer")
    if not drawerContainer then return nil end
    return drawerContainer:FindFirstChild("Knobs")
end

-- =============================================================
-- INTERAKTION (ALLE METHODEN)
-- =============================================================

-- "E" halten simulieren
local function holdE(target, duration)
    if not target then return false end
    
    local prompt = target:FindFirstChild("ProximityPrompt")
    if not prompt then
        for _, child in pairs(target:GetChildren()) do
            if child:IsA("ProximityPrompt") then
                prompt = child
                break
            end
        end
    end
    
    if not prompt then return false end
    
    duration = duration or 1.5
    local start = tick()
    repeat
        pcall(function() prompt:FireServer() end)
        task.wait(0.05)
    until tick() - start > duration
    
    pcall(function() prompt:FireServer() end)
    return true
end

-- Gegenstand aufheben
local function collectItem(item)
    if not item or not item.Parent then return false end
    
    -- Position finden
    local pos = nil
    pcall(function()
        if item:IsA("BasePart") then
            pos = item.Position
        elseif item:IsA("Model") and item:FindFirstChild("Hitbox") then
            local hitbox = item:FindFirstChild("Hitbox")
            if hitbox:IsA("BasePart") then
                pos = hitbox.Position
            end
        elseif item.PrimaryPart then
            pos = item.PrimaryPart.Position
        end
    end)
    
    if pos then
        teleportTo(pos + Vector3.new(0, 1, 0))
        task.wait(0.2)
    end
    
    -- ProximityPrompt suchen
    local success = false
    pcall(function()
        local prompt = item:FindFirstChild("ProximityPrompt")
        if not prompt then
            for _, child in pairs(item:GetChildren()) do
                if child:IsA("ProximityPrompt") then
                    prompt = child
                    break
                end
            end
        end
        if prompt then
            prompt:FireServer()
            task.wait(0.2)
            prompt:FireServer()
            success = true
        end
    end)
    
    return success
end

-- Tür öffnen
local function openDoor(door)
    if not door then return false end
    
    -- Prüfen ob Tür schon offen ist
    local isOpen = false
    pcall(function()
        isOpen = door:GetAttribute("Opened") == true
    end)
    if isOpen then
        print("   🚪 Tür schon offen!")
        return true
    end
    
    print("   🚪 Öffne Tür...")
    
    -- Position finden
    local doorPos = nil
    pcall(function()
        if door:IsA("BasePart") then
            doorPos = door.Position
        elseif door:FindFirstChild("Handle") then
            doorPos = door.Handle.Position
        elseif door.PrimaryPart then
            doorPos = door.PrimaryPart.Position
        end
    end)
    
    if doorPos then
        teleportTo(doorPos + Vector3.new(0, 0, 4))
        task.wait(0.3)
    end
    
    -- Methode 1: RemoteEvent "Open"
    local success = false
    pcall(function()
        local openEvent = door:FindFirstChild("Open")
        if openEvent and openEvent:IsA("RemoteEvent") then
            openEvent:FireServer()
            success = true
            print("   📡 RemoteEvent 'Open' gefeuert!")
        end
    end)
    
    -- Methode 2: ProximityPrompt
    if not success then
        success = holdE(door, 1.5)
        if success then
            print("   🔑 E-Halten erfolgreich!")
        end
    end
    
    -- Warten auf Tür-Öffnung
    if success then
        print("   ⏳ Warte auf Tür...")
        local timeout = 15
        local start = tick()
        repeat
            task.wait(0.2)
            local nowOpen = false
            pcall(function()
                nowOpen = door:GetAttribute("Opened") == true
            end)
            if nowOpen then
                print("   ✅ Tür geöffnet!")
                return true
            end
        until tick() - start > timeout
        print("   ⏰ Timeout!")
    end
    
    return false
end

-- =============================================================
-- RAUM VERARBEITEN
-- =============================================================
local function processRoom(roomNum)
    if isProcessing then return end
    if visitedRooms[roomNum] then return end
    if not roomNum then return end
    
    isProcessing = true
    print("\n" .. string.rep("=", 60))
    print("🏠 RAUM " .. roomNum)
    print(string.rep("=", 60))
    
    -- Charakter
    local c, h, root = getCharSafe()
    if not c or not h or not root then
        print("   ❌ Kein Charakter!")
        isProcessing = false
        return
    end
    
    -- Godmode
    if getgenv().Godmode then
        pcall(function()
            h.MaxHealth = 99999
            h.Health = 100
        end)
    end
    
    -- Noclip
    if getgenv().Noclip then
        pcall(function()
            for _, part in pairs(c:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            for _, part in pairs(Workspace:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end)
    end
    
    -- Speed
    pcall(function() h.WalkSpeed = getgenv().Walkspeed end)
    
    -- Raum holen
    local room = getRoomContainer(roomNum)
    if not room then
        print("   ❌ Raum nicht gefunden!")
        visitedRooms[roomNum] = true
        isProcessing = false
        return
    end
    
    print("   📂 Raum-Container: " .. room.Name)
    
    -- ==========================================
    -- 1. SCHLÜSSEL FINDEN & EINSAMMELN
    -- ==========================================
    if getgenv().AutoCollect then
        print("🔑 Suche Schlüssel...")
        local key = findKey(room)
        if key then
            print("   ✅ KeyObtain gefunden: " .. key.Name)
            if collectItem(key) then
                print("   ✅ Key eingesammelt!")
            else
                print("   ❌ Key konnte nicht eingesammelt werden!")
            end
        else
            print("   ❌ Kein KeyObtain in diesem Raum!")
        end
        
        -- ==========================================
        -- 2. KNOBS FINDEN & EINSAMMELN
        -- ==========================================
        print("💰 Suche Knobs...")
        local knobs = findKnobs(room)
        if knobs then
            print("   ✅ Knobs gefunden: " .. knobs.Name)
            -- Knobs ist ein MeshPart, sammle es ein
            if collectItem(knobs) then
                print("   ✅ Knobs eingesammelt!")
            else
                print("   ❌ Knobs konnten nicht eingesammelt werden!")
            end
        else
            print("   ❌ Keine Knobs in diesem Raum!")
        end
    end
    
    -- ==========================================
    -- 3. TÜR FINDEN & ÖFFNEN
    -- ==========================================
    if getgenv().AutoOpenDoors then
        print("🚪 Suche Tür...")
        local door = findDoor(room)
        if door then
            print("   ✅ Door gefunden: " .. door.Name)
            
            local opened = openDoor(door)
            
            if opened then
                -- Durch Tür gehen
                local doorPos = nil
                pcall(function()
                    if door:FindFirstChild("Handle") then
                        doorPos = door.Handle.Position
                    elseif door:IsA("BasePart") then
                        doorPos = door.Position
                    end
                end)
                
                if doorPos then
                    local forward = root.CFrame.LookVector
                    teleportTo(doorPos + forward * 6)
                    task.wait(0.3)
                end
                
                visitedRooms[roomNum] = true
                print("   ✅ Raum " .. roomNum .. " abgeschlossen!")
            else
                print("   ❌ Tür konnte nicht geöffnet werden!")
                visitedRooms[roomNum] = true
            end
        else
            print("   ❌ Keine Door in diesem Raum!")
            visitedRooms[roomNum] = true
        end
    else
        visitedRooms[roomNum] = true
    end
    
    isProcessing = false
    print(string.rep("=", 60))
end

-- =============================================================
-- RAUM-LISTENER
-- =============================================================
local function startAutoPlay()
    if not getgenv().AutoPlay then return end
    print("🔄 Auto-Play gestartet!")
    print("📌 Warte auf Raumwechsel...")
    
    local connection = nil
    connection = LatestRoom.Changed:Connect(function()
        if not getgenv().AutoPlay then
            if connection then connection:Disconnect() end
            return
        end
        
        local roomNum = getRoom()
        if not roomNum then return end
        
        if not visitedRooms[roomNum] and not isProcessing then
            processRoom(roomNum)
        end
    end)
    
    task.wait(1)
    local roomNum = getRoom()
    if roomNum and not visitedRooms[roomNum] then
        processRoom(roomNum)
    end
end

-- =============================================================
-- GUI
-- =============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsAutoPlay"
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 300, 0, 420)
mainFrame.Position = UDim2.new(0, 10, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
title.Text = "🚪 DOORS AUTO-PLAY"
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

local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -45)
scroll.Position = UDim2.new(0, 5, 0, 40)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 4
scroll.Parent = mainFrame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 4)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

-- =============================================================
-- GUI HELFER
-- =============================================================
local function createToggle(text, color, getVal, setVal)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 70)
    btn.Text = text .. " ❌"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.Parent = scroll
    btn.MouseButton1Click:Connect(function()
        local val = not getVal()
        setVal(val)
        btn.Text = text .. (val and " ✅" or " ❌")
        btn.BackgroundColor3 = val and Color3.fromRGB(40, 160, 40) or (color or Color3.fromRGB(45, 45, 70))
        if text == "▶️ Auto-Play" and val then
            startAutoPlay()
        end
    end)
    return btn
end

local function createButton(text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 70)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.Parent = scroll
    btn.MouseButton1Click:Connect(callback)
    return btn
end

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
    function(v)
        getgenv().Godmode = v
        if v then
            local c, h = getCharSafe()
            if h then
                pcall(function()
                    h.MaxHealth = 99999
                    h.Health = 100
                end)
            end
        end
    end
)

createToggle("🌀 Noclip", Color3.fromRGB(50, 70, 150),
    function() return getgenv().Noclip end,
    function(v)
        getgenv().Noclip = v
        if v then
            pcall(function()
                for _, part in pairs(Workspace:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end)
        end
    end
)

-- SPEED
local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(1, -10, 0, 40)
speedFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
speedFrame.Parent = scroll

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
    local _, h = getCharSafe()
    if h then pcall(function() h.WalkSpeed = getgenv().Walkspeed end) end
end)

spDown.MouseButton1Click:Connect(function()
    getgenv().Walkspeed = math.max(getgenv().Walkspeed - 5, 16)
    speedLabel.Text = "🏃 Speed: " .. getgenv().Walkspeed
    local _, h = getCharSafe()
    if h then pcall(function() h.WalkSpeed = getgenv().Walkspeed end) end
end)

-- VISUAL
createToggle("💡 Vollhelligkeit", Color3.fromRGB(80, 80, 50),
    function() return getgenv().FullBright end,
    function(v)
        getgenv().FullBright = v
        pcall(function()
            if v then
                Lighting.Brightness = 10
                Lighting.Ambient = Color3.fromRGB(255, 255, 255)
                Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
            else
                Lighting.Brightness = 2
                Lighting.Ambient = Color3.fromRGB(0, 0, 0)
                Lighting.OutdoorAmbient = Color3.fromRGB(0, 0, 0)
            end
        end)
    end
)

createToggle("🌫️ Nebel entfernen", Color3.fromRGB(50, 70, 70),
    function() return getgenv().NoFog end,
    function(v)
        getgenv().NoFog = v
        pcall(function() Lighting.FogEnd = v and 10000 or 100 end)
    end
)

-- BUTTONS
createButton("🖱️ Maus anzeigen", Color3.fromRGB(70, 70, 110), function()
    pcall(function() UserInputService.MouseIconEnabled = true end)
end)

createButton("💀 Wiederbeleben", Color3.fromRGB(130, 50, 50), function()
    local c, h = getCharSafe()
    if h then
        pcall(function()
            h.Health = 100
            h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        end)
        print("💚 Wiederbelebt!")
    end
end)

createButton("📊 Fortschritt", Color3.fromRGB(130, 130, 50), function()
    local sorted = {}
    for k in pairs(visitedRooms) do
        table.insert(sorted, k)
    end
    table.sort(sorted)
    print("\n📊 FORTSCHRITT:")
    print("   Abgeschlossene Räume:", #sorted)
    if #sorted > 0 then
        print("   Letzter Raum:", sorted[#sorted])
        print("   Nächster Raum:", sorted[#sorted] + 1)
    end
    print("   Aktueller Raum:", getRoom() or "Unbekannt")
end)

createButton("🔄 Zurücksetzen", Color3.fromRGB(130, 50, 50), function()
    visitedRooms = {}
    print("🔄 Fortschritt zurückgesetzt!")
end)

-- Canvas
scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
end)

closeBtn.MouseButton1Click:Connect(function()
    pcall(function() screenGui:Destroy() end)
    getgenv().AutoPlay = false
end)

-- DRAG & DROP
local drag = false
local dx, dy, fx, fy

mainFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        drag = true
        dx = inp.Position.X
        dy = inp.Position.Y
        fx = mainFrame.Position.X.Offset
        fy = mainFrame.Position.Y.Offset
    end
end)

mainFrame.InputEnded:Connect(function() drag = false end)

UserInputService.InputChanged:Connect(function(inp)
    if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        mainFrame.Position = UDim2.new(0, fx + inp.Position.X - dx, 0, fy + inp.Position.Y - dy)
    end
end)

-- =============================================================
-- START
-- =============================================================
print("")
print("============================================================")
print("🚪 DOORS AUTO-PLAY GELADEN!")
print("============================================================")
print("📌 Pfade basierend auf Raum-Scanner:")
print("   🚪 Tür: CurrentRooms.X.Door")
print("   🔑 Key: CurrentRooms.X.Assets.KeyObtain")
print("   💰 Knobs: CurrentRooms.X.Assets.Dresser.DrawerContainer.Knobs")
print("============================================================")
print("")
print("📋 ANLEITUNG:")
print("   1. Aktiviere 'Auto-Play'")
print("   2. Aktiviere 'Auto-Collect' für Items")
print("   3. Aktiviere 'Auto-Open-Doors' für Türen")
print("   4. Aktiviere 'Godmode' + 'Noclip' für Sicherheit")
print("")
print("✅ Bereit!")
print("============================================================")
