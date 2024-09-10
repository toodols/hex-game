local ReplicatedStorage = game:GetService("ReplicatedStorage")
local React = require(ReplicatedStorage.Packages.react)
local Corner = require(script.Parent.corner).Corner

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
				Room = React.createElement("Frame", {
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
					UICorner = React.createElement "UICorner",
					Hitbox = React.createElement("TextButton", {
						BackgroundTransparency = 1,
						FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
						Size = UDim2.new(1, 0, 1, 0),
						Text = "",
						TextColor3 = Color3.fromRGB(0, 0, 0),
						TextSize = 14,
					}),
					MapTypeLabel = React.createElement("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = Font.new(
							"rbxasset://fonts/families/Michroma.json",
							Enum.FontWeight.Bold,
							Enum.FontStyle.Normal
						),
						Size = UDim2.new(0, 200, 0, 50),
						Text = "Map Size: 9",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 20,
					}),
					StartTimeLabel = React.createElement("TextLabel", {
						AnchorPoint = Vector2.new(0.5, 1),
						BackgroundTransparency = 1,
						FontFace = Font.new(
							"rbxasset://fonts/families/Michroma.json",
							Enum.FontWeight.Bold,
							Enum.FontStyle.Normal
						),
						Position = UDim2.new(0.5, 0, 1, 0),
						Size = UDim2.new(0, 200, 0, 50),
						Text = "Starting in 10s",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						TextSize = 20,
					}),
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
							Toodols = React.createElement("Frame", {
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
									ImageLabel = React.createElement("ImageLabel", {
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
										Text = [[<font size="25">toodols</font>
<i>@BasedTurtles</i>]],
										TextColor3 = Color3.fromRGB(255, 255, 255),
										TextSize = 14,
									}),
								}),
								Frame = React.createElement("Frame", {
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
										ImageLabel = React.createElement("ImageLabel", {
											AnchorPoint = Vector2.new(0.5, 0.5),
											BackgroundTransparency = 1,
											Image = "http://www.roblox.com/asset/?id=6022852108",
											ImageColor3 = Color3.fromRGB(255, 0, 0),
											Position = UDim2.new(0.5, 0, 0.5, 0),
											Size = UDim2.new(0, 30, 0, 30),
										}),
										TextLabel = React.createElement("TextLabel", {
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
										}),
										UIListLayout = React.createElement("UIListLayout", {
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
									List = React.createElement("Frame", {
										AutomaticSize = Enum.AutomaticSize.Y,
										BackgroundColor3 = Color3.fromRGB(50, 50, 50),
										BorderColor3 = Color3.fromRGB(0, 0, 0),
										BorderSizePixel = 0,
										Position = UDim2.new(0, 0, 1, 5),
										Size = UDim2.new(1, 0, 0, 0),
									}, {
										UIListLayout = React.createElement("UIListLayout", {
											Padding = UDim.new(0, 2),
											SortOrder = Enum.SortOrder.LayoutOrder,
										}),
										Red = React.createElement("TextButton", {
											BackgroundColor3 = Color3.fromRGB(30, 30, 30),
											BorderColor3 = Color3.fromRGB(0, 0, 0),
											BorderSizePixel = 0,
											FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
											RichText = true,
											Size = UDim2.new(1, 0, 0, 25),
											Text = "",
											TextColor3 = Color3.fromRGB(0, 0, 0),
											TextSize = 14,
										}, {
											ImageLabel = React.createElement("ImageLabel", {
												AnchorPoint = Vector2.new(0.5, 0.5),
												BackgroundTransparency = 1,
												Image = "http://www.roblox.com/asset/?id=6022852108",
												ImageColor3 = Color3.fromRGB(255, 0, 0),
												Position = UDim2.new(0.5, 0, 0.5, 0),
												Size = UDim2.new(0, 30, 0, 30),
											}),
											TextLabel = React.createElement("TextLabel", {
												AutomaticSize = Enum.AutomaticSize.X,
												BackgroundTransparency = 1,
												FontFace = Font.new(
													"rbxasset://fonts/families/Jura.json",
													Enum.FontWeight.Bold,
													Enum.FontStyle.Normal
												),
												LayoutOrder = 2,
												RichText = true,
												Size = UDim2.new(0, 0, 1, 0),
												Text = "Red",
												TextColor3 = Color3.fromRGB(255, 255, 255),
												TextSize = 14,
											}),
											UIListLayout = React.createElement("UIListLayout", {
												FillDirection = Enum.FillDirection.Horizontal,
												Padding = UDim.new(0, 10),
												SortOrder = Enum.SortOrder.LayoutOrder,
												VerticalAlignment = Enum.VerticalAlignment.Center,
											}),
										}),
										Blue = React.createElement("TextButton", {
											BackgroundColor3 = Color3.fromRGB(30, 30, 30),
											BorderColor3 = Color3.fromRGB(0, 0, 0),
											BorderSizePixel = 0,
											FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
											RichText = true,
											Size = UDim2.new(1, 0, 0, 25),
											Text = "",
											TextColor3 = Color3.fromRGB(0, 0, 0),
											TextSize = 14,
										}, {
											ImageLabel = React.createElement("ImageLabel", {
												AnchorPoint = Vector2.new(0.5, 0.5),
												BackgroundTransparency = 1,
												Image = "http://www.roblox.com/asset/?id=6022852108",
												ImageColor3 = Color3.fromRGB(0, 0, 255),
												Position = UDim2.new(0.5, 0, 0.5, 0),
												Size = UDim2.new(0, 30, 0, 30),
											}),
											TextLabel = React.createElement("TextLabel", {
												AutomaticSize = Enum.AutomaticSize.X,
												BackgroundTransparency = 1,
												FontFace = Font.new(
													"rbxasset://fonts/families/Jura.json",
													Enum.FontWeight.Bold,
													Enum.FontStyle.Normal
												),
												LayoutOrder = 2,
												RichText = true,
												Size = UDim2.new(0, 0, 1, 0),
												Text = "Blue",
												TextColor3 = Color3.fromRGB(255, 255, 255),
												TextSize = 14,
											}),
											UIListLayout = React.createElement("UIListLayout", {
												FillDirection = Enum.FillDirection.Horizontal,
												Padding = UDim.new(0, 10),
												SortOrder = Enum.SortOrder.LayoutOrder,
												VerticalAlignment = Enum.VerticalAlignment.Center,
											}),
										}),
										UICorner = React.createElement(Corner),
										UIStroke = React.createElement("UIStroke", {
											ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
											Color = Color3.fromRGB(255, 255, 255),
											Transparency = 0.8,
										}),
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
							}),
							Leo = React.createElement("Frame", {
								BackgroundTransparency = 1,
								LayoutOrder = 2,
								Size = UDim2.new(1, 0, 0, 45),
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
									ImageLabel = React.createElement("ImageLabel", {
										AnchorPoint = Vector2.new(0.5, 0.5),
										BackgroundColor3 = Color3.fromRGB(29, 29, 29),
										BackgroundTransparency = 0.5,
										BorderColor3 = Color3.fromRGB(0, 0, 0),
										BorderSizePixel = 0,
										Image = "rbxthumb://type=AvatarHeadShot&id=92653295&w=48&h=48",
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
										Text = [[<font size="25">Leo</font>
<i>@H9_zy</i>]],
										TextColor3 = Color3.fromRGB(255, 255, 255),
										TextSize = 14,
									}),
								}),
								Frame = React.createElement("Frame", {
									AnchorPoint = Vector2.new(1, 0.5),
									BackgroundTransparency = 1,
									Position = UDim2.new(1, -5, 0.5, 0),
									Size = UDim2.new(0, 120, 0, 25),
								}, {
									Team = React.createElement("TextButton", {
										BackgroundTransparency = 1,
										FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
										Size = UDim2.new(1, 0, 0, 25),
										Text = "",
										TextColor3 = Color3.fromRGB(0, 0, 0),
										TextSize = 14,
									}, {
										ImageLabel = React.createElement("ImageLabel", {
											AnchorPoint = Vector2.new(0.5, 0.5),
											BackgroundTransparency = 1,
											Image = "http://www.roblox.com/asset/?id=6022852108",
											ImageColor3 = Color3.fromRGB(255, 0, 0),
											Position = UDim2.new(0.125, 0, 0.62, 0),
											Size = UDim2.new(0, 30, 0, 30),
										}),
										TextLabel = React.createElement("TextLabel", {
											AutomaticSize = Enum.AutomaticSize.X,
											BackgroundTransparency = 1,
											FontFace = Font.new(
												"rbxasset://fonts/families/Jura.json",
												Enum.FontWeight.Bold,
												Enum.FontStyle.Normal
											),
											LayoutOrder = 2,
											Position = UDim2.new(0.375, 0, 0.12, 0),
											Size = UDim2.new(0, 0, 1, 0),
											Text = "Red",
											TextColor3 = Color3.fromRGB(255, 255, 255),
											TextSize = 14,
										}),
										UIListLayout = React.createElement("UIListLayout", {
											FillDirection = Enum.FillDirection.Horizontal,
											Padding = UDim.new(0, 10),
											SortOrder = Enum.SortOrder.LayoutOrder,
											VerticalAlignment = Enum.VerticalAlignment.Center,
										}),
										UICorner = React.createElement(Corner),
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
						}),
					}),
					ImageLabel = React.createElement("ImageLabel", {
						BackgroundTransparency = 1,
						Image = "rbxassetid://14073589622",
						ImageTransparency = 0.88,
						Position = UDim2.new(0.334, 0, 0.0467, 0),
						Size = UDim2.new(0, 331, 0, 344),
					}),
				}),
			}),
			Title = React.createElement("Frame", {
				AutomaticSize = Enum.AutomaticSize.Y,
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 0),
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
				Separator = React.createElement("Frame", {
					BackgroundTransparency = 1,
					LayoutOrder = 2,
					Size = UDim2.new(1, 0, 0, 0),
				}, {
					Separator = React.createElement("Frame", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = Color3.fromRGB(255, 255, 255),
						BackgroundTransparency = 0.7,
						BorderColor3 = Color3.fromRGB(27, 42, 53),
						BorderSizePixel = 0,
						Position = UDim2.new(0.5, 0, 0.5, 0),
						Size = UDim2.new(0.8, 0, 0, 1),
						Transparency = 0.7,
					}),
				}),
				UIListLayout = React.createElement("UIListLayout", {
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
			}),
			TextButton = React.createElement("TextButton", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new(
					"rbxasset://fonts/families/Michroma.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Size = UDim2.new(1, 0, 0, 40),
				Text = "Create Room",
				TextColor3 = Color3.fromRGB(0, 0, 0),
				TextScaled = true,
				TextSize = 20,
				TextWrapped = true,
			}, {
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
			}),
		}),
	}),
})

end

return {
  Lobby = Lobby,
}