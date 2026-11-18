-- Bases.luau
-- Owns every player's base plot, the central snack belt, and world dressing.
-- Written fresh for Steal a Snack v3 from the design spec.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Config = require(ReplicatedStorage:WaitForChild("Config"))
local State = require(script.Parent.State)
local CharacterFactory = require(script.Parent.CharacterFactory)

local Bases = {}

local baseCount = 0
local BASE_SPACING = 30
local BASE_ROW_Z = -34

local function makePart(name, size, position, color, material, parent)
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Position = position
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = true
	part.Parent = parent
	return part
end

function Bases.createBase(player)
	baseCount += 1
	local index = baseCount
	local origin = Vector3.new((index - 1) * BASE_SPACING - 60, 0, BASE_ROW_Z)

	local model = Instance.new("Model")
	model.Name = player.Name .. "_Base"

	-- Floor slab.
	makePart("Floor", Vector3.new(24, 1, 18), origin + Vector3.new(0, 0.5, 0),
		Color3.fromRGB(120, 72, 40), Enum.Material.WoodPlanks, model)

	-- Back wall.
	makePart("BackWall", Vector3.new(24, 8, 1), origin + Vector3.new(0, 4, -8.5),
		Color3.fromRGB(235, 220, 190), Enum.Material.SmoothPlastic, model)

	-- Stepped gable peak roof: three slabs, each narrower and higher than the last.
	local roofColors = {
		Color3.fromRGB(200, 60, 60),
		Color3.fromRGB(220, 90, 70),
		Color3.fromRGB(240, 130, 80),
	}
	local roofWidths = { 26, 20, 14 }
	for i = 1, 3 do
		makePart("RoofStep" .. i, Vector3.new(roofWidths[i], 1, 20),
			origin + Vector3.new(0, 9 + i * 1.6, -1),
			roofColors[i], Enum.Material.SmoothPlastic, model)
	end
	-- Neon cap along the roof peak.
	local cap = makePart("RoofCap", Vector3.new(15, 0.6, 1.2),
		origin + Vector3.new(0, 14.4, -1), Color3.fromRGB(255, 210, 60),
		Enum.Material.Neon, model)
	cap.CanCollide = false

	-- Splayed wing walls at +/-45 degrees, each with a Neon cap.
	for _, side in ipairs({ -1, 1 }) do
		local wing = makePart("WingWall" .. side, Vector3.new(1, 7, 12),
			origin + Vector3.new(side * 12.5, 3.5, 0),
			Color3.fromRGB(90, 160, 220), Enum.Material.SmoothPlastic, model)
		wing.CFrame = CFrame.new(origin + Vector3.new(side * 12.5, 3.5, 0))
			* CFrame.Angles(0, math.rad(side * 45), 0)
		local wingCap = makePart("WingCap" .. side, Vector3.new(1.2, 0.6, 12),
			origin + Vector3.new(side * 12.5, 7.2, 0),
			Color3.fromRGB(255, 210, 60), Enum.Material.Neon, model)
		wingCap.CFrame = CFrame.new(origin + Vector3.new(side * 12.5, 7.2, 0))
			* CFrame.Angles(0, math.rad(side * 45), 0)
		wingCap.CanCollide = false
	end

	-- Lock indicator: green = open, red = locked. Steal checks State.isLocked,
	-- this part is the visible signal for it.
	local lockPart = makePart("LockIndicator", Vector3.new(2, 2, 0.6),
		origin + Vector3.new(0, 6, 8.8), Color3.fromRGB(60, 220, 90),
		Enum.Material.Neon, model)
	lockPart.CanCollide = false

	-- Six snack slots in a row across the front of the base.
	local slotPositions = {}
	for slot = 1, Config.BaseSlots do
		local slotX = origin.X - 10 + (slot - 1) * 4
		local slotPos = Vector3.new(slotX, 1.5, origin.Z + 2)
		table.insert(slotPositions, slotPos)
		makePart("SlotPad" .. slot, Vector3.new(3.4, 0.4, 3.4), slotPos - Vector3.new(0, 0.4, 0),
			Color3.fromRGB(255, 235, 170), Enum.Material.SmoothPlastic, model)
	end

	model.Parent = Workspace

	player.Base = model
	player.Slots = {}
	player.SlotModels = {}
	player.SlotPositions = slotPositions
	player.LockIndicator = lockPart
	player.BaseIndex = index
	for i = 1, Config.BaseSlots do
		player.Slots[i] = nil
		player.SlotModels[i] = nil
	end

	return model
