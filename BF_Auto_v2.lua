-- =============================================================
--  BF-Auto | Eigenes Standalone-Script für Blox Fruits
--  Für Delta Executor (BlueStacks): ALLES markieren -> Execute
--  Ban-Risiko: wie bei jedem Script, auf eigene Gefahr
-- =============================================================

local Players = game:GetService("Players")
local Workspace = workspace
local Player = Players.LocalPlayer

print("BF-Auto V2: Script gestartet...")

-- ------------------- Helfer -------------------
local function getHRB()
	local c = Player.Character
	if c then return c:FindFirstChild("HumanoidRootPart") end
	return nil
end

local function teleport(pos)
	local hrb = getHRB()
	if hrb then hrb.CFrame = CFrame.new(pos) end
end

-- Früchte = Model "Fruit" in workspace mit Kind "Handle"
local function findFruits()
	local list = {}
	for _, v in pairs(Workspace:GetChildren()) do
		if v:IsA("Model") and v.Name == "Fruit" then
			local handle = v:FindFirstChild("Handle")
			if handle and handle:IsA("BasePart") then
				table.insert(list, { Model = v, Handle = handle, Position = handle.Position })
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
		if not best or d < bestDist then best, bestDist = f, d end
	end
	return best, bestDist
end

local function playerLevel()
	local ok, lvl = pcall(function() return Player.Data.Level.Value end)
	if ok and lvl then return math.floor(lvl) end
	return 0
end

-- ------------------- GUI -------------------
local Gui = Instance.new("ScreenGui")
Gui.Name = "BFAutoGui"
Gui.ResetOnSpawn = false
Gui.IgnoreGuiInset = true
-- Kamera als Parent: funktioniert sofort, auch wenn PlayerGui noch nicht da ist
local old = workspace:GetCamera():FindFirstChild("BFAutoGui")
if old then old:Destroy() end
Gui.Parent = workspace:GetCamera()

-- Grosses Schild: Beweis dass das Script laeuft (verschwindet nach 5s)
local Notify = Instance.new("TextLabel")
Notify.Size = UDim2.new(0, 340, 0, 60)
Notify.Position = Vector2.new(0.5, 0.1)
Notify.AnchorPoint = Vector2.new(0.5, 0)
Notify.BackgroundColor3 = Color3.new(0.05, 0.35, 0.1)
Notify.Text = "BF-Auto V2 LAUFT!"
Notify.Font = Enum.Font.GothamBold
Notify.TextSize = 28
Notify.TextColor3 = Color3.new(1, 1, 1)
Notify.Parent = Gui
spawn(function() wait(5) Notify:Destroy() end)

local Win = Instance.new("Frame")
Win.Name = "BFAutoWin"
Win.Size = UDim2.new(0, 270, 0, 190)
Win.Position = Vector2.new(8, 45)
Win.BackgroundColor3 = Color3.new(0.08, 0.08, 0.12)
Win.BackgroundTransparency = 0.15
Win.BorderSizePixel = 0
Win.Parent = Gui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 22)
Title.Position = Vector2.new(0, 0)
Title.BackgroundTransparency = 1
Title.Text = "BF-Auto  (eigene Script)"
Title.TextColor3 = Color3.new(1, 0.75, 0.2)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Win

local function makeToggle(y, label)
	local btn = Instance.new("TextButton")
	btn.Size = UDim2.new(0.92, 0, 0, 20)
	btn.Position = Vector2.new(0.04, y)
	btn.BackgroundColor3 = Color3.new(0.16, 0.16, 0.22)
	btn.BackgroundTransparency = 0.1
	btn.Text = label .. "  [OFF]"
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 13
	btn.TextColor3 = Color3.new(0.9, 0.9, 0.9)
	btn.Parent = Win
	local state = false
	btn.Clicked:Connect(function()
		state = not state
		btn.Text = label .. "  [" .. (state and "ON" or "OFF") .. "]"
		btn.BackgroundColor3 = state and Color3.new(0.1, 0.45, 0.25) or Color3.new(0.16, 0.16, 0.22)
	end)
	return btn
end

local tESP   = makeToggle(28, "ESP Früchte")
local tGrab  = makeToggle(54, "Auto Fruchte holen")
local tFight = makeToggle(80, "Auto Kampf")
local tQuest = makeToggle(106, "Auto Quests")

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(0.92, 0, 0, 40)
Status.Position = Vector2.new(0.04, 134)
Status.BackgroundTransparency = 1
Status.Text = "Startet..."
Status.Font = Enum.Font.Gotham
Status.TextSize = 12
Status.TextColor3 = Color3.new(0.75, 0.95, 0.75)
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Win

