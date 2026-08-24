-- =============================================================
--  BF-Auto V6 | ULTIMATE AUTO-PLAY (BlueStacks + Delta)
--  Komplett automatischer Bot - spielt das gesamte Spiel durch
--  ALLES markieren -> direkt in die Delta-Konsole einkopieren -> Execute
-- =============================================================

--[[
    BF-Auto V6 - Ultimate Auto-Play Bot
    Features:
    - Vollautomatisches Durchspielen von Level 1 bis Max
    - Intelligente Fruit-Strategie (kauft/sucht die besten Früchte)
    - Automatische Stat-Verteilung (optimal für Build)
    - Boss-Farming mit Reset
    - Raid-Farming
    - Sea Beast Hunting
    - Auto-Trade
    - Geld-Management
    - Optimierte Quest-Auswahl
    - 24/7 Farming
]]

-- =============================================================
-- SERVICES
-- =============================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local StarterGui = game:GetService("StarterGui")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

-- =============================================================
-- KONFIGURATION
-- =============================================================
local CONFIG = {
    VERSION = "V6.0",
    
    -- Allgemein
    AUTO_START = true,
    SAFE_MODE = true,
    DEBUG = false,
    
    -- Farming
    AUTO_LEVEL = true,
    AUTO_QUEST = true,
    AUTO_BOSS = true,
    AUTO_RAID = true,
    AUTO_SEA_BEAST = true,
    AUTO_FRUIT = true,
    AUTO_TRADE = true,
    AUTO_STATS = true,
    
    -- Einstellungen
    TELEPORT_DELAY = 0.2,
    FARM_DELAY = 0.5,
    CHECK_INTERVAL = 2,
    MAX_DISTANCE = 300,
    BOSS_RESET_TIME = 60,
    RAID_WAIT_TIME = 30,
    
    -- Geld-Management
    MIN_BELI_FOR_FRUIT = 1000000,
    SAVE_BELI_PERCENT = 20,
    AUTO_BUY_FRUIT = true,
    
    -- Früchte
    TARGET_FRUITS = {
        "Venom", "Dough", "Dragon", "Leopard", "Dark",
        "Light", "Flame", "Ice", "Gravity", "Shadow"
    },
    BEST_FRUITS = {
        "Venom", "Dough", "Dragon", "Leopard"
    },
    
    -- Stats
    STAT_PRIORITY = {
        "Melee",
        "Defense",
        "Sword",
        "Gun",
        "Fruit"
    },
    STATS_TO_LEVEL = 2550,
}

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

local function Teleport(pos, safe)
    if not pos then return end
    local hrb = GetHRB()
    if hrb then
        if CONFIG.SAFE_MODE and safe then
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

local function GetPlayerData()
    local data = {
        Level = 0,
        Beli = 0,
        Fruit = "None",
        Race = "Unknown",
        Stats = {Melee = 0, Defense = 0, Sword = 0, Gun = 0, Fruit = 0},
        MaxLevel = 2550,
        CanRaid = false,
        SeaBeastKills = 0,
        BossKills = 0
    }
    
    local playerData = Player:FindFirstChild("Data")
    if playerData then
        local level = playerData:FindFirstChild("Level")
        if level then data.Level = level.Value end
        
        local beli = playerData:FindFirstChild("Beli")
        if beli then data.Beli = beli.Value end
        
        local fruit = playerData:FindFirstChild("Fruit")
        if fruit then data.Fruit = fruit.Value end
        
        local race = playerData:FindFirstChild("Race")
        if race then data.Race = race.Value end
        
        -- Stats
        local stats = playerData:FindFirstChild("Stats")
        if stats then
            for _, stat in pairs({"Melee", "Defense", "Sword", "Gun", "Fruit"}) do
                local s = stats:FindFirstChild(stat)
                if s then data.Stats[stat] = s.Value end
            end
        end
    end
    
    return data
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
                    Name = fruitName and fruitName.Value or "Fruit",
                    Rarity = v:FindFirstChild("Rarity") and v.Rarity.Value or "Common"
                })
            end
        end
    end
    return list
end

local function GetBosses()
    local bosses = {}
    local enemyFolder = Workspace:FindFirstChild("Enemies")
    if enemyFolder then
        for _, v in pairs(enemyFolder:GetChildren()) do
            if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
                if v.Name:find("Boss") or v.Name:find("King") or v.Name:find("Admiral") then
                    table.insert(bosses, v)
                end
            end
        end
    end
    return bosses
