-- CharacterFactory.luau
-- Builds each snack as a character: the FOOD is the body, and the face
-- sits on the food's front. No generic humanoid with a snack on top.
-- Every part is built from primitives (balls, cylinders, boxes) scaled by
-- a per-snack unit `u`, so Legendary / Mythic snacks read bigger in game.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local CharacterFactory = {}

-- Bright, distinct colours that stay vivid under Roblox lighting.
local COLOURS = {
	BunTop = Color3.fromRGB(232, 164, 62),
	BunBottom = Color3.fromRGB(214, 138, 44),
	Patty = Color3.fromRGB(122, 72, 32),
	Tomato = Color3.fromRGB(228, 52, 40),
	Lettuce = Color3.fromRGB(96, 196, 74),
	Cheese = Color3.fromRGB(255, 196, 0),
	Fry = Color3.fromRGB(255, 214, 64),
	FryBox = Color3.fromRGB(226, 38, 38),
	Noodle = Color3.fromRGB(255, 204, 92),
	Bowl = Color3.fromRGB(52, 140, 235),
	Broth = Color3.fromRGB(255, 152, 46),
	Dumpling = Color3.fromRGB(250, 238, 210),
	TacoShell = Color3.fromRGB(244, 178, 62),
	TacoFilling = Color3.fromRGB(150, 84, 28),
	LasagnaSheet = Color3.fromRGB(255, 226, 138),
	LasagnaSauce = Color3.fromRGB(198, 52, 32),
	Queso = Color3.fromRGB(255, 176, 0),
	KebabMeat = Color3.fromRGB(168, 92, 40),
	Skewer = Color3.fromRGB(192, 192, 200),
	Chopstick = Color3.fromRGB(146, 64, 14),
	Naruto = Color3.fromRGB(255, 255, 255),
	NarutoSwirl = Color3.fromRGB(255, 88, 120),
	EyeWhite = Color3.fromRGB(255, 255, 255),
	EyeBlack = Color3.fromRGB(24, 24, 24),
	Seed = Color3.fromRGB(255, 244, 200),
}

-- Scale per rarity: bigger snacks for the rarer tiers.
local function scaleForRarity(rarity: string): number
	if rarity == "Mythic" then
		return 1.3
	elseif rarity == "Legendary" then
		return 1.15
	elseif rarity == "Epic" then
		return 1.05
	else
		return 1
	end
end

