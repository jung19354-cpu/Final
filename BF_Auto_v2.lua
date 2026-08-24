-- =============================================================
--  BF-Auto V5 | QUANTUM EDITION (BlueStacks + Delta)
--  Professionelles UI mit Key-System, Premium-Features
--  ALLES markieren -> direkt in die Delta-Konsole einkopieren -> Execute
-- =============================================================

--[[
    BF-Auto V5 - Ultimate Auto Farm Script
    Features:
    - Modernes UI mit Key-System
    - Auto Fruit Grab mit ESP
    - Auto Combat mit Target-Selektion
    - Auto Quests mit Level-Management
    - Premium-Features
    - Sicherheitsfunktionen
    - Performance optimiert
]]

-- =============================================================
-- KONFIGURATION
-- =============================================================
local CONFIG = {
    VERSION = "V5.0",
    FOLDER = "BF-Auto",
    KEY_FILE = "BF-Auto/Key.json",
    SCRIPT_ID = "bf_auto_v5",
    
    -- Standard Einstellungen
    TELEPORT_DELAY = 0.3,
    GRAB_DELAY = 1.5,
    FIGHT_DELAY = 1.2,
    QUEST_DELAY = 25,
    ESP_UPDATE = 0.5,
    STATUS_UPDATE = 2,
    MAX_FIGHT_DISTANCE = 250,
    SAFE_TELEPORT = true,
    AUTO_REVIVE = true,
    AUTO_EQUIP = true,
    AUTO_STATS = true,
}

-- =============================================================
-- SERVICES
-- =============================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

-- =============================================================
-- UTILITY FUNKTIONEN
-- =============================================================
local function GetHRB()
    local c = Player.Character
    if c then return c:FindFirstChild("HumanoidRootPart") end
    return nil
end

local function GetHumanoid()
    local c = Player.Character
    if c then return c:FindFirstChild("Humanoid") end
    return nil
end

local function IsAlive()
    local hum = GetHumanoid()
    return hum and hum.Health > 0
end

local function GetPlayerLevel()
    local success, lvl = pcall(function()
        local data = Player:FindFirstChild("Data")
        if data then
            local level = data:FindFirstChild("Level")
            if level then return level.Value end
        end
        return 0
    end)
    return success and math.floor(lvl) or 0
end

local function GetPlayerStats()
    local stats = {
        Level = GetPlayerLevel(),
        Health = 0,
        MaxHealth = 0,
        Stamina = 0,
        Beli = 0,
        Fruit = "None",
        Race = "Unknown"
    }
    
    local hum = GetHumanoid()
    if hum then
        stats.Health = math.floor(hum.Health)
        stats.MaxHealth = math.floor(hum.MaxHealth)
    end
    
    local data = Player:FindFirstChild("Data")
    if data then
        local beli = data:FindFirstChild("Beli")
        if beli then stats.Beli = beli.Value end
        
        local fruit = data:FindFirstChild("Fruit")
        if fruit then stats.Fruit = fruit.Value end
        
        local race = data:FindFirstChild("Race")
        if race then stats.Race = race.Value end
    end
    
    return stats
end

local function Teleport(pos, safe)
    if not pos then return end
    local hrb = GetHRB()
    if hrb then
        if CONFIG.SAFE_TELEPORT and safe then
            local ray = RaycastParams.new()
            ray.FilterType = Enum.RaycastFilterType.Blacklist
            ray.FilterDescendantsInstances = {Player.Character}
            
            local origin = pos + Vector3.new(0, 2, 0)
            local result = Workspace:Raycast(origin, Vector3.new(0, -4, 0), ray)
            
            if result then
                pos = result.Position + Vector3.new(0, 3, 0)
            end
        end
        hrb.CFrame = CFrame.new(pos)
    end
end

local function FindFruits()
    local list = {}
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and v.Name == "Fruit" then
            local handle = v:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                local fruitName = v:FindFirstChild("FruitName")
                table.insert(list, {
                    Model = v,
                    Handle = handle,
                    Position = handle.Position,
                    Name = fruitName and fruitName.Value or "Fruit"
                })
            end
        end
    end
    return list
end

local function NearestFruit()
    local hrb = GetHRB()
    if not hrb then return nil end
    
    local best, bestDist
    for _, f in pairs(FindFruits()) do
        local d = (f.Position - hrb.Position).magnitude
        if not best or d < bestDist then
            best = f
            bestDist = d
        end
    end
    return best, bestDist