end

function Bases.setLockVisual(player, locked)
	if player.LockIndicator then
		player.LockIndicator.Color = locked
			and Color3.fromRGB(220, 40, 40)
			or Color3.fromRGB(60, 220, 90)
	end
end

function Bases.getFreeSlot(player)
	if not player.Slots then
		return nil
	end
	for i = 1, Config.BaseSlots do
		if player.Slots[i] == nil then
			return i
		end
	end
	return nil
end

function Bases.placeSnack(player, snackEntry)
	local slot = Bases.getFreeSlot(player)
	if not slot then
		return false
	end
	local model = nil
	local ok, built = pcall(function()
		return CharacterFactory.buildSnack(snackEntry, 0)
	end)
	if ok and built then
		model = built
		local slotPos = player.SlotPositions and player.SlotPositions[slot]
		if slotPos then
			if model.PrimaryPart then
				model:SetPrimaryPartCFrame(CFrame.new(slotPos))
			else
				model:PivotTo(CFrame.new(slotPos))
			end
		end
		model.Parent = player.Base or Workspace
	end
	player.Slots[slot] = snackEntry
	player.SlotModels[slot] = model
	return true
end

function Bases.removeSnack(player, snackId)
	if not player.Slots then
		return nil
	end
	for i = 1, Config.BaseSlots do
		local entry = player.Slots[i]
		if entry and entry.Id == snackId then
			player.Slots[i] = nil
			local model = player.SlotModels[i]
			player.SlotModels[i] = nil
			if model then
				model:Destroy()
			end
			State.removeSnack(player.UserId, snackId)
			return entry
		end
	end
	return nil
end

function Bases.buildBelt()
	local belt = Instance.new("Model")
	belt.Name = "SnackBelt"

	-- Dark belt slab running along X at Z = 0.
	makePart("BeltSlab", Vector3.new(140, 1, 10), Vector3.new(0, 0.5, 0),
		Color3.fromRGB(45, 45, 55), Enum.Material.Slate, belt)
	-- Cream centre lane.
	makePart("CentreLane", Vector3.new(140, 0.3, 3), Vector3.new(0, 1.1, 0),
		Color3.fromRGB(255, 240, 200), Enum.Material.SmoothPlastic, belt)
	-- Gold Neon strips along both edges.
	for _, z in ipairs({ -4.6, 4.6 }) do
		local strip = makePart("EdgeStrip", Vector3.new(140, 0.3, 0.6),
			Vector3.new(0, 1.1, z), Color3.fromRGB(255, 200, 40),
			Enum.Material.Neon, belt)
		strip.CanCollide = false
	end

	-- "SNACK BELT" sign gates at both ends.
	for _, x in ipairs({ 66.5, -66.5 }) do
		local gate = Instance.new("Model")
		gate.Name = "BeltGate" .. x
		makePart("GatePostL", Vector3.new(1, 10, 1), Vector3.new(x, 5, -4.5),
			Color3.fromRGB(200, 60, 60), Enum.Material.SmoothPlastic, gate)
		makePart("GatePostR", Vector3.new(1, 10, 1), Vector3.new(x, 5, 4.5),
			Color3.fromRGB(200, 60, 60), Enum.Material.SmoothPlastic, gate)
		local sign = makePart("GateSign", Vector3.new(1, 3, 10), Vector3.new(x, 10.5, 0),
			Color3.fromRGB(255, 210, 60), Enum.Material.Neon, gate)
		sign.CanCollide = false
		local label = Instance.new("SurfaceGui", sign)
		label.Face = Enum.NormalId.Front
		local text = Instance.new("TextLabel", label)
		text.Size = UDim2.fromScale(1, 1)
		text.BackgroundTransparency = 1
		text.Text = "SNACK BELT"
		text.TextScaled = true
		text.Font = Enum.Font.FredokaOne
		text.TextColor3 = Color3.fromRGB(60, 30, 10)
		gate.Parent = belt
	end

	-- 10 gold Neon chevrons pointing along the belt.
	for i = 1, 10 do
		local x = -63 + (i - 1) * 14
		local chevron = makePart("Chevron" .. i, Vector3.new(2.4, 0.4, 2.4),
			Vector3.new(x, 1.3, 0), Color3.fromRGB(255, 200, 40),
			Enum.Material.Neon, belt)
		chevron.CFrame = CFrame.new(x, 1.3, 0) * CFrame.Angles(0, math.rad(45), 0)
		chevron.CanCollide = false
	end

	-- 16 cobble promenade panels flanking the belt.
	for i = 1, 16 do
		local side = (i % 2 == 0) and 1 or -1
		local x = -56 + math.floor((i - 1) / 2) * 16
		makePart("Promenade" .. i, Vector3.new(12, 0.4, 4),
			Vector3.new(x, 0.3, side * 8), Color3.fromRGB(160, 150, 135),
			Enum.Material.Cobblestone, belt)
	end

	-- 4 round belt bushes.
	local bushPositions = {
		Vector3.new(-60, 1.5, 8), Vector3.new(60, 1.5, 8),
		Vector3.new(-60, 1.5, -8), Vector3.new(60, 1.5, -8),
	}
	for i, pos in ipairs(bushPositions) do
		local bush = Instance.new("Part")
		bush.Name = "Bush" .. i
		bush.Shape = Enum.PartType.Ball
		bush.Size = Vector3.new(3, 3, 3)
		bush.Position = pos
		bush.Color = Color3.fromRGB(60, 180, 80)
		bush.Material = Enum.Material.Grass
		bush.Anchored = true
		bush.Parent = belt
	end

	belt.Parent = Workspace
	return belt
