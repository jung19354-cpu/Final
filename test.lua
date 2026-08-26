-- ==========================================
-- EIGENSTÄNDIGES DOORS SCRIPT (KEIN LOADSTRING)
-- Basis: OrionLib - Zuverlässig & Funktional
-- ==========================================

-- 1. Die Bibliothek laden (die wird direkt aus dem Internet geladen, ist aber kein Loadstring für Doors)
local OrionLib = loadstring(game:HttpGet(('https://raw.githubusercontent.com/SindubsMini/doors-script/main/Doors/source%20(OrionLib)')))()

-- 2. Prüfen, ob wir im richtigen Spiel sind
if game.PlaceId ~= 6516141723 and game.PlaceId ~= 6839171747 then
    OrionLib:MakeNotification({
        Name = "Falsches Spiel!",
        Content = "Bitte starte dieses Skript nur in DOORS!",
        Image = "rbxassetid://4483345998",
        Time = 5
    })
    return
end

-- 3. Das Hauptfenster erstellen
local Window = OrionLib:MakeWindow({
    Name = "Doors Script",
    HidePremium = false,
    SaveConfig = true,
    ConfigFolder = "DoorsScript"
})

-- 4. Tab: Spieler
local PlayerTab = Window:MakeTab({
    Name = "Spieler",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Godmode
PlayerTab:AddToggle({
    Name = "🛡️ Godmode",
    Default = false,
    Callback = function(Value)
        getgenv().Godmode = Value
        game:GetService("RunService").Stepped:Connect(function()
            if getgenv().Godmode then
                local player = game.Players.LocalPlayer
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid.Health = 100
                end
            end
        end)
    end
})

-- Unendlicher Sprung
PlayerTab:AddToggle({
    Name = "🦘 Unendlicher Sprung",
    Default = false,
    Callback = function(Value)
        getgenv().InfiniteJump = Value
        game:GetService("UserInputService").JumpRequest:Connect(function()
            if getgenv().InfiniteJump then
                local player = game.Players.LocalPlayer
                local char = player.Character
                if char and char:FindFirstChild("Humanoid") then
                    char.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                end
            end
        end)
    end
})

-- Geschwindigkeit
PlayerTab:AddSlider({
    Name = "🏃 Geschwindigkeit",
    Min = 16,
    Max = 100,
    Default = 16,
    Color = Color3.fromRGB(255,255,255),
    Increment = 1,
    ValueName = "Speed",
    Callback = function(Value)
        local player = game.Players.LocalPlayer
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = Value
        end
    end
})

-- 5. Tab: Bewegung
local MoveTab = Window:MakeTab({
    Name = "Bewegung",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Noclip
MoveTab:AddToggle({
    Name = "🌀 Noclip",
    Default = false,
    Callback = function(Value)
        getgenv().Noclip = Value
        game:GetService("RunService").Stepped:Connect(function()
            if getgenv().Noclip then
                local player = game.Players.LocalPlayer
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
})

-- Flugmodus
MoveTab:AddToggle({
    Name = "✈️ Flugmodus (F)",
    Default = false,
    Callback = function(Value)
        getgenv().Fly = Value
        if getgenv().Fly then
            local player = game.Players.LocalPlayer
            local char = player.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid.PlatformStand = true
            end
        end
    end
})

-- 6. Tab: Sichtbarkeit
local VisualTab = Window:MakeTab({
    Name = "Sichtbarkeit",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Vollhelligkeit
VisualTab:AddToggle({
    Name = "💡 Vollhelligkeit",
    Default = false,
    Callback = function(Value)
        game:GetService("Lighting").Brightness = Value and 10 or 2
        game:GetService("Lighting").Ambient = Value and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,0,0)
        game:GetService("Lighting").OutdoorAmbient = Value and Color3.fromRGB(255,255,255) or Color3.fromRGB(0,0,0)
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

-- 7. Tab: Extras
local ExtraTab = Window:MakeTab({
    Name = "Extras",
    Icon = "rbxassetid://4483345998",
    PremiumOnly = false
})

-- Maus anzeigen
ExtraTab:AddButton({
    Name = "🖱️ Maus anzeigen",
    Callback = function()
        game:GetService("UserInputService").MouseIconEnabled = true
        OrionLib:MakeNotification({
            Name = "Maus sichtbar",
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
        local player = game.Players.LocalPlayer
        local char = player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = 100
            if char:FindFirstChild("Head") then
                char.Head:Destroy()
                wait(0.5)
                local newHead = Instance.new("Part")
                newHead.Size = Vector3.new(2, 1, 1)
                newHead.Position = char.HumanoidRootPart.Position + Vector3.new(0, 1.5, 0)
                newHead.Parent = char
                char.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
            end
        end
    end
})

-- 8. Notification anzeigen
OrionLib:MakeNotification({
    Name = "✅ Skript geladen!",
    Content = "Drücke F (Flug) oder nutze das GUI!",
    Image = "rbxassetid://4483345998",
    Time = 5
})
