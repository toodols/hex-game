local ReplicatedStorage = game:GetService "ReplicatedStorage"
local UserInputService = game:GetService "UserInputService"

local types = require(ReplicatedStorage.Shared.types)
local React = require(ReplicatedStorage.Packages.react)
local themes = require(ReplicatedStorage.Client.ui.themes)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local Separator = util_components.Separator
local Corner = util_components.Corner
local contexts = require(ReplicatedStorage.Client.ui.context)
local MainContext = contexts.MainContext
local SettingsContext = contexts.SettingsContext

local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type KeybindId = types.KeybindId
type PlayerSettings = types.PlayerSettings

function Rebindable(props: {
	id: KeybindId,
	label: string?,
	LayoutOrder: number?,
	default: Enum.KeyCode?,
})
	local player_settings: PlayerSettings = React.useContext(SettingsContext)
	local value = if player_settings.keybinds[props.id] ~= nil
		then (Enum.KeyCode :: any):FromValue(player_settings.keybinds[props.id])
		else nil

	local input_ref = React.useRef(nil)
	local connection_ref = React.useRef(nil)
	local key, set_key_ = React.useState(value or props.default or Enum.KeyCode.Unknown)
	local button_ref = React.useRef(nil)

	local set_key = function(new_key)
		if new_key == Enum.KeyCode.Unknown then
			player_settings.keybinds[props.id] = nil
		else
			player_settings.keybinds[props.id] = new_key.Value
		end
		client_interaction_remote:FireServer { {
			type = "update_settings",
			settings = player_settings,
		} }
		set_key_(new_key)
	end

	return React.createElement("Frame", {
		LayoutOrder = props.LayoutOrder,
		BackgroundTransparency = 0.7,
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	}, {
		Left = React.createElement("TextLabel", {
			Size = UDim2.new(0, 200, 0, 30),
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			Text = props.label,
			LayoutOrder = 1,
		}),
		Right = React.createElement("TextButton", {
			Text = if key == Enum.KeyCode.Unknown then "None" else UserInputService:GetStringForKeyCode(key),
			Position = UDim2.new(1, -10, 0, 0),
			Size = UDim2.new(0, 60, 0, 30),
			[React.Tag] = "solid align-tr bg-3",
			LayoutOrder = 2,
			ref = button_ref,
			[React.Event.MouseButton1Click] = function(button)
				input_ref.current:CaptureFocus()
				button.Text = "..."
			end,
		}, {
			SneakyInput = React.createElement("TextBox", {
				TextScaled = true,
				Visible = false,
				ref = input_ref,
				[React.Event.Focused] = function(box)
					if connection_ref.current then
						connection_ref.current:Disconnect()
					end
					connection_ref.current = UserInputService.InputBegan:Connect(function(input, gameProcessed)
						if input.UserInputType == Enum.UserInputType.Keyboard then
							if input.KeyCode == Enum.KeyCode.Escape then
								set_key(Enum.KeyCode.Unknown)
								box:ReleaseFocus()
								return
							end

							set_key(input.KeyCode)
							box:ReleaseFocus()
						end
					end)
				end,
				[React.Event.FocusLost] = function(enter_pressed)
					button_ref.current.Text = if key == Enum.KeyCode.Unknown
						then "None"
						else UserInputService:GetStringForKeyCode(key)
					connection_ref.current:Disconnect()
				end,
			}),
			Corner = React.createElement(Corner),
		}),
	})
end

function SettingsMenu()
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
			}),
			Skip = React.createElement(Rebindable, {
				label = "Skip Turn",
				LayoutOrder = 4,
				default = Enum.KeyCode.Y,
				id = "skip",
			}),
			PrimaryAbility = React.createElement(Rebindable, {
				label = "Primary Ability",
				LayoutOrder = 5,
				default = Enum.KeyCode.Q,
				id = "primary_ability",
			}),
			Research = React.createElement(Rebindable, {
				label = "Open Research",
				LayoutOrder = 6,
				default = Enum.KeyCode.R,
				id = "research",
			}),
			ShowPlayerList = React.createElement(Rebindable, {
				label = "Show Player List",
				LayoutOrder = 6,
				default = Enum.KeyCode.T,
				id = "show_player_list",
			}),
			Deconstruct = React.createElement(Rebindable, {
				label = "Deconstruct Selected",
				LayoutOrder = 7,
				default = Enum.KeyCode.X,
				id = "deconstruct",
			}),
			PreviousEntity = React.createElement(Rebindable, {
				label = "Previous Entity",
				LayoutOrder = 8,
				default = Enum.KeyCode.LeftBracket,
				id = "previous_entity",
			}),
			NextEntity = React.createElement(Rebindable, {
				label = "Next Entity",
				LayoutOrder = 9,
				default = Enum.KeyCode.RightBracket,
				id = "next_entity",
			}),
		}),
	})
end

return {
	SettingsMenu = SettingsMenu,
}