end

local function GetNearestEnemy()
    local hrb = GetHRB()
    if not hrb then return nil end
    
    local nearest
    local nearestDist = math.huge
    
    local enemyFolder = Workspace:FindFirstChild("Enemies")
    if enemyFolder then
        for _, v in pairs(enemyFolder:GetChildren()) do
            local hum = v:FindFirstChild("Humanoid")
            local hrp = v:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local dist = (hrp.Position - hrb.Position).magnitude
                if dist < nearestDist then
                    nearestDist = dist
                    nearest = v
                end
            end
        end
    end
    
    return nearest, nearestDist
end

local function GetSeaBeasts()
    local beasts = {}
    for _, v in pairs(Workspace:GetChildren()) do
        if v:IsA("Model") and (v.Name:find("Sea") or v.Name:find("Beast") or v.Name:find("SeaBeast")) then
            if v:FindFirstChild("Humanoid") and v:FindFirstChild("HumanoidRootPart") then
                table.insert(beasts, v)
            end
        end
    end
    return beasts
end

-- =============================================================
-- ADVANCED FARMING LOGIC
-- =============================================================
local FarmLogic = {
    CurrentTask = "Idle",
    CompletedQuests = {},
    BossTimer = 0,
    RaidReady = false,
    SeaBeastTimer = 0,
    FruitCooldown = 0,
    
    -- Level-basierte Strategie
    GetStrategy = function(level)
        if level < 50 then
            return {
                Location = "Jungle",
                Quest = "BanditQuest",
                Enemy = "Bandit",
                Priority = "Level"
            }
        elseif level < 100 then
            return {
                Location = "Desert",
                Quest = "DesertQuest",
                Enemy = "Desert Bandit",
                Priority = "Level"
            }
        elseif level < 200 then
            return {
                Location = "Ice",
                Quest = "IceQuest",
                Enemy = "Snow",
                Priority = "Level"
            }
        elseif level < 350 then
            return {
                Location = "Prison",
                Quest = "PrisonQuest",
                Enemy = "Prisoner",
                Priority = "Level"
            }
        elseif level < 500 then
            return {
                Location = "Magma",
                Quest = "MagmaQuest",
                Enemy = "Magma",
                Priority = "Level"
            }
        elseif level < 700 then
            return {
                Location = "Fishman",
                Quest = "FishmanQuest",
                Enemy = "Fishman",
                Priority = "Level"
            }
        elseif level < 900 then
            return {
                Location = "Sky",
                Quest = "SkyQuest",
                Enemy = "Sky",
                Priority = "Level"
            }
        elseif level < 1100 then
            return {
                Location = "Sea",
                Quest = "SeaQuest",
                Enemy = "Sea Soldier",
                Priority = "Level"
            }
        elseif level < 1350 then
            return {
                Location = "Fajita",
                Quest = "FajitaBossQuest",
                Enemy = "Fajita",
                Priority = "Boss"
            }
        elseif level < 1550 then
            return {
                Location = "Dragon",
                Quest = "DragonQuest",
                Enemy = "Dragon",
                Priority = "Boss"
            }
        elseif level < 1800 then
            return {
                Location = "Venom",
                Quest = "VenomQuest",
                Enemy = "Venom",
                Priority = "Boss"
            }
        elseif level < 2000 then
            return {
                Location = "Dough",
                Quest = "DoughQuest",
                Enemy = "Dough",
                Priority = "Boss"
            }
        elseif level < 2200 then
            return {
                Location = "Dragon",
                Quest = "DragonBossQuest",
                Enemy = "Dragon Boss",
                Priority = "Boss"
            }
        else
            return {
                Location = "Endgame",
                Quest = "EndgameQuest",
                Enemy = "Endgame",
                Priority = "Raid"
            }
        end
    end,
    
    -- Beste Quest finden
    GetBestQuest = function(level)
        local quests = {
            {Level = 0, Name = "BanditQuest", NPC = "Bandit"},
            {Level = 50, Name = "DesertQuest", NPC = "Desert"},
            {Level = 100, Name = "IceQuest", NPC = "Ice"},
            {Level = 200, Name = "PrisonQuest", NPC = "Prison"},
            {Level = 350, Name = "MagmaQuest", NPC = "Magma"},
            {Level = 500, Name = "FishmanQuest", NPC = "Fishman"},
            {Level = 700, Name = "SkyQuest", NPC = "Sky"},
            {Level = 900, Name = "SeaQuest", NPC = "Sea"},
            {Level = 1100, Name = "FajitaBossQuest", NPC = "Fajita"},
            {Level = 1350, Name = "DragonQuest", NPC = "Dragon"},
            {Level = 1550, Name = "VenomQuest", NPC = "Venom"},
            {Level = 1800, Name = "DoughQuest", NPC = "Dough"},
            {Level = 2000, Name = "DragonBossQuest", NPC = "Dragon Boss"},
            {Level = 2200, Name = "EndgameQuest", NPC = "Endgame"},
        }
        
        local best
        for i = #quests, 1, -1 do
            if level >= quests[i].Level then
                best = quests[i]
                break
            end
        end
        return best
    end
}

