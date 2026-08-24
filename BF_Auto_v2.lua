-- =============================================================
--  BF-Auto V4 | ULTIMATE EDITION (BlueStacks + Delta)
--  ALLES markieren -> direkt in die Delta-Konsole einkopieren -> Execute
--  Verbesserte Fehlerbehandlung, mehr Features, stabiler
-- =============================================================

-- GUI-Parent
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local Player = Players.LocalPlayer
local cam = Player.PlayerGui

-- Fehler-Schild
local errGui = Instance.new("ScreenGui")
errGui.Name = "BF_ErrorShield"
errGui.ResetOnSpawn = false
errGui.Parent = cam

local errLabel = Instance.new("TextLabel")
errLabel.Size = UDim2.new(0, 500, 0, 80)
errLabel.Position = UDim2.new(0.5, -250, 0.5, -40)
errLabel.AnchorPoint = Vector2.new(0, 0)
errLabel.BackgroundColor3 = Color3.new(0.85, 0.1, 0.1)
errLabel.BackgroundTransparency = 0.15
errLabel.Font = Enum.Font.GothamBold
errLabel.TextSize = 16
errLabel.TextColor3 = Color3.new(1, 1, 1)
errLabel.TextXAlignment = Enum.TextXAlignment.Left
errLabel.TextWrapped = true
errLabel.Text = "BF-Auto V4: lade..."
errLabel.Parent = errGui

