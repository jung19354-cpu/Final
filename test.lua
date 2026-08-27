-- ==========================================
-- DOORS AUTO-PLAY V6 (EINFACH & ZUVERLÄSSIG)
-- ==========================================

print("🚀 Lade Doors Auto-Play V6...")

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local userInputService = game:GetService("UserInputService")
local lighting = game:GetService("Lighting")
local replicatedStorage = game:GetService("ReplicatedStorage")

-- ==========================================
-- STATUS
-- ==========================================
getgenv().AutoPlay = false
getgenv().AutoCollect = false
getgenv().Godmode = false
getgenv().Noclip = false
getgenv().Walkspeed = 20

-- ==========================================
-- SPIEL-DATEN
-- ==========================================
local gameData = replicatedStorage:FindFirstChild("GameData")
local latestRoom = gameData and gameData:FindFirstChild("LatestRoom")
local currentRooms = workspace:FindFirstChild("CurrentRooms")

if not latestRoom or not currentRooms then
    print("❌ Spiel-Objekte nicht gefunden!")
    return
end

-- ==========================================
-- FORTSCHRITT
-- ==========================================
local completedRooms = {}
local currentRoomNum = 0
local isProcessing = false

-- ==========================================
-- HELFER
-- ==========================================

local function getRoom()
    return latestRoom.Value
end

local function getRoomContainer(num)
    return currentRooms:FindFirstChild(tostring(num))
end

local function findDoor(room)
    if not room then return nil end
    return room:FindFirstChild("Door")
end

local function isDoorOpen(door)
    if not door then return false end
    return door:GetAttribute("Opened") == true
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

local function teleport(pos)
    local root = char:FindFirstChild("HumanoidRootPart")
    if root and pos then
        root.CFrame = CFrame.new(pos)
    end
end

local function collectItem(item)
    if not item then return false end
    local prompt = item:FindFirstChild("ProximityPrompt")
    if prompt then
        prompt:FireServer()
        wait(0.2)
        prompt:FireServer()
        return true
    end
    return false
end

-- ==========================================
-- "E" GEDRÜCKT HALTEN
-- ==========================================
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
    local start = tick()
    
    repeat
        prompt:FireServer()
        wait(0.05)
    until tick() - start > duration
    
    prompt:FireServer()
    return true
end

-- ==========================================
-- RAUM VERARBEITEN
-- ==========================================
local function processRoom(roomNum)
    if isProcessing then return end
    if completedRooms[roomNum] then return end
    isProcessing = true
    
    print("\n🏠 Raum " .. roomNum)
    
    -- Charakter prüfen
    char = player.Character
    if not char then
        player:LoadCharacter()
        wait(1)
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
    end
    
    -- Noclip
    if getgenv().Noclip then
        for _, part in pairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end
    
    -- Speed
    humanoid.WalkSpeed = getgenv().Walkspeed
    
    -- Raum-Container
    local room = getRoomContainer(roomNum)
    if not room then
        print("   ❌ Raum nicht gefunden!")
        isProcessing = false
        return
    end
    
    -- 1. KEYS & KNOBS sammeln
    if getgenv().AutoCollect then
        local keys = findKeys(room)
        for _, key in pairs(keys) do
            local pos = key:IsA("BasePart") and key.Position or 
                       (key:FindFirstChild("Handle") and key.Handle.Position)
            if pos then
                teleport(pos + Vector3.new(0, 1, 0))
                wait(0.2)
                collectItem(key)
                print("   🔑 Key eingesammelt!")
                wait(0.3)
                break
            end
        end
        
        local knobs = findKnobs(room)
        for _, knob in pairs(knobs) do
            local pos = knob:IsA("BasePart") and knob.Position or 
                       (knob:FindFirstChild("Handle") and knob.Handle.Position)
            if pos then
                teleport(pos + Vector3.new(0, 1, 0))
                wait(0.2)
                collectItem(knob)
                print("   💰 Knob eingesammelt!")
                wait(0.3)
                break
            end
        end
    end
    
    -- 2. TÜR FINDEN & ÖFFNEN
    local door = findDoor(room)
    if door then
        if isDoorOpen(door) then
            print("   🚪 Tür schon offen!")
        else
            print("   🚪 Öffne Tür...")
            local handle = door:FindFirstChild("Handle")
            if handle then
                teleport(handle.Position + Vector3.new(0, 0, 4))
                wait(0.5)
                holdE(door, 1.5)
                
                -- Warten, bis Tür offen ist
                local timeout = 10
                local start = tick()
                repeat
                    wait(0.2)
                until isDoorOpen(door) or tick() - start > timeout
                
                if isDoorOpen(door) then
                    print("   ✅ Tür geöffnet!")
                else
                    print("   ⚠️ Tür öffnet nicht!")
                end
            end
        end
        
        -- Durch die Tür gehen
        if isDoorOpen(door) then
            local handle = door:FindFirstChild("Handle")
            if handle then
                -- Vor die Tür gehen (nicht zurück!)
                local forward = root.CFrame.LookVector
                teleport(handle.Position + forward * 6)
                wait(0.3)
                completedRooms[roomNum] = true
                currentRoomNum = roomNum
                print("   ✅ Raum " .. roomNum .. " abgeschlossen!")
            end
        end
    else
        print("   ❌ Keine Tür!")
    end
    
    isProcessing = false
