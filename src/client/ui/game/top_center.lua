local ReplicatedStorage = game:GetService "ReplicatedStorage"
local React = require(ReplicatedStorage.Packages.react)
local RunService = game:GetService "RunService"
local MainContext = require(ReplicatedStorage.Client.ui.context).MainContext
local themes = require(ReplicatedStorage.Client.ui.themes)
local util_components = require(ReplicatedStorage.Client.ui.util_components)
local Corner = util_components.Corner

local decision_remote = ReplicatedStorage:FindFirstChild "DecisionRemote" :: RemoteEvent

function TopCenter()
	local grid = React.useContext(MainContext).grid
	local _, force_update = React.useReducer(function(x)
		return x + 1
	end, 0)
	local bar_ref = React.useRef(nil)
	local display_ref = React.useRef(nil)

	React.useEffect(function()
		local cleanup = grid.grid_update_signal.listen(function(updates)
			for _, update in updates do
				if update.type == "turn_timer" or update.type == "turn" or update.type == "turn_skips" then
					force_update(nil)
				end
			end
		end)
		local connection = RunService.Heartbeat:Connect(function()
			if not bar_ref.current then
				return
			end
			local current_time = DateTime.now().UnixTimestampMillis
			bar_ref.current.Size =
				UDim2.new((current_time - grid.turn_start_time) / (grid.turn_end_time - grid.turn_start_time), 0, 1, 0)
			local t = grid.turn_end_time - current_time
			t = math.max(0, t)
			display_ref.current.Text = "Next Turn: " .. math.floor(t / 100) / 10 .. "s"
		end)

		return function()
			cleanup()
			connection:Disconnect()
		end
	end, {})

	return React.createElement("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Position = UDim2.new(0.5, 0, 0, 20),
	}, {
		HorizontalLayout = React.createElement("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),

		TurnIndicator = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(13, 13, 13),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			LayoutOrder = 1,
			Size = UDim2.fromOffset(120, 80),
			Transparency = 0.2,
		}, {
			Gradient = React.createElement("UIGradient", {
				Color = ColorSequence.new {
					ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 0, 0)),
					ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 255, 255)),
				},
				Rotation = 90,
			}),

			Turns = React.createElement("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				RichText = true,
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.new(0, 0, 0.325, 0),
				Size = UDim2.new(1, 0, 0.4, 0),
				Text = tostring(grid.turn) .. '<font color="#00FF00" size="30"></font>',
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 50,
			}),

			Corner = React.createElement(Corner),

			Title = React.createElement(
				"TextLabel",
				themes.theme_title {
					AutomaticSize = Enum.AutomaticSize.X,
					BackgroundTransparency = 1,
					FontFace = Font.new(
						"rbxasset://fonts/families/Oswald.json",
						Enum.FontWeight.Bold,
						Enum.FontStyle.Normal
					),
					Position = UDim2.fromOffset(0, 5),
					Size = UDim2.new(1, 0, 0, 25),
					Text = "Turn",
					TextColor3 = Color3.fromRGB(255, 255, 255),
					TextSize = 18,
					TextXAlignment = Enum.TextXAlignment.Left,
				},
				{
					PaddingLeft = React.createElement("UIPadding", {
						PaddingLeft = UDim.new(0, 10),
					}),
				}
			),
		}),

		Timer = React.createElement("Frame", {
			BackgroundColor3 = Color3.fromRGB(13, 13, 13),
			BackgroundTransparency = 0.2,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			LayoutOrder = 2,
			Size = UDim2.fromOffset(500, 40),
			Transparency = 0.2,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),

			Bar = React.createElement("Frame", {
				BackgroundColor3 = Color3.fromRGB(57, 57, 57),
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Size = UDim2.new(0, 0, 1, 0),
				ref = bar_ref,
			}, {
				Corner = React.createElement("UICorner", {
					CornerRadius = UDim.new(0, 4),
				}),
			}),

			Display = React.createElement("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundTransparency = 1,
				ref = display_ref,
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				Size = UDim2.fromOffset(0, 20),
				Text = "Next Turn: 0.0s",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 20,
				ZIndex = 2,
			}),
		}),

		SkipButton = React.createElement("TextButton", {
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundColor3 = Color3.fromRGB(13, 13, 13),
			BackgroundTransparency = 0.2,
			BorderColor3 = Color3.fromRGB(0, 0, 0),
			BorderSizePixel = 0,
			FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
			LayoutOrder = 3,
			Size = UDim2.fromOffset(70, 30),
			Text = "",
			TextColor3 = Color3.fromRGB(255, 255, 255),
			TextSize = 20,
			[React.Event.MouseButton1Click] = function()
				decision_remote:FireServer { {
					type = "skip",
				} }
			end,
		}, {
			Corner = React.createElement("UICorner", {
				CornerRadius = UDim.new(0, 4),
			}),

			ImageLabel = React.createElement("ImageLabel", {
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				Image = "http://www.roblox.com/asset/?id=6026667005",
				LayoutOrder = 1,
				Position = UDim2.new(0, 0, 0.5, 0),
				Size = UDim2.fromOffset(20, 20),
			}),

			SkipLabel = React.createElement("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
				LayoutOrder = 2,
				Size = UDim2.new(0, 0, 1, 0),
				Text = "Skip",
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextSize = 20,
			}),

			HorizontalLayout = React.createElement("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				Padding = UDim.new(0, 5),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			SidePad = React.createElement("UIPadding", {
				PaddingLeft = UDim.new(0, 5),
				PaddingRight = UDim.new(0, 10),
			}),

			AmountLabel = React.createElement("TextLabel", {
				AutomaticSize = Enum.AutomaticSize.X,
				BackgroundColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundTransparency = 1,
				BorderColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,
				FontFace = Font.new "rbxasset://fonts/families/SourceSansPro.json",
				LayoutOrder = 2,
				Size = UDim2.new(0, 0, 1, 0),
				Text = `{grid.current_skips}/{grid.needed_skips}`,
				TextColor3 = Color3.fromRGB(190, 190, 190),
				TextSize = 15,
			}),
		}),
	})
end

return {
	TopCenter = TopCenter,
}
