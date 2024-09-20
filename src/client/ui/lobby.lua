local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"
local RunService = game:GetService "RunService"

local React = require(ReplicatedStorage.Packages.react)
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])

local util_components = require(ReplicatedStorage.Client.ui.util_components)
local themes = require(ReplicatedStorage.Client.ui.themes)

local util = require(ReplicatedStorage.Shared.util)
local types = require(ReplicatedStorage.Shared.types)

local Corner = util_components.Corner
local Separator = util_components.Separator

type Room = types.Room

local rooms_remote = ReplicatedStorage:FindFirstChild "Rooms" :: RemoteEvent

function TeamDropdownItem(props: {
	icon_color: Color3,
	text: string,
})
	return React.createElement(React.Fragment, {}, {
		Icon = React.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = "http://www.roblox.com/asset/?id=6022852108",
			ImageColor3 = props.icon_color,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 30, 0, 30),
		}),
		Label = React.createElement(
			"TextLabel",
			themes.theme_label {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/Jura.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
				LayoutOrder = 2,
				Size = UDim2.new(0, 0, 1, 0),
				Text = props.text,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
			}
		),
		HorizontalLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
	})
end

function Dropdown(props: { current: string, options: { [string]: any }, on_change: (string) -> () })
	local open, set_open = React.useState(false)
	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -5, 0.5, 0),
		Size = UDim2.new(0, 150, 0, 25),
	}, {
		Team = React.createElement("TextButton", {
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
		}),
		List = React.createElement(
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
		),
	})
end

function ExpandedMember(props: {
	player: Player,
	teams: { [number]: {
		color: Color3,
		name: string,
	} },
	team: number,
	ZIndex: number,
})
	local is_local_player = props.player == Players.LocalPlayer
	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 45),
		ZIndex = props.ZIndex,
	}, {
		Container = React.createElement("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 1, 0),
			ZIndex = 2,
		}, {
			UIListLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			Headshot = React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(29, 29, 29),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				LayoutOrder = 1,
				Image = Players:GetUserThumbnailAsync(
					props.player.UserId,
					Enum.ThumbnailType.HeadShot,
					Enum.ThumbnailSize.Size48x48
				),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 30, 0, 30),
				Transparency = 0.5,
			}, {
				UICorner = React.createElement(Corner),
			}),
			PlayerNameLabel = React.createElement(
				"TextLabel",
				themes.theme_label {
					LayoutOrder = 2,
					Size = UDim2.new(0, 0, 1, 0),
					Text = `<font size="25">{props.player.DisplayName}</font>\n<i>@{props.player.Name}</i>`,
					TextSize = 12,
				}
			),
		}),
		Team = if is_local_player
			then React.createElement(Dropdown, {
				current = props.team,
				options = util.table_map(props.teams, function(team)
					return React.createElement(TeamDropdownItem, {
						icon_color = team.color,
						text = team.name,
					})
				end),
				on_change = function(team)
					rooms_remote:FireServer {
						type = "set_team",
						team = team,
					}
				end,
			})
			else React.createElement("Frame", {
				BackgroundTransparency = 1,
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -5, 0.5, 0),
				Size = UDim2.new(0, 150, 0, 25),
			}, {
				Icon = React.createElement("ImageLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Image = "http://www.roblox.com/asset/?id=6022852108",
					ImageColor3 = props.teams[props.team].color,
					Position = UDim2.new(0.5, 0, 0.5, 0),
					Size = UDim2.new(0, 30, 0, 30),
				}),
				Label = React.createElement(
					"TextLabel",
					themes.theme_label {
						AutomaticSize = Enum.AutomaticSize.X,
						BackgroundTransparency = 1,
						FontFace = Font.new(
							"rbxasset://fonts/families/Jura.json",
							Enum.FontWeight.Bold,
							Enum.FontStyle.Normal
						),
						LayoutOrder = 2,
						Size = UDim2.new(0, 0, 1, 0),
						Text = props.teams[props.team].name,
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 14,
					}
				),
				HorizontalLayout = React.createElement("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
			}),
		Pattern = React.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://300134974",
			ImageTransparency = 0.77,
			Position = UDim2.new(0.00667, 0, 0.167, 0),
			ScaleType = Enum.ScaleType.Tile,
			Size = UDim2.new(0, 295, 0, 37),
			TileSize = UDim2.new(0, 90, 0, 90),
			ZIndex = 0,
		}, {
			UIGradient = React.createElement("UIGradient", {
				Rotation = 90,
				Transparency = NumberSequence.new {
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(0.524, 0.431),
					NumberSequenceKeypoint.new(1, 1),
				},
			}),
		}),
	})
