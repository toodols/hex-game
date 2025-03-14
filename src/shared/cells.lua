local ReplicatedStorage = game:GetService "ReplicatedStorage"
local load = require(ReplicatedStorage.Shared.asset_server).load
local font = require(ReplicatedStorage.Shared.formatting.methods).font
local item_colors = require(ReplicatedStorage.Shared.items).item_colors

local cell_names = {
	basic = "Basic",
	bar_deposit = `{font("Bar", {color=item_colors.bar})} Deposit`,
	vit_deposit = `{font("Vit", {color=item_colors.vit})} Deposit`,
	rad_deposit = `{font("Rad", {color=item_colors.rad})} Deposit`,
	tar_deposit = `{font("Tar", {color=item_colors.tar})} Deposit`,
	portal = "Portal",
}

local cell_models = {
	basic = load "Tiles/Basic",
	bar_deposit = load "Tiles/BarDeposit",
	vit_deposit = load "Tiles/VitDeposit",
	tar_deposit = load "Tiles/TarDeposit",
	rad_deposit = load "Tiles/RadDeposit",
	portal = load "Tiles/Portal",
}

return { cell_models = cell_models, cell_names = cell_names }
