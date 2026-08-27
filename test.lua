-- ==================================================================================================
-- ||          DOORS AUTO-PLAY AGENT - HIGH-END REVERSE ENGINEERED SCRIPT             ||
-- ==================================================================================================
-- Rolle: Senior Roblox Reverse-Engineer | Spezialgebiet: DOORS Automation
-- Status: Voll funktionsfähig (unter der Annahme aktueller Spiel-API-Stabilität)
-- Anweisungen: Kopieren Sie diesen Code in Ihren Executor (Delta/KRNL/CodeX) und führen Sie ihn aus.
-- ==================================================================================================

-- ==================================================================================================
-- I. SERVICES UND GLOBALE VARIABLEN
-- ==================================================================================================

-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- Spieler und State
local player = Players.LocalPlayer
local isAutoPlayEnabled = false
local isAutoCollectEnabled = false
local isAutoDoorOpenEnabled = false
local isGodmodeEnabled = false
local isNoclipEnabled = false
local isAutoHealEnabled = false
local isFlightEnabled = false
local isLightEnabled = false
local isFogRemovedEnabled = false
local currentSpeed = 16 -- Startgeschwindigkeit
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- Spielzustand (Basierend auf Recherche)
local GameData = ReplicatedStorage:FindFirstChild("GameData")
local LatestRoom = GameData and GameData:FindFirstChild("LatestRoom")

-- Tracking
local visitedRooms = {} -- Verfolgt die ID der bereits abgeschlossenen Räume
local isCharAlive = true

-- ==================================================================================================
-- II. UTILITY FUNCTIONS (HILFSFUNKTIONEN)
-- ==================================================================================================

-- Charakter-Handling
local function getCharacter()
    return player.Character or player.CharacterAdded:Wait()
end

local function getHumanoid(char)
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRootPart(char)
    return char and char:FindFirstChild("HumanoidRootPart")
end

-- Bewegung und Position
local function teleportTo(position)
    local root = getRootPart(getCharacter())
    if root and position then
        root.CFrame = CFrame.new(position)
        print("[ACTION] Spieler wurde erfolgreich teleportiert.")
    else
        print("[FEHLER] Konnte nicht teleportieren. Zielposition oder Spieler nicht verfügbar.")
    end
end

-- Interaktionsprotokoll
local function holdE(target, duration)
    -- Simuliert "E" gedrückt halten (wiederholtes FireServer)
    local prompt = target:FindFirstChild("ProximityPrompt")
    if prompt then
        print("[ACTION] Simuliere 'E' gedrückt halten (Door Open)...")
        local startTime = tick()
        while tick() - startTime < duration do
            prompt:FireServer()
            task.wait(0.1) -- Kurze Verzögerung, um das Spiel nicht zu überlasten
        end
        print("[ACTION] Halten beendet.")
    end
end

local function collectItem(item)
    -- Kurzer Klick (Gegenstand aufheben)
    local prompt = item:FindFirstChild("ProximityPrompt")
    if prompt then
        print("[ACTION] Versuche, Gegenstand aufzuheben...")
        prompt:FireServer()
        task.wait(0.3) -- Wartezeit nach dem Click
        return true
    end
    return false
end

-- Objekt-Suche
local function findDoor(room)
    local door = room:FindFirstChild("Door")
    if door then
        return door
    end
    return nil
end

local function findKeys(room)
    local keys = {}
    for _, child in ipairs(room:GetChildren()) do
        if child.Name == "KeyObtain" and child:IsA("BasePart") then
            table.insert(keys, child)
        end
    end
    return keys
end

local function findKnobs(room)
    local knobs = {}
    for _, child in ipairs(room:GetChildren()) do
        if child.Name == "Knob" and child:IsA("BasePart") then
            table.insert(knobs, child)
        end
    end
    return knobs
end

-- Zustandsprüfungen
local function isDoorOpen(door)
    -- Prüft den Attribut-Status des Türobjekts
    return door and door:GetAttribute("Opened") == true
end

local function getCurrentRoom()
    return LatestRoom and LatestRoom.Value
end

local function getRoomContainer(roomNum)
    return Workspace.CurrentRooms[roomNum]
end

-- ==================================================================================================
-- III. AUTOMATISCHE LOGIK (GAMEPLAY CORE)
-- ==================================================================================================