local ok, errMsg = pcall(function()
    print("BF-Auto V4: Script gestartet...")

    -- =============================================================
    -- KONFIGURATION
    -- =============================================================
    local CONFIG = {
        TELEPORT_DELAY = 0.3,
        GRAB_DELAY = 2,
        FIGHT_DELAY = 1.5,
        QUEST_DELAY = 30,
        ESP_UPDATE = 1,
        STATUS_UPDATE = 3,
        MAX_FIGHT_DISTANCE = 200,
        AUTO_REVIVE = true,
        SAFE_TELEPORT = true,
        AUTO_EQUIP_BEST = true,
    }

    -- =============================================================
    -- HELPER FUNKTIONEN
    -- =============================================================
    local function getHRB()
        local c = Player.Character
        if c then return c:FindFirstChild("HumanoidRootPart") end
        return nil
    end

    local function getHumanoid()
        local c = Player.Character
        if c then return c:FindFirstChild("Humanoid") end
        return nil
    end

    local function teleport(pos, safe)
        if not pos then return end
        local hrb = getHRB()
        if hrb then
            if CONFIG.SAFE_TELEPORT and safe then
                -- Prüfe ob Position sicher ist (nicht in Wänden)
                local raycastParams = RaycastParams.new()
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParams.FilterDescendantsInstances = {Player.Character}
                
                local rayOrigin = pos + Vector3.new(0, 2, 0)
                local rayDirection = Vector3.new(0, -4, 0)
                local result = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
                
                if result then
                    pos = result.Position + Vector3.new(0, 3, 0)
                end
            end
            hrb.CFrame = CFrame.new(pos)
        end
    end

    local function getClosestEnemy()
        local hrb = getHRB()
        if not hrb then return nil end
        
        local enemies = {}
        local enemyFolder = Workspace:FindFirstChild("Enemies")
        if enemyFolder then
            for _, v in pairs(enemyFolder:GetChildren()) do
                local hum = v:FindFirstChild("Humanoid")
                local hrp = v:FindFirstChild("HumanoidRootPart")
                if hum and hrp and hum.Health > 0 then
                    local dist = (hrp.Position - hrb.Position).magnitude
                    table.insert(enemies, {Enemy = v, Distance = dist, HRP = hrp, Humanoid = hum})
                end
            end
        end
        
        table.sort(enemies, function(a, b) return a.Distance < b.Distance end)
        return enemies[1]
    end

    local function findFruits()
        local list = {}
        for _, v in pairs(Workspace:GetChildren()) do
            if v:IsA("Model") and v.Name == "Fruit" then
                local handle = v:FindFirstChild("Handle")
                if handle and handle:IsA("BasePart") then
                    table.insert(list, { 
                        Model = v, 
                        Handle = handle, 
                        Position = handle.Position,
                        Name = v:FindFirstChild("FruitName") and v.FruitName.Value or "Frucht"
                    })
                end
            end
        end
        return list
    end

    local function nearestFruit()
        local hrb = getHRB()
        if not hrb then return nil end
        local best, bestDist
        for _, f in pairs(findFruits()) do
            local d = (f.Position - hrb.Position).magnitude
            if not best or d < bestDist then 
                best = f
                bestDist = d 
            end
        end
        return best, bestDist
    end

    local function playerLevel()
        local success, lvl = pcall(function() 
            local data = Player:FindFirstChild("Data")
            if data then
                local level = data:FindFirstChild("Level")
                if level then return level.Value end
            end
            return 0
        end)
        if success and lvl then return math.floor(lvl) end
        return 0
    end

    local function getPlayerStats()
        local stats = {
            Level = playerLevel(),
            Health = 0,
            MaxHealth = 0,
            Stamina = 0,
            MaxStamina = 0,
            Beli = 0,
            Fruit = "Keine"
        }
        
        local hum = getHumanoid()
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
        end
        
        return stats
    end

    local function isPlayerAlive()
        local hum = getHumanoid()
        return hum and hum.Health > 0
    end

    local function equipBestWeapon()
        if not CONFIG.AUTO_EQUIP_BEST then return end
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

    -- =============================================================
    -- GUI ERSTELLUNG (Modernes Design)
    -- =============================================================
    local Gui = Instance.new("ScreenGui")
    Gui.Name = "BFAutoGui"
    Gui.ResetOnSpawn = false
    Gui.IgnoreGuiInset = true
    
    local old = cam:FindFirstChild("BFAutoGui")
    if old then old:Destroy() end
    Gui.Parent = cam

    -- Hauptfenster
    local Win = Instance.new("Frame")
    Win.Name = "BFAutoWin"
    Win.Size = UDim2.new(0, 300, 0, 280)
    Win.Position = UDim2.new(0, 10, 0, 50)
    Win.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    Win.BackgroundTransparency = 0.2
    Win.BorderSizePixel = 1
    Win.BorderColor3 = Color3.new(0.3, 0.3, 0.5)
    Win.ClipsDescendants = true
    Win.Parent = Gui

    -- Hintergrund
    local Bg = Instance.new("Frame")
    Bg.Size = UDim2.new(1, 0, 1, 0)
    Bg.BackgroundColor3 = Color3.new(0.1, 0.1, 0.15)
    Bg.BackgroundTransparency = 0.5
    Bg.Parent = Win

    -- Titel
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, 0, 0, 28)
    Title.Position = UDim2.new(0, 0, 0, 0)
    Title.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
    Title.BackgroundTransparency = 0.3
    Title.Text = "⚡ BF-Auto V4 ⚡"
    Title.TextColor3 = Color3.new(1, 0.8, 0.2)
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 16
    Title.Parent = Win

    -- Toggle Buttons
    local function createToggle(y, label, icon)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.92, 0, 0, 24)
        btn.Position = UDim2.new(0.04, 0, 0, y)
        btn.BackgroundColor3 = Color3.new(0.15, 0.15, 0.25)
        btn.BackgroundTransparency = 0.3
        btn.BorderSizePixel = 1
        btn.BorderColor3 = Color3.new(0.3, 0.3, 0.5)
        btn.Text = icon .. " " .. label .. "  [OFF]"
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 13
        btn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.Parent = Win
        
        local state = false
        btn.MouseButton1Click:Connect(function()
            state = not state
            btn.Text = icon .. " " .. label .. "  [" .. (state and "ON" or "OFF") .. "]"
            btn.BackgroundColor3 = state and Color3.new(0.1, 0.5, 0.2) or Color3.new(0.15, 0.15, 0.25)
            btn.BorderColor3 = state and Color3.new(0.2, 0.8, 0.2) or Color3.new(0.3, 0.3, 0.5)
            
            -- Sound Feedback
            pcall(function()
                local sound = Instance.new("Sound")
                sound.SoundId = "rbxassetid://9120054074"
                sound.Volume = 0.3
                sound.Parent = Win
                sound:Play()
                task.delay(0.5, function() sound:Destroy() end)
            end)
        end)
        return btn, function() return state end
    end

    local tESP, getESP = createToggle(32, "ESP Früchte", "👁️")
    local tGrab, getGrab = createToggle(60, "Auto Früchte holen", "🍎")
    local tFight, getFight = createToggle(88, "Auto Kampf", "⚔️")
    local tQuest, getQuest = createToggle(116, "Auto Quests", "📜")
    local tSafe, getSafe = createToggle(144, "Safe Teleport", "🛡️")
    local tRevive, getRevive = createToggle(172, "Auto Revive", "💀")

    -- Quick-Info
    local QuickInfo = Instance.new("TextLabel")
    QuickInfo.Size = UDim2.new(0.92, 0, 0, 18)
    QuickInfo.Position = UDim2.new(0.04, 0, 0, 200)
    QuickInfo.BackgroundTransparency = 1
    QuickInfo.Text = "Level: 0 | Früchte: 0"
    QuickInfo.Font = Enum.Font.Gotham
    QuickInfo.TextSize = 12
    QuickInfo.TextColor3 = Color3.new(0.7, 0.7, 0.9)
    QuickInfo.TextXAlignment = Enum.TextXAlignment.Left
    QuickInfo.Parent = Win

    -- Status
    local Status = Instance.new("TextLabel")
    Status.Size = UDim2.new(0.92, 0, 0, 50)
    Status.Position = UDim2.new(0.04, 0, 0, 220)
    Status.BackgroundTransparency = 1
    Status.Text = "🟢 Bereit"
    Status.Font = Enum.Font.Gotham
    Status.TextSize = 11
    Status.TextColor3 = Color3.new(0.7, 1, 0.7)
    Status.TextWrapped = true
    Status.TextXAlignment = Enum.TextXAlignment.Left
    Status.Parent = Win

    -- =============================================================
    -- ESP SYSTEM
    -- =============================================================
    spawn(function() 
        while wait(CONFIG.ESP_UPDATE) do
            if not getESP() then
                for _, f in pairs(findFruits()) do
                    local old = f.Handle:FindFirstChild("BF_ESP")
                    if old then old:Destroy() end
                end
            else
                for _, f in pairs(findFruits()) do
                    local bb = f.Handle:FindFirstChild("BF_ESP")
                    if not bb then
                        bb = Instance.new("BillboardGui")
                        bb.Name = "BF_ESP"
                        bb.Size = UDim2.new(0, 180, 0, 30)
                        bb.AlwaysFaceCamera = true
                        bb.MaxDistance = 500
                        bb.StudsOffset = Vector3.new(0, 3, 0)
                        bb.Parent = f.Handle
                        
                        local label = Instance.new("TextLabel")
                        label.Name = "Label"
                        label.Size = UDim2.new(1, 0, 1, 0)
                        label.BackgroundColor3 = Color3.new(1, 0.3, 0.1)
                        label.BackgroundTransparency = 0.2
                        label.Text = "🍎 " .. (f.Name or "FRUCHT")
                        label.Font = Enum.Font.GothamBold
                        label.TextSize = 16
                        label.TextColor3 = Color3.new(1, 1, 1)
                        label.Parent = bb
                        
                        local distance = Instance.new("TextLabel")
                        distance.Name = "Distance"
                        distance.Size = UDim2.new(1, 0, 0, 14)
                        distance.Position = UDim2.new(0, 0, 1, 0)
                        distance.BackgroundTransparency = 1
                        distance.Text = "0m"
                        distance.Font = Enum.Font.Gotham
                        distance.TextSize = 12
                        distance.TextColor3 = Color3.new(1, 1, 0.5)
                        distance.Parent = bb
                    end
                    
                    -- Update Distance
                    local distLabel = bb:FindFirstChild("Distance")
                    if distLabel and Player.Character then
                        local hrb = getHRB()
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

    -- =============================================================
    -- FRÜCHTE AUTO-GRAB
    -- =============================================================
    spawn(function() 
        while wait(CONFIG.GRAB_DELAY) do
            if getGrab() then
                local f, dist = nearestFruit()
                if f then
                    Status.Text = "🍎 Frucht gefunden (" .. math.floor(dist) .. "m) -> hole sie..."
                    teleport(f.Position + Vector3.new(0, 2, 0), getSafe())
                    wait(CONFIG.TELEPORT_DELAY)
                    
                    -- Versuche zu greifen
                    local hrb = getHRB()
                    if hrb and f.Handle then
                        local distToFruit = (f.Position - hrb.Position).magnitude
                        if distToFruit < 10 then
                            -- Simuliere Touch
                            pcall(function()
                                local touch = f.Handle:FindFirstChild("TouchTransmitter")
                                if touch then
                                    touch:FireServer(hrb)
                                end
                            end)
                        end
                    end
                else
                    Status.Text = "🍎 Keine Früchte in der Nähe..."
                end
            end
        end 
    end)

    -- =============================================================
    -- AUTO KAMPF (Verbessert)
    -- =============================================================
    spawn(function() 
        while wait(CONFIG.FIGHT_DELAY) do
            if getFight() then
                -- Auto-Revive
                if getRevive() and not isPlayerAlive() then
                    Status.Text = "💀 Wiederbeleben..."
                    pcall(function()
                        ReplicatedStorage.Remotes.Character:FireServer("Revive")
                    end)
                    wait(2)
                    continue
                end
                
                -- Beste Waffe ausrüsten
                equipBestWeapon()
                
                local target = getClosestEnemy()
                if target and target.Distance < CONFIG.MAX_FIGHT_DISTANCE then
                    Status.Text = "⚔️ Kämpfe gegen: " .. target.Enemy.Name
                    teleport(target.HRP.Position + Vector3.new(0, 2, 0), getSafe())
                    wait(0.2)
                    
                    -- Angriff
                    pcall(function()
                        ReplicatedStorage.Remotes.Combat:FireServer("Attack", target.Enemy)
                    end)
                    
                    -- Zusätzliche Angriffe wenn nah
                    wait(0.3)
                    if target.Distance < 20 then
                        pcall(function()
                            ReplicatedStorage.Remotes.Combat:FireServer("Attack", target.Enemy)
                        end)
                    end
                else
                    if not target then
                        Status.Text = "⚔️ Keine Gegner in Reichweite..."
                    end
                end
            end
        end 
    end)

    -- =============================================================
    -- AUTO QUESTS (Verbessert)
    -- =============================================================
    local questList = {
        {Level = 700,  NPC = "Raiders",              Name = "RaidersQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 725,  NPC = "Mercenaries",          Name = "MercenariesQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 750,  NPC = "Diamond",              Name = "DiamondBossQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 775,  NPC = "Swan Pirates",         Name = "SwanPiratesQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 800,  NPC = "Factory Staff",        Name = "FactoryQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 850,  NPC = "Jeremy",               Name = "JeremyBossQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 875,  NPC = "Marine Lieutenants",   Name = "MarineLieutenantQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 900,  NPC = "Marine Captains",      Name = "MarineCaptainQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 925,  NPC = "Fajita",               Name = "FajitaBossQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 950,  NPC = "Zombies",              Name = "ZombieQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 975,  NPC = "Vampires",             Name = "VampireQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 1000, NPC = "Snow Troopers",        Name = "SnowTrooperQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 1050, NPC = "Winter Warriors",      Name = "WinterWarriorQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 1100, NPC = "Lab Subordinates",     Name = "LabSubordinateQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 1125, NPC = "Horned Warriors",      Name = "HornedWarriorQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 1150, NPC = "Smoke Admiral",        Name = "SmokeAdmiralBossQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 1425, NPC = "Sea Soldiers",         Name = "SeaSoldierQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 1450, NPC = "Water Fighters",       Name = "WaterFighterQuest", Position = Vector3.new(0, 0, 0)},
        {Level = 1475, NPC = "Tide Keeper",          Name = "TideKeeperBossQuest", Position = Vector3.new(0, 0, 0)},
    }

    spawn(function() 
        while wait(CONFIG.QUEST_DELAY) do
            if getQuest() then
                if not isPlayerAlive() then
                    Status.Text = "📜 Warte auf Wiederbelebung..."
                    wait(3)
                    continue
                end
                
                local lvl = playerLevel()
                local bestQ
                for i = #questList, 1, -1 do
                    if lvl >= questList[i].Level then 
                        bestQ = questList[i]
                        break 
                    end
                end
                
                if bestQ then
                    Status.Text = "📜 Suche NPC: " .. bestQ.NPC
                    local npc = Workspace:FindFirstChild(bestQ.NPC)
                    
                    if npc then
                        local npcPos = npc:GetPivot()
                        if npcPos then
                            teleport(npcPos.Position + Vector3.new(0, 5, 0), getSafe())
                            wait(1)
                            
                            -- Versuche Quest zu starten
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
                                Status.Text = "✅ Quest gestartet: " .. bestQ.Name
                            else
                                Status.Text = "❌ Quest Remote nicht gefunden!"
                            end
                        end
                    else
                        Status.Text = "❌ NPC nicht gefunden: " .. bestQ.NPC
                    end
                else
                    Status.Text = "📜 Level zu niedrig (" .. lvl .. ")"
                end
            end
        end 
    end)

    -- =============================================================
    -- STATUS UPDATES & INFO
    -- =============================================================
    spawn(function() 
        while wait(CONFIG.STATUS_UPDATE) do
            local stats = getPlayerStats()
            local fruits = findFruits()
            local f, dist = nearestFruit()
            
            -- Quick Info
            local fruitInfo = f and "🍎 " .. math.floor(dist) .. "m" or "🔴 Keine"
            QuickInfo.Text = string.format("Level: %d | Früchte: %d | HP: %d/%d", 
                stats.Level, #fruits, stats.Health, stats.MaxHealth)
            
            -- Update ESP distance in background
        end 
    end)

    -- =============================================================
    -- KEYBOARD SHORTCUTS
    -- =============================================================
    local UserInputService = game:GetService("UserInputService")
    
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        
        if input.KeyCode == Enum.KeyCode.F1 then
            -- Toggle ESP
            tESP:Fire()
        elseif input.KeyCode == Enum.KeyCode.F2 then
            -- Toggle Grab
            tGrab:Fire()
        elseif input.KeyCode == Enum.KeyCode.F3 then
            -- Toggle Fight
            tFight:Fire()
        elseif input.KeyCode == Enum.KeyCode.F4 then
            -- Toggle Quest
            tQuest:Fire()
        elseif input.KeyCode == Enum.KeyCode.F5 then
            -- Safe TP Toggle
            tSafe:Fire()
        end
    end)

    -- =============================================================
    -- AUTO-JOIN / REJOIN SCHUTZ
    -- =============================================================
    local function onPlayerAdded(player)
        if player == Player then
            Status.Text = "🔄 Neu verbunden!"
            wait(2)
        end
    end
    
    Players.PlayerAdded:Connect(onPlayerAdded)

    -- =============================================================
    -- STARTUP COMPLETE
    -- =============================================================
    print("✅ BF-Auto V4: Alle Systeme aktiv!")
    warn("⚡ BF-Auto V4 gestartet! Tasten: F1-ESP, F2-Grab, F3-Kampf, F4-Quest, F5-SafeTP")
    Status.Text = "🟢 BF-Auto V4 bereit! F1-F5 für Shortcuts"
end)

-- =============================================================
-- FEHLERBEHANDLUNG
-- =============================================================
if not ok then
    errLabel.Text = "❌ BF-Auto FEHLER:\n" .. tostring(errMsg)
    errLabel.BackgroundColor3 = Color3.new(0.85, 0.1, 0.1)
    task.delay(15, function() errGui:Destroy() end)
else
    errLabel.Text = "✅ BF-Auto V4 erfolgreich gestartet!"
    errLabel.BackgroundColor3 = Color3.new(0.1, 0.5, 0.1)
    task.delay(3, function() 
        errLabel.Text = "BF-Auto V4 läuft im Hintergrund..."
        task.delay(2, function() errGui:Destroy() end)
    end)
end
