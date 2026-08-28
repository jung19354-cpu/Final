-- =============================================================
-- ||   DOORS - KEY SAMMELN & ZUR TÜR TELEPORT (FIX)        ||
-- ||   OFFSET: KEY=3, TÜR=5                                ||
-- ||   ANTI-TELEPORT-FIX: 2x TELEPORT + WARTE             ||
-- =============================================================

print("🚀 Lade DOORS Key-Sammler (FIX)...")
print("📌 Klicke auf '▶ Start'")

-- =============================================================
-- 1. SERVICES
-- =============================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

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

local function getHumanoid(c)
    if not c then return nil end
    return c:FindFirstChildOfClass("Humanoid")
end

-- =============================================================
-- 4. TELEPORT MIT ANTI-TELEPORT-FIX
-- =============================================================
local function teleportTo(pos, offset, label)
    if not pos then 
        print("   ❌ Keine Position!")
        return false 
    end
    
    local c = getChar()
    local root = getRoot(c)
    if not root then
        print("   ❌ Kein HumanoidRootPart!")
        return false
    end
    
    -- Offset anwenden
    offset = offset or Vector3.new(0, 3, 0)
    local targetPos = pos + offset
    
    print("   🎯 " .. (label or "Teleport") .. " zu: " .. tostring(targetPos))
    
    -- Noclip kurz aktivieren, um durch Wände zu kommen
    local h = getHumanoid(c)
    local wasNoclip = false
    if h then
        -- Prüfen ob Noclip aktiv ist
        for _, part in pairs(c:GetDescendants()) do
            if part:IsA("BasePart") then
                if part.CanCollide == false then
                    wasNoclip = true
                end
            end
        end
        -- Temporär Noclip aktivieren
        for _, part in pairs(c:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- ERSTER TELEPORT-VERSUCH
    local success = false
    pcall(function()
        root.CFrame = CFrame.new(targetPos)
    end)
    print("   📍 Teleport 1/2 ausgeführt")
    task.wait(0.1)
    
    -- Prüfen ob Teleport geklappt hat
    local currentPos = root.Position
    local distance = (currentPos - targetPos).Magnitude
    
    if distance < 2 then
        success = true
        print("   ✅ Teleport erfolgreich!")
    else
        print("   ⚠️ Teleport 1/2 unvollständig (Distanz: " .. math.floor(distance) .. ")")
    end
    
    -- ZWEITER TELEPORT-VERSUCH (falls nötig oder zur Sicherheit)
    if distance > 2 then
        pcall(function()
            root.CFrame = CFrame.new(targetPos)
        end)
        print("   📍 Teleport 2/2 ausgeführt")
        task.wait(0.1)
        
        local currentPos2 = root.Position
        local distance2 = (currentPos2 - targetPos).Magnitude
        if distance2 < 2 then
            success = true
            print("   ✅ Teleport 2/2 erfolgreich!")
        else
            print("   ⚠️ Teleport 2/2 unvollständig (Distanz: " .. math.floor(distance2) .. ")")
        end
    end
    
    -- Noclip wieder deaktivieren (nur wenn es vorher nicht aktiv war)
    if not wasNoclip and h then
        task.wait(0.2)
        for _, part in pairs(c:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
    
    return success
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
-- 6. OBJEKTE FINDEN
-- =============================================================

-- Key finden
local function findKey(room)
    if not room then return nil end
    
    -- Methode 1: Assets.KeyObtain
    local assets = room:FindFirstChild("Assets")
    if assets then
        local key = assets:FindFirstChild("KeyObtain")
        if key then return key end
    end
    
    -- Methode 2: Direkt im Raum
    for _, obj in pairs(room:GetDescendants()) do
        if obj.Name == "KeyObtain" or obj.Name == "Key" then
            return obj
        end
    end
    
    return nil
end

-- Tür finden
local function findDoor(room)
    if not room then return nil end
    return room:FindFirstChild("Door")
end

-- =============================================================
-- 7. POSITION HOLEN
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
        print("   ❌ Kein Target für E!")
        return false 
    end
    
    print("   🔑 Drücke E auf: " .. target.Name)
    
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
            task.wait(0.2)
            prompt:FireServer()
            success = true
            print("      ✅ ProximityPrompt gefeuert!")
        end
    end)
    
    -- Methode 2: RemoteEvent
    if not success then
        pcall(function()
            for _, child in pairs(target:GetChildren()) do
                if child:IsA("RemoteEvent") then
                    child:FireServer()
                    success = true
                    print("      ✅ RemoteEvent (" .. child.Name .. ") gefeuert!")
                end
            end
        end)
    end
    
    if not success then
        print("      ❌ Keine Interaktionsmethode gefunden!")
    end
    
    return success
end

-- =============================================================
-- 9. HAUPTLOGIK
-- =============================================================
local function runSequence()
    print("\n" .. string.rep("=", 60))
    print("▶ SEQUENZ START")
    print(string.rep("=", 60))
    
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
    -- SCHRITT 1: KEY FINDEN & TP (Offset 3)
    -- ==========================================
    print("\n🔍 SCHRITT 1: Key finden...")
    local key = findKey(room)
    
    if not key then
        print("❌ KeyObtain nicht gefunden!")
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
    teleportTo(keyPos, Vector3.new(0, 3, 0), "Key")
    task.wait(0.5)
    
    -- ==========================================
    -- SCHRITT 2: E DRÜCKEN
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
    -- SCHRITT 3: TÜR FINDEN & TP (Offset 5)
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
    print("🔄 Teleportiere zu Door (Offset 5)...")
    
    -- 2x Teleport-Versuch für Tür (Offset 5)
    teleportTo(doorPos, Vector3.new(0, 5, 0), "Tür 1/2")
    task.wait(0.3)
    teleportTo(doorPos, Vector3.new(0, 5, 0), "Tür 2/2")
    
    print("\n" .. string.rep("=", 60))
    print("✅ SEQUENZ ABGESCHLOSSEN!")
    print(string.rep("=", 60))
    print("📌 Key wurde aufgehoben und du bist jetzt bei der Tür!")
    print("📌 Offset Key: 3 | Offset Tür: 5")
    print(string.rep("=", 60))
end

-- =============================================================
-- 10. GUI
-- =============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsKeyCollectorFix"
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 100)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -50)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Titel
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
title.Text = "🔑 KEY → 🚪 TÜR (FIX)"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

-- Info
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 18)
infoLabel.Position = UDim2.new(0, 0, 0, 32)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Key-Offset: 3 | Tür-Offset: 5"
infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
infoLabel.TextScaled = true
infoLabel.Font = Enum.Font.SourceSans
infoLabel.Parent = mainFrame

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
startBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
startBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
startBtn.Text = "▶ START"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.TextScaled = true
startBtn.Font = Enum.Font.SourceSansBold
startBtn.Parent = mainFrame

startBtn.MouseButton1Click:Connect(function()
    -- Button deaktivieren
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
print("🔑 DOORS KEY-SAMMLER (FIX) GELADEN!")
print("============================================================")
print("📌 Klicke auf '▶ START'")
print("")
print("📋 SEQUENZ:")
print("   1. Teleport zum Key (Offset 3)")
print("   2. E drücken (Key aufheben)")
print("   3. Teleport zur Tür (2x Versuche, Offset 5)")
print("")
print("🔄 ANTI-TELEPORT-FIX:")
print("   - 2x Teleport-Versuche")
print("   - Noclip temporär aktiviert")
print("   - Kurze Wartezeiten zwischen Teleports")
print("============================================================")
