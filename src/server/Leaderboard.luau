-- Leaderboard.luau
-- Richest-players ranking, refreshed on a timer.
-- Written fresh for Steal a Snack v3 from the design spec.

local State = require(script.Parent.State)

local Leaderboard = {}

Leaderboard.CachedRichest = {}

function Leaderboard.getRichest(n)
	n = n or 10
	local all = {}
	for _, player in pairs(State.Players) do
		table.insert(all, {
			UserId = player.UserId,
			Cash = player.Cash or 0,
			Name = player.Name or tostring(player.UserId),
		})
	end
	table.sort(all, function(a, b)
		return a.Cash > b.Cash
	end)
	local top = {}
	for i = 1, math.min(n, #all) do
		table.insert(top, all[i])
	end
	return top
end

function Leaderboard.start()
	task.spawn(function()
		while true do
			task.wait(10)
			Leaderboard.CachedRichest = Leaderboard.getRichest(10)
			local lines = {}
			for i = 1, math.min(3, #Leaderboard.CachedRichest) do
				local entry = Leaderboard.CachedRichest[i]
				table.insert(lines, string.format(
					"#%d %s ($%d)", i, entry.Name, entry.Cash
				))
			end
			if #lines > 0 then
				print("[Leaderboard] Top 3: " .. table.concat(lines, " | "))
			else
				print("[Leaderboard] No players yet.")
			end
		end
	end)
end

return Leaderboard
