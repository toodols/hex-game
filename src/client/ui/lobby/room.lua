local ReplicationStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"
local RunService = game:GetService "RunService"

local util_components = require(ReplicationStorage.Client.ui.util_components)
local themes = require(ReplicationStorage.Client.ui.themes)
local util = require(ReplicationStorage.Shared.util)
local React = require(ReplicationStorage.Packages.react)
local types = require(ReplicationStorage.Shared.types)
local ExpandedMember = require(script.Parent.expanded_member).ExpandedMember

local Corner = util_components.Corner

type Room = types.Room

local rooms_remote = ReplicationStorage:FindFirstChild "Rooms" :: RemoteEvent
function Room(props: { room: Room })
	local is_expanded = props.room.players[tostring(Players.LocalPlayer.UserId)] ~= nil
	local start_time_label_ref = React.useRef(nil)
	local props_ref = React.useRef(props)
	props_ref.current = props
	React.useEffect(function()
		local connection = RunService.RenderStepped:Connect(function()
			if start_time_label_ref.current and props_ref.current and props_ref.current.room.starting_at then
				start_time_label_ref.current.Text = `Starting in {("%.1f"):format(
					(props_ref.current.room.starting_at - workspace:GetServerTimeNow())
				)}s`
			end
		end)

		return function()
			connection:Disconnect()
		end
	end, {})
	return React.createElement("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(13, 13, 13),
		BackgroundTransparency = 0.3,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
	}, {
		MemberContainer = React.createElement(
			"Frame",
			{
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(0, 0, 0, 50),
				Visible = not is_expanded,
			},
			{
				UIListLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
			},
			util.table_map(props.room.players, function(_, userid)
				return React.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(29, 29, 29),
					BackgroundTransparency = 0.5,
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					LayoutOrder = 1,
					Image = Players:GetUserThumbnailAsync(
						userid,
						Enum.ThumbnailType.HeadShot,
						Enum.ThumbnailSize.Size48x48
					),
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0, 30, 0, 30),
				}, {
					UICorner = React.createElement(Corner),
				})
			end)
		),
		ClickToJoinLabel = React.createElement(
			"TextLabel",
			themes.theme_label {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -15, 0.5, 0),
				Size = UDim2.new(0, 200, 0, 50),
				Text = "Click To Join",
				TextSize = 16,
				TextTransparency = 0.6,
				[React.Tag] = "text-r",
				Visible = not is_expanded,
			}
		),
		Corner = React.createElement(Corner),
		Hitbox = React.createElement(
			"TextButton",
			themes.theme_container {
				Visible = not is_expanded,
				Text = "",
				[React.Event.MouseButton1Click] = function()
					rooms_remote:FireServer {
						type = "join_room",
						room_id = props.room.id,
					}
				end,
			}
		),

		StartTimeLabel = if props.room.starting_at ~= nil
			then React.createElement(
				"TextLabel",
				themes.theme_label {
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 1, 0),
					Size = UDim2.new(0, 200, 0, 50),
					Text = "Starting in",
					TextSize = 20,
					ref = start_time_label_ref,
				}
			)
			else nil,
		ExpandedFrame = React.createElement("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
			Visible = is_expanded,
		}, {
			LeaveRoomButton = React.createElement(
				"TextButton",
				themes.theme_button {
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.new(1, 0, 1, 0),
					Size = UDim2.new(0, 200, 0, 50),
					Text = "Leave Room",
					[React.Event.MouseButton1Click] = function()
						rooms_remote:FireServer {
							type = "leave_room",
							room_id = props.room.id,
						}
					end,
				},
				{
					Corner = React.createElement(Corner),
				}
			),
			ImageLabel = React.createElement("ImageLabel", {
				BackgroundTransparency = 1,
				Image = "rbxassetid://14073589622",
				ImageTransparency = 0.88,
				Position = UDim2.new(0.334, 0, 0.0467, 0),
				Size = UDim2.new(0, 331, 0, 344),
			}),
			MapLabel = React.createElement(
				"TextLabel",
				themes.theme_label {
					Size = UDim2.new(0, 200, 0, 50),
					Text = `Map: {props.room.map}`,
					TextSize = 20,
				}
			),
			ExpandedMemberContainer = React.createElement(
				"Frame",
				themes.theme_vertical_container {
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, -10, 0, 0),
					Size = UDim2.new(0, 300, 0, 0),
				},
				{
					UIListLayout = React.createElement("UIListLayout", {
						Padding = UDim.new(0, 5),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					UIPadding = React.createElement("UIPadding", {
						PaddingBottom = UDim.new(0, 10),
						PaddingTop = UDim.new(0, 10),
					}),
					MembersLabel = React.createElement(
						"TextLabel",
						themes.theme_label {
							LayoutOrder = 1,
							Size = UDim2.new(1, 0, 0, 30),
							Text = "Members",
							TextSize = 25,
						}
					),
					UISizeConstraint = React.createElement("UISizeConstraint", {
						MinSize = Vector2.new(0, 400),
					}),
				},
				util.table_map(util.table_keys(props.room.players), function(userid, num)
					return React.createElement(ExpandedMember, {
						player = Players:GetPlayerByUserId(userid),
						teams = props.room.teams,
						team = props.room.players[userid].team,
						ZIndex = -num,
					})
				end)
			),
		}),
	})
end

return {
	Room = Room,
}
