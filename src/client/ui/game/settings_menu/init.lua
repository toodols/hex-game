local ReplicatedStorage = game:GetService "ReplicatedStorage"

local React = require(ReplicatedStorage.Packages.react)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local Separator = util_components.Separator
local contexts = require(ReplicatedStorage.Client.ui.context)
local SettingsContext = contexts.SettingsContext
local Rebindable = require(script.rebindable).Rebindable

local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

function SettingsMenu()
	local player_settings = React.useContext(SettingsContext)

	local get_keybind_value = function(id: string, default: Enum.KeyCode): Enum.KeyCode
		local value = player_settings.keybinds[id]
		if value ~= nil then
			return (Enum.KeyCode :: any):FromValue(value)
		end
		return default or Enum.KeyCode.Unknown
	end

	local handle_keybind_change = function(id: string, new_key: Enum.KeyCode)
		if new_key == Enum.KeyCode.Unknown then
			player_settings.keybinds[id] = nil
		else
			player_settings.keybinds[id] = new_key.Value
		end
		client_interaction_remote:FireServer { {
			type = "update_settings",
			settings = player_settings,
		} }
	end

	return React.createElement("Frame", {
		Size = UDim2.new(1, -20, 1, -20),
		[React.Tag] = "align-cc background list-v",
	}, {
		SizeConstraint = React.createElement("UISizeConstraint", {
			MaxSize = Vector2.new(600, 600),
		}),
		Header = React.createElement("Frame", {
			LayoutOrder = 1,
			[React.Tag] = "header",
		}, {
			Title = React.createElement("TextLabel", {
				Text = "Settings",
				[React.Tag] = "title",
			}),
		}),
		Content = React.createElement("ScrollingFrame", {
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 1, -40),
			CanvasSize = UDim2.new(1, 0, 0, 0),
			[React.Tag] = "container-scroll-v list-v list-pad-2",
		}, {
			Header = React.createElement("TextLabel", {
				BackgroundTransparency = 0.5,
				Size = UDim2.new(0, 0, 0, 40),
				Text = "Keybinds",
				LayoutOrder = 1,
				[React.Tag] = "title pad-l-30 pad-r-30",
			}),
			Separator = React.createElement(Separator, {
				LayoutOrder = 2,
			}),
			Construct = React.createElement(Rebindable, {
				label = "Toggle Construct",
				LayoutOrder = 3,
				default = Enum.KeyCode.B,
				id = "construct",
				value = get_keybind_value("construct", Enum.KeyCode.B),
				on_changed = function(new_key)
					handle_keybind_change("construct", new_key)
				end,
			}),
			Skip = React.createElement(Rebindable, {
				label = "Skip Turn",
				LayoutOrder = 4,
				default = Enum.KeyCode.Y,
				id = "skip",
				value = get_keybind_value("skip", Enum.KeyCode.Y),
				on_changed = function(new_key)
					handle_keybind_change("skip", new_key)
				end,
			}),
			PrimaryAbility = React.createElement(Rebindable, {
				label = "Primary Ability",
				LayoutOrder = 5,
				default = Enum.KeyCode.Q,
				id = "primary_ability",
				value = get_keybind_value("primary_ability", Enum.KeyCode.Q),
				on_changed = function(new_key)
					handle_keybind_change("primary_ability", new_key)
				end,
			}),
			Research = React.createElement(Rebindable, {
				label = "Open Research",
				LayoutOrder = 6,
				default = Enum.KeyCode.R,
				id = "research",
				value = get_keybind_value("research", Enum.KeyCode.R),
				on_changed = function(new_key)
					handle_keybind_change("research", new_key)
				end,
			}),
			ShowPlayerList = React.createElement(Rebindable, {
				label = "Show Player List",
				LayoutOrder = 6,
				default = Enum.KeyCode.T,
				id = "show_player_list",
				value = get_keybind_value("show_player_list", Enum.KeyCode.T),
				on_changed = function(new_key)
					handle_keybind_change("show_player_list", new_key)
				end,
			}),
			Deconstruct = React.createElement(Rebindable, {
				label = "Deconstruct Selected",
				LayoutOrder = 7,
				default = Enum.KeyCode.X,
				id = "deconstruct",
				value = get_keybind_value("deconstruct", Enum.KeyCode.X),
				on_changed = function(new_key)
					handle_keybind_change("deconstruct", new_key)
				end,
			}),
			PreviousEntity = React.createElement(Rebindable, {
				label = "Previous Entity",
				LayoutOrder = 8,
				default = Enum.KeyCode.LeftBracket,
				id = "previous_entity",
				value = get_keybind_value("previous_entity", Enum.KeyCode.LeftBracket),
				on_changed = function(new_key)
					handle_keybind_change("previous_entity", new_key)
				end,
			}),
			NextEntity = React.createElement(Rebindable, {
				label = "Next Entity",
				LayoutOrder = 9,
				default = Enum.KeyCode.RightBracket,
				id = "next_entity",
				value = get_keybind_value("next_entity", Enum.KeyCode.RightBracket),
				on_changed = function(new_key)
					handle_keybind_change("next_entity", new_key)
				end,
			}),
		}),
	})
end

return {
	SettingsMenu = SettingsMenu,
}
