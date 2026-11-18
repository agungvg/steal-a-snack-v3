-- Effects.luau
-- Short-lived visual feedback for buys and steals.
-- Written fresh for Steal a Snack v3 from the design spec.

local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local Effects = {}

local function burst(position, color, count)
	local ok, err = pcall(function()
		local anchor = Instance.new("Part")
		anchor.Name = "EffectAnchor"
		anchor.Size = Vector3.new(0.5, 0.5, 0.5)
		anchor.Position = position
		anchor.Color = color
		anchor.Material = Enum.Material.Neon
		anchor.Anchored = true
		anchor.CanCollide = false
		anchor.Transparency = 0.4
		anchor.Parent = Workspace

		local emitter = Instance.new("ParticleEmitter")
		emitter.Color = ColorSequence.new(color)
		emitter.Size = NumberSequence.new(0.8)
		emitter.Rate = 0
		emitter.Lifetime = NumberRange.new(0.5, 1)
		emitter.Speed = NumberRange.new(6, 12)
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Parent = anchor
		emitter:Emit(count)

		Debris:AddItem(anchor, 2)
	end)
	if not ok then
		warn("[Effects] burst failed: " .. tostring(err))
	end
end

function Effects.playBuyEffect(position)
	if typeof(position) ~= "Vector3" then
		return
	end
	burst(position, Color3.fromRGB(255, 210, 60), 24)
end

function Effects.playStealEffect(position)
	if typeof(position) ~= "Vector3" then
		return
	end
	burst(position, Color3.fromRGB(255, 60, 90), 32)
end

return Effects
