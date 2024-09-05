local ReplicatedStorage = game:GetService "ReplicatedStorage"
local load = require(ReplicatedStorage.Shared.asset_server).load

local cell_names = {
	basic = "Basic",
	bar_deposit = "Bar Deposit",
	vit_deposit = "Vit Deposit",
	rad_deposit = "Rad Deposit",
	tar_deposit = "Tar Deposit",
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