-- Primitive helpers. Every size is multiplied by u so the whole snack
-- scales as one piece. All parts are Anchored; only the Body collides.
local function addBall(model: Model, u: number, diameter: number, position: Vector3, colour: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = "Ball"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(diameter * u, diameter * u, diameter * u)
	part.Position = position
	part.Color = colour
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.Parent = model
	return part
end

local function addBox(model: Model, u: number, size: Vector3, position: Vector3, colour: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = "Box"
	part.Shape = Enum.PartType.Block
	part.Size = Vector3.new(size.X * u, size.Y * u, size.Z * u)
	part.Position = position
	part.Color = colour
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.Parent = model
	return part
end

-- Cylinder axis is X in Roblox: length runs along X, diameter across Y/Z.
local function addCyl(model: Model, u: number, length: number, diameter: number, position: Vector3, colour: Color3, material: Enum.Material?): Part
	local part = Instance.new("Part")
	part.Name = "Cylinder"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(length * u, diameter * u, diameter * u)
	part.Position = position
	part.Color = colour
	part.Material = material or Enum.Material.SmoothPlastic
	part.Anchored = true
	part.CanCollide = false
	part.Parent = model
	return part
end

-- The face: two bold eyes plus a smile, sitting proud of the front (+Z)
-- surface so they read clearly in-game instead of sinking into the food.
-- frontZ is the Z of the food's front surface. The eye balls have radius
-- 0.13u, so a centre at frontZ + 0.15u leaves them embedded in the food
-- with ~0.28u of bold relief sticking out -- the previous +0.30u centre
-- left a visible gap and the eyes floated in front of the face.
local function addFace(model: Model, u: number, frontZ: number, faceY: number)
	local eyeY = faceY + 0.25 * u
	local eyeZ = frontZ + 0.15 * u
	-- White of the eye, then a black pupil pushed a touch further out.
	addBall(model, u, 0.26, Vector3.new(-0.30 * u, eyeY, eyeZ), COLOURS.EyeWhite)
	addBall(model, u, 0.26, Vector3.new(0.30 * u, eyeY, eyeZ), COLOURS.EyeWhite)
	addBall(model, u, 0.13, Vector3.new(-0.30 * u, eyeY, eyeZ + 0.12 * u), COLOURS.EyeBlack)
	addBall(model, u, 0.13, Vector3.new(0.30 * u, eyeY, eyeZ + 0.12 * u), COLOURS.EyeBlack)
	-- Smile: three small dark balls arcing downwards. Radius is 0.05u, so
	-- a centre at frontZ + 0.08u keeps them seated on the surface with
	-- ~0.13u of relief instead of floating in front of it.
	local smileZ = frontZ + 0.08 * u
	local smileY = faceY - 0.12 * u
	addBall(model, u, 0.10, Vector3.new(-0.20 * u, smileY + 0.05 * u, smileZ), COLOURS.EyeBlack)
	addBall(model, u, 0.10, Vector3.new(0, smileY, smileZ), COLOURS.EyeBlack)
	addBall(model, u, 0.10, Vector3.new(0.20 * u, smileY + 0.05 * u, smileZ), COLOURS.EyeBlack)
end

-- Sesame seeds scattered over a bun top.
local function addSesame(model: Model, u: number, topY: number)
	local seeds = {
		Vector3.new(-0.35, topY, 0.25),
		Vector3.new(0.1, topY + 0.06, 0.3),
		Vector3.new(0.4, topY, -0.1),
		Vector3.new(-0.1, topY + 0.04, -0.35),
		Vector3.new(0.3, topY, 0.35),
	}
	for _, offset in ipairs(seeds) do
		addBall(model, u, 0.12, Vector3.new(offset.X * u, offset.Y * u, offset.Z * u), COLOURS.Seed)
	end
end

-- One builder per snack. Each returns the Body part (the visible main
-- piece) and the Z of the front surface where the face should sit.
local function buildBurger(model: Model, u: number): (Part, number)
	local body = addBox(model, u, Vector3.new(1.7, 0.35, 1.7), Vector3.new(0, -0.55 * u, 0), COLOURS.BunBottom)
	addBox(model, u, Vector3.new(1.9, 0.30, 1.9), Vector3.new(0, -0.22 * u, 0), COLOURS.Patty)
	addBox(model, u, Vector3.new(1.8, 0.12, 1.8), Vector3.new(0, -0.02 * u, 0), COLOURS.Tomato)
	addBox(model, u, Vector3.new(2.0, 0.10, 2.0), Vector3.new(0, 0.10 * u, 0), COLOURS.Lettuce)
	addBox(model, u, Vector3.new(1.8, 0.10, 1.8), Vector3.new(0, 0.20 * u, 0), COLOURS.Cheese)
	-- Tall top bun: a squashed ball, height about 0.55u of bun above the stack.
	local bun = addBall(model, u, 1.9, Vector3.new(0, 0.55 * u, 0), COLOURS.BunTop)
	bun.Size = Vector3.new(1.9 * u, 1.1 * u, 1.9 * u)
	-- Bun dome tops out at y = 1.10u (centre 0.55u + half-height 0.55u);
	-- seeds centred at 1.06u (radius 0.06u) sit on the dome instead of
	-- being buried inside it, which 1.02u did.
	addSesame(model, u, 1.06)
	return body, 0.95 * u
end

local function buildFries(model: Model, u: number): (Part, number)
	local body = addBox(model, u, Vector3.new(1.5, 1.3, 0.9), Vector3.new(0, 0, 0), COLOURS.FryBox)
	addBox(model, u, Vector3.new(1.5, 0.25, 0.9), Vector3.new(0, 0.75 * u, 0), COLOURS.FryBox)
	for i = -2, 2 do
		local fry = addBox(model, u, Vector3.new(0.22, 1.2, 0.22), Vector3.new(i * 0.28 * u, 1.05 * u, 0), COLOURS.Fry)
		fry.CFrame = CFrame.new(fry.Position) * CFrame.Angles(0, 0, math.rad(i * 6))
	end
	return body, 0.48 * u
end

local function buildNoodles(model: Model, u: number): (Part, number)
	local body = addCyl(model, u, 0.9, 1.9, Vector3.new(0, 0, 0), COLOURS.Bowl)
	body.CFrame = CFrame.new(body.Position) * CFrame.Angles(0, 0, math.rad(90))
	addCyl(model, u, 0.2, 1.6, Vector3.new(0, 0.45 * u, 0), COLOURS.Broth).CFrame =
		CFrame.new(0, 0.45 * u, 0) * CFrame.Angles(0, 0, math.rad(90))
	-- Noodle swirls: a ring of small balls on top of the broth.
	for i = 0, 7 do
		local angle = (i / 8) * math.pi * 2
		addBall(model, u, 0.30, Vector3.new(math.cos(angle) * 0.55 * u, 0.55 * u, math.sin(angle) * 0.55 * u), COLOURS.Noodle)
	end
	addBall(model, u, 0.34, Vector3.new(0, 0.58 * u, 0), COLOURS.Noodle)
	return body, 0.95 * u
end

local function buildRamen(model: Model, u: number): (Part, number)
	local body = addCyl(model, u, 1.0, 2.0, Vector3.new(0, 0, 0), COLOURS.Bowl)
	body.CFrame = CFrame.new(body.Position) * CFrame.Angles(0, 0, math.rad(90))
	addCyl(model, u, 0.2, 1.7, Vector3.new(0, 0.5 * u, 0), COLOURS.Broth).CFrame =
		CFrame.new(0, 0.5 * u, 0) * CFrame.Angles(0, 0, math.rad(90))
	for i = 0, 5 do
		local angle = (i / 6) * math.pi * 2
		addBall(model, u, 0.28, Vector3.new(math.cos(angle) * 0.5 * u, 0.6 * u, math.sin(angle) * 0.5 * u), COLOURS.Noodle)
	end
	-- Narutomaki: white disc with a pink swirl dot, floating on the broth.
	local naruto = addCyl(model, u, 0.12, 0.5, Vector3.new(0.45 * u, 0.65 * u, 0.35 * u), COLOURS.Naruto)
	naruto.CFrame = CFrame.new(naruto.Position) * CFrame.Angles(0, 0, math.rad(90))
	addBall(model, u, 0.16, Vector3.new(0.45 * u, 0.72 * u, 0.35 * u), COLOURS.NarutoSwirl)
	-- Chopsticks leaning out of the bowl.
	local stick1 = addCyl(model, u, 2.2, 0.10, Vector3.new(0.5 * u, 1.0 * u, -0.2 * u), COLOURS.Chopstick)
	stick1.CFrame = CFrame.new(stick1.Position) * CFrame.Angles(math.rad(35), 0, math.rad(25))
	local stick2 = addCyl(model, u, 2.2, 0.10, Vector3.new(0.65 * u, 1.0 * u, 0.05 * u), COLOURS.Chopstick)
	stick2.CFrame = CFrame.new(stick2.Position) * CFrame.Angles(math.rad(35), 0, math.rad(18))
	return body, 1.0 * u
end

local function buildDumpling(model: Model, u: number): (Part, number)
	local body = addBall(model, u, 1.7, Vector3.new(0, 0, 0), COLOURS.Dumpling)
	body.Size = Vector3.new(1.7 * u, 1.15 * u, 1.15 * u)
	-- Pleated top ridge.
	for i = -2, 2 do
		addBall(model, u, 0.28, Vector3.new(i * 0.32 * u, 0.55 * u, 0), COLOURS.Dumpling)
	end
	return body, 0.58 * u
end

local function buildTaco(model: Model, u: number): (Part, number)
	-- Shell: a half-cylinder look made from a squashed ball, cut visually
	-- by the filling piled along the top.
	local body = addBall(model, u, 1.8, Vector3.new(0, -0.1 * u, 0), COLOURS.TacoShell)
	body.Size = Vector3.new(1.8 * u, 1.3 * u, 0.9 * u)
	for i = -2, 2 do
		addBall(model, u, 0.42, Vector3.new(i * 0.34 * u, 0.55 * u, 0), COLOURS.TacoFilling)
		addBall(model, u, 0.24, Vector3.new(i * 0.34 * u, 0.75 * u, 0.1 * u), COLOURS.Tomato)
	end
	addBox(model, u, Vector3.new(1.6, 0.12, 0.7), Vector3.new(0, 0.45 * u, 0), COLOURS.Lettuce)
	return body, 0.48 * u
end

local function buildLasagna(model: Model, u: number): (Part, number)
	local body = addBox(model, u, Vector3.new(1.9, 0.45, 1.4), Vector3.new(0, -0.45 * u, 0), COLOURS.LasagnaSheet)
	addBox(model, u, Vector3.new(1.9, 0.18, 1.4), Vector3.new(0, -0.15 * u, 0), COLOURS.LasagnaSauce)
	addBox(model, u, Vector3.new(1.9, 0.45, 1.4), Vector3.new(0, 0.15 * u, 0), COLOURS.LasagnaSheet)
	addBox(model, u, Vector3.new(1.9, 0.18, 1.4), Vector3.new(0, 0.45 * u, 0), COLOURS.LasagnaSauce)
	addBox(model, u, Vector3.new(1.9, 0.40, 1.4), Vector3.new(0, 0.72 * u, 0), COLOURS.LasagnaSheet)
	-- Melted cheese dripping over the top layer.
	for i = -1, 1 do
		addBall(model, u, 0.30, Vector3.new(i * 0.55 * u, 0.92 * u, 0.55 * u), COLOURS.Cheese)
	end
	return body, 0.72 * u
end

local function buildQueso(model: Model, u: number): (Part, number)
	local body = addBox(model, u, Vector3.new(1.7, 1.2, 1.2), Vector3.new(0, 0, 0), COLOURS.Queso)
	-- Cheese holes: darker dimples pressed into the front face.
	addBall(model, u, 0.30, Vector3.new(-0.45 * u, 0.25 * u, 0.60 * u), COLOURS.Cheese)
	addBall(model, u, 0.22, Vector3.new(0.35 * u, -0.25 * u, 0.60 * u), COLOURS.Cheese)
	addBall(model, u, 0.26, Vector3.new(0.15 * u, 0.4 * u, 0.60 * u), COLOURS.Cheese)
	-- A wedge cut from the top corner.
	addBox(model, u, Vector3.new(0.6, 0.35, 1.0), Vector3.new(0.55 * u, 0.72 * u, 0), COLOURS.Cheese)
	return body, 0.62 * u
end

local function buildKebab(model: Model, u: number): (Part, number)
	local skewer = addCyl(model, u, 2.6, 0.10, Vector3.new(0, 0.1 * u, 0), COLOURS.Skewer)
	skewer.CFrame = CFrame.new(skewer.Position) * CFrame.Angles(0, 0, math.rad(90))
	local body = addBall(model, u, 0.85, Vector3.new(0, 0.55 * u, 0), COLOURS.KebabMeat)
	addBall(model, u, 0.85, Vector3.new(0, -0.05 * u, 0), COLOURS.KebabMeat)
	addBall(model, u, 0.85, Vector3.new(0, -0.65 * u, 0), COLOURS.KebabMeat)
	addBall(model, u, 0.40, Vector3.new(0, 0.25 * u, 0), COLOURS.Tomato)
	addBall(model, u, 0.40, Vector3.new(0, -0.35 * u, 0), COLOURS.Lettuce)
	return body, 0.45 * u
end

local BUILDERS = {
	["Baron Burger"] = buildBurger,
	["Soggy Fry"] = buildFries,
	["Noodle Ned"] = buildNoodles,
	["Eternal Ramen"] = buildRamen,
	["Dancing Dumpling"] = buildDumpling,
	["Turbo Taco"] = buildTaco,
	["Lord Lasagna"] = buildLasagna,
	["Queen Queso"] = buildQueso,
	["King Kebab"] = buildKebab,
}

-- Builds a snack character model. tier (0/1/2) staggers the caption height
-- so labels do not overlap when walkers bunch up on the belt.
function CharacterFactory.buildSnack(snackData, tier: number?)
	local u = scaleForRarity(snackData.Rarity)
	local labelTier = tier or 0

	local model = Instance.new("Model")
	model.Name = snackData.Name

	local builder = BUILDERS[snackData.Name] or buildDumpling
	local body, frontZ = builder(model, u)
	body.Name = "Body"
	body.CanCollide = true

	-- Face on the food's front, with bold relief.
	addFace(model, u, frontZ, 0.1 * u)

	-- Round Neon rarity disc floating above the snack.
	local discColour = Config.RarityColors[snackData.Rarity] or Color3.fromRGB(255, 255, 255)
	local disc = addCyl(model, u, 0.06, 1.70, Vector3.new(0, 1.9 * u, 0), discColour, Enum.Material.Neon)
	disc.Name = "RarityDisc"
	disc.CFrame = CFrame.new(disc.Position) * CFrame.Angles(0, 0, math.rad(90))

	-- Caption: name + price, raised per label tier.
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "Caption"
	billboard.Size = UDim2.new(0, 200, 0, 50)
	billboard.StudsOffsetWorldSpace = Vector3.new(0, 2.4 * u + labelTier * 1.6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = body

	local label = Instance.new("TextLabel")
	label.Name = "CaptionLabel"
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = string.format("%s\n$%d", snackData.Name, snackData.Price)
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.Parent = billboard

	model:SetAttribute("SnackName", snackData.Name)
	model:SetAttribute("Rarity", snackData.Rarity)
	model:SetAttribute("Price", snackData.Price)
	model:SetAttribute("Rate", snackData.Rate)
	model.PrimaryPart = body

	return model
end

-- Parents a ClickDetector to the visible Body part (never to an invisible
-- root plate) and wires MouseClick to the callback.
function CharacterFactory.attachClick(model: Model, callback: (Player) -> ())
	local body = model:FindFirstChild("Body")
	assert(body ~= nil, "CharacterFactory.attachClick: model has no Body part")
	local detector = Instance.new("ClickDetector")
	detector.MaxActivationDistance = 32
	detector.Parent = body
	detector.MouseClick:Connect(callback)
	return detector
end

-- Updates the caption billboard text on an already-built snack.
function CharacterFactory.setCaption(model: Model, text: string)
	local body = model:FindFirstChild("Body")
	if body == nil then
		return
	end
	local billboard = body:FindFirstChild("Caption")
	if billboard == nil then
		return
	end
	local label = billboard:FindFirstChild("CaptionLabel")
	if label and label:IsA("TextLabel") then
		label.Text = text
	end
end

function CharacterFactory.countParts(model: Model): number
	local count = 0
	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			count += 1
		end
	end
	return count
end

return CharacterFactory
