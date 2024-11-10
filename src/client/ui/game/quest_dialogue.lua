local ReplicatedStorage = game:GetService "ReplicatedStorage"

local React = require(ReplicatedStorage.Packages.react)
local types = require(ReplicatedStorage.Shared.types)
local util = require(ReplicatedStorage.Shared.util)
local format_text = require(ReplicatedStorage.Shared.formatting).format_text
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local hooks = require(ReplicatedStorage.Client.ui.hooks)
local themes = require(ReplicatedStorage.Client.ui.themes)
local Corner = util_components.Corner

local client_interaction_remote = ReplicatedStorage:FindFirstChild "ClientInteractionRemote" :: RemoteEvent

type Quest = types.Quest

function QuestDialogue(props: {
	quest: Quest,
})
	local grid = React.useContext(MainContext).grid
	local message_num, set_message_num = React.useState(1)
	local current_stage_data = props.quest.current_stage_data
	return React.createElement(
		"TextButton",
		{
			BackgroundColor3 = Color3.fromRGB(13, 13, 13),
			BackgroundTransparency = 0.4,
			Text = "",
			BorderSizePixel = 0,
			AutoButtonColor = false,
			LayoutOrder = 1,
			Size = UDim2.new(0, 600, 0, 80),
			[React.Event.MouseButton1Click] = function()
				if message_num < #current_stage_data.messages then
					set_message_num(message_num + 1)
				elseif current_stage_data.can_advance then
					client_interaction_remote:FireServer {
						{
							type = "quest_advance",
							quest_id = props.quest.id,
						},
					}
				end
			end,
		},
		{
			Title = React.createElement("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/Oswald.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.new(0, 0, 0, 5),
				RichText = true,
				Size = UDim2.new(1, 0, 0, 25),
				Text = `{props.quest.title}`,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 18,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, {
				PaddingLeft = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
				}),
			}),
			Description = React.createElement("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/Michroma.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				LayoutOrder = 2,
				Position = UDim2.new(0, 0, 0, 30),
				RichText = true,
				Size = UDim2.new(1, 0, 0, 0),
				Text = format_text(grid, current_stage_data.messages[message_num], {
					this_quest = props.quest,
				}),
				TextColor3 = Color3.fromRGB(200, 200, 200),
				TextSize = 13,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, {
				PaddingLeft = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
				}),
			}),
			ContinueLabel = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(1, 1),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/Michroma.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				LayoutOrder = 2,
				Position = UDim2.new(1, -5, 1, -5),
				Size = UDim2.new(1, 0, 0, 0),
				Text = "Click to Continue",
				Visible = current_stage_data.can_advance or message_num < #current_stage_data.messages,
				TextColor3 = Color3.fromRGB(130, 130, 130),
				TextSize = 13,
				TextWrapped = true,
				TextXAlignment = Enum.TextXAlignment.Right,
			}, {
				PaddingLeft = React.createElement("UIPadding", {
					PaddingLeft = UDim.new(0, 10),
				}),
			}),
			Corner = React.createElement(Corner),
		},
		if current_stage_data.choices and message_num == #current_stage_data.messages
			then {
				Choices = React.createElement(
					"Frame",
					{
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 40),
						Position = UDim2.new(0, 0, 1, 0),
					},
					{
						HorizontalLayout = React.createElement("UIListLayout", {
							FillDirection = Enum.FillDirection.Horizontal,
							VerticalAlignment = Enum.VerticalAlignment.Center,
							HorizontalAlignment = Enum.HorizontalAlignment.Right,
							Padding = UDim.new(0, 5),
						}),
					},
					util.table_map(current_stage_data.choices, function(choice)
						return React.createElement(
							"TextButton",
							themes.theme_button {
								BackgroundTransparency = 0.8,
								BackgroundColor3 = Color3.fromRGB(0, 0, 0),
								Text = choice.text,
								Size = UDim2.new(0, 0, 0, 30),
								[React.Event.MouseButton1Click] = function()
									client_interaction_remote:FireServer {
										{
											type = "quest_select_choice",
											quest_id = props.quest.id,
											current_stage = props.quest.current_stage,
											choice_id = choice.id,
										},
									}
								end,
							},
							{
								Padding = React.createElement("UIPadding", {
									PaddingLeft = UDim.new(0, 5),
									PaddingRight = UDim.new(0, 5),
								}),
								Corner = React.createElement(Corner),
							}
						)
					end)
				),
			}
			else nil
	)
end

return {
	QuestDialogue = QuestDialogue,
}
