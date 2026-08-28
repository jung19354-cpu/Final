-- =============================================================
-- ||   DOORS TP-TEST - NUR TELEPORT ZU KEY & KNOBS          ||
-- ||   MIT 2 UI-BUTTONS - OFFSET 1 ZUM VERMEIDEN VON BUGS  ||
-- =============================================================

print("🚀 Lade DOORS TP-Test-Skript...")
print("📌 Klicke auf 'TP zu Key' oder 'TP zu Knobs'")
 
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
-- 3. CHARAKTER-FUNKTION
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
-- 4. TELEPORT-FUNKTION MIT OFFSET
-- =============================================================
local function teleportTo(pos, offset)
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
    
    offset = offset or Vector3.new(0, 1, 0) -- Standard-Offset 1 nach oben
    local targetPos = pos + offset
    
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
-- 6. OBJEKTE FINDEN
-- =============================================================

-- Key finden: CurrentRooms.X.Assets.KeyObtain
local function findKey(room)
    if not room then return nil end
    local assets = room:FindFirstChild("Assets")
    if not assets then return nil end
    return assets:FindFirstChild("KeyObtain")
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

-- Door finden: CurrentRooms.X.Door
local function findDoor(room)
    if not room then return nil end
    return room:FindFirstChild("Door")
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
-- 8. GUI MIT 2 BUTTONS
-- =============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsTPTest"
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 250, 0, 120)
mainFrame.Position = UDim2.new(0.5, -125, 0.5, -60)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Titel
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
title.Text = "📍 TP-TEST"
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

-- =============================================================
-- 9. BUTTONS ERSTELLEN
-- =============================================================
local function createButton(text, color, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.9, 0, 0, 30)
    btn.Position = UDim2.new(0.05, 0, 0, 0)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 70)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSansBold
    btn.Parent = mainFrame
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- Button 1: TP zu Key
local keyBtn = createButton("🔑 TP zu Key", Color3.fromRGB(60, 120, 60), function()
    print("\n============================================================")
    print("🔑 TP zu KEY")
    print("============================================================")
    
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
    
    local key = findKey(room)
    if not key then
        print("❌ KeyObtain nicht gefunden in Raum " .. roomNum)
        return
    end
    
    print("✅ KeyObtain gefunden: " .. key.Name)
    
    local pos = getObjectPosition(key)
    if not pos then
        print("❌ Keine Position für KeyObtain!")
        return
    end
    
    print("📍 Position: " .. tostring(pos))
    print("🔄 Teleportiere mit Offset 1...")
    
    teleportTo(pos, Vector3.new(0, 1, 0))
    
    print("============================================================")
end)

-- Button 2: TP zu Knobs
local knobsBtn = createButton("💰 TP zu Knobs", Color3.fromRGB(60, 80, 140), function()
    print("\n============================================================")
    print("💰 TP zu KNOBS")
    print("============================================================")
    
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
    
    local knobs = findKnobs(room)
    if not knobs then
        print("❌ Knobs nicht gefunden in Raum " .. roomNum)
        return
    end
    
    print("✅ Knobs gefunden: " .. knobs.Name)
    
    local pos = getObjectPosition(knobs)
    if not pos then
        print("❌ Keine Position für Knobs!")
        return
    end
    
    print("📍 Position: " .. tostring(pos))
    print("🔄 Teleportiere mit Offset 1...")
    
    teleportTo(pos, Vector3.new(0, 1, 0))
    
    print("============================================================")
end)

-- Button 3 (optional): TP zu Door
local doorBtn = createButton("🚪 TP zu Door", Color3.fromRGB(80, 60, 120), function()
    print("\n============================================================")
    print("🚪 TP zu DOOR")
    print("============================================================")
    
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
    
    local door = findDoor(room)
    if not door then
        print("❌ Door nicht gefunden in Raum " .. roomNum)
        return
    end
    
    print("✅ Door gefunden: " .. door.Name)
    
    local pos = getObjectPosition(door)
    if not pos then
        print("❌ Keine Position für Door!")
        return
    end
    
    print("📍 Position: " .. tostring(pos))
    print("🔄 Teleportiere mit Offset 1...")
    
    teleportTo(pos, Vector3.new(0, 1, 0))
    
    print("============================================================")
end)

-- Buttons positionieren
keyBtn.Position = UDim2.new(0.05, 0, 0.35, 0)
knobsBtn.Position = UDim2.new(0.05, 0, 0.55, 0)
doorBtn.Position = UDim2.new(0.05, 0, 0.75, 0)

-- =============================================================
-- 10. DRAG & DROP
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
-- 11. START
-- =============================================================
print("")
print("============================================================")
print("📍 TP-TEST SKRIPT GELADEN!")
print("============================================================")
print("📌 Klicke auf einen Button, um zu teleportieren:")
print("   🔑 TP zu Key     - Teleport zum KeyObtain")
print("   💰 TP zu Knobs   - Teleport zu den Knobs")
print("   🚪 TP zu Door    - Teleport zur Tür")
print("")
print("🔄 Offset: +1 nach oben (verhindert Bugging)")
print("============================================================")
