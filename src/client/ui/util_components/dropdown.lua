local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local Corner = require(script.Parent.corner).Corner
local themes = require(ReplicatedStorage.Client.ui.themes)
local util = require(ReplicatedStorage.Shared.util)

function Dropdown(props: {
	LayoutOrder: number?,
	AnchorPoint: Vector2?,
	Size: UDim2?,
	Position: UDim2?,
	current: string,
	options: { [string]: any },
	on_change: (string) -> (),
})
	local open, set_open = React.useState(false)
	return React.createElement("Frame", {
		AnchorPoint = props.AnchorPoint,
		BackgroundTransparency = 1,
		Position = props.Position,
		Size = props.Size or UDim2.new(0, 150, 0, 25),
	}, {
		Item = if #util.table_keys(props.options) > 1
			then React.createElement("TextButton", {
				BackgroundColor3 = Color3.fromRGB(30, 30, 30),
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 25),
				Text = "",
				[React.Event.MouseButton1Click] = function()
					set_open(not open)
				end,
			}, {
				Current = React.createElement("Frame", themes.theme_container {}, { props.options[props.current] }),
				DropdownIcon = React.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(1, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=6034818372",
					LayoutOrder = 3,
					Position = UDim2.new(1, 0, 0.5, 0),
					Size = UDim2.new(0, 30, 0, 30),
				}),

				UICorner = React.createElement(Corner),
				UIStroke = React.createElement("UIStroke", {
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
					Color = Color3.fromRGB(255, 255, 255),
					Transparency = 0.8,
				}),
			})
			else React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 25),
			}, {
				Current = props.options[props.current],
			}),
		List = if #util.table_keys(props.options) > 1
			then React.createElement(
				"Frame",
				{
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Color3.fromRGB(50, 50, 50),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Visible = open,
					Position = UDim2.new(0, 0, 1, 5),
					Size = UDim2.new(1, 0, 0, 0),
				},
				{
					UIListLayout = React.createElement("UIListLayout", {
						Padding = UDim.new(0, 2),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					Corner = React.createElement(Corner),
					UIStroke = React.createElement("UIStroke", {
						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.fromRGB(255, 255, 255),
						Transparency = 0.8,
					}),
				},
				util.table_map(props.options, function(v, k)
					return React.createElement("TextButton", {
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundTransparency = 1,
						Text = "",
						[React.Event.MouseButton1Click] = function()
							set_open(false)
							if props.on_change then
								props.on_change(k)
							end
						end,
					}, {
						v,
					})
				end)
			)
			else nil,
	})
end

return {
	Dropdown = Dropdown,
}
