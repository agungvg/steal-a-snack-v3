-- Weather.luau
-- Cycles the sky Clear -> Rain -> Storm -> Clear on a timer, retinting
-- Lighting to match each phase and recording the phase in State.
-- Lighting access is guarded with pcall so unit tests (no real Lighting
-- effects to change) never crash on a weather change.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Config = require(ReplicatedStorage:WaitForChild("Config"))

local State = require(script.Parent.State)

local Weather = {}

local CYCLE = { "Clear", "Rain", "Storm" }

-- Lighting look per phase.
local LIGHTING = {
	Clear = {
		Brightness = 2,
		ClockTime = 14,
		FogEnd = 100000,
		Ambient = Color3.fromRGB(178, 178, 178),
	},
	Rain = {
		Brightness = 1,
		ClockTime = 15,
		FogEnd = 600,
		Ambient = Color3.fromRGB(110, 110, 125),
	},
	Storm = {
		Brightness = 0.4,
		ClockTime = 17,
		FogEnd = 250,
		Ambient = Color3.fromRGB(60, 60, 80),
	},
}

local currentIndex = 1
local running = false

local function applyLighting(phase: string)
	local settings = LIGHTING[phase]
	if settings == nil then
		return
	end
	pcall(function()
		local lighting = game:GetService("Lighting")
		lighting.Brightness = settings.Brightness
		lighting.ClockTime = settings.ClockTime
		lighting.FogEnd = settings.FogEnd
		lighting.Ambient = settings.Ambient
	end)
end

local function advance()
	currentIndex = currentIndex % #CYCLE + 1
	local phase = CYCLE[currentIndex]
	State.CurrentWeather = phase
	applyLighting(phase)
	print("[Weather] Now " .. phase)
	return phase
end

-- Starts the weather timer loop. Safe to call once; a second call is a no-op.
function Weather.start()
	if running then
		return
	end
	running = true
	-- Apply the starting phase immediately so the sky matches State.
	State.CurrentWeather = CYCLE[currentIndex]
	applyLighting(CYCLE[currentIndex])
	task.spawn(function()
		-- Guard the interval so a misconfigured Config can never spin
		-- the loop with a zero / negative wait.
		local interval = Config.WeatherCycleSeconds
		if type(interval) ~= "number" or interval <= 0 then
			interval = 120
		end
		while running do
			task.wait(interval)
			advance()
		end
	end)
end

function Weather.getCurrent(): string
	return State.CurrentWeather
end

return Weather