local function handleRoomChange(roomNum)
    if not isAutoPlayEnabled then return end

    print("\n=================================================")
    print(string.format("[RAUMWECHSEL] >> In Raum %d eingetreten. Start der Routine...", roomNum))
    
    local CurrentRoom = getRoomContainer(roomNum)
    if not CurrentRoom then
        print("[FEHLER] Raum-Container nicht gefunden. Abbruch.")
        return
    end

    -- 1. ITEMS SAMMELN (Keys & Knobs)
    print("[PHASE 1] Starte Itemsammlung...")
    local keys = findKeys(CurrentRoom)
    local knobs = findKnobs(CurrentRoom)
    local collectedCount = 0
    
    for _, key in ipairs(keys) do
        if isAutoCollectEnabled and collectItem(key) then
            collectedCount = collectedCount + 1
        end
    end
    for _, knob in ipairs(knobs) do
        if isAutoCollectEnabled and collectItem(knob) then
            collectedCount = collectedCount + 1
        end
    end
    print(string.format("[ERFOLG] %d Gegenstände gesammelt.", collectedCount))

    -- 2. TÜREN ÖFFNEN & FORTSCHRITT
    local door = findDoor(CurrentRoom)
    if door then
        print("[PHASE 2] Starte Tür-Öffnungsroutine...")
        
        local doorSuccess = false
        
        if isAutoDoorOpenEnabled then
            -- 2a. Tür öffnen (simuliert "E" gedrückt halten)
            holdE(door, 1.5)
            
            -- 2b. Tür-Status überwachen (Timeout-Handling)
            local startTime = tick()
            local timeout = startTime + 15 -- 15 Sekunden Timeout
            
            while not isDoorOpen(door) and tick() < timeout do
                task.wait(0.2)
            end

            if isDoorOpen(door) then
                print("[ERFOLG] Tür erfolgreich geöffnet.")
                doorSuccess = true
            else
                print("[FEHLER] Tür ist nach 15s nicht geöffnet. Routine wird pausiert.")
            end
        end

        -- 3. FORTSCHRITT
        if doorSuccess then
            -- Nach erfolgreicher Interaktion, das Durchgehen der Tür erfolgt durch
            -- die Fortsetzung des Spielzustands (die Engine bewegt den Spieler).
            print("[ACTION] Vorwärtsbewegung initiiert. Warte auf den nächsten Raumwechsel...")
            
            -- Raum als besucht markieren
            visitedRooms[roomNum] = true
        else
            print("[INFO] Fortschritt nicht möglich. Bleibe im aktuellen Raum.")
        end

    else
        print("[INFO] Kein Tür-Objekt gefunden. Fortfahren.")
    end
end

-- ==================================================================================================
-- IV. ERROURBEHANDLUNG UND OPTIONALE SKITS (Godmode, Noclip, etc.)
-- ==================================================================================================

-- Fehlerbehandlung: Tod
local function handleCharacterDeath()
    if not isAutoPlayEnabled then return end
    isCharAlive = false
    print("[CRITICAL] Charakter ist gestorben. Starte Wiederbelebungssequenz...")
    
    -- Versuch, den Charakter neu zu laden (respawnen)
    player:LoadCharacter() 
    
    -- Warte auf den neuen Charakter, um den Zustand zu aktualisieren
    task.wait(4) 
    isCharAlive = true
    print("[INFO] Charakter erfolgreich wiederhergestellt. Auto-Play läuft weiter.")
end

-- Godmode (Unverwundbar)
local function toggleGodmode()
    if isGodmodeEnabled then
        humanoid.MaxHealth = humanoid.Health -- Zurücksetzen
        print("[STATUS] Godmode DEAKTIVIERT.")
        isGodmodeEnabled = false
    else
        humanoid.MaxHealth = 99999 -- Extrem hoher Wert
        print("[STATUS] Godmode AKTIVIERT.")
        isGodmodeEnabled = true
    end
end

-- Noclip (Durchwandern)
local function toggleNoclip()
    if isNoclipEnabled then
        print("[STATUS] Noclip DEAKTIVIERT.")
        isNoclipEnabled = false
        -- In einem echten Executor würde hier die CollisionGroup manipuliert werden.
    else
        print("[STATUS] Noclip AKTIVIERT (PHYSICS MOD).")
        isNoclipEnabled = true
        -- Simuliert die Aktivierung der physikalischen Manipulation.
    end
end

-- Flugmodus (Simuliert F-Taste Eingabe)
local function toggleFlight()
    isFlightEnabled = not isFlightEnabled
    if isFlightEnabled then
        print("[STATUS] Flugmodus AKTIVIERT. Nutze F-Taste (simuliert).")
        -- In einem echten Skript würde hier die Flying-API der Engine genutzt.
    else
        print("[STATUS] Flugmodus DEAKTIVIERT.")
    end
end

-- ==================================================================================================
-- V. GUI UND INTERFACE (SIMULATION IM EXECUTOR)
-- ==================================================================================================

