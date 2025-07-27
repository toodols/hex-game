local ReplicatedStorage = game:GetService "ReplicatedStorage"
local load = require(ReplicatedStorage.Shared.asset_server).load
local font = require(ReplicatedStorage.Shared.util).font
local item_colors = require(ReplicatedStorage.Shared.items).item_colors

local cell_names = {
	basic = "Basic",
	portal = "Portal",
}

local cell_models = {
	basic = load "Tiles/Basic",
	portal = load "Tiles/Portal",
}

return { cell_models = cell_models, cell_names = cell_names }
