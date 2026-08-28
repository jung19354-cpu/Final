-- =============================================================
-- ||   DOORS AUTO-PLAY SCRIPT (SELBST-LERNEND)              ||
-- ||   ANALYSIERT DAS SPIEL UND FINDET ALLE OBJEKTE         ||
-- ||   KEINE FESTEN NAMEN MEHR - ALLES DYNAMISCH            ||
-- =============================================================

print("🚀 Lade Selbst-lernendes DOORS Auto-Play Script...")
print("⏳ Analysiere Spiel-Struktur...")

-- =============================================================
-- I. SERVICES
-- =============================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =============================================================
-- II. SPIEL-ANALYSE (SELBST-LERNEND)
-- =============================================================

-- 1. FINDET DEN AKTUELLEN RAUM
local function findLatestRoom()
    -- Suche in ReplicatedStorage nach GameData
    local gameData = ReplicatedStorage:FindFirstChild("GameData")
    if gameData then
        local latest = gameData:FindFirstChild("LatestRoom")
        if latest then
            return latest
        end
    end
    
    -- Alternative: Suche in Workspace
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj.Name == "LatestRoom" and obj:IsA("NumberValue") then
            return obj
        end
        if obj.Name == "LatestRoom" and obj:IsA("BindableValue") then
            return obj
        end
    end
    
    return nil
end

-- 2. FINDET DEN CURRENTROOMS-CONTAINER
local function findCurrentRooms()
    -- Suche in Workspace
    local currentRooms = Workspace:FindFirstChild("CurrentRooms")
    if currentRooms then
        return currentRooms
    end
    
    -- Alternative: Suche nach Räumen
    for _, obj in pairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj.Name:match("Room%d+") then
            -- Wir haben einen Raum gefunden, also ist Workspace selbst der Container
            return Workspace
        end
    end
    
    return nil
end

-- 3. FINDET DIE TÜR IN EINEM RAUM
local function findDoorInRoom(room)
    if not room then return nil end
    
    -- Suche nach typischen Tür-Namen
    local doorNames = {"Door", "DoorModel", "DoorPart", "DoorHandle", "ExitDoor", "RoomDoor"}
    for _, name in pairs(doorNames) do
        local door = room:FindFirstChild(name)
        if door then
            return door
        end
    end
    
    -- Suche in Descendants
    for _, obj in pairs(room:GetDescendants()) do
        if obj:IsA("Model") or obj:IsA("BasePart") then
            for _, name in pairs(doorNames) do
                if obj.Name == name then
                    return obj
                end
            end
            -- Prüfe auf Attribute
            if obj:FindFirstChild("Open") or obj:FindFirstChild("ProximityPrompt") then
                return obj
            end
        end
    end
    
    return nil
end

-- 4. FINDET SCHLÜSSEL IN EINEM RAUM
local function findKeysInRoom(room)
    local keys = {}
    if not room then return keys end
    
    local keyNames = {"KeyObtain", "Key", "KeyPart", "KeyModel", "KeyPickup"}
    for _, obj in pairs(room:GetDescendants()) do
        for _, name in pairs(keyNames) do
            if obj.Name == name then
                table.insert(keys, obj)
            end
        end
    end
    
    return keys
end

-- 5. FINDET KNOBS (GELD) IN EINEM RAUM
local function findKnobsInRoom(room)
    local knobs = {}
    if not room then return knobs end
    
    local knobNames = {"Knob", "KnobPart", "KnobModel", "Money", "Coin"}
    for _, obj in pairs(room:GetDescendants()) do
        for _, name in pairs(knobNames) do
            if obj.Name == name then
                table.insert(knobs, obj)
            end
        end
    end
    
    return knobs
end