-- =============================================================
-- UI SYSTEM
-- =============================================================
local function CreateUI()
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "BF_Auto_V6"
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.Parent = CoreGui
    
    -- Main Frame
    local Main = Instance.new("Frame")
    Main.Size = UDim2.new(0, 350, 0, 500)
    Main.Position = UDim2.new(0, 10, 0, 10)
    Main.BackgroundColor3 = Color3.fromRGB(6, 3, 15)
    Main.BackgroundTransparency = 0.1
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Parent = ScreenGui
    
    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(0, 12)
    MainCorner.Parent = Main
    
    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = Color3.fromRGB(100, 50, 220)
    MainStroke.Transparency = 0.3
    MainStroke.Thickness = 1.5
    MainStroke.Parent = Main
    
    -- Header
    local Header = Instance.new("Frame")
    Header.Size = UDim2.new(1, 0, 0, 45)
    Header.BackgroundColor3 = Color3.fromRGB(10, 5, 22)
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
    Title.Text = "🤖 BF-Auto V6 - Ultimate Bot"
    Title.TextColor3 = Color3.fromRGB(200, 160, 255)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 14
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    -- Status Section
    local StatusFrame = Instance.new("Frame")
    StatusFrame.Size = UDim2.new(1, -20, 0, 80)
    StatusFrame.Position = UDim2.new(0, 10, 0, 50)
    StatusFrame.BackgroundColor3 = Color3.fromRGB(10, 5, 22)
    StatusFrame.BackgroundTransparency = 0.7
    StatusFrame.BorderSizePixel = 0
    StatusFrame.Parent = Main
    
    local StatusCorner = Instance.new("UICorner")
    StatusCorner.CornerRadius = UDim.new(0, 8)
    StatusCorner.Parent = StatusFrame
    
    local StatusLabel = Instance.new("TextLabel")
    StatusLabel.Size = UDim2.new(1, -10, 0.5, 0)
    StatusLabel.Position = UDim2.new(0, 5, 0, 3)
    StatusLabel.BackgroundTransparency = 1
    StatusLabel.Text = "🟢 Initialisiere..."
    StatusLabel.TextColor3 = Color3.fromRGB(150, 255, 150)
    StatusLabel.Font = Enum.Font.GothamBold
    StatusLabel.TextSize = 13
    StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    StatusLabel.Parent = StatusFrame
    
    local TaskLabel = Instance.new("TextLabel")
    TaskLabel.Size = UDim2.new(1, -10, 0.5, 0)
    TaskLabel.Position = UDim2.new(0, 5, 0.5, 2)
    TaskLabel.BackgroundTransparency = 1
    TaskLabel.Text = "📋 Aufgabe: Warten..."
    TaskLabel.TextColor3 = Color3.fromRGB(180, 180, 220)
    TaskLabel.Font = Enum.Font.Gotham
    TaskLabel.TextSize = 11
    TaskLabel.TextXAlignment = Enum.TextXAlignment.Left
    TaskLabel.Parent = StatusFrame
    
    -- Info Section
    local InfoFrame = Instance.new("Frame")
    InfoFrame.Size = UDim2.new(1, -20, 0, 120)
    InfoFrame.Position = UDim2.new(0, 10, 0, 135)
    InfoFrame.BackgroundColor3 = Color3.fromRGB(10, 5, 22)
    InfoFrame.BackgroundTransparency = 0.7
    InfoFrame.BorderSizePixel = 0
    InfoFrame.Parent = Main
    
    local InfoCorner = Instance.new("UICorner")
    InfoCorner.CornerRadius = UDim.new(0, 8)
    InfoCorner.Parent = InfoFrame
    
    local InfoLabel = Instance.new("TextLabel")
    InfoLabel.Size = UDim2.new(1, -10, 1, 0)
    InfoLabel.Position = UDim2.new(0, 5, 0, 5)
    InfoLabel.BackgroundTransparency = 1
    InfoLabel.Text = "📊 Level: 0\n💰 Beli: 0\n🍎 Fruit: None\n⚔️ Stats: 0/0/0/0/0"
    InfoLabel.TextColor3 = Color3.fromRGB(180, 160, 220)
    InfoLabel.Font = Enum.Font.Gotham
    InfoLabel.TextSize = 11
    InfoLabel.TextXAlignment = Enum.TextXAlignment.Left
    InfoLabel.TextYAlignment = Enum.TextYAlignment.Top
    InfoLabel.TextLineHeight = 1.3
    InfoLabel.Parent = InfoFrame
    
    -- Controls
    local ControlsFrame = Instance.new("Frame")
    ControlsFrame.Size = UDim2.new(1, -20, 0, 110)
    ControlsFrame.Position = UDim2.new(0, 10, 0, 260)
    ControlsFrame.BackgroundColor3 = Color3.fromRGB(10, 5, 22)
    ControlsFrame.BackgroundTransparency = 0.7
    ControlsFrame.BorderSizePixel = 0
    ControlsFrame.Parent = Main
    
    local ControlsCorner = Instance.new("UICorner")
    ControlsCorner.CornerRadius = UDim.new(0, 8)
    ControlsCorner.Parent = ControlsFrame
    
    local StartBtn = Instance.new("TextButton")
    StartBtn.Size = UDim2.new(0.45, -5, 0, 35)
    StartBtn.Position = UDim2.new(0.05, 0, 0.15, 0)
    StartBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 40)
    StartBtn.BackgroundTransparency = 0.5
    StartBtn.BorderSizePixel = 0
    StartBtn.Text = "▶️ Start Bot"
    StartBtn.TextColor3 = Color3.fromRGB(150, 255, 150)
    StartBtn.Font = Enum.Font.GothamBold
    StartBtn.TextSize = 12
    StartBtn.Parent = ControlsFrame
    
    local StartCorner = Instance.new("UICorner")
    StartCorner.CornerRadius = UDim.new(0, 6)
    StartCorner.Parent = StartBtn
    
    local StopBtn = Instance.new("TextButton")
    StopBtn.Size = UDim2.new(0.45, -5, 0, 35)
    StopBtn.Position = UDim2.new(0.5, 5, 0.15, 0)
    StopBtn.BackgroundColor3 = Color3.fromRGB(80, 30, 30)
    StopBtn.BackgroundTransparency = 0.5
    StopBtn.BorderSizePixel = 0
    StopBtn.Text = "⏹️ Stop Bot"
    StopBtn.TextColor3 = Color3.fromRGB(255, 150, 150)
    StopBtn.Font = Enum.Font.GothamBold
    StopBtn.TextSize = 12
    StopBtn.Parent = ControlsFrame
    
    local StopCorner = Instance.new("UICorner")
    StopCorner.CornerRadius = UDim.new(0, 6)
    StopCorner.Parent = StopBtn
    
    -- Progress Bar
    local ProgressFrame = Instance.new("Frame")
    ProgressFrame.Size = UDim2.new(0.9, 0, 0, 20)
    ProgressFrame.Position = UDim2.new(0.05, 0, 0.65, 0)
    ProgressFrame.BackgroundColor3 = Color3.fromRGB(20, 10, 40)
    ProgressFrame.BackgroundTransparency = 0.5
    ProgressFrame.BorderSizePixel = 0
    ProgressFrame.Parent = ControlsFrame
    
    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(0, 10)
    ProgressCorner.Parent = ProgressFrame
    
    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(0, 0, 1, 0)
    ProgressBar.BackgroundColor3 = Color3.fromRGB(100, 50, 220)
    ProgressBar.BackgroundTransparency = 0.3
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = ProgressFrame
    
    local ProgressCorner2 = Instance.new("UICorner")
    ProgressCorner2.CornerRadius = UDim.new(0, 10)
    ProgressCorner2.Parent = ProgressBar
    
    local ProgressLabel = Instance.new("TextLabel")
    ProgressLabel.Size = UDim2.new(1, 0, 1, 0)
    ProgressLabel.BackgroundTransparency = 1
    ProgressLabel.Text = "0%"
    ProgressLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    ProgressLabel.Font = Enum.Font.GothamBold
    ProgressLabel.TextSize = 10
    ProgressLabel.Parent = ProgressFrame
    
    -- Close Button
    local CloseBtn = Instance.new("ImageButton")
    CloseBtn.Size = UDim2.new(0, 20, 0, 20)
    CloseBtn.Position = UDim2.new(1, -25, 0, 12)
    CloseBtn.BackgroundTransparency = 1
    CloseBtn.Image = "rbxassetid://79324227570635"
    CloseBtn.ImageColor3 = Color3.fromRGB(200, 80, 80)
    CloseBtn.Parent = Header
    
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
    end)
    
    -- Drag
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
        Main = Main,
        ScreenGui = ScreenGui,
        SetStatus = function(text, color)
            StatusLabel.Text = text
            if color then StatusLabel.TextColor3 = color end
        end,
        SetTask = function(text)
            TaskLabel.Text = "📋 " .. text
        end,
        UpdateInfo = function(data)
            local stats = data.Stats or {}
            InfoLabel.Text = string.format(
                "📊 Level: %d (Max: 2550)\n💰 Beli: %s\n🍎 Fruit: %s (%s)\n⚔️ Stats: %d/%d/%d/%d/%d",
                data.Level or 0,
                tostring(data.Beli or 0),
                data.Fruit or "None",
                data.Race or "Unknown",
                stats.Melee or 0,
                stats.Defense or 0,
                stats.Sword or 0,
                stats.Gun or 0,
                stats.Fruit or 0
            )
        end,
        UpdateProgress = function(percent)
            local p = math.min(percent or 0, 100)
            ProgressBar.Size = UDim2.new(p / 100, 0, 1, 0)
            ProgressLabel.Text = math.floor(p) .. "%"
        end,
        StartBtn = StartBtn,
        StopBtn = StopBtn,
        IsRunning = false
    }
