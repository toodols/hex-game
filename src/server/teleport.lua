local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TeleportService = game:GetService "TeleportService"

local remotes = require(script.Parent.remotes)
local teleport_remote = remotes.teleport_remote
local placeids = require(ReplicatedStorage.Shared.placeids)

teleport_remote.OnServerEvent:Connect(function(player, data)
	if data == "lobby" then
		local success, err = pcall(TeleportService.Teleport, TeleportService, placeids.lobby, player)
		if not success then
			warn(`Failed to teleport {player.Name} to the lobby:`, err)
		end
	end
end)

return {}
