local ReplicatedStorage = game:GetService "ReplicatedStorage"

local settings = require(ReplicatedStorage.Client.settings)
local React = require(ReplicatedStorage.Packages.react)

local util_components = require(ReplicatedStorage.Client.ui.util_components)
local contexts = require(ReplicatedStorage.Client.ui.context)

local default_settings = require(ReplicatedStorage.Shared.settings).default_settings

local Rebindable = require(script.rebindable).Rebindable

local Separator = util_components.Separator
local SettingsContext = contexts.SettingsContext

local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

function SettingsMenu()
	local player_settings = React.useContext(SettingsContext)

	local handle_keybind_change = function(id: string, new_key: Enum.KeyCode)
		if new_key == Enum.KeyCode.Unknown then
			player_settings.keybinds[id] = nil
		else
			player_settings.keybinds[id] = new_key
		end
		-- client tells server the updated settings and server triggers updates for Main with the new settings
		-- so the duration when keybinds are updated to when they are actually bound by the ui is the player's ping
		-- i could have client -> self but it would cause double rendering which is redundant
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
				default = default_settings.keybinds.construct,
				id = "construct",
				value = settings.get_keybind(player_settings, "construct"),
				on_changed = function(new_key)
					handle_keybind_change("construct", new_key)
				end,
			}),
			Skip = React.createElement(Rebindable, {
				label = "Skip Turn",
				LayoutOrder = 4,
				id = "skip",
				default = default_settings.keybinds.skip,
				value = settings.get_keybind(player_settings, "skip"),
				on_changed = function(new_key)
					handle_keybind_change("skip", new_key)
				end,
			}),
			PrimaryAbility = React.createElement(Rebindable, {
				label = "Primary Ability",
				LayoutOrder = 5,
				id = "primary_ability",
				default = default_settings.keybinds.primary_ability,
				value = settings.get_keybind(player_settings, "primary_ability"),
				on_changed = function(new_key)
					handle_keybind_change("primary_ability", new_key)
				end,
			}),
			Research = React.createElement(Rebindable, {
				label = "Open Research",
				LayoutOrder = 6,
				id = "research",
				default = default_settings.keybinds.research,
				value = settings.get_keybind(player_settings, "research"),
				on_changed = function(new_key)
					handle_keybind_change("research", new_key)
				end,
			}),
			ShowPlayerList = React.createElement(Rebindable, {
				label = "Show Player List",
				LayoutOrder = 6,
				id = "show_player_list",
				default = default_settings.keybinds.show_player_list,
				value = settings.get_keybind(player_settings, "show_player_list"),
				on_changed = function(new_key)
					handle_keybind_change("show_player_list", new_key)
				end,
			}),
			Deconstruct = React.createElement(Rebindable, {
				label = "Deconstruct Selected",
				LayoutOrder = 7,
				id = "deconstruct",
				default = default_settings.keybinds.deconstruct,
				value = settings.get_keybind(player_settings, "deconstruct"),
				on_changed = function(new_key)
					handle_keybind_change("deconstruct", new_key)
				end,
			}),
			PreviousEntity = React.createElement(Rebindable, {
				label = "Previous Entity",
				LayoutOrder = 8,
				id = "previous_entity",
				default = default_settings.keybinds.previous_entity,
				value = settings.get_keybind(player_settings, "previous_entity"),
				on_changed = function(new_key)
					handle_keybind_change("previous_entity", new_key)
				end,
			}),
			NextEntity = React.createElement(Rebindable, {
				label = "Next Entity",
				LayoutOrder = 9,
				id = "next_entity",
				default = default_settings.keybinds.next_entity,
				value = settings.get_keybind(player_settings, "next_entity"),
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