end

-- =============================================================
-- BOT ENGINE
-- =============================================================
local BotEngine = {
    Running = false,
    UI = nil,
    
    -- State
    CurrentTask = "Idle",
    TaskTimer = 0,
    LevelTarget = 2550,
    
    -- Stats
    TotalBeli = 0,
    TotalLevels = 0,
    TotalFruits = 0,
    TotalBosses = 0,
    
    -- Timers
    LastCheck = 0,
    FruitCheck = 0,
    BossCheck = 0,
    RaidCheck = 0,
    SeaBeastCheck = 0,
    TradeCheck = 0,
    
    Initialize = function(self)
        print("🤖 BF-Auto V6 Bot initialisiert...")
        self.Running = true
        self.LastCheck = tick()
        self:StartLoop()
    end,
    
    StartLoop = function(self)
        spawn(function()
            while self.Running do
                self:Update()
                wait(CONFIG.CHECK_INTERVAL)
            end
        end)
    end,
    
    Update = function(self)
        local data = GetPlayerData()
        
        -- Update UI
        if self.UI then
            self.UI.UpdateInfo(data)
            self.UI.UpdateProgress((data.Level / 2550) * 100)
        end
        
        -- Check if max level reached
        if data.Level >= 2550 then
            self:HandleMaxLevel(data)
            return
        end
        
        -- Main Logic
        self:HandleFarming(data)
        self:HandleFruits(data)
        self:HandleStats(data)
        self:HandleBosses(data)
        self:HandleRaids(data)
        self:HandleSeaBeasts(data)
        self:HandleTrades(data)
    end,
    
    HandleFarming = function(self, data)
        local strategy = FarmLogic.GetStrategy(data.Level)
        local quest = FarmLogic.GetBestQuest(data.Level)
        
        if not quest then
            self:SetStatus("⏳ Keine Quest verfügbar", Color3.fromRGB(255, 200, 100))
            return
        end
        
        -- Find and start quest
        local npc = Workspace:FindFirstChild(quest.NPC)
        if npc then
            local npcPos = npc:GetPivot()
            if npcPos then
                self:SetStatus("📜 Hole Quest: " .. quest.Name, Color3.fromRGB(100, 200, 255))
                Teleport(npcPos.Position + Vector3.new(0, 5, 0), true)
                wait(CONFIG.TELEPORT_DELAY)
                
                pcall(function()
                    local remote = ReplicatedStorage:FindFirstChild("Remotes")
                    if remote then
                        local questEvent = remote:FindFirstChild("QuestEvent")
                        if questEvent then
                            questEvent:FireServer("StartQuest", quest.Name)
                        end
                    end
                end)
            end
        end
        
        -- Farm enemies
        local enemy, dist = GetNearestEnemy()
        if enemy and dist < CONFIG.MAX_DISTANCE then
            self:SetStatus("⚔️ Farme: " .. enemy.Name, Color3.fromRGB(255, 150, 100))
            Teleport(enemy:GetPivot().Position + Vector3.new(0, 2, 0), true)
            wait(CONFIG.TELEPORT_DELAY)
            
            pcall(function()
                ReplicatedStorage.Remotes.Combat:FireServer("Attack", enemy)
            end)
        else
            self:SetStatus("🚶 Suche Gegner...", Color3.fromRGB(200, 200, 200))
        end
    end,
    
    HandleFruits = function(self, data)
        if not CONFIG.AUTO_FRUIT then return end
        
        -- Check for fruits in world
        local fruits = FindFruits()
        if #fruits > 0 then
            -- Find best fruit
            local bestFruit
            local bestRarity = 0
            
            for _, f in pairs(fruits) do
                local rarity = f.Rarity == "Mythical" and 5 or
                              f.Rarity == "Legendary" and 4 or
                              f.Rarity == "Rare" and 3 or
                              f.Rarity == "Uncommon" and 2 or 1
                
                -- Check if fruit is in target list
                for _, target in pairs(CONFIG.TARGET_FRUITS) do
                    if f.Name:find(target) then
                        rarity = rarity + 10
                        break
                    end
                end
                
                if rarity > bestRarity then
                    bestRarity = rarity
                    bestFruit = f
                end
            end
            
            if bestFruit then
                self:SetStatus("🍎 Hole Frucht: " .. bestFruit.Name, Color3.fromRGB(255, 200, 100))
                Teleport(bestFruit.Position + Vector3.new(0, 2, 0), true)
                wait(CONFIG.TELEPORT_DELAY)
                self.TotalFruits = self.TotalFruits + 1
            end
        end
        
        -- Check if we should buy fruit
        if CONFIG.AUTO_BUY_FRUIT and data.Beli > CONFIG.MIN_BELI_FOR_FRUIT then
            local currentFruit = data.Fruit
            local shouldBuy = false
            
            -- Check if current fruit is bad
            for _, best in pairs(CONFIG.BEST_FRUITS) do
                if currentFruit == best then
                    shouldBuy = false
                    break
                end
                shouldBuy = true
            end
            
            if shouldBuy then
                self:SetStatus("🛒 Kaufe Frucht...", Color3.fromRGB(255, 200, 100))
                pcall(function()
                    -- Try to buy from fruit dealer
                    local fruitDealer = Workspace:FindFirstChild("FruitDealer")
                    if fruitDealer then
                        local pos = fruitDealer:GetPivot()
                        Teleport(pos.Position + Vector3.new(0, 3, 0), true)
                        wait(1)
                        
                        -- Try to buy best available fruit
                        for _, fruitName in pairs(CONFIG.BEST_FRUITS) do
                            pcall(function()
                                local remote = ReplicatedStorage:FindFirstChild("Remotes")
                                if remote then
                                    local buyRemote = remote:FindFirstChild("BuyFruit")
                                    if buyRemote then
                                        buyRemote:FireServer(fruitName)
                                    end
                                end
                            end)
                            wait(0.5)
                        end
                    end
                end)
            end
        end
    end,
    
    HandleStats = function(self, data)
        if not CONFIG.AUTO_STATS then return end
        
        local stats = data.Stats
        local totalStats = 0
        
        for _, v in pairs(stats) do
            totalStats = totalStats + v
        end
        
        -- Check if we can level up stats
        if totalStats < data.Level * 3 then
            self:SetStatus("📊 Verwalte Stats...", Color3.fromRGB(100, 200, 255))
            
            -- Find stat with lowest level
            local lowestStat = "Melee"
            local lowestValue = math.huge
            
            for stat, value in pairs(stats) do
                if value < lowestValue then
                    lowestValue = value
                    lowestStat = stat
                end
            end
            
            -- Level up stat
            pcall(function()
                local statRemote = ReplicatedStorage:FindFirstChild("Remotes")
                if statRemote then
                    local statEvent = statRemote:FindFirstChild("LevelStat")
                    if statEvent then
                        statEvent:FireServer(lowestStat)
                    end
                end
            end)
            
            self:SetStatus("📊 Erhöhe: " .. lowestStat, Color3.fromRGB(100, 200, 255))
        end
    end,
    
    HandleBosses = function(self, data)
        if not CONFIG.AUTO_BOSS then return end
        
        -- Check if time for boss
        if tick() - self.BossCheck < CONFIG.BOSS_RESET_TIME then return end
        
        local bosses = GetBosses()
        if #bosses > 0 then
            local nearestBoss
            local nearestDist = math.huge
            
            for _, boss in pairs(bosses) do
                local hrp = boss:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local hrb = GetHRB()
                    if hrb then
                        local dist = (hrp.Position - hrb.Position).magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                            nearestBoss = boss
                        end
                    end
                end
            end
            
            if nearestBoss then
                self:SetStatus("👑 Kämpfe Boss: " .. nearestBoss.Name, Color3.fromRGB(255, 200, 100))
                Teleport(nearestBoss:GetPivot().Position + Vector3.new(0, 2, 0), true)
                wait(CONFIG.TELEPORT_DELAY)
                
                pcall(function()
                    ReplicatedStorage.Remotes.Combat:FireServer("Attack", nearestBoss)
                    wait(0.2)
                    ReplicatedStorage.Remotes.Combat:FireServer("Attack", nearestBoss)
                    wait(0.2)
                    ReplicatedStorage.Remotes.Combat:FireServer("Attack", nearestBoss)
                end)
                
                self.TotalBosses = self.TotalBosses + 1
            end
        end
        
        self.BossCheck = tick()
    end,
    
    HandleRaids = function(self, data)
        if not CONFIG.AUTO_RAID then return end
        
        -- Check if level is high enough for raids        if data.Level < 1200 then return end
        if tick() - self.RaidCheck < CONFIG.RAID_WAIT_TIME then return end
        
        -- Check for raid NPC
        local raidNPC = Workspace:FindFirstChild("RaidNPC")
        if raidNPC then
            self:SetStatus("⚡ Starte Raid...", Color3.fromRGB(255, 200, 100))
            local pos = raidNPC:GetPivot()
            Teleport(pos.Position + Vector3.new(0, 3, 0), true)
            wait(1)
            
            pcall(function()
                local remote = ReplicatedStorage:FindFirstChild("Remotes")
                if remote then
                    local raidRemote = remote:FindFirstChild("StartRaid")
                    if raidRemote then
                        raidRemote:FireServer()
                    end
                end
            end)
        end
        
        self.RaidCheck = tick()
    end,
    
    HandleSeaBeasts = function(self, data)
        if not CONFIG.AUTO_SEA_BEAST then return end
        
        -- Check if level is high enough
        if data.Level < 700 then return end
        if tick() - self.SeaBeastCheck < 60 then return end
        
        local beasts = GetSeaBeasts()
        if #beasts > 0 then
            local nearestBeast
            local nearestDist = math.huge
            
            for _, beast in pairs(beasts) do
                local hrp = beast:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local hrb = GetHRB()
                    if hrb then
                        local dist = (hrp.Position - hrb.Position).magnitude
                        if dist < nearestDist then
                            nearestDist = dist
                            nearestBeast = beast
                        end
                    end
                end
            end
            
            if nearestBeast then
                self:SetStatus("🐉 Jage Sea Beast!", Color3.fromRGB(255, 200, 100))
                Teleport(nearestBeast:GetPivot().Position + Vector3.new(0, 5, 0), true)
                wait(CONFIG.TELEPORT_DELAY)
                
                pcall(function()
                    ReplicatedStorage.Remotes.Combat:FireServer("Attack", nearestBeast)
                    wait(0.3)
                    ReplicatedStorage.Remotes.Combat:FireServer("Attack", nearestBeast)
                end)
            end
        end
        
        self.SeaBeastCheck = tick()
    end,
    
    HandleTrades = function(self, data)
        if not CONFIG.AUTO_TRADE then return end
        if tick() - self.TradeCheck < 300 then return end -- 5 minutes
        
        -- Check for trade NPC
        local tradeNPC = Workspace:FindFirstChild("TradeNPC")
        if tradeNPC then
            self:SetStatus("💱 Prüfe Trades...", Color3.fromRGB(200, 200, 255))
            local pos = tradeNPC:GetPivot()
            Teleport(pos.Position + Vector3.new(0, 3, 0), true)
            wait(1)
            
            pcall(function()
                -- Auto-trade logic
                local remote = ReplicatedStorage:FindFirstChild("Remotes")
                if remote then
                    local tradeRemote = remote:FindFirstChild("Trade")
                    if tradeRemote then
                        tradeRemote:FireServer()
                    end
                end
            end)
        end
        
        self.TradeCheck = tick()
    end,
    
    HandleMaxLevel = function(self, data)
        self:SetStatus("🎉 MAX LEVEL ERREICHT!", Color3.fromRGB(255, 215, 0))
        self.CurrentTask = "MaxLevel"
        
        -- Continue farming for fruits and beli
        self:HandleFruits(data)
        self:HandleBosses(data)
        self:HandleSeaBeasts(data)
        
        -- Check for upgrades
        if data.Beli > 10000000 then
            self:SetStatus("💰 Farme Beli für Upgrades...", Color3.fromRGB(255, 215, 0))
        end
    end,
    
    SetStatus = function(self, text, color)
        if self.UI then
            self.UI.SetStatus(text, color)
            self.UI.SetTask(text)
        end
    end
}

