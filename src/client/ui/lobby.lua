local ReplicatedStorage = game:GetService "ReplicatedStorage"
local Players = game:GetService "Players"
local React = require(ReplicatedStorage.Packages.react)
local ReactRoblox = require(ReplicatedStorage.Packages["react-roblox"])
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local themes = require(ReplicatedStorage.Client.ui.themes)
local util = require(ReplicatedStorage.Shared.util)

local Corner = util_components.Corner
local Separator = util_components.Separator

function Dropdown()
	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		Position = UDim2.new(1, -5, 0.5, 0),
		Size = UDim2.new(0, 120, 0, 25),
	}, {
		Team = React.createElement("TextButton", {
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
			Size = UDim2.new(1, 0, 0, 25),
			Text = "",
			TextColor3 = Color3.fromRGB(0, 0, 0),
			TextSize = 14,
		}, {
			Icon = React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = "http://www.roblox.com/asset/?id=6022852108",
				ImageColor3 = Color3.fromRGB(255, 0, 0),
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
					Text = "Red",
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
			DropdownIcon = React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = "http://www.roblox.com/asset/?id=6034818372",
				LayoutOrder = 3,
				Position = UDim2.new(0.5, 0, 0.5, 0),
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
			util.table_map({}, function(team)
				return React.createElement("TextButton", {
					BackgroundColor3 = Color3.fromRGB(30, 30, 30),
					BorderColor3 = Color3.fromRGB(0, 0, 0),
					BorderSizePixel = 0,
					Size = UDim2.new(1, 0, 0, 25),
					Text = "",
				}, {
					ImageLabel = React.createElement("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						Image = "http://www.roblox.com/asset/?id=6022852108",
						ImageColor3 = Color3.fromRGB(0, 0, 255),
						Position = UDim2.new(0.5, 0, 0.5, 0),
						Size = UDim2.new(0, 30, 0, 30),
					}),
					TextLabel = React.createElement(
						"TextLabel",
						themes.theme_label {
							LayoutOrder = 2,
							Size = UDim2.new(0, 0, 1, 0),
							Text = "Blue",
							TextSize = 14,
						}
					),
					UIListLayout = React.createElement("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						Padding = UDim.new(0, 10),
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
				})
			end)
		),
	})
end

function ExpandedMember()
	return React.createElement("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = 3,
		Size = UDim2.new(1, 0, 0, 45),
		ZIndex = 2,
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
				Image = "rbxthumb://type=AvatarHeadShot&id=195294332&w=48&h=48",
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.new(0, 30, 0, 30),
				Transparency = 0.5,
			}, {
				UICorner = React.createElement(Corner),
			}),
			TextLabel = React.createElement("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/Michroma.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				RichText = true,
				Size = UDim2.new(0, 0, 1, 0),
				Text = `<font size="25">toodols</font>\n<i>@BasedTurtles</i>`,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 14,
			}),
		}),
		Dropdown = React.createElement(Dropdown, {}),
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

function Room()
	return React.createElement("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.fromRGB(13, 13, 13),
		BackgroundTransparency = 0.3,
		BorderColor3 = Color3.fromRGB(0, 0, 0),
		BorderSizePixel = 0,
		Position = UDim2.new(0.016, 0, 0.133, 0),
		Size = UDim2.new(1, 0, 0, 0),
		Transparency = 0.3,
	}, {
		MemberContainer = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			Position = UDim2.new(0, 10, 0, 0),
			Size = UDim2.new(0, 0, 0, 50),
			Visible = false,
		}, {
			UIListLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 10),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
		}),
		ClickToExpandLabel = React.createElement("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
			Position = UDim2.new(1, -15, 0.5, 0),
			Size = UDim2.new(0, 200, 0, 50),
			Text = "Click To Expand",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 16,
			TextTransparency = 0.6,
			TextXAlignment = Enum.TextXAlignment.Right,
			Visible = false,
		}),
		Corner = React.createElement(Corner),
		Hitbox = React.createElement(
			"TextButton",
			themes.theme_container {
				Text = "",
			}
		),
		MapTypeLabel = React.createElement(
			"TextLabel",
			themes.theme_label {
				Size = UDim2.new(0, 200, 0, 50),
				Text = "Map Size: 9",
				TextSize = 20,
			}
		),
		StartTimeLabel = React.createElement(
			"TextLabel",
			themes.theme_label {
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.new(0.5, 0, 1, 0),
				Size = UDim2.new(0, 200, 0, 50),
				Text = "Starting in 10s",
				TextSize = 20,
			}
		),
		Frame = React.createElement("Frame", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 0),
		}, {
			ExpandedMemberContainer = React.createElement("Frame", {
				AnchorPoint = Vector2.new(1, 0),
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -10, 0, 0),
				Size = UDim2.new(0, 300, 0, 0),
			}, {
				UIListLayout = React.createElement("UIListLayout", {
					Padding = UDim.new(0, 5),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				UIPadding = React.createElement("UIPadding", {
					PaddingBottom = UDim.new(0, 10),
					PaddingTop = UDim.new(0, 10),
				}),
				Members = React.createElement("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
					LayoutOrder = 1,
					Size = UDim2.new(1, 0, 0, 30),
					Text = "Members",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 25,
				}),
				UISizeConstraint = React.createElement("UISizeConstraint", {
					MinSize = Vector2.new(0, 400),
				}),
			}, util.table_map({}, function() end)),
		}),
		ImageLabel = React.createElement("ImageLabel", {
			BackgroundTransparency = 1,
			Image = "rbxassetid://14073589622",
			ImageTransparency = 0.88,
			Position = UDim2.new(0.334, 0, 0.0467, 0),
			Size = UDim2.new(0, 331, 0, 344),
		}),
	})
end

function Lobby()
	return React.createElement("ScreenGui", {
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
				Container = React.createElement("Frame", {
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Size = UDim2.new(1, 0, 0, 0),
				}, {
					UIListLayout = React.createElement("UIListLayout", {
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						Padding = UDim.new(0, 10),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				}),
				Title = React.createElement("Frame", {
					AutomaticSize = Enum.AutomaticSize.Y,
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 0),
					LayoutOrder = 1,
				}, {
					Text = React.createElement("TextLabel", {
						AutomaticSize = Enum.AutomaticSize.XY,
						BackgroundTransparency = 1,
						FontFace = Font.new(
							"rbxasset://fonts/families/Sarpanch.json",
							Enum.FontWeight.Bold,
							Enum.FontStyle.Normal
						),
						LayoutOrder = 1,
						Position = UDim2.new(0, 400, 0, 0),
						Size = UDim2.new(0, 200, 0, 25),
						Text = "Rooms",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 50,
					}),
					Separator = React.createElement(Separator, {
						LayoutOrder = 2,
					}),
					UIListLayout = React.createElement("UIListLayout", {
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
				}),
				TextButton = React.createElement(
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