-- 6. FINDET INTERAKTIONS-METHODE
local function findInteractionMethod(obj)
    -- Prüfe auf RemoteEvent "Open"
    local openEvent = obj:FindFirstChild("Open")
    if openEvent and openEvent:IsA("RemoteEvent") then
        return "RemoteEvent", openEvent
    end
    
    -- Prüfe auf RemoteEvent "DoorOpen"
    local doorOpen = obj:FindFirstChild("DoorOpen")
    if doorOpen and doorOpen:IsA("RemoteEvent") then
        return "RemoteEvent", doorOpen
    end
    
    -- Prüfe auf ProximityPrompt
    local prompt = obj:FindFirstChild("ProximityPrompt")
    if prompt then
        return "ProximityPrompt", prompt
    end
    
    -- Prüfe auf Handle mit ProximityPrompt
    local handle = obj:FindFirstChild("Handle")
    if handle then
        prompt = handle:FindFirstChild("ProximityPrompt")
        if prompt then
            return "ProximityPrompt", prompt
        end
    end
    
    return nil, nil
end

-- 7. FINDET TÜR-STATUS
local function getDoorStatus(door)
    if not door then return "unknown" end
    
    -- Prüfe Attribute
    local opened = door:GetAttribute("Opened")
    if opened ~= nil then
        return opened and "open" or "closed"
    end
    
    local isOpen = door:GetAttribute("IsOpen")
    if isOpen ~= nil then
        return isOpen and "open" or "closed"
    end
    
    -- Prüfe ob offen (Position / State)
    local handle = door:FindFirstChild("Handle")
    if handle then
        -- Prüfe ob die Tür rotiert ist (offen)
        if handle.Rotation.Y > 45 and handle.Rotation.Y < 135 then
            return "open"
        end
    end
    
    return "unknown"
end

-- =============================================================
-- III. GEFUNDENE OBJEKTE SPEICHERN
-- =============================================================
local Found = {
    LatestRoom = nil,
    CurrentRooms = nil,
    DoorNames = {},
    KeyNames = {},
    KnobNames = {},
    InteractionType = nil,
    InteractionObject = nil,
}