end

local function GetClosestEnemy()
    local hrb = GetHRB()
    if not hrb then return nil end
    
    local enemies = {}
    local enemyFolder = Workspace:FindFirstChild("Enemies")
    if enemyFolder then
        for _, v in pairs(enemyFolder:GetChildren()) do
            local hum = v:FindFirstChild("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local dist = (hrp.Position - hrb.Position).magnitude
                table.insert(enemies, {
                    Enemy = v,
                    Distance = dist,
                    HRP = hrp,
                    Humanoid = hum,
                    Name = v.Name
                })
            end
        end
    end
    
    table.sort(enemies, function(a, b) return a.Distance < b.Distance end)
    return enemies[1]
end

local function EquipBestWeapon()
    if not CONFIG.AUTO_EQUIP then return end
    
    local backpack = Player:FindFirstChild("Backpack")
    if not backpack then return end
    
    local bestWeapon
    local bestDamage = 0
    
    for _, item in pairs(backpack:GetChildren()) do
        if item:IsA("Tool") then
            local damage = item:FindFirstChild("Damage") and item.Damage.Value or 0
            if damage > bestDamage then
                bestDamage = damage
                bestWeapon = item
            end
        end
    end
    
    if bestWeapon and bestWeapon.Parent == backpack then
        pcall(function()
            bestWeapon.Parent = Player.Character
        end)
    end
end

local function ToTime(expire)
    if not expire or expire <= 0 then return "Lifetime" end
    local left = expire - os.time()
    if left < 0 then return "Expired" end
    local days = math.floor(left / 86400)
    local hours = math.floor((left % 86400) / 3600)
    local minutes = math.floor((left % 3600) / 60)
    if days > 0 then return string.format("%dd %dh", days, hours) end
    if hours > 0 then return string.format("%dh %dm", hours, minutes) end
    return string.format("%dm", minutes)
end

-- =============================================================
-- KEY SYSTEM
-- =============================================================
local KEY_FILE = CONFIG.KEY_FILE

local function SaveKey(key)
    if not isfolder(CONFIG.FOLDER) then makefolder(CONFIG.FOLDER) end
    pcall(writefile, KEY_FILE, HttpService:JSONEncode({ key = key }))
end

local function LoadSavedKey()
    if isfolder(CONFIG.FOLDER) and isfile(KEY_FILE) then
        local ok, v = pcall(function()
            return HttpService:JSONDecode(readfile(KEY_FILE))
        end)
        if ok and type(v) == "table" and v.key then return v.key end
    end
    return ""
end

local function ClearKey()
    if not isfolder(CONFIG.FOLDER) then makefolder(CONFIG.FOLDER) end
    pcall(writefile, KEY_FILE, HttpService:JSONEncode({}))
end

-- =============================================================
-- UI SYSTEM (Quantum Style)
-- =============================================================
local function CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BF_Auto_V5"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = CoreGui
    
    -- Main Frame
    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 320, 0, 400)
    Main.Position = UDim2.new(0, 10, 0, 10)
    Main.BackgroundColor3 = Color3.fromRGB(8, 4, 20)
    Main.BackgroundTransparency = 0.15
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = Main
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(120, 60, 220)
    MainStroke.Transparency = 0.4
    MainStroke.Thickness = 1.5
    MainStroke.Parent = Main
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 40)
    Header.BackgroundColor3 = Color3.fromRGB(12, 6, 25)
    Header.BackgroundTransparency = 0.5
    Header.BorderSizePixel = 0
    Header.Parent = Main
    
    local HeaderCorner = Instance.new("UICorner")
    HeaderCorner.CornerRadius = UDim.new(0, 12)
    HeaderCorner.Parent = Header
    
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -60, 1, 0)
    Title.Position = UDim2.new(0, 10, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = "⚡ BF-Auto V5"
    Title.TextColor3 = Color3.fromRGB(200, 160, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    local VersionLabel = Instance.new("TextLabel")
    VersionLabel.Size = UDim2.new(0, 60, 1, 0)
    VersionLabel.Position = UDim2.new(1, -70, 0, 0)
    VersionLabel.BackgroundTransparency = 1
    VersionLabel.Text = "v5.0"
    VersionLabel.TextColor3 = Color3.fromRGB(100, 80, 150)
    VersionLabel.Font = Enum.Font.GothamBold
    VersionLabel.TextSize = 11
    VersionLabel.TextXAlignment = Enum.TextXAlignment.Right
    VersionLabel.Parent = Header
    
    -- Divider
    local Divider = Instance.new("Frame")
    Divider.Size = UDim2.new(1, -20, 0, 1)
    Divider.Position = UDim2.new(0, 10, 0, 40)
    Divider.BackgroundColor3 = Color3.fromRGB(120, 60, 220)
    Divider.BackgroundTransparency = 0.7
    Divider.BorderSizePixel = 0
    Divider.Parent = Main
    
    -- Content Scroller
    local Scrolling = Instance.new("ScrollingFrame")
    Scrolling.Size = UDim2.new(1, -20, 1, -50)
    Scrolling.Position = UDim2.new(0, 10, 0, 45)
    Scrolling.BackgroundTransparency = 1
    Scrolling.BorderSizePixel = 0
    Scrolling.ScrollBarThickness = 4
    Scrolling.ScrollBarImageColor3 = Color3.fromRGB(120, 60, 220)
    Scrolling.CanvasSize = UDim2.new(0, 0, 0, 500)
    Scrolling.Parent = Main
    
    -- Status Bar
    local StatusBar = Instance.new("Frame")
    StatusBar.Size = UDim2.new(1, -20, 0, 25)
    StatusBar.Position = UDim2.new(0, 10, 1, -35)
    StatusBar.BackgroundColor3 = Color3.fromRGB(12, 6, 25)
    StatusBar.BackgroundTransparency = 0.7
    StatusBar.BorderSizePixel = 0
    StatusBar.Parent = Main
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 6)
    StatusCorner.Parent = StatusBar
    
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -10, 1, 0)
    StatusLabel.Position = UDim2.new(0, 5, 0, 0)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "🟢 Bereit"
    StatusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
    StatusLabel.Font = Enum.Font.Gotham
    StatusLabel.TextSize = 11
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = StatusBar
    
    -- Toggle Buttons
    local function CreateToggle(parent, y, label, icon, default)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, -10, 0, 28)
        btn.Position = UDim2.new(0, 5, 0, y)
        btn.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel = 0
        btn.Text = ""
        btn.AutoButtonColor = false
        btn.ClipsDescendants = true
        btn.Parent = parent
        
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 6)
        btnCorner.Parent = btn
        
        local btnStroke = Instance.new("UIStroke")
        btnStroke.Color = Color3.fromRGB(100, 50, 190)
        btnStroke.Transparency = 0.5
        btnStroke.Thickness = 1
        btnStroke.Parent = btn
        
        local lbl = Instance.new("TextLabel")
        lbl.Size = UDim2.new(1, -50, 1, 0)
        lbl.Position = UDim2.new(0, 30, 0, 0)
        lbl.BackgroundTransparency = 1
        lbl.Text = icon .. " " .. label .. "  [OFF]"
        lbl.TextColor3 = Color3.fromRGB(200, 180, 230)
        lbl.Font = Enum.Font.GothamBold
        lbl.TextSize = 12
        lbl.TextXAlignment = Enum.TextXAlignment.Left
        lbl.Parent = btn
        
        local status = false
        
        btn.MouseButton1Click:Connect(function()
            status = not status
            lbl.Text = icon .. " " .. label .. "  [" .. (status and "ON" or "OFF") .. "]"
            btn.BackgroundColor3 = status and Color3.fromRGB(30, 80, 40) or Color3.fromRGB(20, 10, 40)
            btnStroke.Color = status and Color3.fromRGB(50, 200, 80) or Color3.fromRGB(100, 50, 190)
        end)
        
        return btn, function() return status end
    end
    
    -- Create Toggles
    local yPos = 5
    local espBtn, getESP = CreateToggle(Scrolling, yPos, "ESP Früchte", "👁️")
    yPos = yPos + 33
    local grabBtn, getGrab = CreateToggle(Scrolling, yPos, "Auto Früchte", "🍎")
    yPos = yPos + 33
    local fightBtn, getFight = CreateToggle(Scrolling, yPos, "Auto Kampf", "⚔️")
    yPos = yPos + 33
    local questBtn, getQuest = CreateToggle(Scrolling, yPos, "Auto Quests", "📜")
    yPos = yPos + 33
    local safeBtn, getSafe = CreateToggle(Scrolling, yPos, "Safe Teleport", "🛡️")
    yPos = yPos + 33
    local reviveBtn, getRevive = CreateToggle(Scrolling, yPos, "Auto Revive", "💀")
    yPos = yPos + 33
    local statBtn, getStat = CreateToggle(Scrolling, yPos, "Auto Stats", "📊")
    yPos = yPos + 33
    
    -- Info Display
    local InfoFrame = Instance.new("Frame")
    InfoFrame.Size = UDim2.new(1, -10, 0, 80)
    InfoFrame.Position = UDim2.new(0, 5, 0, yPos + 5)
    InfoFrame.BackgroundColor3 = Color3.fromRGB(12, 6, 25)
    InfoFrame.BackgroundTransparency = 0.7
    InfoFrame.BorderSizePixel = 0
    InfoFrame.Parent = Scrolling
    
    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 6)
    InfoCorner.Parent = InfoFrame
    
    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(1, -10, 1, 0)
    InfoLabel.Position = UDim2.new(0, 5, 0, 5)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = "📊 Level: 0\n🍎 Früchte: 0\n❤️ HP: 0/0"
    InfoLabel.TextColor3 = Color3.fromRGB(180, 160, 220)
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.TextSize = 11
    InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
    InfoLabel.TextLineHeight = 1.2
    InfoLabel.Parent = InfoFrame
    
    -- Close Button
    local CloseBtn = Instance.new("ImageButton")
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -25, 0, 10)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Image = "rbxassetid://79324227570635"
    CloseBtn.ImageColor3 = Color3.fromRGB(200, 80, 80)
    CloseBtn.Parent = Header
    
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    -- Drag Functionality
    local dragging = false
    local dragStart
    local startPos
    
    Header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
        end
    end)
    
    Header.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    return {
        GetESP = getESP,
        GetGrab = getGrab,
        GetFight = getFight,
        GetQuest = getQuest,
        GetSafe = getSafe,
        GetRevive = getRevive,
        GetStat = getStat,
        SetStatus = function(text, color)
            StatusLabel.Text = text
            if color then
                StatusLabel.TextColor3 = color
            end
        end,
        UpdateInfo = function(stats)
            local fruitCount = #FindFruits()
            InfoLabel.Text = string.format(
                "📊 Level: %d\n🍎 Früchte: %d\n❤️ HP: %d/%d\n💰 Beli: %s",
                stats.Level or 0,
                fruitCount,
                stats.Health or 0,
                stats.MaxHealth or 0,
                tostring(stats.Beli or 0)
            )
        end
    }
