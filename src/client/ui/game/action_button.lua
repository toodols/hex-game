local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local TweenService = game:GetService "TweenService"
local Corner = require(ReplicatedStorage.Client.ui.util_components).Corner

function TextActionButton(
	props: {
		color: Color3,
		Text: string,
		on_click: () -> (),
		LayoutOrder: number,
		Position: UDim2?,
		Size: UDim2?,
		AnchorPoint: Vector2?,
		enabled: boolean?,
	},
	ref
)
	local enabled = if props.enabled then props.enabled else true

	return React.createElement("TextButton", {
		BackgroundColor3 = props.color,
		BackgroundTransparency = 1,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		FontFace = Font.new("rbxasset://fonts/families/Michroma.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		ref = ref,
		[React.Event.MouseButton1Click] = if enabled then props.on_click else nil,
		[React.Event.MouseEnter] = if props[React.Event.MouseEnter]
			then props[React.Event.MouseEnter]
			else if enabled
				then function(self)
					TweenService:Create(self, TweenInfo.new(0.2), {
						BackgroundTransparency = 0.8,
					}):Play()
				end
				else nil,
		[React.Event.MouseLeave] = if props[React.Event.MouseLeave]
			then props[React.Event.MouseLeave]
			else if enabled
				then function(self)
					TweenService:Create(self, TweenInfo.new(0.2), {
						BackgroundTransparency = 1,
					}):Play()
				end
				else nil,
		Position = props.Position or UDim2.new(0, 0, 0, 0),
		Size = props.Size or UDim2.new(1, 0, 0, 20),
		AnchorPoint = props.AnchorPoint or Vector2.new(0, 0),
		Text = props.Text,
		TextColor3 = if enabled then props.color else props.color:Lerp(Color3.fromRGB(255, 255, 255), 0.5),
		TextSize = 14,
	})
end

function SquareActionButton(props: {
	on_click: () -> (),
	color: Color3,
	Image: string,
	LayoutOrder: number?,
	ImageColor3: Color3,
})
	return React.createElement("TextButton", {
		Text = "",
		BackgroundColor3 = Color3.fromRGB(71, 71, 71),
		[React.Tag] = "background square-action-button",

		[React.Event.MouseEnter] = function(current)
			TweenService:Create(current, TweenInfo.new(0.5), {
				BackgroundColor3 = props.color,
			}):Play()
		end,
		[React.Event.MouseLeave] = function(current)
			TweenService:Create(current, TweenInfo.new(0.5), {
				BackgroundColor3 = Color3.fromRGB(71, 71, 71),
			}):Play()
		end,
		LayoutOrder = props.LayoutOrder,
		[React.Event.MouseButton1Click] = props.on_click,
	}, {
		Icon = React.createElement("ImageLabel", {
			ImageColor3 = props.ImageColor3,
			Image = props.Image,
			Size = UDim2.new(0.5, 0, 0.5, 0),
			[React.Tag] = "align-cc",
		}),
	})
end

return {
	TextActionButton = React.forwardRef(TextActionButton),
	SquareActionButton = SquareActionButton,
}
