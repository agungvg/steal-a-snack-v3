-- tests/stub_env.luau
-- Minimal Roblox environment stub so the Luau CLI can load and exercise the
-- server modules without Roblox Studio.
--
-- What it provides:
--   * game:GetService for the services the modules use, with a mock
--     ReplicatedStorage whose WaitForChild("Config") returns the loaded
--     Config module, and a DataStoreService whose GetDataStore errors, so
--     Saves.Store is nil exactly as it is in Studio without DataStores.
--   * Instance.new returning mock instances with Name/Parent/ClassName,
--     children tracking, WaitForChild/FindFirstChild/GetDescendants,
--     SetAttribute/GetAttribute, Destroy, Clone, and mock signals
--     (Touched, MouseClick, OnClientEvent, PlayerAdded, ...) with Connect.
--   * Vector3 / Color3 / CFrame / UDim2 / UDim / Vector2 / Enum / BrickColor
--     value types with the operations the modules use.
--   * task.spawn/task.delay queueing (never run inline) and a task.wait
--     with a tick budget: a start() loop that waits forever trips the
--     budget instead of hanging the test process.
--   * A `require` that resolves script.Parent.<Name> tokens and already
--     loaded module tables from the registry, and a `script` table whose
--     Parent proxy and WaitForChild both read that registry.
--   * A tiny Test helper (check / need / runStart / finish) shared by the
--     test files.
--
-- Usage: test files start with require("./stub_env") to document the
-- dependency, but they are NOT run directly. The Luau CLI sandboxes every
-- required module in its own environment, so globals set by a required
-- stub are invisible to the modules under test. Instead tests/run.sh
-- assembles one combined chunk per test file (tests/build_combined.mjs):
-- this stub, then every module's source embedded as a string, then the
-- test file with its require line stripped. The combined chunk runs as
-- the main script, so one environment holds the stub globals, the
-- modules (loaded with loadstring, which sees the main chunk's globals),
-- and the test. The stub loads every server module in dependency order;
-- a module that fails to load is recorded in Test.loadErrors and
-- Test.need(name) reports it instead of crashing the whole file.

local registry = {}
local loadErrors = {}

-- ---------------------------------------------------------------- tick budget
local tickCount = 0
local TICK_BUDGET = 200

local function resetTicks()
	tickCount = 0
end

-- ------------------------------------------------------------ spawn queue
local spawnQueue = {}

local function queueFn(fn, args)
	table.insert(spawnQueue, { fn = fn, args = args })
end

task = {
	spawn = function(fn, ...)
		queueFn(fn, { ... })
	end,
	defer = function(fn, ...)
		queueFn(fn, { ... })
	end,
	delay = function(_seconds, fn, ...)
		queueFn(fn, { ... })
	end,
	wait = function(seconds)
		tickCount += 1
		if tickCount > TICK_BUDGET then
			error("stub: tick budget exceeded", 0)
		end
		return seconds or 0
	end,
	cancel = function(_thread) end,
}

-- ------------------------------------------------------------- value types
-- NOTE: these are GLOBALS, not locals. Modules are loaded with loadstring
-- into this chunk's environment, so they can only see globals; a local
-- here would be nil inside every module (Config's Color3.fromRGB, the
-- HUD's UDim2.new, and so on).
Vector3 = {}
local vectorMt = {}
vectorMt.__add = function(a, b)
	return Vector3.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
vectorMt.__sub = function(a, b)
	return Vector3.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
vectorMt.__mul = function(a, b)
	if type(a) == "number" then
		return Vector3.new(a * b.X, a * b.Y, a * b.Z)
	end
	if type(b) == "number" then
		return Vector3.new(a.X * b, a.Y * b, a.Z * b)
	end
	return Vector3.new(a.X * b.X, a.Y * b.Y, a.Z * b.Z)
end
vectorMt.__div = function(a, b)
	if type(b) == "number" then
		return Vector3.new(a.X / b, a.Y / b, a.Z / b)
	end
	return Vector3.new(a.X / b.X, a.Y / b.Y, a.Z / b.Z)
end
vectorMt.__unm = function(a)
	return Vector3.new(-a.X, -a.Y, -a.Z)
end
vectorMt.__eq = function(a, b)
	return a.X == b.X and a.Y == b.Y and a.Z == b.Z
end
vectorMt.__tostring = function(a)
	return ("Vector3(%g, %g, %g)"):format(a.X, a.Y, a.Z)
end
vectorMt.__index = function(t, k)
	if k == "Magnitude" then
		return math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
	end
	if k == "Unit" then
		local m = math.sqrt(t.X * t.X + t.Y * t.Y + t.Z * t.Z)
		if m == 0 then
			return Vector3.new(0, 0, 0)
		end
		return Vector3.new(t.X / m, t.Y / m, t.Z / m)
	end
	return rawget(t, k)
end

function Vector3.new(x, y, z)
	return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vectorMt)
end
Vector3.zero = Vector3.new(0, 0, 0)
Vector3.one = Vector3.new(1, 1, 1)
Vector3.yAxis = Vector3.new(0, 1, 0)
Vector3.xAxis = Vector3.new(1, 0, 0)
Vector3.zAxis = Vector3.new(0, 0, 1)

Vector2 = {}
function Vector2.new(x, y)
	return { X = x or 0, Y = y or 0 }
end

Color3 = {}
function Color3.new(r, g, b)
	return { R = r or 0, G = g or 0, B = b or 0 }
end
function Color3.fromRGB(r, g, b)
	return Color3.new((r or 0) / 255, (g or 0) / 255, (b or 0) / 255)
end
function Color3.fromHSV(h, s, v)
	-- Standard HSV conversion, good enough for a stub.
	local c = v * s
	local x = c * (1 - math.abs((h * 6) % 2 - 1))
	local m = v - c
	local r, g, b = 0, 0, 0
	local sector = math.floor(h * 6) % 6
	if sector == 0 then r, g, b = c, x, 0
	elseif sector == 1 then r, g, b = x, c, 0
	elseif sector == 2 then r, g, b = 0, c, x
	elseif sector == 3 then r, g, b = 0, x, c
	elseif sector == 4 then r, g, b = x, 0, c
	else r, g, b = c, 0, x end
	return Color3.new(r + m, g + m, b + m)
end

CFrame = {}
local cframeMt = {}
cframeMt.__mul = function(a, b)
	local ap = a.Position or Vector3.new(0, 0, 0)
	local bp = b.Position or Vector3.new(0, 0, 0)
	return CFrame.new(ap + bp)
end
cframeMt.__tostring = function(_a)
	return "CFrame"
end

function CFrame.new(x, y, z)
	local pos
	if type(x) == "table" and x.X ~= nil then
		pos = x
	elseif x == nil then
		pos = Vector3.new(0, 0, 0)
	else
		pos = Vector3.new(x or 0, y or 0, z or 0)
	end
	return setmetatable({ Position = pos, X = pos.X, Y = pos.Y, Z = pos.Z }, cframeMt)
end
function CFrame.Angles(_rx, _ry, _rz)
	return CFrame.new(0, 0, 0)
end
function CFrame.lookAt(pos, _target)
	return CFrame.new(pos)
end

UDim = {}
function UDim.new(scale, offset)
	return { Scale = scale or 0, Offset = offset or 0 }
end

UDim2 = {}
function UDim2.new(xScale, xOffset, yScale, yOffset)
	return { X = UDim.new(xScale, xOffset), Y = UDim.new(yScale, yOffset) }
end
function UDim2.fromScale(x, y)
	return UDim2.new(x, 0, y, 0)
end
function UDim2.fromOffset(x, y)
	return UDim2.new(0, x, 0, y)
end

Enum = setmetatable({}, {
	__index = function(_self, category)
		return setmetatable({}, {
			__index = function(_self2, item)
				return category .. "." .. item
			end,
		})
	end,
})

BrickColor = {}
function BrickColor.new(nameOrNumber)
	if type(nameOrNumber) == "string" then
		return { Name = nameOrNumber, Color = Color3.new(1, 1, 1) }
	end
	return { Name = "BrickColor", Color = Color3.new(1, 1, 1) }
end

tick = os.clock

warn = function(...)
	print("[warn]", ...)
end

-- ---------------------------------------------------------------- signals
local function makeSignal()
	local signal = { _handlers = {}, _isSignal = true }
	function signal:Connect(fn)
		table.insert(self._handlers, fn)
		return { Disconnect = function() end, Connected = true }
	end
	function signal:Once(fn)
		return self:Connect(fn)
	end
	function signal:Fire(...)
		for _, fn in ipairs(self._handlers) do
			fn(...)
		end
	end
	function signal:Wait()
		return nil
	end
	return signal
end

local SIGNAL_NAMES = {
	"Touched", "TouchEnded", "MouseClick", "MouseButton1Click",
	"MouseButton1Down", "Activated", "Changed", "ChildAdded",
	"ChildRemoved", "AncestryChanged", "OnClientEvent", "OnServerEvent",
	"PlayerAdded", "PlayerRemoving", "Heartbeat", "RenderStepped",
	"Stepped", "MouseEnter", "MouseLeave", "FocusLost", "TextChanged",
}

-- --------------------------------------------------------------- instances
local InstanceMethods = {}

function InstanceMethods:FindFirstChild(name)
	for _, child in ipairs(self.Children or {}) do
		if child.Name == name then
			return child
		end
	end
	return nil
end

function InstanceMethods:FindFirstChildOfClass(className)
	for _, child in ipairs(self.Children or {}) do
		if child.ClassName == className then
			return child
		end
	end
	return nil
end

function InstanceMethods:FindFirstChildWhichIsA(className)
	return self:FindFirstChildOfClass(className)
end

function InstanceMethods:GetChildren()
	return self.Children or {}
end

function InstanceMethods:GetDescendants()
	local out = {}
	local function walk(inst)
		for _, child in ipairs(inst.Children or {}) do
			table.insert(out, child)
			walk(child)
		end
	end
	walk(self)
	return out
end

function InstanceMethods:WaitForChild(name, _timeout)
	local found = self:FindFirstChild(name)
	if found then
		return found
	end
	-- Stub behaviour: a waited-for child appears on demand.
	local child = makeInstance("Folder")
	child.Name = name
	child.Parent = self
	return child
end

function InstanceMethods:Destroy()
	self.Parent = nil
	self._destroyed = true
end

function InstanceMethods:SetAttribute(name, value)
	self.Attributes = self.Attributes or {}
	self.Attributes[name] = value
end

function InstanceMethods:GetAttribute(name)
	return (self.Attributes or {})[name]
end

-- Roblox class hierarchy, so IsA("BasePart") is true for a Part and
-- IsA("GuiObject") is true for a TextLabel, as in the real engine.
local CLASS_PARENTS = {
	Part = "BasePart",
	MeshPart = "BasePart",
	UnionOperation = "BasePart",
	WedgePart = "BasePart",
	CornerWedgePart = "BasePart",
	SpawnLocation = "BasePart",
	Seat = "BasePart",
	VehicleSeat = "BasePart",
	BasePart = "PVInstance",
	Model = "PVInstance",
	Workspace = "Model",
	PVInstance = "Instance",
	TextLabel = "GuiObject",
	TextButton = "GuiObject",
	TextBox = "GuiObject",
	ImageLabel = "GuiObject",
	ImageButton = "GuiObject",
	Frame = "GuiObject",
	ScrollingFrame = "GuiObject",
	GuiObject = "Instance",
	ScreenGui = "LayerCollector",
	BillboardGui = "LayerCollector",
	SurfaceGui = "LayerCollector",
	LayerCollector = "Instance",
}

function InstanceMethods:IsA(className)
	local class = self.ClassName
	while class ~= nil do
		if class == className then
			return true
		end
		class = CLASS_PARENTS[class]
	end
	return false
end

function InstanceMethods:Clone()
	local copy = makeInstance(self.ClassName)
	for k, v in pairs(self) do
		if k ~= "Children" and k ~= "Parent" and k ~= "Attributes" then
			-- Signals are fresh on the clone; plain values and value
			-- types (Vector3/CFrame tables carry a metatable) are shared.
			if type(v) ~= "table" or getmetatable(v) ~= nil then
				copy[k] = v
			end
		end
	end
	for name, value in pairs(self.Attributes or {}) do
		copy:SetAttribute(name, value)
	end
	for _, child in ipairs(self.Children or {}) do
		local childCopy = child:Clone()
		childCopy.Parent = copy
	end
	return copy
end

function InstanceMethods:PivotTo(cf)
	self.CFrame = cf
	if cf ~= nil and cf.Position ~= nil then
		self.Position = cf.Position
	end
end

function InstanceMethods:SetPrimaryPartCFrame(cf)
	self:PivotTo(cf)
end

function InstanceMethods:GetPrimaryPartCFrame()
	return self:GetPivot()
end

function InstanceMethods:MoveTo(position)
	self:PivotTo(CFrame.new(position))
end

function InstanceMethods:GetPivot()
	if self.CFrame ~= nil then
		return self.CFrame
	end
	return CFrame.new(self.Position or Vector3.new(0, 0, 0))
end

function InstanceMethods:FireClient(_player, ...)
	self._firedClient = self._firedClient or {}
	table.insert(self._firedClient, { ... })
end

function InstanceMethods:FireAllClients(...)
	self._firedAll = self._firedAll or {}
	table.insert(self._firedAll, { ... })
end

function InstanceMethods:FireServer(...)
	self._firedServer = self._firedServer or {}
	table.insert(self._firedServer, { ... })
end

function InstanceMethods:InvokeServer(...)
	return nil
end

function InstanceMethods:InvokeClient(...)
	return nil
end

function InstanceMethods:GetMass()
	return 1
end

local function makeInstance(className)
	local inst = {
		ClassName = className,
		Name = className,
		Children = {},
		Attributes = {},
	}
	for _, signalName in ipairs(SIGNAL_NAMES) do
		inst[signalName] = makeSignal()
	end
	setmetatable(inst, {
		__index = function(t, k)
			local v = rawget(t, k)
			if v ~= nil then
				return v
			end
			return InstanceMethods[k]
		end,
		__newindex = function(t, k, v)
			if k == "Parent" then
				local old = rawget(t, "Parent")
				if old ~= nil and old.Children ~= nil then
					for i, c in ipairs(old.Children) do
						if c == t then
							table.remove(old.Children, i)
							break
						end
					end
				end
				rawset(t, "Parent", v)
				if v ~= nil then
					v.Children = v.Children or {}
					table.insert(v.Children, t)
				end
			else
				rawset(t, k, v)
			end
		end,
	})
	return inst
end

Instance = {}
function Instance.new(className, parent)
	local inst = makeInstance(className)
	if parent ~= nil then
		inst.Parent = parent
	end
	return inst
end

-- ------------------------------------------------------------------- game
local services = {}

local function makeService(name)
	local svc = makeInstance(name)
	svc.Name = name
	services[name] = svc
	return svc
end

local workspaceService = makeService("Workspace")
local lightingService = makeService("Lighting")
local playersService = makeService("Players")
local replicatedStorage = makeService("ReplicatedStorage")
local dataStoreService = makeService("DataStoreService")
local serverScriptService = makeService("ServerScriptService")
local serverStorage = makeService("ServerStorage")
local starterGui = makeService("StarterGui")
local runService = makeService("RunService")
local tweenService = makeService("TweenService")
local debrisService = makeService("Debris")
local httpService = makeService("HttpService")
local soundService = makeService("SoundService")

workspace = workspaceService

-- LocalPlayer with a PlayerGui, for the HUD test.
local localPlayer = makeInstance("Player")
localPlayer.Name = "TestPlayer"
localPlayer.UserId = 12345
localPlayer.DisplayName = "TestPlayer"
local playerGui = makeInstance("PlayerGui")
playerGui.Name = "PlayerGui"
playerGui.Parent = localPlayer
localPlayer.PlayerGui = playerGui

playersService.LocalPlayer = localPlayer
function playersService:GetPlayers()
	return { localPlayer }
end
function playersService:GetPlayerByUserId(userId)
	if userId == localPlayer.UserId then
		return localPlayer
	end
	return nil
end
function playersService:GetPlayerFromCharacter(_character)
	return nil
end

-- ReplicatedStorage: Config comes from the loaded registry; SnackEvents is
-- created on demand as a RemoteEvent; anything else appears as a Folder.
function replicatedStorage:WaitForChild(name, _timeout)
	if name == "Config" then
		return registry.Config
	end
	local found = InstanceMethods.FindFirstChild(self, name)
	if found then
		return found
	end
	local className = "Folder"
	if name == "SnackEvents" then
		className = "RemoteEvent"
	end
	local child = makeInstance(className)
	child.Name = name
	child.Parent = self
	return child
end

-- DataStores are unavailable in the stub, exactly like Studio offline:
-- Saves must see Store == nil and degrade gracefully.
function dataStoreService:GetDataStore(_name)
	error("DataStoreService unavailable in test stub", 0)
end
function dataStoreService:GetGlobalDataStore()
	error("DataStoreService unavailable in test stub", 0)
end

function runService:IsStudio()
	return true
end
function runService:IsServer()
	return true
end
function runService:IsClient()
	return false
end

function tweenService:Create(_instance, _tweenInfo, _properties)
	return {
		Play = function() end,
		Cancel = function() end,
		Pause = function() end,
		Destroy = function() end,
	}
end

function debrisService:AddItem(_item, _lifetime) end

function httpService:JSONEncode(value)
	if type(value) == "string" then
		return '"' .. value .. '"'
	elseif type(value) == "number" or type(value) == "boolean" then
		return tostring(value)
	elseif type(value) == "table" then
		local parts = {}
		for k, v in pairs(value) do
			table.insert(parts, '"' .. tostring(k) .. '":' .. httpService:JSONEncode(v))
		end
		return "{" .. table.concat(parts, ",") .. "}"
	end
	return "null"
end
function httpService:JSONDecode(_text)
	return {}
end

game = {
	PlaceId = 106001400572518,
	GameId = 10777536865,
	CreatorId = 0,
	CreatorType = "User",
	Workspace = workspaceService,
	Lighting = lightingService,
	Players = playersService,
	ReplicatedStorage = replicatedStorage,
	DataStoreService = dataStoreService,
	ServerScriptService = serverScriptService,
	ServerStorage = serverStorage,
	StarterGui = starterGui,
	RunService = runService,
	TweenService = tweenService,
	Debris = debrisService,
	HttpService = httpService,
	SoundService = soundService,
}

function game:GetService(name)
	if services[name] ~= nil then
		return services[name]
	end
	return makeService(name)
end

-- ------------------------------------------------------- script / require
script = {
	Name = "TestScript",
	Parent = setmetatable({}, {
		__index = function(_self, key)
			-- A token the stub `require` resolves against the registry.
			return { __moduleName = key }
		end,
	}),
}

function script:WaitForChild(name, _timeout)
	local entry = registry[name]
	if entry ~= nil then
		return entry
	end
	error("stub: script:WaitForChild(" .. tostring(name) .. ") not in registry", 0)
end

require = function(target)
	if type(target) == "table" then
		if target.__moduleName ~= nil then
			return registry[target.__moduleName]
		end
		-- Already a loaded module table (e.g. Config from ReplicatedStorage).
		return target
	elseif type(target) == "string" then
		return registry[target]
	end
	return target
end

-- ------------------------------------------------------------ test helper
Test = {
	passed = 0,
	failed = 0,
	loadErrors = loadErrors,
	registry = registry,
}

function Test.check(name, cond, extra)
	if cond then
		Test.passed += 1
		print("PASS: " .. name)
	else
		Test.failed += 1
		if extra ~= nil then
			print("FAIL: " .. name .. " — " .. tostring(extra))
		else
			print("FAIL: " .. name)
		end
	end
end

function Test.need(name)
	local module = registry[name]
	if module == nil then
		error("module '" .. name .. "' failed to load: " .. tostring(loadErrors[name]), 0)
	end
	return module
end

-- A mock Roblox Player instance: the object the server modules actually
-- pass around. Bases.createBase attaches .Base/.Slots/.SlotPositions to
-- it, and Economy/Steal/Rebirth read .UserId (and .Slots) off it. The
-- State player table is a different object — it holds Cash/Snacks, not
-- the base — so tests must not pass State tables where a Player is wanted.
function Test.mockPlayer(userId, name)
	local player = makeInstance("Player")
	player.Name = name or ("Player" .. tostring(userId))
	player.UserId = userId
	return player
end

-- Run a system's start() the way a test can tolerate: either it returns
-- (loop spawned or no loop), or it runs its loop inline until the tick
-- budget trips, which proves the loop started.
function Test.runStart(name, startFn)
	resetTicks()
	local ok, err = pcall(startFn)
	if ok then
		return true, nil
	end
	if tostring(err):find("tick budget exceeded") ~= nil then
		return true, "loop-budget"
	end
	return false, name .. " start() failed: " .. tostring(err)
end

-- Run queued task.spawn/task.delay functions, each under its own tick
-- budget. Returns a list of non-budget errors (empty means clean).
function Test.runSpawned(maxSteps)
	maxSteps = maxSteps or 50
	local errors = {}
	local steps = 0
	while #spawnQueue > 0 and steps < maxSteps do
		steps += 1
		local job = table.remove(spawnQueue, 1)
		resetTicks()
		local ok, err = pcall(job.fn, table.unpack(job.args))
		if not ok and tostring(err):find("tick budget exceeded") == nil then
			table.insert(errors, tostring(err))
		end
	end
	return errors
end

function Test.finish()
	print(("RESULT: passed=%d failed=%d"):format(Test.passed, Test.failed))
	if Test.failed > 0 then
		error(("RESULT: %d test(s) failed"):format(Test.failed), 0)
	end
end

-- ---------------------------------------------------------- module loading
-- Modules are loaded from source text with loadstring, so they execute in
-- this chunk's environment and see the stub globals (game, Instance,
-- Color3, task, script, require). SOURCES is embedded by the test runner
-- (tests/build_combined.mjs); each entry is one file's full source.
local function loadModuleSource(name, source)
	resetTicks()
	local fn, compileErr = loadstring(source, "@" .. name)
	if fn == nil then
		loadErrors[name] = "compile: " .. tostring(compileErr)
		print("LOAD-FAIL: " .. name .. ": compile: " .. tostring(compileErr))
		return false
	end
	local ok, result = pcall(fn)
	if ok then
		registry[name] = result
	else
		loadErrors[name] = tostring(result)
		print("LOAD-FAIL: " .. name .. ": " .. tostring(result))
	end
	return ok
end

-- Load one extra embedded source on demand (init.server, Hud.client).
-- Raises on failure; wrap in pcall when a failure is itself the test.
function Test.loadExtra(name)
	local source = SOURCES[name]
	if source == nil then
		error("no embedded source for " .. name, 0)
	end
	resetTicks()
	local fn, compileErr = loadstring(source, "@" .. name)
	if fn == nil then
		error("compile " .. name .. ": " .. tostring(compileErr), 0)
	end
	local ok, result = pcall(fn)
	if not ok then
		error("run " .. name .. ": " .. tostring(result), 0)
	end
	return result
end
