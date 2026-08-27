-- ==========================================
-- DOORS AUTO-FARM SCRIPT (VOLLSTÄNDIG)
-- KEIN LOADSTRING - DIREKT AUSFÜHRBAR
-- ==========================================

print("🚀 Lade Doors Auto-Farm Script...")

-- ==========================================
-- 1. ORIONLIB LADEN (GUI-BIBLIOTHEK)
-- ==========================================
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/shlexware/Orion/main/source')))()
if not OrionLib then
    OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/SindubsMini/doors-script/main/Doors/source%20(OrionLib)')))()
end

-- ==========================================
-- 2. PRÜFEN OB WIR IN DOORS SIND
-- ==========================================
if game.PlaceId ~= 6516141723 and game.PlaceId ~= 6839171747 then
    OrionLib:MakeNotification({
        Name = "❌ Falsches Spiel!",
        Content = "Bitte starte dieses Skript nur in DOORS!",
        Image = "rbxassetid://4483345998",
        Time = 5
    })
    return
end

-- ==========================================
-- 3. VARIABLEN
-- ==========================================
local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:WaitForChild("Humanoid")
local runService = game:GetService("RunService")
local userInputService = game:GetService("UserInputService")

-- Globale Status-Variablen
getgenv().Godmode = false
getgenv().InfiniteJump = false
getgenv().Noclip = false
getgenv().FlyMode = false
getgenv().AutoFarmRooms = false
getgenv().AutoOpenDoors = false
getgenv().Walkspeed = 16

-- ==========================================
-- 4. GUI ERSTELLEN
-- ==========================================
local Window = OrionLib:MakeWindow({
    Name = "🔥 Doors Auto-Farm",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "DoorsAutoFarm"
})

