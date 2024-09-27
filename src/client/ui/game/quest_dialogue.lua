local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local format_text = require(ReplicatedStorage.Shared.formatting).format_text
local Corner = util_components.Corner

function QuestDialogue(props: {
	title: string,
	messages: { string },
	can_advance: boolean,
	advance: () -> (),
})
	local grid = React.useContext(MainContext).grid
	local message_num, set_message_num = React.useState(1)

	return React.createElement("TextButton", {
		BackgroundColor3 = Color3.fromRGB(13, 13, 13),
		BackgroundTransparency = 0.5,
		Text = "",
		BorderSizePixel = 0,
		LayoutOrder = 1,
		Size = UDim2.new(0, 600, 0, 80),
		[React.Event.MouseButton1Click] = function()
			if message_num < #props.messages then
				set_message_num(message_num + 1)
			elseif props.can_advance then
				props.advance()
			end
		end,
	}, {
		Title = React.createElement("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			FontFace = Font.new("rbxasset://fonts/families/Oswald.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			Position = UDim2.new(0, 0, 0, 5),
			RichText = true,
			Size = UDim2.new(1, 0, 0, 25),
			Text = `{props.title}: {message_num}/{#props.messages}`,
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
			FontFace = Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			LayoutOrder = 2,
			Position = UDim2.new(0, 0, 0, 30),
			RichText = true,
			Size = UDim2.new(1, 0, 0, 0),
			Text = format_text(grid, props.messages[message_num]),
			TextColor3 = Color3.fromRGB(170, 170, 170),
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
			FontFace = Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
			LayoutOrder = 2,
			Position = UDim2.new(1, -5, 1, -5),
			Size = UDim2.new(1, 0, 0, 0),
			Text = "Click to Continue",
			Visible = props.can_advance or message_num < #props.messages,
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
	})
end

return {
	QuestDialogue = QuestDialogue,
}