end

-- ==========================================
-- RAUM-LISTENER
-- ==========================================
local function startAutoPlay()
    if not getgenv().AutoPlay then return end
    
    print("🔄 Auto-Play V6 gestartet!")
    
    latestRoom:GetPropertyChangedSignal("Value"):Connect(function()
        if not getgenv().AutoPlay then return end
        
        local roomNum = getRoom()
        if not roomNum then return end
        if completedRooms[roomNum] then return end
        if isProcessing then return end
        
        processRoom(roomNum)
    end)
    
    -- Ersten Raum sofort verarbeiten
    wait(0.5)
    local roomNum = getRoom()
    if roomNum and not completedRooms[roomNum] then
        processRoom(roomNum)
    end
end

-- ==========================================
-- GUI
-- ==========================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsV6"
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 280, 0, 400)
mainFrame.Position = UDim2.new(0, 10, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
mainFrame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 35)
title.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
title.Text = "🤖 AUTO-PLAY V6"
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
scrollFrame.Size = UDim2.new(1, -10, 1, -45)
scrollFrame.Position = UDim2.new(0, 5, 0, 40)
scrollFrame.BackgroundTransparency = 1
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.ScrollBarThickness = 4
scrollFrame.Parent = mainFrame

local uiList = Instance.new("UIListLayout")
uiList.Padding = UDim.new(0, 4)
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Parent = scrollFrame

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

createToggle("▶️ Auto-Play", Color3.fromRGB(200, 100, 50),
    function() return getgenv().AutoPlay end,
    function(v) getgenv().AutoPlay = v end
)

createToggle("🔑 Auto-Collect", Color3.fromRGB(60, 120, 60),
    function() return getgenv().AutoCollect end,
    function(v) getgenv().AutoCollect = v end
)

createToggle("🛡️ Godmode", Color3.fromRGB(80, 50, 130),
    function() return getgenv().Godmode end,
    function(v) getgenv().Godmode = v end
)

createToggle("🌀 Noclip", Color3.fromRGB(50, 70, 150),
    function() return getgenv().Noclip end,
    function(v) getgenv().Noclip = v end
)

-- Speed
local speedFrame = Instance.new("Frame")
speedFrame.Size = UDim2.new(1, -10, 0, 40)
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

createButton("📊 Fortschritt", Color3.fromRGB(130, 130, 50), function()
    print("\n📊 FORTSCHRITT:")
    local sorted = {}
    for k in pairs(completedRooms) do
        table.insert(sorted, k)
    end
    table.sort(sorted)
    print("   Abgeschlossene Räume:", #sorted)
    if #sorted > 0 then
        print("   Letzter: Raum " .. sorted[#sorted])
        print("   Nächster: Raum " .. (sorted[#sorted] + 1))
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

mainFrame.InputEnded:Connect(function() dragging = false end)

userInputService.InputChanged:Connect(function(inp)
    if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
        mainFrame.Position = UDim2.new(0, fpx + inp.Position.X - dsx, 0, fpy + inp.Position.Y - dsy)
    end
end)

print("✅ Doors Auto-Play V6 geladen!")
print("📌 Einfach & zuverlässig!")
print("📌 Aktiviere Auto-Play!")
