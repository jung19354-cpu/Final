-- =============================================================
-- ||   DOORS - KEY SAMMELN & ZUR TÜR TELEPORT             ||
-- ||   SEQUENZ: TP zu Key → E drücken → TP zur Tür        ||
-- =============================================================

print("🚀 Lade DOORS Key-Sammler...")
print("📌 Klicke auf '▶ Start'")

-- =============================================================
-- 1. SERVICES
-- =============================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =============================================================
-- 2. SPIEL-OBJEKTE
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
-- 3. CHARAKTER
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

local function getRoot(c)
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

-- =============================================================
-- 4. TELEPORT MIT OFFSET 3
-- =============================================================
local function teleportTo(pos)
    if not pos then 
        print("❌ Keine Position!")
        return false 
    end
    
    local c = getChar()
    local root = getRoot(c)
    if not root then
        print("❌ Kein HumanoidRootPart!")
        return false
    end
    
    local targetPos = pos + Vector3.new(0, 3, 0) -- Offset 3 nach oben
    
    pcall(function()
        root.CFrame = CFrame.new(targetPos)
        print("📍 Teleportiert zu: " .. tostring(targetPos))
    end)
    return true
end

-- =============================================================
-- 5. RAUM-FUNKTIONEN
-- =============================================================
local function getRoom()
    return LatestRoom and LatestRoom.Value
end

local function getRoomContainer(num)
    if not num then return nil end
    return CurrentRooms:FindFirstChild(tostring(num))
end

-- =============================================================
-- 6. OBJEKTE FINDEN (MIT SCANNER-ARTIGER SUCHE)
-- =============================================================

-- Finde ALLE Objekte im Raum (für Debug)
local function findAllObjects(room)
    if not room then return {} end
    local objects = {}
    for _, obj in pairs(room:GetDescendants()) do
        if obj.Name and obj.Name ~= "" then
            objects[obj.Name] = objects[obj.Name] or {}
            table.insert(objects[obj.Name], obj)
        end
    end
    return objects
end

-- Key finden: CurrentRooms.X.Assets.KeyObtain
local function findKey(room)
    if not room then return nil end
    
    -- Methode 1: Assets.KeyObtain
    local assets = room:FindFirstChild("Assets")
    if assets then
        local key = assets:FindFirstChild("KeyObtain")
        if key then return key end
    end
    
    -- Methode 2: Direkt im Raum suchen
    for _, obj in pairs(room:GetChildren()) do
        if obj.Name == "KeyObtain" then
            return obj
        end
    end
    
    -- Methode 3: In Descendants suchen
    for _, obj in pairs(room:GetDescendants()) do
        if obj.Name == "KeyObtain" then
            return obj
        end
        if obj.Name == "Key" and obj:IsA("BasePart") then
            return obj
        end
    end
    
    return nil
end

-- Knobs finden: CurrentRooms.X.Assets.Dresser.DrawerContainer.Knobs
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

-- Tür finden: CurrentRooms.X.Door
local function findDoor(room)
    if not room then return nil end
    
    -- Methode 1: Direkt im Raum
    local door = room:FindFirstChild("Door")
    if door then return door end
    
    -- Methode 2: In Descendants suchen
    for _, obj in pairs(room:GetDescendants()) do
        if obj.Name == "Door" then
            return obj
        end
    end
    
    return nil
end

-- =============================================================
-- 7. POSITION EINES OBJEKTS HOLEN
-- =============================================================
local function getObjectPosition(obj)
    if not obj then return nil end
    
    local pos = nil
    pcall(function()
        if obj:IsA("BasePart") then
            pos = obj.Position
        elseif obj:IsA("Model") and obj:FindFirstChild("Hitbox") then
            local hitbox = obj:FindFirstChild("Hitbox")
            if hitbox:IsA("BasePart") then
                pos = hitbox.Position
            end
        elseif obj.PrimaryPart then
            pos = obj.PrimaryPart.Position
        elseif obj:FindFirstChild("Handle") then
            pos = obj.Handle.Position
        end
    end)
    
    return pos
end

-- =============================================================
-- 8. INTERAKTION - E DRÜCKEN
-- =============================================================
local function pressE(target)
    if not target then 
        print("❌ Kein Target für E!")
        return false 
    end
    
    print("🔄 Drücke E auf: " .. target.Name)
    
    local success = false
    
    -- Methode 1: ProximityPrompt
    pcall(function()
        local prompt = target:FindFirstChild("ProximityPrompt")
        if not prompt then
            for _, child in pairs(target:GetChildren()) do
                if child:IsA("ProximityPrompt") then
                    prompt = child
                    break
                end
            end
        end
        if prompt then
            prompt:FireServer()
            success = true
            print("   ✅ ProximityPrompt gefeuert!")
        end
    end)
    
    -- Methode 2: RemoteEvent
    if not success then
        pcall(function()
            for _, child in pairs(target:GetChildren()) do
                if child:IsA("RemoteEvent") then
                    child:FireServer()
                    success = true
                    print("   ✅ RemoteEvent (" .. child.Name .. ") gefeuert!")
                end
            end
        end)
    end
    
    -- Methode 3: ClickDetector
    if not success then
        pcall(function()
            local clicker = target:FindFirstChild("ClickDetector")
            if clicker then
                clicker:Click()
                success = true
                print("   ✅ ClickDetector ausgelöst!")
            end
        end)
    end
    
    if not success then
        print("   ❌ Keine Interaktionsmethode gefunden!")
    end
    
    return success
