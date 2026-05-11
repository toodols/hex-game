local ReplicatedStorage = game:GetService "ReplicatedStorage"
local types = require(ReplicatedStorage.Shared.types)
local default_settings = require(ReplicatedStorage.Shared.settings).default_settings

type PlayerSettings = types.PlayerSettings
function get_keybind(player_settings: PlayerSettings, keybind_id): Enum.KeyCode
	return player_settings.keybinds[keybind_id] or default_settings.keybinds[keybind_id] or Enum.KeyCode.Unknown
end

return {
	get_keybind = get_keybind,
}
