-- =============================================================
-- ||   DOORS AUTO-PLAY - DAS FINALE SKRIPT                 ||
-- ||   MIT GUI - MIT TELEPORT - MIT AUTO-FARM              ||
-- =============================================================

print("🚀 Lade FINALES Doors Auto-Play Skript...")

local player = game.Players.LocalPlayer
local userInputService = game:GetService("UserInputService")
local lighting = game:GetService("Lighting")
local replicatedStorage = game:GetService("ReplicatedStorage")
local runService = game:GetService("RunService")


-- =============================================================
-- SPIEL-OBJEKTE
-- =============================================================
local gameData = replicatedStorage:FindFirstChild("GameData")
local latestRoom = gameData and gameData:FindFirstChild("LatestRoom")
local currentRooms = workspace:FindFirstChild("CurrentRooms")

if not latestRoom or not currentRooms then
    print("❌ Kritische Objekte nicht gefunden!")
    return
end

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
        player:LoadCharacter()
        task.wait(1)
        c = player.Character
    end
    return c
end

local function getHumanoid(c)
    return c and c:FindFirstChild("Humanoid")
end

local function getRoot(c)
    return c and c:FindFirstChild("HumanoidRootPart")
end

-- =============================================================
-- TELEPORT
-- =============================================================
local function teleport(pos)
    local c = getChar()
    local root = getRoot(c)
    if root and pos then
        root.CFrame = CFrame.new(pos)
        return true
    end
    return false
end

-- =============================================================
-- INTERAKTION (E HALTEN)
-- =============================================================
local function holdE(target, duration)
    if not target then return false end
    
    local prompt = target:FindFirstChild("ProximityPrompt")
    if not prompt then
        local handle = target:FindFirstChild("Handle")
        if handle then
            prompt = handle:FindFirstChild("ProximityPrompt")
        end
    end
    
    if not prompt then return false end
    
    duration = duration or 1.5
    print("   🔑 Halte E für " .. duration .. "s...")
    
    local start = tick()
    repeat
        prompt:FireServer()
        task.wait(0.05)
    until tick() - start > duration
    
    prompt:FireServer()
    return true
end

-- =============================================================
-- GEGENSTAND AUFHEBEN
-- =============================================================
local function collectItem(item)
    if not item or not item.Parent then return false end
    
    local pos = item:IsA("BasePart") and item.Position or 
                (item:FindFirstChild("Handle") and item.Handle.Position)
    
    if pos then
        teleport(pos + Vector3.new(0, 1, 0))
        task.wait(0.2)
    end
    
    local prompt = item:FindFirstChild("ProximityPrompt")
    if not prompt then return false end
    
    prompt:FireServer()
    task.wait(0.2)
    prompt:FireServer()
    return true
end

-- =============================================================
-- RAUM-FUNKTIONEN
-- =============================================================
local function getRoom()
    return latestRoom.Value
end

local function getRoomContainer(num)
    return currentRooms:FindFirstChild(tostring(num))
end

local function findDoor(room)
    return room and room:FindFirstChild("Door")
end

local function isDoorOpen(door)
    return door and door:GetAttribute("Opened") == true
end

local function findKeys(room)
    local keys = {}
    if not room then return keys end
    for _, obj in pairs(room:GetDescendants()) do
        if obj.Name == "KeyObtain" or obj.Name == "Key" then
            table.insert(keys, obj)
        end
    end
    return keys
end

local function findKnobs(room)
    local knobs = {}
    if not room then return knobs end
    for _, obj in pairs(room:GetDescendants()) do
        if obj.Name == "Knob" then
            table.insert(knobs, obj)
        end
    end
    return knobs
end

