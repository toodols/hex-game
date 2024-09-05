local ReplicatedStorage = game:GetService "ReplicatedStorage"
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])
local React = require(ReplicatedStorage.Packages.react)
local TweenService = game:GetService "TweenService"

function ActionButton(props: {
	color: Color3,
	Text: string,
	on_click: () -> (),
	LayoutOrder: number,
})
	return React.createElement("TextButton", {
		BackgroundColor3 = props.color,
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		FontFace = Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		[React.Event.MouseButton1Click] = props.on_click,
		[React.Event.MouseEnter] = function(self)
			TweenService:Create(self, TweenInfo.new(0.2), {
				BackgroundTransparency = 0.8,
			}):Play()
		end,
		[React.Event.MouseLeave] = function(self)
			TweenService:Create(self, TweenInfo.new(0.2), {
				BackgroundTransparency = 1,
			}):Play()
		end,
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.new(1, 0, 0, 20),
		Text = props.Text,
		TextColor3 = props.color,
		TextSize = 14,
	})
end

return {
	ActionButton = ActionButton,
}
