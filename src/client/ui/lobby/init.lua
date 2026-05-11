local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"

local React = require(ReplicatedStorage.Packages.react)
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])

local util_components = require(ReplicatedStorage.Client.ui.util_components)
local stylesheets = require(ReplicatedStorage.Client.ui.stylesheets)

local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)

local Room = require(script.room).Room
local CreateRoom = require(script.create_room).CreateRoom

local Separator = util_components.Separator

type Room = types.Room

local rooms_remote = ReplicatedStorage:FindFirstChild "Rooms" :: RemoteEvent

function Lobby()
	local rooms: { [string]: Room }, set_rooms = React.useState {}
	local servers, set_servers = React.useState {}
	local is_creating_room, set_is_creating_room = React.useState(false)

	React.useEffect(function()
		local connection = rooms_remote.OnClientEvent:Connect(function(data)
			local player_room = nil
			for _, room in data.rooms do
				if room.players[tostring(Players.LocalPlayer.UserId)] ~= nil then
					player_room = room
				end
			end
			if player_room then
				set_is_creating_room(false)
			end
			set_rooms(data.rooms)
			set_servers(data.servers)
		end)
		rooms_remote:FireServer {
			type = "get_rooms",
		}
		return function()
			connection:Disconnect()
		end
	end, {})

	return React.createElement("ScreenGui", {
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
	}, {
		StyleLink = React.createElement("StyleLink", {
			StyleSheet = stylesheets.default_stylesheet,
		}),
		Background = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.2,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 0,
		}, {
			PatternContainer = React.createElement("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.new(0.171, 0, 0.251, 0),
			}, {
				Pattern = React.createElement("ImageLabel", {
					BackgroundTransparency = 1,
					Image = "rbxassetid://300134974",
					ImageTransparency = 0.95,
					Position = UDim2.new(-0.025, 0, 1.35, 0),
					ScaleType = Enum.ScaleType.Tile,
					Size = UDim2.new(5.88, 0, 2.63, 0),
					TileSize = UDim2.new(0, 120, 0, 120),
				}, {
					UIGradient = React.createElement("UIGradient", {
						Rotation = -90,
						Transparency = NumberSequence.new {
							NumberSequenceKeypoint.new(0, 0),
							NumberSequenceKeypoint.new(0.309, 0.688),
							NumberSequenceKeypoint.new(0.49, 0.906),
							NumberSequenceKeypoint.new(1, 1),
						},
					}),
				}),
			}),
		}),
		Hearts = React.createElement("TextButton", {
			Position = UDim2.new(1, -5, 1, -5),
			Size = UDim2.new(0, 50, 0, 50),
			TextSize = 18,
			[React.Tag] = "text-r align-br",
			Text = "♥︎",
		}),
		Rooms = React.createElement("Frame", {
			LayoutOrder = 1,
			[React.Tag] = "container align-tc",
		}, {
			VerticalLayout = React.createElement("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			CurrentRooms = React.createElement("Frame", {
				LayoutOrder = 1,
				Size = UDim2.new(0, 1000, 0, 0),
				[React.Tag] = "align-tc container-v list-v list-tc",
			}, {
				Container = React.createElement(
					"Frame",
					{
						LayoutOrder = 3,
						[React.Tag] = "container-v list-v list-pad-5 list-tc",
					},
					util.table_map(rooms, function(room)
						return React.createElement(Room, { room = room })
					end)
				),
				Title = React.createElement("Frame", {
					LayoutOrder = 1,
					[React.Tag] = "container-v list-v list-tc",
				}, {
					Text = React.createElement("TextLabel", {
						LayoutOrder = 1,
						Position = UDim2.new(0, 400, 0, 0),
						Size = UDim2.new(0, 0, 0, 50),
						Text = "Rooms",
						TextSize = 50,
					}),
					Separator = React.createElement(Separator, {
						LayoutOrder = 2,
					}),
				}),
				CreateRoom = React.createElement(CreateRoom, {
					expanded = is_creating_room,
					set_expanded = set_is_creating_room,
				}),
			}),
		}),
	})
end

function init_ui()
	local root = ReactRoblox.createRoot(Players.LocalPlayer.PlayerGui)
	root:render(React.createElement(Lobby))
end

return {
	Lobby = Lobby,
	init_ui = init_ui,
}