-- =============================================================
-- RAUM VERARBEITEN
-- =============================================================
local function processRoom(roomNum)
    if isProcessing then return end
    if visitedRooms[roomNum] then return end
    
    isProcessing = true
    
    print("\n" .. string.rep("=", 50))
    print("🏠 RAUM " .. roomNum)
    print(string.rep("=", 50))
    
    -- Charakter prüfen
    local c = getChar()
    if not c then
        print("   ❌ Kein Charakter!")
        isProcessing = false
        return
    end
    
    local humanoid = getHumanoid(c)
    local root = getRoot(c)
    if not humanoid or not root then
        isProcessing = false
        return
    end
    
    -- Godmode
    if getgenv().Godmode then
        humanoid.Health = 100
        humanoid.MaxHealth = 100
    end
    
    -- Noclip
    if getgenv().Noclip then
        for _, part in pairs(c:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- Speed
    humanoid.WalkSpeed = getgenv().Walkspeed
    
    -- Raum holen
    local room = getRoomContainer(roomNum)
    if not room then
        print("   ❌ Raum nicht gefunden!")
        isProcessing = false
        return
    end
    
    -- 1. KEYS & KNOBS
    if getgenv().AutoCollect then
        print("🔑 Sammle Items...")
        local keys = findKeys(room)
        for _, key in pairs(keys) do
            if collectItem(key) then
                print("   ✅ Key eingesammelt!")
                break
            end
        end
        
        local knobs = findKnobs(room)
        for _, knob in pairs(knobs) do
            if collectItem(knob) then
                print("   ✅ Knob eingesammelt!")
                break
            end
        end
    end
    
    -- 2. TÜR ÖFFNEN
    if getgenv().AutoOpenDoors then
        local door = findDoor(room)
        if door then
            if isDoorOpen(door) then
                print("   🚪 Tür schon offen!")
            else
                print("   🚪 Öffne Tür...")
                local handle = door:FindFirstChild("Handle")
                if handle then
                    teleport(handle.Position + Vector3.new(0, 0, 4))
                    task.wait(0.3)
                    holdE(door, 1.5)
                end
                
                print("   ⏳ Warte...")
                local timeout = 15
                local start = tick()
                repeat
                    task.wait(0.2)
                until isDoorOpen(door) or tick() - start > timeout
                
                if isDoorOpen(door) then
                    print("   ✅ Tür geöffnet!")
                    local handle = door:FindFirstChild("Handle")
                    if handle then
                        local forward = root.CFrame.LookVector
                        teleport(handle.Position + forward * 6)
                        task.wait(0.3)
                        visitedRooms[roomNum] = true
                        print("   ✅ Raum " .. roomNum .. " abgeschlossen!")
                    end
                else
                    print("   ⏰ Timeout!")
                end
            end
        else
            print("   ❌ Keine Tür!")
            visitedRooms[roomNum] = true
        end
    else
        visitedRooms[roomNum] = true
    end
    
    isProcessing = false
    print(string.rep("=", 50))
end

-- =============================================================
-- RAUM-LISTENER
-- =============================================================
local function startAutoPlay()
    if not getgenv().AutoPlay then return end
    print("🔄 Auto-Play gestartet!")
    
    latestRoom.Changed:Connect(function()
        if not getgenv().AutoPlay then return end
        local num = getRoom()
        if num and not visitedRooms[num] and not isProcessing then
            processRoom(num)
        end
    end)
    
    task.wait(1)
    local num = getRoom()
    if num and not visitedRooms[num] then
        processRoom(num)
    end
end

-- =============================================================
-- GUI
-- =============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsFinal"
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 420)
mainFrame.Position = UDim2.new(0, 10, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 25)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Titel
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
title.Text = "🚪 DOORS FINAL"
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
local function toggle(text, color, get, set)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 65)
    btn.Text = text .. " ❌"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.Parent = scroll
    
    btn.MouseButton1Click:Connect(function()
        local val = not get()
        set(val)
        btn.Text = text .. (val and " ✅" or " ❌")
        btn.BackgroundColor3 = val and Color3.fromRGB(40, 160, 40) or (color or Color3.fromRGB(45, 45, 65))
        if text == "▶️ Auto-Play" and val then
            startAutoPlay()
        end
    end)
    return btn
end

local function button(text, color, cb)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 32)
    btn.BackgroundColor3 = color or Color3.fromRGB(45, 45, 65)
    btn.Text = text
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.Parent = scroll
    btn.MouseButton1Click:Connect(cb)
    return btn
end

-- =============================================================
-- TOGGLES
-- =============================================================
toggle("▶️ Auto-Play", Color3.fromRGB(200, 100, 50),
    function() return getgenv().AutoPlay end,
    function(v) getgenv().AutoPlay = v end
)

