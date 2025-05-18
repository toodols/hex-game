local ReplicatedStorage = game:GetService "ReplicatedStorage"
local UserInputService = game:GetService "UserInputService"

local React = require(ReplicatedStorage.Packages.react)
local themes = require(ReplicatedStorage.Client.ui.themes)
local Corner = require(ReplicatedStorage.Client.ui.util_components).Corner
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext

function Rebindable(props: {
	id: string,
	label: string?,
	LayoutOrder: number?,
	default: Enum.KeyCode?,
})
	local context = React.useContext(MainContext)
	local input_ref = React.useRef(nil)
	local connection_ref = React.useRef(nil)
	local key, set_key = React.useState(props.default or Enum.KeyCode.Unknown)
	local button_ref = React.useRef(nil)
	return React.createElement("Frame", {
		LayoutOrder = props.LayoutOrder,
		BackgroundTransparency = 0.7,
		Size = UDim2.new(1, 0, 0, 30),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
	}, {
		Left = React.createElement(
			"TextLabel",
			themes.theme_label {
				Size = UDim2.new(0, 200, 0, 30),
				BackgroundTransparency = 1,
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				Text = props.label,
				LayoutOrder = 1,
			}
		),
		Right = React.createElement(
			"TextButton",
			themes.theme_button {
				Text = if key == Enum.KeyCode.Unknown then "None" else UserInputService:GetStringForKeyCode(key),
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.new(1, -10, 0, 0),
				Size = UDim2.new(0, 60, 0, 30),
				BackgroundTransparency = 0.5,
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				TextSize = 16,
				LayoutOrder = 2,
				ref = button_ref,
				[React.Event.MouseButton1Click] = function(button)
					input_ref.current:CaptureFocus()
					button.Text = "..."
				end,
			},
			{
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
			}
		),
	})
end

function SettingsMenu()
	local context = React.useContext(MainContext)
	local world = context.world
	return React.createElement(
		"Frame",
		themes.theme_background {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, -20, 1, -20),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.new(0.5, 0, 0.5, 0),
		},
		{
			Corner = React.createElement(Corner),
			SizeConstraint = React.createElement("UISizeConstraint", {
				MaxSize = Vector2.new(600, 600),
			}),
			VerticalLayout = React.createElement("UIListLayout", {
				Padding = UDim.new(0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			Header = React.createElement(
				"Frame",
				themes.theme_solid {
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 0, 40),
				},
				{
					Corner = React.createElement(Corner),
					Title = React.createElement(
						"TextLabel",
						themes.theme_title {
							Size = UDim2.new(0, 0, 1, 0),
							Text = "Settings",
						},
						{
							SidePad = React.createElement("UIPadding", {
								PaddingLeft = UDim.new(0, 10),
							}),
						}
					),
				}
			),
			Content = React.createElement("ScrollingFrame", {
				LayoutOrder = 2,
				Size = UDim2.new(1, 0, 1, -40),
				CanvasSize = UDim2.new(1, 0, 0, 0),
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
			}, {
				VerticalLayout = React.createElement("UIListLayout", {
					Padding = UDim.new(0, 4),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Header = React.createElement(
					"TextLabel",
					themes.theme_title {
						Size = UDim2.new(0, 0, 0, 40),
						Text = "Keybinds",
						LayoutOrder = 2,
					},
					{
						LeftPad = React.createElement("UIPadding", {
							PaddingLeft = UDim.new(0, 10),
						}),
					}
				),
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
		}
	)
end

return {
	SettingsMenu = SettingsMenu,
}