end

function Room(props: { room: Room })
	local is_expanded = props.room.players[tostring(Players.LocalPlayer.UserId)] ~= nil
	local start_time_label_ref = React.useRef(nil)
	local props_ref = React.useRef(props)
	props_ref.current = props
	React.useEffect(function()
		local connection = RunService.RenderStepped:Connect(function()
			if start_time_label_ref.current and props_ref.current and props_ref.current.room.starting_at then
				start_time_label_ref.current.Text = `Starting in {math.floor(
					(props_ref.current.room.starting_at - DateTime.now().UnixTimestampMillis) / 100
				) / 10}s`
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
		Transparency = 0.3,
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
					Transparency = 0.5,
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
				TextXAlignment = Enum.TextXAlignment.Right,
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
			MapTypeLabel = React.createElement(
				"TextLabel",
				themes.theme_label {
					Size = UDim2.new(0, 200, 0, 50),
					Text = "Map Size: 9",
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

function Lobby()
	local rooms, set_rooms = React.useState {}
	local servers, set_servers = React.useState {}
	React.useEffect(function()
		local connection = rooms_remote.OnClientEvent:Connect(function(data)
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
		Background = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(0, 0, 0),
			BackgroundTransparency = 0.2,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, 0, 1, 0),
			Transparency = 0.2,
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
		Rooms = React.createElement("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			AutomaticSize = Enum.AutomaticSize.XY,
			BackgroundTransparency = 1,
			LayoutOrder = 1,
			Position = UDim2.new(0.5, 0, 0, 0),
		}, {
			UIListLayout = React.createElement("UIListLayout", {
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			CurrentRooms = React.createElement("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				LayoutOrder = 1,
				Position = UDim2.new(0.5, 0, 0, 0),
				Size = UDim2.new(0, 1000, 0, 0),
			}, {
				UIListLayout = React.createElement("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0, 10),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Container = React.createElement(
					"Frame",
					themes.theme_vertical_container {
						LayoutOrder = 3,
					},
					{
						UIListLayout = React.createElement("UIListLayout", {
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							Padding = UDim.new(0, 10),
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
					},
					util.table_map(rooms, function(room)
						return React.createElement(Room, { room = room })
					end)
				),
				Title = React.createElement(
					"Frame",
					themes.theme_vertical_container {
						LayoutOrder = 1,
					},
					{
						Text = React.createElement(
							"TextLabel",
							themes.theme_title {
								LayoutOrder = 1,
								Position = UDim2.new(0, 400, 0, 0),
								Size = UDim2.new(0, 0, 0, 50),
								Text = "Rooms",
								TextSize = 50,
							}
						),
						Separator = React.createElement(Separator, {
							LayoutOrder = 2,
						}),
						UIListLayout = React.createElement("UIListLayout", {
							HorizontalAlignment = Enum.HorizontalAlignment.Center,
							SortOrder = Enum.SortOrder.LayoutOrder,
						}),
					}
				),
				CreateRoomButton = React.createElement(
					"TextButton",
					themes.theme_button {
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BorderColor3 = Color3.fromRGB(0, 0, 0),
						BorderSizePixel = 0,
						Size = UDim2.new(1, 0, 0, 40),
						Text = "Create Room",
						TextColor3 = Color3.fromRGB(0, 0, 0),
						TextScaled = true,
						TextSize = 20,
						TextWrapped = true,
						LayoutOrder = 2,
						[React.Event.MouseButton1Click] = function()
							rooms_remote:FireServer {
								type = "new_room",
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