-- ANALYSE DURCHFÜHREN
local function analyzeGame()
    print("🔍 Analysiere Spiel...")
    
    -- LatestRoom finden
    Found.LatestRoom = findLatestRoom()
    if Found.LatestRoom then
        print("   ✅ LatestRoom gefunden:", Found.LatestRoom.Name)
    else
        print("   ⚠️ LatestRoom nicht gefunden! Versuche Alternative...")
        -- Alternative: Suche nach Raum-Nummer in Workspace
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("NumberValue") and obj.Name:match("Room") then
                Found.LatestRoom = obj
                print("   ✅ Alternativen LatestRoom gefunden:", obj.Name)
                break
            end
        end
    end
    
    -- CurrentRooms finden
    Found.CurrentRooms = findCurrentRooms()
    if Found.CurrentRooms then
        print("   ✅ CurrentRooms gefunden:", Found.CurrentRooms.Name)
    else
        print("   ⚠️ CurrentRooms nicht gefunden!")
    end
    
    -- Einen Test-Raum analysieren
    local testRoom = nil
    if Found.CurrentRooms then
        for _, child in pairs(Found.CurrentRooms:GetChildren()) do
            if child:IsA("Model") and child.Name:match("Room") then
                testRoom = child
                break
            end
        end
    end
    
    if testRoom then
        print("   🔍 Analysiere Test-Raum:", testRoom.Name)
        
        -- Tür finden
        local door = findDoorInRoom(testRoom)
        if door then
            print("   ✅ Tür gefunden:", door.Name)
            Found.DoorNames = {door.Name}
            
            -- Interaktionsmethode finden
            local method, obj = findInteractionMethod(door)
            if method then
                Found.InteractionType = method
                Found.InteractionObject = obj
                print("   ✅ Interaktionsmethode:", method, "(" .. obj.Name .. ")")
            else
                print("   ⚠️ Keine Interaktionsmethode gefunden!")
            end
        else
            print("   ⚠️ Keine Tür im Test-Raum gefunden!")
        end
        
        -- Schlüssel finden
        local keys = findKeysInRoom(testRoom)
        if #keys > 0 then
            print("   ✅ Schlüssel gefunden:", #keys)
            for _, key in pairs(keys) do
                table.insert(Found.KeyNames, key.Name)
            end
        end
        
        -- Knobs finden
        local knobs = findKnobsInRoom(testRoom)
        if #knobs > 0 then
            print("   ✅ Knobs gefunden:", #knobs)
            for _, knob in pairs(knobs) do
                table.insert(Found.KnobNames, knob.Name)
            end
        end
    else
        print("   ⚠️ Kein Test-Raum gefunden!")
    end
    
    print("✅ Analyse abgeschlossen!")
end

-- =============================================================
-- IV. AUTO-PLAY LOGIK (DYNAMISCH)
-- =============================================================

local visitedRooms = {}
local isProcessing = false

-- STATUS-VARIABLEN
getgenv().AutoPlay = false
getgenv().AutoCollect = false
getgenv().AutoOpenDoors = false
getgenv().Godmode = false
getgenv().Noclip = false
getgenv().AutoHeal = false
getgenv().Walkspeed = 20

-- CHARAKTER-FUNKTIONEN
local function getCharacter()
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

local function getRootPart(c)
    if not c then return nil end
    return c:FindFirstChild("HumanoidRootPart")
end

local function getCharacterSafe()
    local c = getCharacter()
    if not c then return nil, nil, nil end
    local h = getHumanoid(c)
    local r = getRootPart(c)
    return c, h, r
end

-- TELEPORT
local function teleportTo(position)
    if not position then return false end
    local c, h, root = getCharacterSafe()
    if root then
        pcall(function()
            root.CFrame = CFrame.new(position)
        end)
        return true
    end
    return false
end

-- INTERAKTION (DYNAMISCH)
local function interactWithObject(obj)
    if not obj then return false end
    
    -- Methode 1: RemoteEvent
    local method, event = findInteractionMethod(obj)
    if method == "RemoteEvent" and event then
        pcall(function()
            event:FireServer()
        end)
        return true
    end
    
    -- Methode 2: ProximityPrompt
    if method == "ProximityPrompt" and event then
        pcall(function()
            -- "E" halten simulieren
            local start = tick()
            repeat
                event:FireServer()
                task.wait(0.05)
            until tick() - start > 1.5
            event:FireServer()
        end)
        return true
    end
    
    return false
end

-- TÜR ÖFFNEN
local function openDoor(door)
    if not door then return false end
    
    -- Prüfe ob schon offen
    local status = getDoorStatus(door)
    if status == "open" then
        print("   🚪 Tür schon offen!")
        return true
    end
    
    print("   🚪 Öffne Tür mit:", Found.InteractionType or "unbekannt")
    
    -- Teleport zur Tür
    local handle = door:FindFirstChild("Handle")
    if handle then
        teleportTo(handle.Position + Vector3.new(0, 0, 4))
        task.wait(0.3)
    end
    
    -- Interagiere
    local success = interactWithObject(door)
    
    if success then
        print("   ⏳ Warte auf Tür...")
        local timeout = 15
        local start = tick()
        repeat
            task.wait(0.2)
            status = getDoorStatus(door)
            if status == "open" then
                print("   ✅ Tür geöffnet! (nach " .. math.floor(tick() - start) .. "s)")
                return true
            end
        until tick() - start > timeout
    end
    
    print("   ⏰ Timeout! Tür öffnet nicht.")
    return false
end

-- GEGENSTAND AUFHEBEN
local function collectItem(item)
    if not item or not item.Parent then return false end
    
    local pos = nil
    pcall(function()
        if item:IsA("BasePart") then
            pos = item.Position
        elseif item:FindFirstChild("Handle") then
            pos = item.Handle.Position
        elseif item.PrimaryPart then
            pos = item.PrimaryPart.Position
        end
    end)
    
    if pos then
        teleportTo(pos + Vector3.new(0, 1, 0))
        task.wait(0.2)
    end
    
    return interactWithObject(item)
end

-- RAUM VERARBEITEN
local function processRoom(roomNum)
    if isProcessing then return end
    if visitedRooms[roomNum] then return end
    if not roomNum then return end
    
    isProcessing = true
    print("\n" .. string.rep("=", 50))
    print("🏠 RAUM " .. roomNum)
    print(string.rep("=", 50))
    
    -- Charakter prüfen
    local c, h, root = getCharacterSafe()
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
    
    -- Auto-Heal
    if getgenv().AutoHeal then
        pcall(function()
            if h.Health < 80 then
                h.Health = 100
                print("   💚 Auto-Heal!")
            end
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
                if part:IsA("BasePart") and part.CanCollide then
                    part.CanCollide = false
                end
            end
        end)
    end
    
    -- Speed
    pcall(function()
        h.WalkSpeed = getgenv().Walkspeed
    end)
    
    -- Raum holen
    local room = nil
    if Found.CurrentRooms then
        room = Found.CurrentRooms:FindFirstChild(tostring(roomNum))
        if not room then
            -- Versuche mit "Room" + Nummer
            room = Found.CurrentRooms:FindFirstChild("Room" .. roomNum)
        end
    end
    if not room then
        print("   ❌ Raum nicht gefunden!")
        visitedRooms[roomNum] = true
        isProcessing = false
        return
    end
    
    -- 1. AUTO-COLLECT
    if getgenv().AutoCollect then
        print("🔑 Sammle Items...")
        
        local keys = findKeysInRoom(room)
        for _, key in pairs(keys) do
            if collectItem(key) then
                print("   ✅ Key eingesammelt!")
                break
            end
        end
        
        local knobs = findKnobsInRoom(room)
        for _, knob in pairs(knobs) do
            if collectItem(knob) then
                print("   ✅ Knob eingesammelt!")
                break
            end
        end
    end
    
    -- 2. AUTO-OPEN-DOORS
    if getgenv().AutoOpenDoors then
        local door = findDoorInRoom(room)
        if door then
            local opened = openDoor(door)
            
            if opened then
                -- Durch die Tür gehen
                local handle = door:FindFirstChild("Handle")
                if handle then
                    local forward = root.CFrame.LookVector
                    teleportTo(handle.Position + forward * 6)
                    task.wait(0.3)
                    visitedRooms[roomNum] = true
                    print("   ✅ Raum " .. roomNum .. " abgeschlossen!")
                else
                    visitedRooms[roomNum] = true
                    print("   ⚠️ Raum " .. roomNum .. " markiert (kein Handle)")
                end
            else
                print("   ❌ Tür konnte nicht geöffnet werden!")
                visitedRooms[roomNum] = true
            end
        else
            print("   ❌ Keine Tür gefunden!")
            visitedRooms[roomNum] = true
        end
    else
        visitedRooms[roomNum] = true
    end
    
    isProcessing = false
    print(string.rep("=", 50))
end

-- =============================================================
-- V. RAUM-LISTENER
-- =============================================================
local function startAutoPlay()
    if not getgenv().AutoPlay then return end
    print("🔄 Auto-Play gestartet!")
    
    if not Found.LatestRoom then
        print("❌ LatestRoom nicht gefunden! Führe Analyse durch...")
        analyzeGame()
        if not Found.LatestRoom then
            print("❌ Kann nicht starten - kein LatestRoom!")
            return
        end
    end
    
    -- Raumwechsel-Listener
    local connection = nil
    connection = Found.LatestRoom.Changed:Connect(function()
        if not getgenv().AutoPlay then
            if connection then connection:Disconnect() end
            return
        end
        
        local roomNum = Found.LatestRoom.Value
        if not roomNum then return end
        
        if not visitedRooms[roomNum] and not isProcessing then
            processRoom(roomNum)
        end
    end)
    
    -- Aktuellen Raum verarbeiten
    task.wait(1)
    local roomNum = Found.LatestRoom.Value
    if roomNum and not visitedRooms[roomNum] then
        processRoom(roomNum)
    end
end

-- =============================================================
-- VI. ANALYSE STARTEN
-- =============================================================
analyzeGame()

print("")
print("📊 ANALYSE-ERGEBNISSE:")
print("   LatestRoom:", Found.LatestRoom and Found.LatestRoom.Name or "❌")
print("   CurrentRooms:", Found.CurrentRooms and Found.CurrentRooms.Name or "❌")
print("   Interaktionsmethode:", Found.InteractionType or "❌")
print("   Gefundene Tür-Namen:", #Found.DoorNames > 0 and table.concat(Found.DoorNames, ", ") or "❌")
print("   Gefundene Schlüssel-Namen:", #Found.KeyNames > 0 and table.concat(Found.KeyNames, ", ") or "❌")
print("   Gefundene Knob-Namen:", #Found.KnobNames > 0 and table.concat(Found.KnobNames, ", ") or "❌")
print("")

if not Found.LatestRoom or not Found.CurrentRooms then
    print("⚠️ WARNUNG: Nicht alle Objekte gefunden!")
    print("   Das Skript kann trotzdem versuchen zu laufen.")
    print("   Falls es nicht funktioniert, starte das Spiel neu.")
end

-- =============================================================
-- VII. GUI (EINFACH)
-- =============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsAutoPlaySelf"
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 420)
mainFrame.Position = UDim2.new(0, 10, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
title.Text = "🚪 AUTO-PLAY (SELBST)"
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
scroll.Size = UDim2.new(1, -10, 1, -50)
scroll.Position = UDim2.new(0, 5, 0, 45)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 4
scroll.Parent = mainFrame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 4)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

-- GUI HELFER
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

-- TOGGLES
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
            local c, h = getCharacterSafe()
            if h then
                pcall(function()
                    h.MaxHealth = 99999
                    h.Health = 100
                end)
            end
        end
    end
)

createToggle("💚 Auto-Heal", Color3.fromRGB(60, 160, 60),
    function() return getgenv().AutoHeal end,
    function(v) getgenv().AutoHeal = v end
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
    local _, h = getCharacterSafe()
    if h then
        pcall(function() h.WalkSpeed = getgenv().Walkspeed end)
    end
end)

spDown.MouseButton1Click:Connect(function()
    getgenv().Walkspeed = math.max(getgenv().Walkspeed - 5, 16)
    speedLabel.Text = "🏃 Speed: " .. getgenv().Walkspeed
    local _, h = getCharacterSafe()
    if h then
        pcall(function() h.WalkSpeed = getgenv().Walkspeed end)
    end
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
        pcall(function()
            Lighting.FogEnd = v and 10000 or 100
        end)
    end
)

-- BUTTONS
createButton("🖱️ Maus anzeigen", Color3.fromRGB(70, 70, 110), function()
    pcall(function()
        UserInputService.MouseIconEnabled = true
    end)
end)

createButton("💀 Wiederbeleben", Color3.fromRGB(130, 50, 50), function()
    local c, h = getCharacterSafe()
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
    if Found.LatestRoom then
        print("   Aktueller Raum:", Found.LatestRoom.Value or "Unbekannt")
    end
end)

createButton("🔍 Neu analysieren", Color3.fromRGB(50, 130, 130), function()
    analyzeGame()
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
    pcall(function()
        screenGui:Destroy()
    end)
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

mainFrame.InputEnded:Connect(function()
    drag = false
end)

UserInputService.InputChanged:Connect(function(inp)
    if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        mainFrame.Position = UDim2.new(0, fx + inp.Position.X - dx, 0, fy + inp.Position.Y - dy)
    end
end)

-- =============================================================
-- VIII. START
-- =============================================================
print("")
print("============================================================")
print("🚪 DOORS AUTO-PLAY SCRIPT (SELBST-LERNEND) GELADEN!")
print("============================================================")
print("📌 Das Skript analysiert das Spiel selbstständig!")
print("📌 Keine fest codierten Namen mehr!")
print("📌 Der 'Neu analysieren'-Button aktualisiert die Daten!")
print("============================================================")
print("")
print("📋 ANLEITUNG:")
print("   1. Aktiviere 'Auto-Play' für Vollautomatik")
print("   2. Aktiviere 'Auto-Collect' für Schlüssel & Knobs")
print("   3. Aktiviere 'Auto-Open-Doors' für Türen")
print("   4. Aktiviere 'Godmode' + 'Noclip' für Sicherheit")
print("   5. Falls nichts passiert, klicke 'Neu analysieren'")
print("")
print("✅ Skript bereit!")
print("============================================================")
