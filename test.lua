-- =============================================================
-- ||   DOORS RAUM-SCANNER - ZEIGT ALLE OBJEKTE IM RAUM    ||
-- ||   FROM SCRATCH - NUR SCAN - KEINE INTERAKTION         ||
-- =============================================================

print("🔍 Lade DOORS Raum-Scanner...")
print("📌 Scannt den aktuellen Raum und zeigt ALLE Objekte an.")

-- =============================================================
-- 1. SERVICES LADEN
-- =============================================================
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- =============================================================
-- 2. SPIEL-OBJEKTE FINDEN
-- =============================================================
local GameData = ReplicatedStorage:FindFirstChild("GameData")
local LatestRoom = GameData and GameData:FindFirstChild("LatestRoom")
local CurrentRooms = Workspace:FindFirstChild("CurrentRooms")

if not LatestRoom then
    print("❌ 'LatestRoom' nicht gefunden in ReplicatedStorage.GameData!")
    print("   Bist du in DOORS?")
    return
end

if not CurrentRooms then
    print("❌ 'CurrentRooms' nicht gefunden im Workspace!")
    print("   Bist du in einem Raum?")
    return
end

local currentRoomNumber = LatestRoom.Value
print("✅ Aktuelle Raum-Nummer: " .. tostring(currentRoomNumber))

-- =============================================================
-- 3. RAUM OBJEKT HOLEN
-- =============================================================
local currentRoom = CurrentRooms:FindFirstChild(tostring(currentRoomNumber))

if not currentRoom then
    print("❌ Raum " .. tostring(currentRoomNumber) .. " nicht in CurrentRooms gefunden!")
    print("   Warte auf Laden des Raums...")
    task.wait(2)
    currentRoom = CurrentRooms:FindFirstChild(tostring(currentRoomNumber))
    if not currentRoom then
        print("❌ Raum immer noch nicht gefunden!")
        return
    end
end

print("✅ Raum-Container gefunden: " .. currentRoom.Name)
print("")

-- =============================================================
-- 4. ALLE OBJEKTE IM RAUM DURCHSUCHEN
-- =============================================================
print("📊 SCANNE RAUM " .. tostring(currentRoomNumber) .. "...")
print("============================================================")

local objects = {
    Models = {},
    Parts = {},
    Other = {}
}

local totalCount = 0

-- Alle Descendants durchgehen
for _, obj in pairs(currentRoom:GetDescendants()) do
    totalCount = totalCount + 1
    
    local objType = obj.ClassName
    local objName = obj.Name or "Unbenannt"
    local objPath = ""
    
    -- Pfad erstellen
    local pathParts = {}
    local parent = obj
    while parent and parent ~= workspace do
        table.insert(pathParts, 1, parent.Name or "?")
        parent = parent.Parent
    end
    objPath = table.concat(pathParts, ".")
    
    -- Kategorisieren
    if obj:IsA("Model") then
        table.insert(objects.Models, {
            Name = objName,
            Class = objType,
            Path = objPath,
            Children = #obj:GetChildren(),
            Descendants = #obj:GetDescendants()
        })
    elseif obj:IsA("BasePart") then
        table.insert(objects.Parts, {
            Name = objName,
            Class = objType,
            Path = objPath,
            Position = obj.Position,
            Size = obj.Size,
            Material = obj.Material and tostring(obj.Material) or "Kein"
        })
    else
        table.insert(objects.Other, {
            Name = objName,
            Class = objType,
            Path = objPath,
            Parent = obj.Parent and obj.Parent.Name or "Kein"
        })
    end
end