end

-- =============================================================
-- FEATURES
-- =============================================================
local function StartFeatures(UI)
    -- ESP System
    spawn(function()
        while wait(CONFIG.ESP_UPDATE) do
            if not UI.GetESP() then
                for _, f in pairs(FindFruits()) do
                    local old = f.Handle:FindFirstChild("BF_ESP")
                    if old then old:Destroy() end
                end
            else
                for _, f in pairs(FindFruits()) do
                    local bb = f.Handle:FindFirstChild("BF_ESP")
                    if not bb then
                        bb = Instance.new("BillboardGui")
                        bb.Name = "BF_ESP"
                        bb.Size = UDim2.new(0, 200, 0, 35)
                        bb.AlwaysFaceCamera = true
                        bb.MaxDistance = 500
                        bb.StudsOffset = Vector3.new(0, 3, 0)
                        bb.Parent = f.Handle
                        
                        local label = Instance.new("TextLabel")
                        label.Name = "Label"
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundColor3 = Color3.fromRGB(255, 100, 0)
                        label.BackgroundTransparency = 0.2
                        label.Text = "🍎 " .. f.Name
                        label.Font = Enum.Font.GothamBold
                        label.TextSize = 14
                        label.TextColor3 = Color3.new(1, 1, 1)
                        label.Parent = bb
                        
                        local dist = Instance.new("TextLabel")
                        dist.Name = "Distance"
                        dist.Size = UDim2.new(1, 0, 0, 14)
                        dist.Position = UDim2.new(0, 0, 1, 0)
                        dist.BackgroundTransparency = 1
                        dist.Text = "0m"
                        dist.Font = Enum.Font.Gotham
                        dist.TextSize = 11
                        dist.TextColor3 = Color3.new(1, 1, 0.5)
                        dist.Parent = bb
                    end
                    
                    local distLabel = bb:FindFirstChild("Distance")
                    if distLabel and Player.Character then
                        local hrb = GetHRB()
                        if hrb then
                            local dist = (f.Position - hrb.Position).magnitude
                            distLabel.Text = math.floor(dist) .. "m"
                            distLabel.TextColor3 = dist < 100 and Color3.new(0, 1, 0) or
                                                  dist < 300 and Color3.new(1, 1, 0) or
                                                  Color3.new(1, 0, 0)
                        end
                    end
                end
            end
        end
    end)
    
    -- Auto Grab
    spawn(function()
        while wait(CONFIG.GRAB_DELAY) do
            if UI.GetGrab() then
                local f, dist = NearestFruit()
                if f then
                    UI.SetStatus("🍎 Frucht gefunden (" .. math.floor(dist) .. "m)", Color3.fromRGB(255, 200, 100))
                    Teleport(f.Position + Vector3.new(0, 2, 0), UI.GetSafe())
                    wait(CONFIG.TELEPORT_DELAY)
                else
                    UI.SetStatus("🍎 Keine Früchte in der Nähe", Color3.fromRGB(200, 200, 200))
                end
            end
        end
    end)
    
    -- Auto Fight
    spawn(function()
        while wait(CONFIG.FIGHT_DELAY) do
            if UI.GetFight() then
                if UI.GetRevive() and not IsAlive() then
                    UI.SetStatus("💀 Wiederbeleben...", Color3.fromRGB(255, 100, 100))
                    pcall(function()
                        ReplicatedStorage.Remotes.Character:FireServer("Revive")
                    end)
                    wait(2)
                    continue
                end
                
                EquipBestWeapon()
                
                local target = GetClosestEnemy()
                if target and target.Distance < CONFIG.MAX_FIGHT_DISTANCE then
                    UI.SetStatus("⚔️ Kämpfe gegen: " .. target.Name, Color3.fromRGB(255, 150, 100))
                    Teleport(target.HRP.Position + Vector3.new(0, 2, 0), UI.GetSafe())
                    wait(0.2)
                    
                    pcall(function()
                        ReplicatedStorage.Remotes.Combat:FireServer("Attack", target.Enemy)
                    end)
                    
                    wait(0.3)
                    if target.Distance < 20 then
                        pcall(function()
                            ReplicatedStorage.Remotes.Combat:FireServer("Attack", target.Enemy)
                        end)
                    end
                else
                    UI.SetStatus("⚔️ Keine Gegner in Reichweite", Color3.fromRGB(200, 200, 200))
                end
            end
        end
    end)
    
    -- Auto Quests
    local questList = {
        {Level = 700,  NPC = "Raiders",              Name = "RaidersQuest"},
        {Level = 725,  NPC = "Mercenaries",          Name = "MercenariesQuest"},
        {Level = 750,  NPC = "Diamond",              Name = "DiamondBossQuest"},
        {Level = 775,  NPC = "Swan Pirates",         Name = "SwanPiratesQuest"},
        {Level = 800,  NPC = "Factory Staff",        Name = "FactoryQuest"},
        {Level = 850,  NPC = "Jeremy",               Name = "JeremyBossQuest"},
        {Level = 875,  NPC = "Marine Lieutenants",   Name = "MarineLieutenantQuest"},
        {Level = 900,  NPC = "Marine Captains",      Name = "MarineCaptainQuest"},
        {Level = 925,  NPC = "Fajita",               Name = "FajitaBossQuest"},
        {Level = 950,  NPC = "Zombies",              Name = "ZombieQuest"},
        {Level = 975,  NPC = "Vampires",             Name = "VampireQuest"},
        {Level = 1000, NPC = "Snow Troopers",        Name = "SnowTrooperQuest"},
        {Level = 1050, NPC = "Winter Warriors",      Name = "WinterWarriorQuest"},
        {Level = 1100, NPC = "Lab Subordinates",     Name = "LabSubordinateQuest"},
        {Level = 1125, NPC = "Horned Warriors",      Name = "HornedWarriorQuest"},
        {Level = 1150, NPC = "Smoke Admiral",        Name = "SmokeAdmiralBossQuest"},
        {Level = 1425, NPC = "Sea Soldiers",         Name = "SeaSoldierQuest"},
        {Level = 1450, NPC = "Water Fighters",       Name = "WaterFighterQuest"},
        {Level = 1475, NPC = "Tide Keeper",          Name = "TideKeeperBossQuest"},
    }
    
    spawn(function()
        while wait(CONFIG.QUEST_DELAY) do
            if UI.GetQuest() then
                if not IsAlive() then
                    UI.SetStatus("📜 Warte auf Wiederbelebung...", Color3.fromRGB(255, 200, 100))
                    wait(3)
                    continue
                end
                
                local lvl = GetPlayerLevel()
                local bestQ
                for i = #questList, 1, -1 do
                    if lvl >= questList[i].Level then
                        bestQ = questList[i]
                        break
                    end
                end
                
                if bestQ then
                    UI.SetStatus("📜 Suche NPC: " .. bestQ.NPC, Color3.fromRGB(100, 200, 255))
                    local npc = Workspace:FindFirstChild(bestQ.NPC)
                    
                    if npc then
                        local npcPos = npc:GetPivot()
                        if npcPos then
                            Teleport(npcPos.Position + Vector3.new(0, 5, 0), UI.GetSafe())
                            wait(1)
                            
                            local success = pcall(function()
                                local questRemote = ReplicatedStorage:FindFirstChild("Remotes")
                                if questRemote then
                                    local questEvent = questRemote:FindFirstChild("QuestEvent")
                                    if questEvent then
                                        questEvent:FireServer("StartQuest", bestQ.Name)
                                    end
                                end
                            end)
                            
                            if success then
                                UI.SetStatus("✅ Quest gestartet: " .. bestQ.Name, Color3.fromRGB(100, 255, 100))
                            else
                                UI.SetStatus("❌ Quest Remote nicht gefunden!", Color3.fromRGB(255, 100, 100))
                            end
                        end
                    else
                        UI.SetStatus("❌ NPC nicht gefunden: " .. bestQ.NPC, Color3.fromRGB(255, 100, 100))
                    end
                else
                    UI.SetStatus("📜 Level zu niedrig (" .. lvl .. ")", Color3.fromRGB(255, 200, 100))
                end
            end
        end
    end)
    
    -- Status Update
    spawn(function()
        while wait(CONFIG.STATUS_UPDATE) do
            local stats = GetPlayerStats()
            UI.UpdateInfo(stats)
        end
    end)