end

function Bases.buildEnvironment()
	local env = Instance.new("Model")
	env.Name = "Environment"

	-- Ground slab + SpawnLocation pad.
	makePart("Ground", Vector3.new(220, 2, 160), Vector3.new(0, -1, -10),
		Color3.fromRGB(110, 190, 90), Enum.Material.Grass, env)
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "SpawnLocation"
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, 20)
	spawn.Color = Color3.fromRGB(255, 235, 170)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Parent = env

	-- Roofs: an open pergola over the back third of every base plot,
	-- plus a sloped canopy over each market stall.
	local pergolaColors = {
		Color3.fromRGB(240, 120, 60), Color3.fromRGB(90, 170, 240),
		Color3.fromRGB(240, 200, 60), Color3.fromRGB(150, 90, 220),
	}
	for i = 1, 4 do
		local x = -45 + (i - 1) * 30
		for beam = 1, 5 do
			makePart("PergolaBeam" .. i .. "_" .. beam, Vector3.new(1, 0.8, 14),
				Vector3.new(x - 6 + beam * 3, 11, -40),
				pergolaColors[i], Enum.Material.Wood, env)
		end
		-- Sloped market-stall canopy.
		local canopy = makePart("StallCanopy" .. i, Vector3.new(12, 0.6, 8),
			Vector3.new(x, 8, -14), pergolaColors[i], Enum.Material.SmoothPlastic, env)
		canopy.CFrame = CFrame.new(x, 8, -14) * CFrame.Angles(math.rad(-18), 0, 0)
		local postA = makePart("StallPostA" .. i, Vector3.new(0.8, 8, 0.8),
			Vector3.new(x - 5, 4, -11), Color3.fromRGB(120, 72, 40),
			Enum.Material.Wood, env)
		postA.CanCollide = false
		local postB = makePart("StallPostB" .. i, Vector3.new(0.8, 8, 0.8),
			Vector3.new(x + 5, 4, -11), Color3.fromRGB(120, 72, 40),
			Enum.Material.Wood, env)
		postB.CanCollide = false
	end

	-- Carnival: STATIC ferris wheel at (-92, 15), 12 rainbow Neon rim
	-- segments + bulbs, 8 spokes, 8 cabins, A-frame legs and pennants.
	-- STATIC on purpose: no rotation script, so it never desyncs.
	local wheel = Instance.new("Model")
	wheel.Name = "FerrisWheel"
	local wheelCentre = Vector3.new(-92, 15, -20)
	local rainbow = {
		Color3.fromRGB(255, 60, 60), Color3.fromRGB(255, 140, 40),
		Color3.fromRGB(255, 220, 60), Color3.fromRGB(80, 220, 90),
		Color3.fromRGB(60, 160, 255), Color3.fromRGB(160, 90, 255),
	}
	for i = 1, 12 do
		local angle = (i - 1) * (math.pi * 2 / 12)
		local rimPos = wheelCentre + Vector3.new(math.cos(angle) * 12, math.sin(angle) * 12, 0)
		local rim = makePart("Rim" .. i, Vector3.new(6.6, 0.8, 0.8), rimPos,
			rainbow[((i - 1) % 6) + 1], Enum.Material.Neon, wheel)
		rim.CFrame = CFrame.new(rimPos) * CFrame.Angles(0, 0, angle + math.pi / 12)
		rim.CanCollide = false
		local bulb = Instance.new("Part")
		bulb.Name = "Bulb" .. i
		bulb.Shape = Enum.PartType.Ball
		bulb.Size = Vector3.new(1.2, 1.2, 1.2)
		bulb.Position = rimPos
		bulb.Color = Color3.fromRGB(255, 240, 180)
		bulb.Material = Enum.Material.Neon
		bulb.Anchored = true
		bulb.CanCollide = false
		bulb.Parent = wheel
	end
	for i = 1, 8 do
		local angle = (i - 1) * (math.pi * 2 / 8)
		local spoke = makePart("Spoke" .. i, Vector3.new(24, 0.6, 0.6),
			wheelCentre, Color3.fromRGB(230, 230, 230), Enum.Material.SmoothPlastic, wheel)
		spoke.CFrame = CFrame.new(wheelCentre) * CFrame.Angles(0, 0, angle)
		spoke.CanCollide = false
	end
	for i = 1, 8 do
		local angle = (i - 1) * (math.pi * 2 / 8)
		local cabinPos = wheelCentre + Vector3.new(math.cos(angle) * 12, math.sin(angle) * 12, 1.2)
		makePart("Cabin" .. i, Vector3.new(2.6, 2.6, 2.2), cabinPos,
			rainbow[((i - 1) % 6) + 1], Enum.Material.SmoothPlastic, wheel)
	end
	-- A-frame legs.
	for _, side in ipairs({ -1, 1 }) do
		local leg = makePart("WheelLeg" .. side, Vector3.new(1, 17, 1),
			wheelCentre + Vector3.new(side * 4, -8, 0),
			Color3.fromRGB(200, 60, 60), Enum.Material.SmoothPlastic, wheel)
		leg.CFrame = CFrame.new(wheelCentre + Vector3.new(side * 4, -8, 0))
			* CFrame.Angles(0, 0, math.rad(side * -14))
	end
	-- Pennants on top of the wheel.
	for i = 1, 3 do
		makePart("Pennant" .. i, Vector3.new(1.6, 2.2, 0.3),
			wheelCentre + Vector3.new(-3 + i * 3, 28.5, 0),
			rainbow[i], Enum.Material.Neon, wheel).CanCollide = false
	end
	wheel.Parent = env

	-- 3-tier tower at (95, -25) with rainbow Neon trim, cyan beacon,
	-- 1 PointLight and a gold flag.
	local tower = Instance.new("Model")
	tower.Name = "PrizeTower"
	local towerBase = Vector3.new(95, 0, -25)
	local tierSizes = { 14, 10, 6 }
	for i = 1, 3 do
		local tierY = (i - 1) * 6
		makePart("TowerTier" .. i, Vector3.new(tierSizes[i], 6, tierSizes[i]),
			towerBase + Vector3.new(0, 3 + tierY, 0),
			Color3.fromRGB(240, 230, 210), Enum.Material.SmoothPlastic, tower)
		local trim = makePart("TowerTrim" .. i, Vector3.new(tierSizes[i] + 0.6, 0.6, tierSizes[i] + 0.6),
			towerBase + Vector3.new(0, 6 + tierY, 0),
			rainbow[((i - 1) % 6) + 1], Enum.Material.Neon, tower)
		trim.CanCollide = false
	end
	local beacon = makePart("Beacon", Vector3.new(2, 2, 2),
		towerBase + Vector3.new(0, 19.5, 0), Color3.fromRGB(60, 230, 255),
		Enum.Material.Neon, tower)
	beacon.Shape = Enum.PartType.Ball
	local beaconLight = Instance.new("PointLight", beacon)
	beaconLight.Color = Color3.fromRGB(60, 230, 255)
	beaconLight.Range = 24
	beaconLight.Brightness = 2
	-- Gold flag on a pole above the beacon.
	makePart("FlagPole", Vector3.new(0.5, 5, 0.5), towerBase + Vector3.new(0, 22, 0),
		Color3.fromRGB(120, 120, 120), Enum.Material.Metal, tower)
	makePart("GoldFlag", Vector3.new(4, 2.4, 0.3), towerBase + Vector3.new(2.2, 23.5, 0),
		Color3.fromRGB(255, 200, 40), Enum.Material.Neon, tower).CanCollide = false

	tower.Parent = env
	env.Parent = Workspace
	return env
end

return Bases