toggle("🔑 Auto-Collect", Color3.fromRGB(60, 120, 60),
    function() return getgenv().AutoCollect end,
    function(v) getgenv().AutoCollect = v end
)

toggle("🚪 Auto-Open-Doors", Color3.fromRGB(60, 80, 140),
    function() return getgenv().AutoOpenDoors end,
    function(v) getgenv().AutoOpenDoors = v end
)

toggle("🛡️ Godmode", Color3.fromRGB(80, 50, 130),
    function() return getgenv().Godmode end,
    function(v) getgenv().Godmode = v end
)

toggle("🌀 Noclip", Color3.fromRGB(50, 70, 150),
    function() return getgenv().Noclip end,
    function(v) getgenv().Noclip = v end
)

-- =============================================================
-- SPEED
-- =============================================================
local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(1, -10, 0, 40)
speedFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
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
    local c = getChar()
    local h = getHumanoid(c)
    if h then h.WalkSpeed = getgenv().Walkspeed end
end)

spDown.MouseButton1Click:Connect(function()
    getgenv().Walkspeed = math.max(getgenv().Walkspeed - 5, 16)
    speedLabel.Text = "🏃 Speed: " .. getgenv().Walkspeed
    local c = getChar()
    local h = getHumanoid(c)
    if h then h.WalkSpeed = getgenv().Walkspeed end
end)

-- =============================================================
-- VISUAL
-- =============================================================
toggle("💡 Vollhelligkeit", Color3.fromRGB(80, 80, 50),
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

toggle("🌫️ Nebel entfernen", Color3.fromRGB(50, 70, 70),
    function() return getgenv().NoFog end,
    function(v)
        getgenv().NoFog = v
        lighting.FogEnd = v and 10000 or 100
    end
)

-- =============================================================
-- BUTTONS
-- =============================================================
button("🖱️ Maus anzeigen", Color3.fromRGB(70, 70, 110), function()
    userInputService.MouseIconEnabled = true
end)

button("💀 Wiederbeleben", Color3.fromRGB(130, 50, 50), function()
    local c = getChar()
    local h = getHumanoid(c)
    if h then
        h.Health = 100
        h:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    end
end)

button("📊 Fortschritt", Color3.fromRGB(130, 130, 50), function()
    local sorted = {}
    for k in pairs(visitedRooms) do
        table.insert(sorted, k)
    end
    table.sort(sorted)
    print("\n📊 FORTSCHRITT:")
    print("   Abgeschlossen:", #sorted)
    if #sorted > 0 then
        print("   Letzter Raum:", sorted[#sorted])
        print("   Nächster Raum:", sorted[#sorted] + 1)
    end
    print("   Aktueller Raum:", getRoom())
end)

button("🔄 Zurücksetzen", Color3.fromRGB(130, 50, 50), function()
    visitedRooms = {}
    print("🔄 Fortschritt zurückgesetzt!")
end)

-- Canvas
scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
end)

closeBtn.MouseButton1Click:Connect(function()
    screenGui:Destroy()
    getgenv().AutoPlay = false
end)

-- =============================================================
-- DRAG & DROP
-- =============================================================
local drag = false
local dx, dy, fx, fy

mainFrame.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
        drag = true
        dx, dy = inp.Position.X, inp.Position.Y
        fx, fy = mainFrame.Position.X.Offset, mainFrame.Position.Y.Offset
    end
end)

mainFrame.InputEnded:Connect(function() drag = false end)

userInputService.InputChanged:Connect(function(inp)
    if drag and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        mainFrame.Position = UDim2.new(0, fx + inp.Position.X - dx, 0, fy + inp.Position.Y - dy)
    end
end)

-- =============================================================
-- START
-- =============================================================
print("")
print("==========================================")
print("🚪 DOORS FINAL SKRIPT GELADEN!")
print("==========================================")
print("📌 GUI ist sichtbar!")
print("📌 Aktiviere Auto-Play für Vollautomatik!")
print("📌 Auto-Collect + Auto-Open-Doors aktivieren!")
print("📌 Godmode + Noclip für Sicherheit!")
print("==========================================")
