-- Lade USSI
local Params = {
    RepoURL = "https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/",
    SSI = "saveinstance",
}
local synsaveinstance = loadstring(game:HttpGet(Params.RepoURL .. Params.SSI .. ".luau", true), Params.SSI)()

-- Optionen für den Save-Vorgang (hier kannst du bei Bedarf etwas anpassen)
local Options = {
    SafeMode = true, -- Aktiviere diesen Modus, falls es Probleme gibt
    SaveBytecode = true, -- Versuche, Skripte zu dekompilieren (falls unterstützt)
}

-- Führe den Save-Vorgang aus
synsaveinstance(Options)