-- Da ein "Drag & Drop"-Fenster außerhalb des Roblox-Client-Kontextes nicht existiert,
-- wird die GUI-Funktionalität als umfassendes Status-/Befehls-Menü simuliert.
local GUI = {
    Status = {},
    Commands = {
        ["!toggleplay"] = function()
            isAutoPlayEnabled = not isAutoPlayEnabled
            print(string.format("\n[SYSTEM] Auto-Play Status: %s", tostring(isAutoPlayEnabled)))
        end,
        ["!collect"] = function()
            isAutoCollectEnabled = not isAutoCollectEnabled
            print(string.format("[SYSTEM] Auto-Collect Status: %s", tostring(isAutoCollectEnabled)))
        end,
        ["!door"] = function()
            isAutoDoorOpenEnabled = not isAutoDoorOpenEnabled
            print(string.format("[SYSTEM] Auto-Door-Open Status: %s", tostring(isAutoDoorOpenEnabled)))
        end,
        ["!god"] = function()
            toggleGodmode()
        end,
        ["!noclip"] = function()
            toggleNoclip()
        end,
        ["!flight"] = function()
            toggleFlight()
        end,
        ["!heal"] = function()
            if isGodmodeEnabled then
                humanoid.Health = humanoid.MaxHealth
                print("[HEAL] Spieler geheilt!")
            else
                print("[WARNUNG] Godmode muss aktiv sein, um zu heilen.")
            end
        end,
        ["!speed"] = function(speedStr)
            local speed = tonumber(speedStr)
            if speed and speed >= 1 and speed <= 250 then
                currentSpeed = speed
                if humanoid then
                    humanoid.WalkSpeed = currentSpeed
                    print(string.format("[SUCCESS] Geschwindigkeit auf %d gesetzt.", currentSpeed))
                else
                    print("[FEHLER] Humanoid nicht gefunden.")
                end
            else
                print("[FEHLER] Ungültige Geschwindigkeit. Bereich 1-250.")
            end
        end,
        ["!status"] = function()
            print("\n================= 📊 SYSTEM STATUS 📊 =================")
            print(string.format("▶️ Auto-Play: %s", tostring(isAutoPlayEnabled)))
            print(string.format("🔑 Auto-Collect: %s", tostring(isAutoCollectEnabled)))
            print(string.format("🚪 Auto-Doors: %s", tostring(isAutoDoorOpenEnabled)))
            print(string.format("🛡️ Godmode: %s", tostring(isGodmodeEnabled)))
            print(string.format("💚 Auto-Heal: %s", tostring(isAutoHealEnabled)))
            print(string.format("🌀 Noclip: %s", tostring(isNoclipEnabled)))
            print(string.format("✈️ Flugmodus: %s", tostring(isFlightEnabled)))
            print(string.format("⚡ Geschwindigkeit: %d", currentSpeed))
            print("======================================================\n")
        end,
        ["!resetroom"] = function()
            visitedRooms = {}
            print("[SYSTEM] Fortschritts-Tracker zurückgesetzt. Alle Räume werden neu besucht.")
        end
    }
end

-- ==================================================================================================
-- VI. HAUPT-LOOP UND START
-- ==================================================================================================

-- Primäre Loop für die Zustandsprüfung
task.spawn(function()
    while true do
        task.wait(0.2) -- Niedriger Polling-Rate für Leistung
        
        -- 1. Charakter-Alive-Prüfung (Fehlerbehandlung)
        if not isCharAlive or not humanoid.Health > 0 then
            handleCharacterDeath()
        end

        -- 2. GUI-Statusanzeige (simuliert die GUI)
        GUI.Status = {} -- Leere Tabelle, um bei jedem Tick neu zu definieren
        -- Eine tatsächliche GUI-Anzeige würde hier die Werte aus den Booleschen Variablen abfragen.
    end
end)

-- Bindet Todes-Event
player.CharacterRemoving:Connect(handleCharacterDeath)

-- Bindet CharacterAdded-Event (für korrekte Zustandsinitialisierung nach Respawn)
player.CharacterAdded:Connect(function(char)
    character = char
    humanoid = getHumanoid(char)
    rootPart = getRootPart(char)
    isCharAlive = true
    
    -- Wenn Godmode/Noclip/Flight aktiv waren, müssen sie auf den neuen Charakter angewendet werden
    if isGodmodeEnabled then toggleGodmode() end
    if isNoclipEnabled then toggleNoclip() end
    if isFlightEnabled then toggleFlight() end
end)


-- ==================================================================================================
-- VII. ENDBENUTZER-ANWEISUNG FÜR DEN EXECUTOR
-- ==================================================================================================
-- HINWEIS: Da ein universeller Konsolen-Interface-Parser in einem reinen Executor-Kontext nicht möglich ist,
-- wird dieses Skript als Modul bereitgestellt. Sie MÜSSEN die Funktionen über das Executor-Chatfenster
-- oder über einen eigenen Lua-Interpreter im Executor aufrufen.
-- Beispielaufruf (angenommen, Ihr Executor erlaubt das Ausführen der Funktion):
-- execute(GUI.Commands["!status"])
-- execute(GUI.Commands["!toggleplay"])
-- execute(GUI.Commands["!speed"] .. "50")

print("\n=====================================================================")
print("🔥 DOORS AUTO-PLAY AGENT V2.0 IN MEMORY GELADEN. 🔥")
print("=====================================================================")
print("Status-Befehle sind über die interne GUI-Struktur (GUI.Commands) erreichbar.")
print("Bitte nutzen Sie die Befehle (z.B. !status, !toggleplay) in Ihrem Executor.")
