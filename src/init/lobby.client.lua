-- lobby.client.lua

local ReplicatedStorage = game:GetService "ReplicatedStorage"
local init_lobby_ui = require(ReplicatedStorage.Client.ui.lobby).init_ui

init_lobby_ui()