local function isOn(btn) return btn.BackgroundColor3 == Color3.new(0.1, 0.45, 0.25) end

-- ------------------- ESP: Früchte anzeigen -------------------
spawn(function() while true do wait(1)
	if not isOn(tESP) then
		for _, f in pairs(findFruits()) do
			local old = f.Handle:FindFirstChild("BF_ESP")
			if old then old:Destroy() end
		end
		continue
	end
	for _, f in pairs(findFruits()) do
		local bb = f.Handle:FindFirstChild("BF_ESP")
		if not bb then
			bb = Instance.new("BillboardGui")
			bb.Name = "BF_ESP"
			bb.Size = UDim2.new(0, 160, 0, 24)
			bb.AlwaysFaceCamera = true
			bb.Parent = f.Handle
		end
		local label = bb:FindFirstChild("Label")
		if not label then
			label = Instance.new("TextLabel")
			label.Name = "Label"
			label.Size = UDim2.new(1, 0, 1, 0)
			label.BackgroundColor3 = Color3.new(1, 0.3, 0.1)
			label.Text = "FRUCHT!"
			label.Font = Enum.Font.GothamBold
			label.TextSize = 16
			label.Parent = bb
		end
	end
end end)

-- ------------------- Auto: Früchte holen -------------------
spawn(function() while true do wait(2)
	local f, dist = nearestFruit()
	if isOn(tGrab) and f then
		Status.Text = "Frucht gefunden (" .. math.floor(dist) .. "m) -> hole sie..."
		-- Auf die Frucht springen/teleportieren, TouchTransmitter holt sie
		teleport(f.Position + Vector3.new(0, 1, 0))
	end
end end)

-- ------------------- Auto: Kampf -------------------
spawn(function() while true do wait(1.5)
	if isOn(tFight) then
		local enemies = Workspace.Enemies and Workspace.Enemies:GetChildren() or {}
		local hrb = getHRB()
		if hrb then
			for _, e in pairs(enemies) do
				local part = e:FindFirstChild("HumanoidRootPart")
				local hum = e:FindFirstChild("Humanoid")
				if part and hum and hum.Health > 0 then
					local d = (part.Position - hrb.Position).magnitude
					if d < 150 then
						-- In die Nähe des Feindes teleportieren und angreifen
						teleport(part.Position + Vector3.new(0, 1, 0))
						wait(0.2)
						local ok = pcall(function()
							game:GetService("ReplicatedStorage").Remotes.Combat:FireServer("Attack", e)
						end)
						Status.Text = ok and "Kampf gegen: " .. e.Name or "Kampf (Teleport-Modus)"
					end
					break
				end
			end
		end
	end
end end)

-- ------------------- Auto: Quests -------------------
local quests = {
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

spawn(function() while true do wait(30)
	if isOn(tQuest) then
		local lvl = playerLevel()
		local bestQ
		for i = #quests, 1, -1 do
			if lvl >= quests[i].Level then bestQ = quests[i]; break end
		end
		if bestQ then
			local npc = Workspace:FindFirstChild(bestQ.NPC)
			if npc then
				teleport(n:GetPosition().Y > 0 and npc.Position or Vector3.new(0, 10, 0))
				wait(1)
				local ok = pcall(function()
					game:GetService("ReplicatedStorage").Remotes.QuestEvent:FireServer("StartQuest", bestQ.Name)
				end)
				Status.Text = (ok and "Quest gestartet: " or "Quest Remote nicht gefunden: ") .. bestQ.Name
			end
		else
			Status.Text = "Level zu niedrig für Quests (" .. lvl .. ")"
		end
	end
end end)

-- ------------------- Statusanzeige -------------------
spawn(function() while true do wait(3)
	local fruits = findFruits()
	local f, dist = nearestFruit()
	local info = "# Früchte: " .. #fruits
	if f then info = info .. " | Nächste: " .. math.floor(dist) .. "m" end
	info = info .. "\nLevel: " .. playerLevel()
	Status.Text = Status.Text ~= "" and Status.Text or info
end end)

warn("BF-Auto V2 gestartet! Toggles unten links.")
print("BF-Auto V2: Fenster gebaut, alles aktiv.")