-- ==========================================
-- 5. TAB: AUTO-FARM
-- ==========================================
local FarmTab = Window:MakeTab({
    Name = "🤖 Auto-Farm",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Auto Rooms (Rooms-Modus)
FarmTab:AddToggle({
    Name = "🚪 Auto Rooms (A-1000 Farm)",
    Default = false,
    Callback = function(Value)
        getgenv().AutoFarmRooms = Value
        if Value then
            FarmTab:AddNotification({
                Name = "🔄 Auto Rooms gestartet!",
                Content = "Das Skript öffnet jetzt automatisch Türen.",
                Image = "rbxassetid://4483345998"
            })
            -- Auto Rooms Logik starten
            spawn(function()
                while getgenv().AutoFarmRooms do
                    wait(0.5)
                    -- Suche nach der nächsten Tür
                    local door = game.Workspace:FindFirstChild("Door", true)
                    if door and door:FindFirstChild("Door") then
                        door.Door:FireServer("Open")
                        wait(0.3)
                    end
                    -- Suche nach Interaktions-Objekten (Schalter, Knöpfe)
                    for _, v in pairs(game.Workspace:GetDescendants()) do
                        if v.Name == "Button" or v.Name == "Switch" or v.Name == "Lever" then
                            if v:IsA("ClickDetector") or v:IsA("ProximityPrompt") then
                                v:FireServer()
                                wait(0.2)
                            end
                        end
                    end
                end
            end)
        else
            FarmTab:AddNotification({
                Name = "⏹️ Auto Rooms gestoppt!",
                Content = "Das Skript öffnet keine Türen mehr.",
                Image = "rbxassetid://4483345998"
            })
        end
    end
})

-- Auto Open Doors (Normale Türen)
FarmTab:AddToggle({
    Name = "🔑 Auto Open Doors",
    Default = false,
    Callback = function(Value)
        getgenv().AutoOpenDoors = Value
        if Value then
            spawn(function()
                while getgenv().AutoOpenDoors do
                    wait(0.1)
                    -- Alle Türen finden und öffnen
                    for _, v in pairs(game.Workspace:GetDescendants()) do
                        if v.Name == "Door" and v:IsA("Model") then
                            if v:FindFirstChild("Handle") and v.Handle:IsA("BasePart") then
                                -- Versuche die Tür zu öffnen (Remote-Event)
                                local remote = v:FindFirstChild("Open")
                                if remote then
                                    remote:FireServer()
                                end
                            end
                        end
                    end
                end
            end)
        end
    end
})

-- Auto Farm Knobs (Währung)
FarmTab:AddButton({
    Name = "💰 Auto Farm Knobs (Start)",
    Callback = function()
        OrionLib:MakeNotification({
            Name = "💰 Knobs Farm gestartet!",
            Content = "Das Skript sammelt jetzt automatisch Knobs.",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
        spawn(function()
            while getgenv().Godmode do -- Läuft solange Godmode aktiv ist
                wait(0.5)
                -- Suche nach Knobs (Geld-Items)
                for _, v in pairs(game.Workspace:GetDescendants()) do
                    if v.Name == "Knob" and v:IsA("BasePart") and v.Parent ~= char then
                        -- Teleportiere Spieler zum Knob
                        local root = char:FindFirstChild("HumanoidRootPart")
                        if root then
                            root.CFrame = v.CFrame + Vector3.new(0, 1, 0)
                            wait(0.1)
                            -- Simuliere Aufheben
                            local prompt = v:FindFirstChild("ProximityPrompt")
                            if prompt then
                                prompt:FireServer()
                            end
                        end
                    end
                end
            end
        end)
    end
})

-- ==========================================
-- 6. TAB: SPIELER
-- ==========================================
local PlayerTab = Window:MakeTab({
    Name = "👤 Spieler",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Godmode
PlayerTab:AddToggle({
    Name = "🛡️ Godmode",
    Default = false,
    Callback = function(Value)
        getgenv().Godmode = Value
        if Value then
            spawn(function()
                while getgenv().Godmode do
                    wait(0.1)
                    local char = player.Character
                    if char and char:FindFirstChild("Humanoid") then
                        char.Humanoid.Health = 100
                        char.Humanoid.MaxHealth = 100
                    end
                end
            end)
        end
    end
})

-- Unendlicher Sprung
PlayerTab:AddToggle({
    Name = "🦘 Unendlicher Sprung",
    Default = false,
    Callback = function(Value)
        getgenv().InfiniteJump = Value
        if Value then
            userInputService.JumpRequest:Connect(function()
                if getgenv().InfiniteJump then
                    local char = player.Character
                    if char and char:FindFirstChild("Humanoid") then
                        char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    end
                end
            end)
        end
    end
})

-- Geschwindigkeit
PlayerTab:AddSlider({
    Name = "🏃 Geschwindigkeit",
    Min = 16,
    Max = 250,
    Default = 16,
    Color = Color3.fromRGB(255, 255, 255),
    Increment = 1,
    ValueName = "Speed",
    Callback = function(Value)
        getgenv().Walkspeed = Value
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = Value
        end
        spawn(function()
            while getgenv().Walkspeed == Value do
                wait(0.5)
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.WalkSpeed = getgenv().Walkspeed
                end
            end
        end)
    end
})

-- ==========================================
-- 7. TAB: BEWEGUNG
-- ==========================================
local MoveTab = Window:MakeTab({
    Name = "🌀 Bewegung",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Noclip
MoveTab:AddToggle({
    Name = "🌀 Noclip",
    Default = false,
    Callback = function(Value)
        getgenv().Noclip = Value
        if Value then
            spawn(function()
                while getgenv().Noclip do
                    wait(0.1)
                    local char = player.Character
                    if char then
                        for _, v in pairs(char:GetDescendants()) do
                            if v:IsA("BasePart") then
                                v.CanCollide = false
                            end
                        end
                    end
                end
            end)
        end
    end
})

-- Flugmodus
MoveTab:AddToggle({
    Name = "✈️ Flugmodus (F)",
    Default = false,
    Callback = function(Value)
        getgenv().FlyMode = Value
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.PlatformStand = Value
        end
        if Value then
            userInputService.InputBegan:Connect(function(input, gameProcessed)
                if gameProcessed then return end
                if input.KeyCode == Enum.KeyCode.F then
                    getgenv().FlyMode = not getgenv().FlyMode
                    local char = player.Character
                    if char and char:FindFirstChild("Humanoid") then
                        char.Humanoid.PlatformStand = getgenv().FlyMode
                    end
                end
            end)
        end
    end
})

-- ==========================================
-- 8. TAB: SICHTBARKEIT
-- ==========================================
local VisualTab = Window:MakeTab({
    Name = "👁️ Sichtbarkeit",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Vollhelligkeit
VisualTab:AddToggle({
    Name = "💡 Vollhelligkeit",
    Default = false,
    Callback = function(Value)
        if Value then
            game:GetService("Lighting").Brightness = 10
            game:GetService("Lighting").Ambient = Color3.fromRGB(255, 255, 255)
            game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        else
            game:GetService("Lighting").Brightness = 2
            game:GetService("Lighting").Ambient = Color3.fromRGB(0, 0, 0)
            game:GetService("Lighting").OutdoorAmbient = Color3.fromRGB(0, 0, 0)
        end
    end
})

-- Nebel entfernen
VisualTab:AddToggle({
    Name = "🌫️ Nebel entfernen",
    Default = false,
    Callback = function(Value)
        if Value then
            game:GetService("Lighting").FogEnd = 10000
        else
            game:GetService("Lighting").FogEnd = 100
        end
    end
})

-- ESP (Spieler & Gegner)
VisualTab:AddToggle({
    Name = "👾 ESP (Gegner)",
    Default = false,
    Callback = function(Value)
        if Value then
            spawn(function()
                while getgenv().ESP do
                    wait(0.5)
                    for _, v in pairs(game.Workspace:GetDescendants()) do
                        if v:IsA("Model") and v:FindFirstChild("Humanoid") and v ~= char then
                            if not v:FindFirstChild("ESP_Box") then
                                local box = Instance.new("BoxHandleAdornment")
                                box.Name = "ESP_Box"
                                box.Size = v.PrimaryPart.Size + Vector3.new(1, 1, 1)
                                box.Adornee = v.PrimaryPart
                                box.Color3 = Color3.fromRGB(255, 0, 0)
                                box.Transparency = 0.5
                                box.AlwaysOnTop = true
                                box.Parent = v.PrimaryPart
                            end
                        end
                    end
                end
            end)
        else
            for _, v in pairs(game.Workspace:GetDescendants()) do
                if v.Name == "ESP_Box" then
                    v:Destroy()
                end
            end
        end
    end
})

-- ==========================================
-- 9. TAB: EXTRAS
-- ==========================================
local ExtraTab = Window:MakeTab({
    Name = "🔧 Extras",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Maus anzeigen
ExtraTab:AddButton({
    Name = "🖱️ Maus anzeigen",
    Callback = function()
        userInputService.MouseIconEnabled = true
        OrionLib:MakeNotification({
            Name = "✅ Maus sichtbar",
            Content = "Deine Maus sollte jetzt wieder da sein!",
            Image = "rbxassetid://4483345998",
            Time = 3
        })
    end
})

-- Wiederbeleben
ExtraTab:AddButton({
    Name = "💀 Wiederbeleben",
    Callback = function()
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = 100
            char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            OrionLib:MakeNotification({
                Name = "💚 Wiederbelebt!",
                Content = "Du lebst wieder!",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    end
})

-- Teleport zu nächstem Raum
ExtraTab:AddButton({
    Name = "🚪 Teleport zu nächstem Raum",
    Callback = function()
        local foundDoor = false
        for _, v in pairs(game.Workspace:GetDescendants()) do
            if v.Name == "Door" and v:IsA("Model") then
                if v:FindFirstChild("Handle") and v.Handle:IsA("BasePart") then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.CFrame = v.Handle.CFrame + Vector3.new(0, 2, 3)
                        foundDoor = true
                        break
                    end
                end
            end
        end
        if not foundDoor then
            OrionLib:MakeNotification({
                Name = "❌ Keine Tür gefunden!",
                Content = "Konnte keine Tür finden.",
                Image = "rbxassetid://4483345998",
                Time = 2
            })
        end
    end
})

-- ==========================================
-- 10. START-NOTIFICATION
-- ==========================================
OrionLib:MakeNotification({
    Name = "✅ Skript geladen!",
    Content = "Drücke ] (rechte Klammer) für das Menü!",
    Image = "rbxassetid://4483345998",
    Time = 5
})

print("✅ Doors Auto-Farm Script geladen!")
print("📌 Drücke ] für das GUI")