-- =============================================================
-- MAIN START
-- =============================================================
local function StartBot()
    -- Create UI
    local UI = CreateUI()
    BotEngine.UI = UI
    
    -- Button Events
    UI.StartBtn.MouseButton1Click:Connect(function()
        if not BotEngine.Running then
            UI.IsRunning = true
            BotEngine:Initialize()
            UI.SetStatus("🟢 Bot läuft!", Color3.fromRGB(150, 255, 150))
            UI.StartBtn.Text = "🔄 Bot läuft..."
            UI.StartBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 50)
            
            pcall(function()
                StarterGui:SetCore("SendNotification", {
                    Title = "🤖 BF-Auto V6",
                    Text = "Bot gestartet! Durchspielt das gesamte Spiel!",
                    Duration = 5,
                })
            end)
        end
    end)
    
    UI.StopBtn.MouseButton1Click:Connect(function()
        if BotEngine.Running then
            BotEngine.Running = false
            UI.IsRunning = false
            UI.SetStatus("⏹️ Bot gestoppt", Color3.fromRGB(255, 150, 150))
            UI.StartBtn.Text = "▶️ Start Bot"
            UI.StartBtn.BackgroundColor3 = Color3.fromRGB(30, 80, 40)
        end
    end)
    
    -- Auto-start if enabled
    if CONFIG.AUTO_START then
        wait(1)
        UI.StartBtn:Fire()
    end
    
    print("✅ BF-Auto V6 gestartet! Bot wird das Spiel automatisch durchspielen!")
    print("📋 Ziel: Level 2550, Beste Früchte, Maximierte Stats")
    
    -- Keep UI alive
    while UI.ScreenGui and UI.ScreenGui.Parent do
        wait(1)
    end
end

-- =============================================================
-- ERROR HANDLER & START
-- =============================================================
local success, err = xpcall(StartBot, function(e)
    pcall(function()
        StarterGui:SetCore("SendNotification", {
            Title = "❌ BF-Auto Error",
            Text = tostring(e),
            Duration = 10,
        })
    end)
    warn("[BF-Auto] Error: " .. tostring(e))
    print("🔄 Versuche Neustart in 5 Sekunden...")
    task.wait(5)
    StartBot()
end)

if not success then
    warn("[BF-Auto] Failed to start: " .. tostring(err))
    print("⚠️ Bitte führe das Script erneut aus")
end
