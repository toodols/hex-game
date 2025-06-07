local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TeleportService = game:GetService "TeleportService"

local remotes = require(script.Parent.remotes)
local teleport_remote = remotes.teleport_remote
local placeids = require(ReplicatedStorage.Shared.placeids)

teleport_remote.OnServerEvent:Connect(function(player, data)
	if data == "lobby" then
		TeleportService:Teleport(placeids.lobby, player)
	end
end)

return {}
