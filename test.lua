-- =============================================================
-- ||   DOORS - FUNC_FORCEOPEN TEST                          ||
-- ||   Findet die Tür und feuert das RemoteEvent            ||
-- =============================================================

print("🚀 Lade Func_ForceOpen Test...")
print("📌 Klicke auf '▶ Tür testen'")

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

if not LatestRoom then
    print("❌ LatestRoom nicht gefunden!")
    return
end

if not CurrentRooms then
    print("❌ CurrentRooms nicht gefunden!")
    return
end

print("✅ LatestRoom: " .. tostring(LatestRoom.Value))
print("✅ CurrentRooms: " .. tostring(CurrentRooms))

-- =============================================================
-- 3. RAUM-FUNKTIONEN
-- =============================================================
local function getRoom()
    return LatestRoom and LatestRoom.Value
end

local function getRoomContainer(num)
    if not num then return nil end
    return CurrentRooms:FindFirstChild(tostring(num))
end

-- =============================================================
-- 4. TEST-FUNKTION: FUNC_FORCEOPEN FINDEN & AUSFÜHREN
-- =============================================================
local function testFuncForceOpen()
    print("\n" .. string.rep("=", 60))
    print("🔍 FUNC_FORCEOPEN TEST")
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
    
    -- Tür finden
    local door = room:FindFirstChild("Door")
    if not door then
        print("❌ Keine Tür in diesem Raum!")
        
        -- Alle Objekte im Raum anzeigen
        print("   🔍 Durchsuche Raum nach Objekten...")
        for _, obj in pairs(room:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                print("      ✅ " .. obj.Name .. " (" .. obj.ClassName .. ")")
            end
        end
        return
    end
    
    print("✅ Door gefunden: " .. door.Name)
    
    -- ==========================================
    -- SUCHE NACH FUNC_FORCEOPEN
    -- ==========================================
    print("🔍 Suche nach 'Func_ForceOpen'...")
    
    local forceOpenEvent = nil
    
    -- Methode 1: Direkt im Door-Modell suchen
    forceOpenEvent = door:FindFirstChild("Func_ForceOpen")
    if forceOpenEvent then
        print("   ✅ Direkt gefunden: Func_ForceOpen")
    end
    
    -- Methode 2: In allen Descendants suchen
    if not forceOpenEvent then
        for _, obj in pairs(door:GetDescendants()) do
            if obj.Name == "Func_ForceOpen" then
                forceOpenEvent = obj
                print("   ✅ In Descendants gefunden: Func_ForceOpen")
                break
            end
        end
    end
    
    -- Methode 3: Nach ähnlichen Namen suchen
    if not forceOpenEvent then
        print("   🔍 Suche nach ähnlichen Namen...")
        for _, obj in pairs(door:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                local name = obj.Name:lower()
                if name:find("force") or name:find("open") or name:find("door") then
                    print("      ⚠️ Ähnlich gefunden: " .. obj.Name .. " (" .. obj.ClassName .. ")")
                    forceOpenEvent = obj
                    break
                end
            end
        end
    end
    
    -- ==========================================
    -- ALLE REMOTEEVENTS ANZEIGEN
    -- ==========================================
    print("\n📋 Alle RemoteEvents in der Tür:")
    local foundAny = false
    for _, obj in pairs(door:GetDescendants()) do
        if obj:IsA("RemoteEvent") then
            print("   📡 " .. obj.Name .. " (RemoteEvent)")
            foundAny = true
        end
        if obj:IsA("RemoteFunction") then
            print("   📡 " .. obj.Name .. " (RemoteFunction)")
            foundAny = true
        end
    end
    if not foundAny then
        print("   ❌ Keine RemoteEvents gefunden!")
    end
    
    -- ==========================================
    -- FUNC_FORCEOPEN AUSFÜHREN
    -- ==========================================
    if forceOpenEvent then
        print("\n🚪 Führe Func_ForceOpen aus...")
        
        local success, err = pcall(function()
            forceOpenEvent:FireServer()
        end)
        
        if success then
            print("   ✅ Func_ForceOpen erfolgreich gefeuert!")
            
            -- Prüfen ob Tür jetzt offen ist
            task.wait(0.5)
            local isOpen = false
            pcall(function()
                isOpen = door:GetAttribute("Opened") == true
            end)
            
            if isOpen then
                print("   ✅ Tür ist jetzt geöffnet!")
            else
                print("   ⚠️ Tür-Status konnte nicht überprüft werden.")
                print("   📌 Schau selbst nach, ob die Tür aufgegangen ist.")
            end
        else
            print("   ❌ Fehler beim Ausführen: " .. tostring(err))
        end
    else
        print("\n❌ Func_ForceOpen nicht gefunden!")
        print("   💡 Die Tür hat vielleicht ein anderes RemoteEvent.")
        print("   📌 Siehe Liste oben für andere Namen.")
    end
    
    print("\n" .. string.rep("=", 60))
    print("✅ TEST ABGESCHLOSSEN")
    print(string.rep("=", 60))
end

-- =============================================================
-- 5. GUI
-- =============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsForceOpenTest"
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
title.Text = "🚪 FUNC_FORCEOPEN TEST"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.Font = Enum.Font.SourceSansBold
title.Parent = mainFrame

-- Info
local infoLabel = Instance.new("TextLabel")
infoLabel.Size = UDim2.new(1, 0, 0, 18)
infoLabel.Position = UDim2.new(0, 0, 0, 32)
infoLabel.BackgroundTransparency = 1
infoLabel.Text = "Klicke zum Testen der Tür"
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
startBtn.Text = "▶ Tür testen"
startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
startBtn.TextScaled = true
startBtn.Font = Enum.Font.SourceSansBold
startBtn.Parent = mainFrame

startBtn.MouseButton1Click:Connect(function()
    -- Button deaktivieren
    startBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
    startBtn.Text = "⏳ TESTE..."
    startBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
    startBtn.Active = false
    
    -- Test ausführen
    local success, err = pcall(testFuncForceOpen)
    if not success then
        print("❌ FEHLER: " .. tostring(err))
    end
    
    -- Button reaktivieren
    task.wait(0.5)
    startBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
    startBtn.Text = "▶ Tür testen"
    startBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    startBtn.Active = true
end)

-- =============================================================
-- 6. DRAG & DROP
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
-- 7. START
-- =============================================================
print("")
print("============================================================")
print("🚪 FUNC_FORCEOPEN TEST GELADEN!")
print("============================================================")
print("📌 Klicke auf '▶ Tür testen'")
print("")
print("📋 WAS PASSIERT:")
print("   1. Aktuelle Tür wird gesucht")
print("   2. Nach 'Func_ForceOpen' gesucht")
print("   3. Alle RemoteEvents in der Tür werden angezeigt")
print("   4. Falls gefunden: Func_ForceOpen wird ausgeführt")
print("   5. Tür-Status wird geprüft")
print("============================================================")