-- =============================================================
-- 5. ERGEBNISSE ANZEIGEN
-- =============================================================
print("")
print("📊 SCAN-ERGEBNISSE:")
print("============================================================")
print("   Gesamt Objekte: " .. totalCount)
print("   Models: " .. #objects.Models)
print("   Parts: " .. #objects.Parts)
print("   Andere: " .. #objects.Other)
print("============================================================")

-- MODELS anzeigen
if #objects.Models > 0 then
    print("")
    print("📦 MODELS (" .. #objects.Models .. "):")
    print("------------------------------------------------------------")
    for i, obj in pairs(objects.Models) do
        print(string.format("   %d. %s (%s)", i, obj.Name, obj.Class))
        print("      Pfad: " .. obj.Path)
        print("      Kinder: " .. obj.Children .. ", Descendants: " .. obj.Descendants)
    end
end

-- PARTS anzeigen
if #objects.Parts > 0 then
    print("")
    print("🧩 PARTS (" .. #objects.Parts .. "):")
    print("------------------------------------------------------------")
    for i, obj in pairs(objects.Parts) do
        print(string.format("   %d. %s (%s)", i, obj.Name, obj.Class))
        print("      Pfad: " .. obj.Path)
        print("      Position: " .. tostring(obj.Position))
        print("      Größe: " .. tostring(obj.Size))
        print("      Material: " .. obj.Material)
    end
end

-- ANDERE Objekte anzeigen
if #objects.Other > 0 then
    print("")
    print("📄 ANDERE OBJEKTE (" .. #objects.Other .. "):")
    print("------------------------------------------------------------")
    for i, obj in pairs(objects.Other) do
        print(string.format("   %d. %s (%s)", i, obj.Name, obj.Class))
        print("      Pfad: " .. obj.Path)
        print("      Parent: " .. obj.Parent)
    end
end

print("")
print("============================================================")
print("✅ SCAN ABGESCHLOSSEN!")
print("============================================================")

-- =============================================================
-- 6. GUI MIT ALLEN OBJEKTEN
-- =============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DoorsScanner"
screenGui.Parent = playerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 350, 0, 450)
mainFrame.Position = UDim2.new(0.5, -175, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 30)
mainFrame.BackgroundTransparency = 0.1
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- Titel
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 40)
title.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
title.Text = "🔍 RAUM-SCANNER - Raum " .. tostring(currentRoomNumber)
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

-- Scroll für Objekte
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -10, 1, -50)
scroll.Position = UDim2.new(0, 5, 0, 45)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.ScrollBarThickness = 6
scroll.Parent = mainFrame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 3)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = scroll

-- =============================================================
-- GUI: OBJEKTE ANZEIGEN (NACH TYPEN SORTIERT)
-- =============================================================

-- Kategorie-Überschrift erstellen
local function createCategory(titleText, count)
    local cat = Instance.new("TextLabel")
    cat.Size = UDim2.new(1, -10, 0, 25)
    cat.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
    cat.Text = titleText .. " (" .. count .. ")"
    cat.TextColor3 = Color3.fromRGB(255, 255, 200)
    cat.TextScaled = true
    cat.Font = Enum.Font.SourceSansBold
    cat.Parent = scroll
    return cat
end

-- Objekt-Button erstellen
local function createObjectButton(obj, typeLabel)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 28)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
    btn.Text = obj.Name .. " (" .. obj.Class .. ")"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.TextScaled = true
    btn.Font = Enum.Font.SourceSans
    btn.Parent = scroll
    
    -- Detail-Information als Tooltip
    btn.MouseButton1Click:Connect(function()
        local detail = "📌 Name: " .. obj.Name .. "\n"
        detail = detail .. "📦 Class: " .. obj.Class .. "\n"
        detail = detail .. "📁 Pfad: " .. obj.Path .. "\n"
        if obj.Position then
            detail = detail .. "📍 Position: " .. tostring(obj.Position) .. "\n"
        end
        if obj.Size then
            detail = detail .. "📐 Größe: " .. tostring(obj.Size) .. "\n"
        end
        if obj.Material then
            detail = detail .. "🎨 Material: " .. obj.Material .. "\n"
        end
        if obj.Children then
            detail = detail .. "📂 Kinder: " .. obj.Children .. "\n"
        end
        if obj.Descendants then
            detail = detail .. "📂 Descendants: " .. obj.Descendants .. "\n"
        end
        if obj.Parent then
            detail = detail .. "👪 Parent: " .. obj.Parent
        end
        print("\n📋 DETAILS FÜR: " .. obj.Name)
        print("============================================================")
        print(detail)
        print("============================================================")
    end)
    return btn
end

-- MODELS
if #objects.Models > 0 then
    createCategory("📦 MODELS", #objects.Models)
    for _, obj in pairs(objects.Models) do
        createObjectButton(obj, "Model")
    end
end

-- PARTS
if #objects.Parts > 0 then
    createCategory("🧩 PARTS", #objects.Parts)
    for _, obj in pairs(objects.Parts) do
        createObjectButton(obj, "Part")
    end
end

-- ANDERE
if #objects.Other > 0 then
    createCategory("📄 ANDERE", #objects.Other)
    for _, obj in pairs(objects.Other) do
        createObjectButton(obj, "Other")
    end
end

-- Canvas aktualisieren
scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
end)

-- Close
closeBtn.MouseButton1Click:Connect(function()
    pcall(function() screenGui:Destroy() end)
end)

-- =============================================================
-- 7. DRAG & DROP
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
-- 8. START
-- =============================================================
print("")
print("============================================================")
print("✅ RAUM-SCANNER ABGESCHLOSSEN!")
print("============================================================")
print("📊 Gefundene Objekte:")
print("   Models: " .. #objects.Models)
print("   Parts: " .. #objects.Parts)
print("   Andere: " .. #objects.Other)
print("   Gesamt: " .. totalCount)
print("============================================================")
print("")
print("📌 Klicke auf ein Objekt im GUI für Details!")
print("📌 Die Details werden in der Konsole angezeigt.")
print("============================================================")
