-- Steal a Snack — client HUD.
-- Builds every interface element in code (no prebuilt assets) and updates
-- it from the "SnackEvents" RemoteEvent the server fires.
--
-- Messages the HUD understands:
--   { Type = "Cash", Cash = 250, Income = 12, Snacks = 3 }
--   { Type = "Weather", Weather = "Rain" }            (or Text)
--   { Type = "Leaderboard", Lines = { "1. Alice — $500", ... } }
--   { Type = "Feedback", Text = "Snack bought!" }
--   "a plain string"                                  (shown as feedback)

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage:WaitForChild("Config"))

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SnackHud"
screenGui.ResetOnSpawn = false
screenGui.Parent = playerGui

local function makeLabel(parent, name, text, size, position, textSize, color)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Text = text
	label.Size = size
	label.Position = position
	label.BackgroundTransparency = 1
	label.TextColor3 = color or Color3.fromRGB(255, 255, 255)
	label.TextSize = textSize or 18
	label.Font = Enum.Font.GothamBold
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function makePanel(parent, name, size, position)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Size = size
	frame.Position = position
	frame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	frame.BackgroundTransparency = 0.35
	frame.BorderSizePixel = 0
	frame.Parent = parent
	return frame
end

-- Cash panel, top-right: kept clear of the top-left Roblox menu buttons.
local cashPanel = makePanel(
	screenGui,
	"CashPanel",
	UDim2.new(0, 230, 0, 96),
	UDim2.new(1, -242, 0, 12)
)
local cashLabel = makeLabel(
	cashPanel,
	"CashLabel",
	"Cash: $" .. tostring(Config.StartingCash),
	UDim2.new(1, -16, 0, 30),
	UDim2.new(0, 8, 0, 6),
	22,
	Color3.fromRGB(255, 210, 60)
)
local incomeLabel = makeLabel(
	cashPanel,
	"IncomeLabel",
	"+$0 / sec",
	UDim2.new(1, -16, 0, 24),
	UDim2.new(0, 8, 0, 36),
	16,
	Color3.fromRGB(120, 255, 140)
)
local snacksLabel = makeLabel(
	cashPanel,
	"SnacksLabel",
	"Snacks: 0 / " .. tostring(Config.BaseSlots),
	UDim2.new(1, -16, 0, 24),
	UDim2.new(0, 8, 0, 62),
	16
)

-- Weather, top-centre.
local weatherLabel = makeLabel(
	screenGui,
	"WeatherLabel",
	"Weather: Clear",
	UDim2.new(0, 260, 0, 30),
	UDim2.new(0.5, -130, 0, 12),
	18
)
weatherLabel.TextXAlignment = Enum.TextXAlignment.Center

-- Leaderboard, left side below the Roblox menu buttons.
local boardPanel = makePanel(
	screenGui,
	"LeaderboardPanel",
	UDim2.new(0, 230, 0, 170),
	UDim2.new(0, 12, 0, 120)
)
makeLabel(
	boardPanel,
	"LeaderboardTitle",
	"Richest Players",
	UDim2.new(1, -16, 0, 26),
	UDim2.new(0, 8, 0, 6),
	18,
	Color3.fromRGB(255, 210, 60)
)
local leaderboardLabel = makeLabel(
	boardPanel,
	"LeaderboardLabel",
	"No players yet",
	UDim2.new(1, -16, 1, -40),
	UDim2.new(0, 8, 0, 34),
	15
)
leaderboardLabel.TextYAlignment = Enum.TextYAlignment.Top

-- Feedback, bottom-centre.
local feedbackLabel = makeLabel(
	screenGui,
	"FeedbackLabel",
	"",
	UDim2.new(0, 520, 0, 30),
	UDim2.new(0.5, -260, 1, -48),
	18
)
feedbackLabel.TextXAlignment = Enum.TextXAlignment.Center

local function showFeedback(text)
	local shown = tostring(text)
	feedbackLabel.Text = shown
	-- Feedback is gold so it stands out from the white HUD text.
	feedbackLabel.TextColor3 = Color3.fromRGB(255, 210, 60)
	-- Clear it again after a few seconds, but only if nothing newer
	-- has replaced it in the meantime.
	task.delay(4, function()
		if feedbackLabel.Text == shown then
			feedbackLabel.Text = ""
		end
	end)
end

local function onEvent(message)
	if typeof(message) == "string" then
		showFeedback(message)
		return
	end
	if typeof(message) ~= "table" then
		return
	end

	local kind = message.Type or message.Kind
	if kind == "Cash" then
		if message.Cash ~= nil then
			cashLabel.Text = "Cash: $" .. tostring(message.Cash)
		end
		if message.Income ~= nil then
			incomeLabel.Text = "+$" .. tostring(message.Income) .. " / sec"
		end
		if message.Snacks ~= nil then
			snacksLabel.Text = "Snacks: " .. tostring(message.Snacks) .. " / " .. tostring(Config.BaseSlots)
		end
	elseif kind == "Weather" then
		local weather = message.Weather or message.Text
		if weather ~= nil then
			weatherLabel.Text = "Weather: " .. tostring(weather)
		end
	elseif kind == "Leaderboard" then
		local lines = message.Lines or message.Players
		if typeof(lines) == "table" then
			local parts = {}
			for _, line in ipairs(lines) do
				table.insert(parts, tostring(line))
			end
			leaderboardLabel.Text = table.concat(parts, "\n")
		elseif message.Text ~= nil then
			leaderboardLabel.Text = tostring(message.Text)
		end
	elseif kind == "Feedback" then
		if message.Text ~= nil then
			showFeedback(message.Text)
		end
	elseif kind == "Snacks" then
		if message.Count ~= nil then
			snacksLabel.Text = "Snacks: " .. tostring(message.Count) .. " / " .. tostring(Config.BaseSlots)
		end
	end
end

local snackEvents = ReplicatedStorage:WaitForChild("SnackEvents")
snackEvents.OnClientEvent:Connect(onEvent)
