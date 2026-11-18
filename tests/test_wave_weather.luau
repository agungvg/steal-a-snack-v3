require("./stub_env")

local Wave = Test.need("Wave")
local Weather = Test.need("Weather")

local function positiveNumbers(weights)
	local count = 0
	local sum = 0
	for _key, value in pairs(weights) do
		if type(value) == "number" then
			sum += value
			if value > 0 then
				count += 1
			end
		end
	end
	return count, sum
end

Test.check("wave starts at 1", Wave.getWave() == 1, "got " .. tostring(Wave.getWave()))

local weights = Wave.getRarityWeights()
Test.check("rarity weights is a table", type(weights) == "table")
local weightCount, weightSum = positiveNumbers(weights)
Test.check("rarity weights have positive entries", weightCount >= 1, "positive: " .. tostring(weightCount))
Test.check("rarity weights sum above zero", weightSum > 0, "sum: " .. tostring(weightSum))

local waveStarted, waveErr = Test.runStart("Wave", Wave.start)
Test.check("Wave.start runs", waveStarted, waveErr)
Test.check("wave number never goes backwards", Wave.getWave() >= 1)
local weightsAfter = Wave.getRarityWeights()
local countAfter, sumAfter = positiveNumbers(weightsAfter)
Test.check("weights stay valid after start", type(weightsAfter) == "table" and sumAfter > 0 and countAfter >= 1)

Test.check("weather starts Clear", Weather.getCurrent() == "Clear", "got " .. tostring(Weather.getCurrent()))

local weatherStarted, weatherErr = Test.runStart("Weather", Weather.start)
Test.check("Weather.start runs", weatherStarted, weatherErr)
Test.check("weather is still a named condition", type(Weather.getCurrent()) == "string", "got " .. tostring(Weather.getCurrent()))

local spawnErrors = Test.runSpawned()
Test.check("spawned wave/weather jobs are clean", #spawnErrors == 0, table.concat(spawnErrors, "; "))

Test.finish()