end

-- =============================================================
-- 9. HAUPTLOGIK: KEY → E → TÜR
-- =============================================================
local function runSequence()
    print("\n============================================================")
    print("▶ SEQUENZ START")
    print("============================================================")
    
    -- Raum holen
    local roomNum = getRoom()
    if not roomNum then
        print("❌ Keine Raum-Nummer!")
        return
    end
    
    local room = getRoomContainer(roomNum)
    if not room then
        print("❌ Raum " .. roomNum .. " nicht gefunden!")
        return
    end
    
    print("📂 Raum: " .. roomNum)
    
    -- ==========================================
    -- SCHRITT 1: KEY FINDEN & TP
    -- ==========================================
    print("\n🔍 SCHRITT 1: Key finden...")
    local key = findKey(room)
    
    if not key then
        print("❌ KeyObtain nicht gefunden!")
        print("   Durchsuche Raum nach allen Objekten...")
        
        local allObjects = findAllObjects(room)
        print("   Gefundene Objekte:")
        for name, objs in pairs(allObjects) do
            print("      - " .. name .. " (" .. #objs .. "x)")
        end
        return
    end
    
    print("✅ Key gefunden: " .. key.Name)
    
    local keyPos = getObjectPosition(key)
    if not keyPos then
        print("❌ Keine Position für Key!")
        return
    end
    
    print("📍 Key-Position: " .. tostring(keyPos))
    print("🔄 Teleportiere zu Key (Offset 3)...")
    teleportTo(keyPos)
    task.wait(0.5)
    
    -- ==========================================
    -- SCHRITT 2: E DRÜCKEN (KEY AUFHEBEN)
    -- ==========================================
    print("\n🔑 SCHRITT 2: Key aufheben (E drücken)...")
    local success = pressE(key)
    
    if success then
        print("✅ Key erfolgreich aufgehoben!")
    else
        print("⚠️ Key konnte nicht aufgehoben werden!")
    end
    
    task.wait(0.5)
    
    -- ==========================================
    -- SCHRITT 3: TÜR FINDEN & TP
    -- ==========================================
    print("\n🚪 SCHRITT 3: Tür finden...")
    local door = findDoor(room)
    
    if not door then
        print("❌ Door nicht gefunden!")
        return
    end
    
    print("✅ Door gefunden: " .. door.Name)
    
    local doorPos = getObjectPosition(door)
    if not doorPos then
        print("❌ Keine Position für Door!")
        return
    end
    
    print("📍 Door-Position: " .. tostring(doorPos))
    print("🔄 Teleportiere zu Door (Offset 3)...")
    teleportTo(doorPos)
    
    print("\n============================================================")
    print("✅ SEQUENZ ABGESCHLOSSEN!")
    print("============================================================")
    print("📌 Key wurde aufgehoben und du bist jetzt bei der Tür!")
    print("============================================================")
end

-- =============================================================
-- 10. GUI MIT START-BUTTON
-- =============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsKeyCollector"
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 80)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -40)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Titel
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
title.Text = "🔑 KEY → 🚪 TÜR"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 25, 0, 25)
closeBtn.Position = UDim2.new(1, -30, 0, 2)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 40, 40)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextScaled = true
closeBtn.Font = Enum.Font.SourceSansBold
closeBtn.Parent = mainFrame

closeBtn.MouseButton1Click:Connect(function()
    pcall(function() screenGui:Destroy() end)
end)

-- START-Button
local startBtn = Instance.new("TextButton")
startBtn.Size = UDim2.new(0.9, 0, 0, 35)
startBtn.Position = UDim2.new(0.05, 0, 0.45, 0)
startBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
startBtn.Text = "▶ START"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.TextScaled = true
startBtn.Font = Enum.Font.SourceSansBold
startBtn.Parent = mainFrame

startBtn.MouseButton1Click:Connect(function()
    -- Button deaktivieren (während der Sequenz)
    startBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    startBtn.Text = "⏳ LÄUFT..."
    startBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    startBtn.Active = false
    
    -- Sequenz ausführen
    local success, err = pcall(runSequence)
    if not success then
        print("❌ FEHLER: " .. tostring(err))
    end
    
    -- Button reaktivieren
    task.wait(0.5)
    startBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
    startBtn.Text = "▶ START"
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.Active = true
end)

-- =============================================================
-- 11. DRAG & DROP
-- =============================================================
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
-- 12. START
-- =============================================================
print("")
print("============================================================")
print("🔑 DOORS KEY-SAMMLER GELADEN!")
print("============================================================")
print("📌 Klicke auf '▶ START'")
print("")
print("📋 SEQUENZ:")
print("   1. Teleport zum Key (Offset 3)")
print("   2. E drücken (Key aufheben)")
print("   3. Teleport zur Tür (Offset 3)")
print("============================================================")