end

-- =============================================================
-- KEYBOARD SHORTCUTS
-- =============================================================
local function SetupShortcuts(UI)
    UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        
        if input.KeyCode == Enum.KeyCode.F1 then
            espBtn:Fire()
        elseif input.KeyCode == Enum.KeyCode.F2 then
            grabBtn:Fire()
        elseif input.KeyCode == Enum.KeyCode.F3 then
            fightBtn:Fire()
        elseif input.KeyCode == Enum.KeyCode.F4 then
            questBtn:Fire()
        elseif input.KeyCode == Enum.KeyCode.F5 then
            safeBtn:Fire()
        elseif input.KeyCode == Enum.KeyCode.F6 then
            reviveBtn:Fire()
        end
    end)
end

-- =============================================================
-- MAIN
-- =============================================================
local function Main()
    -- Create UI
    local UI = CreateUI()
    UI.SetStatus("🟢 BF-Auto V5 gestartet!", Color3.fromRGB(150, 255, 150))
    
    -- Setup Shortcuts
    SetupShortcuts(UI)
    
    -- Start Features
    StartFeatures(UI)
    
    -- Notification
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "⚡ BF-Auto V5",
            Text = "Gestartet! F1-F6 für Shortcuts",
            Duration = 5,
        })
    end)
    
    print("✅ BF-Auto V5: Alle Systeme aktiv!")
    warn("⚡ BF-Auto V5 gestartet! F1-ESP, F2-Grab, F3-Kampf, F4-Quest, F5-SafeTP, F6-Revive")
end

-- =============================================================
-- START
-- =============================================================
-- Error Handler
local xpcallOk, xpcallErr = xpcall(Main, function(err)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "❌ BF-Auto Error",
            Text = tostring(err),
            Duration = 10,
        })
    end)
    warn("[BF-Auto] Error: " .. tostring(err))
end)

if not xpcallOk then
    warn("[BF-Auto] Failed to start: " .. tostring(xpcallErr))
end
