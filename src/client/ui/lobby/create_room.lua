local ReplicatedStorage = game:GetService "ReplicatedStorage"
local TweenService = game:GetService "TweenService"

local React = require(ReplicatedStorage.Packages.react)
local themes = require(ReplicatedStorage.Client.ui.themes)
local util = require(ReplicatedStorage.Shared.util)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local Corner = util_components.Corner
local Dropdown = util_components.Dropdown

local rooms_remote = ReplicatedStorage:FindFirstChild "Rooms" :: RemoteEvent

function CreateRoom(props: { expanded: boolean, set_expanded: (boolean) -> () })
	local create_room_frame_ref = React.useRef(nil)
	local map_type, set_map_type = React.useState "my_map"

	React.useEffect(function()
		local current = create_room_frame_ref.current
		if current then
			if props.expanded then
				TweenService:Create(current, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
					Size = UDim2.new(1, 0, 0, 420),
				}):Play()
			else
				TweenService:Create(current, TweenInfo.new(0.2), {
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					Size = UDim2.new(1, 0, 0, 40),
				}):Play()
			end
		end
	end, {
		props.expanded,
	})
	return React.createElement("Frame", {
		Size = UDim2.new(1, 0, 0, 40),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		LayoutOrder = 2,
		ref = create_room_frame_ref,
	}, {
		CreateRoomButton = React.createElement(
			"TextButton",
			themes.theme_button {
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 1, 0),
				Text = "Create Room",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextScaled = true,
				Visible = not props.expanded,
				TextSize = 20,
				TextWrapped = true,
				[React.Event.MouseButton1Click] = function()
					props.set_expanded(true)
					rooms_remote:FireServer {
						type = "leave_room",
					}
				end,
			},
			{
				UICorner = React.createElement(Corner),
				UIGradient = React.createElement("UIGradient", {
					Rotation = 90,
					Transparency = NumberSequence.new {
						NumberSequenceKeypoint.new(0, 0),
						NumberSequenceKeypoint.new(0.502, 0.131),
						NumberSequenceKeypoint.new(1, 0),
					},
				}),
				UITextSizeConstraint = React.createElement("UITextSizeConstraint", {
					MaxTextSize = 20,
				}),
			}
		),
		Content = if props.expanded
			then React.createElement("Frame", {
				Size = UDim2.new(1, 0, 0, 420),
				BackgroundTransparency = 1,
			}, {
				Dropdown = React.createElement(Dropdown, {
					Position = UDim2.new(0, 10, 0, 10),
					AnchorPoint = Vector2.new(0, 0),
					current = map_type,
					options = {
						my_map = React.createElement(
							"TextLabel",
							themes.theme_title {
								Size = UDim2.new(1, 0, 0, 25),
								Text = "Standard",
								TextSize = 18,
							}
						),
						tutorial_map = React.createElement(
							"TextLabel",
							themes.theme_title {
								Size = UDim2.new(1, 0, 0, 25),
								Text = "Tutorial",
								TextSize = 18,
							}
						),
						lightning = React.createElement(
							"TextLabel",
							themes.theme_title {
								Size = UDim2.new(1, 0, 0, 25),
								Text = "Standard Lightning",
								TextSize = 18,
							}
						),
					},
					on_change = set_map_type,
				}),
				FinalizeButton = React.createElement(
					"TextButton",
					themes.theme_button {
						BackgroundTransparency = 1,
						Size = UDim2.new(1, 0, 0, 30),
						Text = "Finalize",
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.new(0.5, 0, 1, 0),
						[React.Event.MouseButton1Click] = function()
							props.set_expanded(false)
							rooms_remote:FireServer {
								type = "new_room",
								map_type = map_type,
							}
						end,
					},
					{}
				),
			})
			else nil,
	})
end

return {
	CreateRoom = CreateRoom,
}
